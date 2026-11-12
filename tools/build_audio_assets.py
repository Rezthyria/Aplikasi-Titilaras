"""Bangun aset audio FLAC dari dataset Shure terbaru.

Input : dataset_titilaras_baru/Shure_*.wav
Output: assets/audio/{instrumen}_{artikulasi}_{angka}.flac

Pipeline:
- hanya memilih rekaman mic Shure;
- Sustain diperlakukan sebagai open (id app: muka);
- Shure_Demung_Demung adalah demung tengkep (nama file dataset salah);
- label tengkep tetap menjadi tengkep untuk saron/peking;
- memilih kandidat yang paling dekat dengan register target;
- trim onset agar sample responsif;
- trim ekor senyap, fade pendek, normalisasi puncak ke -3 dBFS;
- encode FLAC lossless.
"""
from __future__ import annotations

import re
from pathlib import Path

import librosa
import numpy as np
import soundfile as sf
from scipy.signal import medfilt

ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "dataset_titilaras_baru"
OUT_DIR = ROOT / "assets" / "audio"
OUT_SR = 48000
MAX_SECONDS_OPEN = 1.45
MAX_SECONDS_TENGKEP = 0.82
PEAK_TARGET = 10 ** (-3 / 20)  # -3 dBFS, headroom aman anti-crack.

NOTE_TO_ANGKA = {"da": 1, "mi": 2, "na": 3, "ti": 4, "la": 5}

# Frekuensi natural terukur (Hz) per instrumen & angka.
TARGET = {
    "demung": {1: 472.4, 2: 409.8, 3: 357.3, 4: 312.2, 5: 272.5},
    "saron": {1: 948.8, 2: 824.3, 3: 719.3, 4: 631.2, 5: 549.8},
    "peking": {1: 1889.9, 2: 1643.9, 3: 1440.7, 4: 1250.3, 5: 1091.5},
}

OPEN_TOKENS = {"sustain"}
TENGKEP_TOKENS = {"demung", "tengkep", "tengkep (d)"}


def parse(stem: str):
    if "-" not in stem:
        return None
    left, right = stem.split("-", 1)
    parts = left.split("_")
    if len(parts) < 3 or parts[0].lower() != "shure":
        return None
    note = re.match(r"^(da|mi|na|ti|la)(_ageung|_alit)?$", right.lower().strip())
    if not note:
        return None
    instrument = parts[1].lower()
    if instrument not in TARGET:
        return None
    return {
        "instrument": instrument,
        "articulation": "_".join(parts[2:]).lower(),
        "angka": NOTE_TO_ANGKA[note.group(1)],
    }


def _mono_float(path: Path, sr: int) -> np.ndarray:
    y, _ = librosa.load(path, sr=sr, mono=True)
    if y.size == 0:
        return np.zeros(1, dtype=np.float32)
    return y.astype(np.float32)


def energy_at(path: Path, target: float) -> float:
    y = _mono_float(path, 22050)
    y, _ = librosa.effects.trim(y, top_db=42)
    if len(y) < 1024:
        return 0.0
    win = y * np.hanning(len(y))
    nfft = 1 << int(np.ceil(np.log2(len(win) * 2)))
    spec = np.abs(np.fft.rfft(win, n=nfft))
    freqs = np.fft.rfftfreq(nfft, 1 / 22050)
    band = (freqs >= target * 0.965) & (freqs <= target * 1.035)
    total = (freqs >= 80) & (freqs <= 4200)
    denom = spec[total].sum()
    return float(spec[band].sum() / denom) if denom > 0 else 0.0


def onset_start(y: np.ndarray, sr: int) -> int:
    """Cari awal transient/attack, bukan awal ambience.

    Rekaman wilahan punya noise ruangan sebelum pukulan. Untuk sinkron dengan
    metronome, posisi 0 harus dekat ke transient pertama, dengan pre-roll sangat
    kecil agar klik sample tidak ikut terpotong.
    """
    peak = float(np.max(np.abs(y))) if len(y) else 0.0
    if peak <= 0:
        return 0

    candidates: list[int] = []

    try:
        onsets = librosa.onset.onset_detect(y=y, sr=sr, units="samples", backtrack=True)
        if len(onsets) > 0:
            candidates.append(int(onsets[0]))
    except Exception:
        pass

    # Envelope RMS 1 ms untuk mengabaikan noise ambience dan menangkap attack.
    frame = max(16, int(0.001 * sr))
    kernel = np.ones(frame, dtype=np.float32) / frame
    env = np.sqrt(np.convolve(y * y, kernel, mode="same"))
    smooth = medfilt(env, kernel_size=9)
    noise_len = min(len(smooth), int(0.12 * sr))
    noise_floor = float(np.percentile(smooth[:noise_len], 95)) if noise_len else 0.0
    threshold = max(peak * 0.035, noise_floor * 5.0)
    above = np.where(smooth >= threshold)[0]
    if len(above) > 0:
        candidates.append(int(above[0]))

    # Transient lokal: cari lonjakan slope terbesar sebelum puncak awal.
    search_len = min(len(smooth), int(0.35 * sr))
    if search_len > frame * 2:
        diff = np.diff(smooth[:search_len], prepend=smooth[0])
        min_amp = max(peak * 0.012, noise_floor * 2.5)
        valid = np.where(smooth[:search_len] >= min_amp)[0]
        if len(valid) > 0:
            window_end = min(search_len, int(valid[0]) + int(0.08 * sr))
            transient = int(np.argmax(diff[:window_end]))
            candidates.append(transient)

    start = min(c for c in candidates if c >= 0) if candidates else 0
    return max(0, start - int(0.0015 * sr))


def trim_tail(
    y: np.ndarray,
    sr: int,
    max_seconds: float,
    min_seconds: float,
) -> np.ndarray:
    max_len = int(max_seconds * sr)
    min_len = min(len(y), int(min_seconds * sr))
    y = y[:max_len]
    peak = float(np.max(np.abs(y))) if len(y) else 0.0
    if peak <= 0:
        return y
    frame = max(64, int(0.008 * sr))
    hop = max(16, frame // 4)
    rms = []
    starts = []
    for start in range(0, max(1, len(y) - frame), hop):
        chunk = y[start : start + frame]
        rms.append(float(np.sqrt(np.mean(chunk * chunk))))
        starts.append(start)
    if rms:
        rms_arr = np.asarray(rms)
        floor = float(np.percentile(rms_arr[-min(len(rms_arr), 12) :], 65))
        threshold = max(peak * 0.010, floor * 2.2)
        hold = max(2, int(0.055 * sr / hop))
        cut = len(y)
        for i in range(len(rms_arr) - hold):
            if starts[i] < min_len:
                continue
            if np.all(rms_arr[i : i + hold] <= threshold):
                cut = starts[i] + int(0.035 * sr)
                break
        y = y[: max(min_len, min(len(y), cut))]
    return y


def process_and_write(src: Path, dst: Path, artikulasi: str) -> dict[str, float]:
    y = _mono_float(src, OUT_SR)
    y = y[onset_start(y, OUT_SR) :]
    y = trim_tail(
        y,
        OUT_SR,
        MAX_SECONDS_TENGKEP if artikulasi == "tengkep" else MAX_SECONDS_OPEN,
        0.18 if artikulasi == "tengkep" else 0.62,
    )
    if len(y) == 0:
        y = np.zeros(int(0.1 * OUT_SR), dtype=np.float32)

    fade_in = min(int(0.0015 * OUT_SR), max(1, len(y) // 100))
    fade_out = min(int(0.095 * OUT_SR), max(1, len(y) // 3))
    env = np.ones_like(y)
    env[:fade_in] = np.linspace(0, 1, fade_in)
    env[-fade_out:] = np.linspace(1, 0, fade_out)
    y = y * env

    peak_before = float(np.max(np.abs(y))) if len(y) else 0.0
    if peak_before > 0:
        y = y / peak_before * PEAK_TARGET
    peak_after = float(np.max(np.abs(y))) if len(y) else 0.0
    sf.write(dst, y.astype(np.float32), OUT_SR, format="FLAC", subtype="PCM_16")
    return {
        "seconds": len(y) / OUT_SR,
        "peak_before": peak_before,
        "peak_after": peak_after,
    }


def write_metronome() -> None:
    n = int(OUT_SR * 0.045)
    t = np.arange(n) / OUT_SR
    click = np.sin(2 * np.pi * 1800 * t) * np.exp(-t * 95)
    click += 0.35 * np.sin(2 * np.pi * 900 * t) * np.exp(-t * 80)
    peak = float(np.max(np.abs(click))) if len(click) else 0.0
    if peak > 0:
        click = click / peak * 0.55
    sf.write(
        OUT_DIR / "metronome.flac",
        click.astype(np.float32),
        OUT_SR,
        format="FLAC",
        subtype="PCM_16",
    )


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in [*OUT_DIR.glob("*.wav"), *OUT_DIR.glob("*.flac"), *OUT_DIR.glob("*.ogg")]:
        old.unlink()

    files = [(p, parse(p.stem)) for p in DATASET.glob("Shure_*.wav")]
    files = [(p, meta) for p, meta in files if meta]

    groups = {"muka": OPEN_TOKENS, "tengkep": TENGKEP_TOKENS}
    built: list[tuple[str, str, float, dict[str, float]]] = []
    missing: list[str] = []
    for instrument, targets in TARGET.items():
        for artikulasi, tokens in groups.items():
            for angka, target in targets.items():
                candidates = [
                    p
                    for p, meta in files
                    if meta["instrument"] == instrument
                    and meta["articulation"] in tokens
                    and meta["angka"] == angka
                ]
                if not candidates:
                    missing.append(f"{instrument}_{artikulasi}_{angka}")
                    continue
                scored = [(energy_at(p, target), p) for p in candidates]
                scored.sort(reverse=True)
                best_score, best = scored[0]
                dst = OUT_DIR / f"{instrument}_{artikulasi}_{angka}.flac"
                metrics = process_and_write(best, dst, artikulasi)
                built.append((dst.name, best.name, best_score, metrics))

    print(f"Dibangun {len(built)} file FLAC dari dataset Shure:")
    for name, src, score, metrics in built:
        print(
            f"  {name:23} <- {src:48} "
            f"score={score:.3f} dur={metrics['seconds']:.2f}s "
            f"peak={metrics['peak_after']:.3f}"
        )
    if missing:
        print("\nTIDAK ADA SUMBER untuk:")
        for item in missing:
            print(f"  {item}")
        raise SystemExit(1)
    write_metronome()
    print("  metronome.flac          <- generated click")


if __name__ == "__main__":
    main()

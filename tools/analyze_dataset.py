from __future__ import annotations

import math
import re
from pathlib import Path

import librosa
import numpy as np
import soundfile as sf
from scipy.signal import find_peaks

ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "Dataset_Titilaras"
SR = 22050

NOTE_TO_ANGKA = {"da": 1, "mi": 2, "na": 3, "ti": 4, "la": 5}
ANGKA_TO_NOTE = {v: k for k, v in NOTE_TO_ANGKA.items()}


def parse_name(stem: str):
    if "-" not in stem:
        return None
    left, right = stem.split("-", 1)
    parts = left.split("_")
    if len(parts) < 3:
        return None
    note_raw = right.lower().strip()
    m = re.match(r"^(da|mi|na|ti|la)(_ageung|_alit)?$", note_raw)
    if not m:
        return None
    octave = {"_ageung": -1, "_alit": 1}.get(m.group(2), 0)
    return dict(mic=parts[0], instrument=parts[1], articulation="_".join(parts[2:]),
                angka=NOTE_TO_ANGKA[m.group(1)], octave=octave)


def spectral_peaks(path: Path, fmin=80, fmax=1700):
    y, _ = librosa.load(path, sr=SR, mono=True)
    yt, _ = librosa.effects.trim(y, top_db=35)
    if len(yt) < SR * 0.05:
        yt = y
    start = int(0.05 * SR)
    end = min(len(yt), start + int(0.6 * SR))
    seg = yt[start:end] if end - start > 1024 else yt
    nfft = 1 << int(math.ceil(math.log2(len(seg) * 2)))
    win = seg * np.hanning(len(seg))
    spec = np.abs(np.fft.rfft(win, n=nfft))
    freqs = np.fft.rfftfreq(nfft, 1 / SR)
    band = (freqs >= fmin) & (freqs <= fmax)
    fb, sb = freqs[band], spec[band]
    if len(sb) == 0:
        return float("nan"), []
    peaks, props = find_peaks(sb, height=sb.max() * 0.12, distance=3)
    if len(peaks) == 0:
        return float("nan"), []
    order = np.argsort(sb[peaks])[::-1]
    top = [(float(fb[peaks[i]]), float(sb[peaks[i]] / sb.max())) for i in order[:6]]
    # fundamental = lowest-freq peak with magnitude >= 0.30 of the max peak
    strong = sorted([f for f, m in top if m >= 0.30])
    fundamental = strong[0] if strong else top[0][0]
    return fundamental, top


def main():
    rows = []
    for path in sorted(DATASET.glob("*.wav")):
        meta = parse_name(path.stem)
        if not meta:
            continue
        fund, peaks = spectral_peaks(path)
        rows.append((meta, fund, peaks))

    print("Lowest-strong-peak fundamental (Hz). mid = fund / 2^octave\n")
    print(f"{'instr':7} {'articul':12} {'ang':3} {'oct':>3} {'mic':8} {'fund':>8} {'mid':>8}   peaks(Hz@rel)")
    for meta, fund, peaks in sorted(rows, key=lambda r: (
            r[0]['instrument'].lower(), r[0]['articulation'].lower(),
            r[0]['angka'], r[0]['octave'], r[0]['mic'])):
        mid = fund / (2 ** meta['octave']) if math.isfinite(fund) else float('nan')
        ps = " ".join(f"{f:.0f}@{m:.2f}" for f, m in peaks)
        print(f"{meta['instrument'][:7]:7} {meta['articulation'][:12]:12} "
              f"{meta['angka']:<3} {meta['octave']:>3} {meta['mic'][:8]:8} "
              f"{fund:8.1f} {mid:8.1f}   {ps}")

    # Register relationship: mean fundamental of MIDDLE-octave (oct 0) notes per instrument
    print("\n=== Rata-rata fundamental nada oktaf-tengah (oct=0) per instrumen, sustain ===")
    reg = {}
    for meta, fund, peaks in rows:
        if meta['octave'] != 0 or 'sustain' not in meta['articulation'].lower():
            continue
        if math.isfinite(fund):
            reg.setdefault(meta['instrument'].lower(), []).append(fund)
    for instr in sorted(reg):
        vals = np.array(reg[instr])
        print(f"{instr:8}: mean={vals.mean():.1f} Hz  median={np.median(vals):.1f} Hz  n={len(vals)}  vals={np.round(vals,0)}")


if __name__ == "__main__":
    main()

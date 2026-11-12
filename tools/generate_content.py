from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTENT_DIR = ROOT / "assets" / "content"

SYLLABLE = {1: "da", 2: "mi", 3: "na", 4: "ti", 5: "la"}

LARAS = {
    "salendro": {
        "unit_id": "unit_salendro",
        "title": "Salendro",
        "file": "salendro.json",
        "scale": [1, 2, 3, 4, 5],
        "base": 1,
    },
}


def tone(number: int, octave: int = 0) -> dict:
    return {"angka": number, "oktafRelatif": octave}


def opt_number(number: int) -> dict:
    return {"label": f"{number} {SYLLABLE[number]}", "nilai": str(number)}


def opt_sequence(seq: list[int]) -> dict:
    value = "-".join(str(n) for n in seq)
    return {"label": value, "nilai": value}


def opt_syllables(seq: list[int]) -> dict:
    value = "-".join(SYLLABLE[n] for n in seq)
    return {"label": value, "nilai": value}


def nearby_numbers(target: int) -> list[int]:
    order = [target, ((target) % 5) + 1, ((target + 1) % 5) + 1]
    result = []
    for item in order:
        if item not in result:
            result.append(item)
    for item in [1, 2, 3, 4, 5]:
        if len(result) >= 3:
            break
        if item not in result:
            result.append(item)
    return result


def sequence_distractors(seq: list[int]) -> list[list[int]]:
    variants = [seq]
    if len(seq) >= 2:
        variants.append([seq[1], seq[0], *seq[2:]])
        variants.append([*seq[:-2], seq[-1], seq[-2]])
    variants.append([((n) % 5) + 1 for n in seq])
    result = []
    for item in variants:
        if item not in result:
            result.append(item)
    return result[:3]


def loop(
    *,
    acuan: bool,
    jenis_acuan: str,
    mode_input: str,
    arah: str = "menurun",
    tona_patokan: int | None = None,
    pola_contoh: list[int] | None = None,
) -> dict:
    data = {
        "acuanAktif": acuan,
        "jenisAcuan": jenis_acuan,
        "arahTangga": arah,
        "modePutarAcuan": "otomatis" if acuan else "atas_permintaan",
        "bolehLewatiAcuan": True,
        "batasPemutaranUlang": 4,
        "modeInput": mode_input,
        "bolehPercobaanUlang": True,
        "jedaAcuanStimulusMs": 450,
        "skoring": {"skorPenuh": 100, "skorUlang": 60},
    }
    if tona_patokan is not None:
        data["tonaPatokan"] = tone(tona_patokan)
    if pola_contoh is not None:
        data["polaContoh"] = [tone(n) for n in pola_contoh]
    return data


def single_tone_questions(laras_id: str, scale: list[int]) -> list[dict]:
    questions = []
    octaves = [0, -1, 1]
    for idx, octave in enumerate(octaves):
        for number in scale:
            questions.append(
                {
                    "id": f"{laras_id}_dengar_nada_{idx}_{number}",
                    "prompt": "Dengarkan satu nada, lalu pilih angka nadanya.",
                    "stimulus": {"jenis": "tona", "tona": tone(number, octave)},
                    "kunciJawaban": str(number),
                    "pilihan": [opt_number(n) for n in nearby_numbers(number)],
                }
            )
    return questions


PAIR_PATTERNS = [
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 1],
    [1, 3],
    [2, 4],
    [3, 5],
    [4, 1],
    [5, 2],
    [2, 1],
    [3, 2],
    [4, 3],
    [5, 4],
    [1, 5],
    [2, 5],
    [5, 3],
    [4, 2],
]


MELODY_PATTERNS = [
    [1, 2, 3],
    [2, 3, 4],
    [3, 4, 5],
    [5, 4, 3],
    [4, 3, 2],
    [3, 2, 1],
    [1, 3, 2],
    [2, 4, 3],
    [3, 5, 4],
    [5, 3, 1],
    [1, 4, 2],
    [2, 5, 3],
    [4, 1, 5],
    [5, 2, 4],
    [3, 1, 4],
    [1, 2, 3, 5],
    [5, 4, 3, 1],
    [2, 3, 5, 4],
    [4, 2, 1, 3],
    [3, 4, 2, 5],
    [5, 1, 2, 4],
    [1, 5, 4, 2],
    [2, 1, 3, 4],
    [4, 5, 3, 2],
]


def sequence_questions(laras_id: str, prefix: str, patterns: list[list[int]], prompt: str) -> list[dict]:
    questions = []
    for idx, seq in enumerate(patterns, start=1):
        questions.append(
            {
                "id": f"{laras_id}_{prefix}_{idx}",
                "prompt": prompt,
                "stimulus": {
                    "jenis": "urutan_tona",
                    "urutanTona": [tone(n) for n in seq],
                },
                "kunciJawaban": "-".join(str(n) for n in seq),
                "pilihan": [opt_sequence(item) for item in sequence_distractors(seq)],
            }
        )
    return questions


def reading_questions(laras_id: str, patterns: list[list[int]]) -> list[dict]:
    questions = []
    for idx, seq in enumerate(patterns, start=1):
        octave_seq = []
        for pos, number in enumerate(seq):
            octave = 0
            if idx % 7 == 0 and pos == 0:
                octave = -1
            elif idx % 6 == 0 and pos == len(seq) - 1:
                octave = 1
            octave_seq.append(tone(number, octave))
        questions.append(
            {
                "id": f"{laras_id}_baca_{idx}",
                "prompt": "Baca notasi angka yang tampil, lalu pilih bacaan daminatilanya.",
                "stimulus": {"jenis": "urutan_tona", "urutanTona": octave_seq},
                "kunciJawaban": "-".join(SYLLABLE[n] for n in seq),
                "pilihan": [opt_syllables(item) for item in sequence_distractors(seq)],
            }
        )
    return questions


def syllable_questions(laras_id: str) -> list[dict]:
    questions = []
    for octave in [0, -1, 1]:
        for number in [1, 2, 3, 4, 5]:
            suffix = "tengah" if octave == 0 else ("rendah" if octave < 0 else "tinggi")
            questions.append(
                {
                    "id": f"{laras_id}_nama_{suffix}_{number}",
                    "prompt": "Angka yang tampil dibaca sebagai apa?",
                    "stimulus": {"jenis": "tona", "tona": tone(number, octave)},
                    "kunciJawaban": SYLLABLE[number],
                    "pilihan": [
                        {"label": SYLLABLE[n], "nilai": SYLLABLE[n]}
                        for n in nearby_numbers(number)
                    ],
                }
            )
    return questions


def dictation_questions(laras_id: str, patterns: list[list[int]]) -> list[dict]:
    questions = []
    for idx, seq in enumerate(patterns, start=1):
        questions.append(
            {
                "id": f"{laras_id}_dikte_{idx}",
                "prompt": "Dengarkan urutan nada, lalu tuliskan notasi angkanya.",
                "stimulus": {
                    "jenis": "urutan_tona",
                    "urutanTona": [tone(n) for n in seq],
                },
                "kunciJawaban": "-".join(str(n) for n in seq),
                "pilihan": [],
            }
        )
    return questions


def exercise(
    *,
    ex_id: str,
    title: str,
    kind: str,
    config: dict,
    questions: list[dict],
) -> dict:
    return {
        "id": ex_id,
        "judul": title,
        "jenis": kind,
        "konfigLoop": config,
        "soal": questions,
    }


def make_unit(laras_id: str, data: dict) -> dict:
    scale = data["scale"]
    title = data["title"]
    base = data["base"]
    bab = [
        {
            "id": f"bab_{laras_id}_dengar",
            "judul": f"Dengar {title}",
            "tujuan": "Membedakan angka nada dari bunyi tunggal dan pola pendek.",
            "prasyaratBabId": [],
            "kriteria": {"minimalSesi": 1, "minimalSkor": 60},
            "latihan": [
                exercise(
                    ex_id=f"latihan_{laras_id}_dengar_nada",
                    title=f"Dengar Nada {title}",
                    kind="dengar",
                    config=loop(
                        acuan=True,
                        jenis_acuan="tangga_nada",
                        mode_input="pilih_opsi",
                    ),
                    questions=single_tone_questions(laras_id, scale),
                ),
                exercise(
                    ex_id=f"latihan_{laras_id}_pola_dua",
                    title=f"Dengar Pola Dua Nada {title}",
                    kind="dengar",
                    config=loop(
                        acuan=True,
                        jenis_acuan="tangga_nada",
                        mode_input="susun_urutan",
                    ),
                    questions=sequence_questions(
                        laras_id,
                        "pola_dua",
                        PAIR_PATTERNS,
                        "Dengarkan dua nada, lalu pilih urutan yang sama.",
                    ),
                ),
                exercise(
                    ex_id=f"latihan_{laras_id}_pola_melodi",
                    title=f"Dengar Pola Melodi {title}",
                    kind="dengar",
                    config=loop(
                        acuan=True,
                        jenis_acuan="tangga_nada",
                        mode_input="susun_urutan",
                    ),
                    questions=sequence_questions(
                        laras_id,
                        "pola_melodi",
                        MELODY_PATTERNS,
                        "Dengarkan pola nada, lalu pilih urutan yang sama.",
                    ),
                ),
            ],
        },
        {
            "id": f"bab_{laras_id}_notasi",
            "judul": f"Notasi Angka {title}",
            "tujuan": "Membaca angka, titik oktaf, dan nama nada daminatila.",
            "prasyaratBabId": [],
            "kriteria": {"minimalSesi": 1, "minimalSkor": 60},
            "latihan": [
                exercise(
                    ex_id=f"latihan_{laras_id}_baca",
                    title=f"Baca Notasi {title}",
                    kind="baca_notasi",
                    config=loop(
                        acuan=False,
                        jenis_acuan="tona_patokan",
                        mode_input="pilih_opsi",
                        tona_patokan=base,
                    ),
                    questions=reading_questions(laras_id, MELODY_PATTERNS),
                ),
                exercise(
                    ex_id=f"latihan_{laras_id}_nama_nada",
                    title=f"Nama Nada {title}",
                    kind="solfeg",
                    config=loop(
                        acuan=False,
                        jenis_acuan="pola_contoh",
                        mode_input="pilih_opsi",
                        pola_contoh=scale[:3],
                    ),
                    questions=syllable_questions(laras_id),
                ),
            ],
        },
        {
            "id": f"bab_{laras_id}_memori_dikte",
            "judul": f"Dikte {title}",
            "tujuan": "Mengingat pola lalu menuliskannya sebagai angka.",
            "prasyaratBabId": [],
            "kriteria": {"minimalSesi": 1, "minimalSkor": 60},
            "latihan": [
                exercise(
                    ex_id=f"latihan_{laras_id}_dikte",
                    title=f"Dikte {title}",
                    kind="dikte",
                    config=loop(
                        acuan=True,
                        jenis_acuan="tangga_nada",
                        mode_input="tulis_notasi",
                    ),
                    questions=dictation_questions(laras_id, MELODY_PATTERNS),
                ),
            ],
        },
    ]
    return {
        "id": data["unit_id"],
        "judul": title,
        "laras": laras_id,
        "bab": bab,
    }


def main() -> None:
    CONTENT_DIR.mkdir(parents=True, exist_ok=True)
    for laras_id, data in LARAS.items():
        unit = make_unit(laras_id, data)
        path = CONTENT_DIR / data["file"]
        path.write_text(
            json.dumps(unit, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        total = sum(len(lat["soal"]) for bab in unit["bab"] for lat in bab["latihan"])
        print(f"{path.name}: {total} soal")


if __name__ == "__main__":
    main()

import 'dart:math' as math;

import 'models.dart';

double frekuensiTona(
  Tona tona,
  ProfilTuning profil, {
  double offsetHz = 0,
  double offsetCents = 0,
}) {
  final entry = profil.entryFor(tona.angka);
  final akar = profil.frekuensiNadaDasarHz + offsetHz;
  final cents = entry.cents + (tona.oktafRelatif * 1200) + offsetCents;
  return akar * math.pow(2, cents / 1200);
}

class HasilPitch {
  final double? frekuensiHz;
  final Tona? tonaTerdekat;
  final double? selisihCents;
  final bool tepat;
  final String pesan;

  const HasilPitch({
    required this.frekuensiHz,
    required this.tonaTerdekat,
    required this.selisihCents,
    required this.tepat,
    required this.pesan,
  });
}

/// Memetakan frekuensi hasil deteksi ke nada salendro berdasarkan *pitch class*
/// (oktaf-independen). Latihan suara hanya perlu mengenali nada (da/mi/na/ti/la)
/// yang dinyanyikan, di oktaf mana pun suara pengguna berada. Pendekatan ini
/// jauh lebih tahan terhadap rentang vokal manusia daripada pencocokan oktaf
/// absolut.
HasilPitch petakanPitchKeTona(
  double? frekuensiHz,
  ProfilTuning profil,
  double toleransiCents,
) {
  if (frekuensiHz == null || frekuensiHz <= 0) {
    return const HasilPitch(
      frekuensiHz: null,
      tonaTerdekat: null,
      selisihCents: null,
      tepat: false,
      pesan: 'Suara belum terdeteksi',
    );
  }

  final base = profil.frekuensiNadaDasarHz;
  final cents = 1200 * math.log(frekuensiHz / base) / math.ln2;
  var cmod = cents % 1200;
  if (cmod < 0) cmod += 1200;

  TonaTuning? bestEntry;
  double? bestDelta;
  for (final entry in profil.tonaTengah) {
    var delta = cmod - (entry.cents % 1200);
    if (delta > 600) delta -= 1200;
    if (delta < -600) delta += 1200;
    if (bestDelta == null || delta.abs() < bestDelta.abs()) {
      bestDelta = delta;
      bestEntry = entry;
    }
  }

  if (bestEntry == null) {
    return const HasilPitch(
      frekuensiHz: null,
      tonaTerdekat: null,
      selisihCents: null,
      tepat: false,
      pesan: 'Suara belum terdeteksi',
    );
  }

  final tepat = bestDelta!.abs() <= toleransiCents;
  final oktaf = ((cents - bestEntry.cents) / 1200).round().clamp(-2, 2);
  final tona = Tona(angka: bestEntry.angka, oktafRelatif: oktaf);
  final arah = tepat
      ? 'tepat'
      : bestDelta > 0
      ? 'terlalu tinggi'
      : 'terlalu rendah';
  return HasilPitch(
    frekuensiHz: frekuensiHz,
    tonaTerdekat: tona,
    selisihCents: bestDelta,
    tepat: tepat,
    pesan: arah,
  );
}

/// Estimasi pitch dengan NSDF (Normalized Square Difference Function, metode
/// McLeod). Memilih puncak NSDF pertama di atas ambang relatif sehingga tahan
/// terhadap octave error (yang sering terjadi pada autokorelasi mentah) dan
/// noise. Mengembalikan frekuensi fundamental Hz, atau null bila tidak ada
/// nada yang cukup jelas.
///
/// Penting: panjang [samples] harus minimal dua periode dari [minHz]
/// (mis. window 2048 sampel @44.1kHz untuk minHz 70). Pemanggil sebaiknya
/// menampung sampel ke window tetap, bukan menganalisis tiap chunk mentah.
double? estimasiPitchAutokorelasi(
  List<double> samples,
  int sampleRate, {
  double minHz = 70,
  double maxHz = 700,
  double rmsThreshold = 0.012,
  double kejelasanMinimum = 0.6,
  double ambangPuncak = 0.85,
}) {
  final n = samples.length;
  if (n == 0) return null;
  final minLag = math.max(1, (sampleRate / maxHz).floor());
  final maxLag = (sampleRate / minHz).floor();
  if (maxLag <= minLag || n < 2 * maxLag) return null;

  var sumSquare = 0.0;
  for (final v in samples) {
    sumSquare += v * v;
  }
  if (math.sqrt(sumSquare / n) < rmsThreshold) return null;

  final nsdf = List<double>.filled(maxLag + 1, 0);
  for (var lag = minLag; lag <= maxLag; lag++) {
    var m = 0.0;
    var e = 0.0;
    final limit = n - lag;
    for (var i = 0; i < limit; i++) {
      final a = samples[i];
      final b = samples[i + lag];
      m += a * b;
      e += a * a + b * b;
    }
    nsdf[lag] = e > 0 ? 2 * m / e : 0;
  }

  // Kumpulkan puncak lokal positif dan nilai maksimum globalnya.
  final peaks = <int>[];
  var globalMax = 0.0;
  for (var lag = minLag + 1; lag < maxLag; lag++) {
    if (nsdf[lag] > nsdf[lag - 1] &&
        nsdf[lag] >= nsdf[lag + 1] &&
        nsdf[lag] > 0) {
      peaks.add(lag);
      if (nsdf[lag] > globalMax) globalMax = nsdf[lag];
    }
  }
  if (peaks.isEmpty || globalMax < kejelasanMinimum) return null;

  // Puncak PERTAMA (lag terkecil) di atas ambang relatif -> periode dasar.
  final threshold = ambangPuncak * globalMax;
  var chosen = -1;
  for (final lag in peaks) {
    if (nsdf[lag] >= threshold) {
      chosen = lag;
      break;
    }
  }
  if (chosen <= minLag || chosen >= maxLag) return null;

  // Interpolasi parabola untuk presisi sub-sampel.
  final a = nsdf[chosen - 1];
  final b = nsdf[chosen];
  final c = nsdf[chosen + 1];
  final denom = a - 2 * b + c;
  final shift = denom != 0 ? 0.5 * (a - c) / denom : 0.0;
  final period = chosen + shift;
  if (period <= 0) return null;
  return sampleRate / period;
}

// ===== Game Tebak Melodi: durasi, pemutaran, dan penilaian =====

/// Durasi (dalam ketukan) yang "dikonsumsi" tiap simbol pada deretnya.
/// Nada/istirahat: 1/2^beam. Titik perpanjangan ke-k: menambah base/2^k
/// (dot pertama +50%, dot kedua +25%, dst — total sesuai augmentasi jianpu).
List<double> ketukPerSimbol(List<SimbolNot> simbol) {
  final hasil = List<double>.filled(simbol.length, 0);
  var lastBase = 0.0;
  var lastIndexAda = false;
  var dotCount = 0;
  for (var i = 0; i < simbol.length; i++) {
    final s = simbol[i];
    switch (s.jenis) {
      case JenisSimbol.nada:
      case JenisSimbol.istirahat:
        final base = 1.0 / (1 << s.beam);
        hasil[i] = base;
        lastBase = base;
        lastIndexAda = true;
        dotCount = 0;
      case JenisSimbol.perpanjangan:
        if (lastIndexAda) {
          dotCount++;
          hasil[i] = lastBase / (1 << dotCount);
        } else {
          hasil[i] = 0;
        }
    }
  }
  return hasil;
}

/// Mengubah deret simbol menjadi kejadian audio (titik perpanjangan dilipat ke
/// nada/istirahat sebelumnya).
List<KejadianMelodi> kejadianMelodi(List<SimbolNot> simbol) {
  final ketuk = ketukPerSimbol(simbol);
  final events = <KejadianMelodi>[];
  for (var i = 0; i < simbol.length; i++) {
    final s = simbol[i];
    if (s.jenis == JenisSimbol.perpanjangan) {
      if (events.isNotEmpty) {
        final last = events.removeLast();
        events.add(
          KejadianMelodi(tona: last.tona, ketuk: last.ketuk + ketuk[i]),
        );
      }
    } else {
      events.add(KejadianMelodi(tona: s.tona, ketuk: ketuk[i]));
    }
  }
  return events;
}

/// Indeks simbol yang sesudahnya garis birama `|` digambar (default 4/4).
List<int> indeksBirama(List<SimbolNot> simbol, {double ketukPerBirama = 4}) {
  final ketuk = ketukPerSimbol(simbol);
  final bars = <int>[];
  var cum = 0.0;
  for (var i = 0; i < simbol.length; i++) {
    cum += ketuk[i];
    final kelipatan = cum / ketukPerBirama;
    final dekat = (kelipatan - kelipatan.round()).abs() < 1e-6;
    if (dekat && cum > 0 && i < simbol.length - 1) {
      bars.add(i);
    }
  }
  return bars;
}

class HasilBandingNot {
  final SimbolNot? target;
  final SimbolNot? jawaban;
  final bool benar;

  const HasilBandingNot({
    required this.target,
    required this.jawaban,
    required this.benar,
  });
}

/// Membandingkan jawaban siswa dengan target posisi-per-posisi.
List<HasilBandingNot> bandingkanMelodi(
  List<SimbolNot> target,
  List<SimbolNot> jawaban,
) {
  final n = math.max(target.length, jawaban.length);
  return [
    for (var i = 0; i < n; i++)
      HasilBandingNot(
        target: i < target.length ? target[i] : null,
        jawaban: i < jawaban.length ? jawaban[i] : null,
        benar:
            i < target.length && i < jawaban.length && target[i] == jawaban[i],
      ),
  ];
}

/// Skor 0..100 dari proporsi simbol target yang dijawab benar.
int skorMelodi(List<HasilBandingNot> hasil) {
  if (hasil.isEmpty) return 0;
  final benar = hasil.where((item) => item.benar).length;
  return (benar * 100 / hasil.length).round();
}

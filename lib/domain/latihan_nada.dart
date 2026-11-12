import 'dart:math';

/// Generator dan penilaian untuk latihan berbasis HIMPUNAN nada (1..5):
/// "Tebak Nada Hilang" dan "Tebak Harmoni". Keduanya adaptif per level.
const int levelMaksSetNada = 5;

/// Soal Tebak Nada Hilang: deret [urutan] (permutasi 1..5) dimainkan, tetapi
/// nada pada [hilang] diganti istirahat. Siswa menebak nada yang hilang.
class SoalNadaHilang {
  final List<int> urutan;
  final Set<int> hilang;

  const SoalNadaHilang({required this.urutan, required this.hilang});
}

/// Jumlah nada yang dihilangkan menurut level (1 termudah, 3 tersulit).
int jumlahHilangUntukLevel(int level) =>
    switch (level.clamp(1, levelMaksSetNada)) {
      1 => 1,
      2 => 1,
      3 => 2,
      4 => 2,
      _ => 3,
    };

SoalNadaHilang buatNadaHilang(int level, Random r) {
  final acak = level >= 2; // level 1 berurutan da-mi-na-ti-la
  final urutan = [1, 2, 3, 4, 5];
  if (acak) urutan.shuffle(r);
  final k = jumlahHilangUntukLevel(level);
  final pool = [...urutan]..shuffle(r);
  final hilang = pool.take(k).toSet();
  return SoalNadaHilang(urutan: urutan, hilang: hilang);
}

/// Jumlah nada serentak menurut level untuk Tebak Harmoni.
int jumlahHarmoniUntukLevel(int level) =>
    switch (level.clamp(1, levelMaksSetNada)) {
      1 => 1,
      2 => 2,
      3 => 2,
      4 => 3,
      _ => 3,
    };

Set<int> buatHarmoni(int level, Random r) {
  final n = jumlahHarmoniUntukLevel(level);
  final l = level.clamp(1, levelMaksSetNada);
  if (l <= 2) {
    final mulai = r.nextInt(4) + 1;
    return {mulai, mulai + 1}.take(n).toSet();
  }
  if (l == 4) {
    final mulai = r.nextInt(3) + 1;
    return {mulai, mulai + 1, mulai + 2};
  }
  final pool = [1, 2, 3, 4, 5]..shuffle(r);
  return pool.take(n).toSet();
}

/// Skor 0..100: benar (true positive) dikurangi salah pilih (false positive),
/// dinormalkan terhadap jumlah target.
int skorSetNada(Set<int> target, Set<int> jawaban) {
  if (target.isEmpty) return 0;
  final tp = target.intersection(jawaban).length;
  final fp = jawaban.difference(target).length;
  final net = (tp - fp).clamp(0, target.length);
  return (net * 100 / target.length).round();
}

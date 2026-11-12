import 'models.dart';
import 'logic.dart';

class StatusAudio {
  final bool memakaiFallback;
  final String pesan;

  const StatusAudio({required this.memakaiFallback, required this.pesan});
}

abstract class AudioPort {
  Future<void> muatProfilTuning(ProfilTuning profil);
  Future<void> setInstrumen(PilihanInstrumen instrumen);
  Future<void> setArtikulasi(Artikulasi artikulasi);
  Future<void> putarTona(Tona tona);

  /// Membunyikan beberapa nada serentak (untuk latihan harmoni).
  Future<void> putarSerentak(List<Tona> nada);
  Future<void> putarUrutan(List<Tona> urutan, {Duration jeda});
  Future<void> putarPolaIrama(PolaIrama pola);

  /// Memutar deret kejadian melodi dengan ritme (durasi per ketukan) pada
  /// tempo [bpm]. Istirahat (tona null) hanya menahan jeda. Jika [metronome]
  /// aktif, click pendek dibunyikan pada awal tiap kejadian agar rest tetap
  /// terbaca sebagai ketukan.
  Future<void> putarMelodi(
    List<KejadianMelodi> kejadian, {
    double bpm,
    bool metronome,
  });
  Stream<StatusAudio> get status;
}

abstract class PitchPort {
  Future<bool> mintaIzinMikrofon();
  bool get izinDiberikan;
  Stream<HasilPitch> mulaiDeteksi(ProfilTuning profil, double toleransiCents);
  Future<void> hentikanDeteksi();
}

abstract class StoragePort {
  Future<Pengaturan> muatPengaturan();
  Future<void> simpanPengaturan(Pengaturan pengaturan);
  Future<ProgresPengguna> muatProgres();
  Future<void> simpanProgres(ProgresPengguna progres);
  Future<void> resetProgres();
}

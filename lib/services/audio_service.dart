import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../domain/models.dart';
import '../domain/services.dart';

/// Memutar sample saron asli (FLAC) tanpa pitch-shift.
///
/// Penamaan aset: `assets/audio/{instrumen}_{artikulasi}_{angka}.flac`.
///
/// Agar tidak terputus-putus: tiap sample dimuat sekali ke pemutar tersendiri
/// (cache), lalu dimainkan ulang dengan `seek(0)+play()` TANPA menghentikan
/// nada sebelumnya — sehingga ekor decay nada saling menyambung dan beberapa
/// nada bisa berbunyi serentak (untuk latihan harmoni).
class JustAudioService implements AudioPort {
  final Map<String, AudioPlayer> _pemutar = {};
  final StreamController<StatusAudio> _status =
      StreamController<StatusAudio>.broadcast();

  PilihanInstrumen _instrumen = PilihanInstrumen.auto;
  Artikulasi _artikulasi = Artikulasi.muka;

  @override
  Stream<StatusAudio> get status => _status.stream;

  @override
  Future<void> muatProfilTuning(ProfilTuning profil) async {}

  @override
  Future<void> setInstrumen(PilihanInstrumen instrumen) async {
    _instrumen = instrumen;
    _status.add(StatusAudio(memakaiFallback: false, pesan: instrumen.label));
  }

  @override
  Future<void> setArtikulasi(Artikulasi artikulasi) async {
    _artikulasi = artikulasi;
  }

  Future<AudioPlayer?> _siapkan(String path) async {
    final ada = _pemutar[path];
    if (ada != null) return ada;
    try {
      final player = AudioPlayer();
      await player.setAsset(path);
      _pemutar[path] = player;
      return player;
    } catch (error) {
      _status.add(
        StatusAudio(
          memakaiFallback: false,
          pesan: 'Sample audio tidak ditemukan: $path',
        ),
      );
      return null;
    }
  }

  Future<void> _bunyikan(Tona tona) async {
    final player = await _siapkan(_assetPath(tona));
    if (player == null) return;
    await player.seek(Duration.zero);
    unawaited(player.play());
  }

  Future<void> _bunyikanClick() async {
    final player = await _siapkan('assets/audio/metronome.flac');
    if (player == null) return;
    await player.seek(Duration.zero);
    unawaited(player.play());
  }

  @override
  Future<void> putarTona(Tona tona) async {
    await _bunyikan(tona);
  }

  @override
  Future<void> putarSerentak(List<Tona> nada) async {
    for (final tona in nada) {
      await _bunyikan(tona);
    }
  }

  @override
  Future<void> putarUrutan(List<Tona> urutan, {Duration? jeda}) async {
    final wait = jeda ?? const Duration(milliseconds: 620);
    for (final tona in urutan) {
      await _bunyikan(tona);
      await Future<void>.delayed(wait);
    }
  }

  @override
  Future<void> putarPolaIrama(PolaIrama pola) async {
    final beatMs = (60000 / pola.tempoBpm).round();
    for (final ketuk in pola.ketukan) {
      await _bunyikan(Tona(angka: ketuk.angka));
      await Future<void>.delayed(Duration(milliseconds: beatMs));
    }
  }

  @override
  Future<void> putarMelodi(
    List<KejadianMelodi> kejadian, {
    double bpm = 96,
    bool metronome = false,
  }) async {
    final beatMs = 60000 / bpm;
    for (final k in kejadian) {
      final bunyi = <Future<void>>[];
      if (metronome) {
        bunyi.add(_bunyikanClick());
      }
      if (k.tona != null) {
        bunyi.add(_bunyikan(k.tona!));
      }
      if (bunyi.isNotEmpty) {
        await Future.wait(bunyi);
      }
      await Future<void>.delayed(
        Duration(milliseconds: (k.ketuk * beatMs).round()),
      );
    }
  }

  String _instrumenUntuk(Tona tona) {
    if (_instrumen != PilihanInstrumen.auto) return _instrumen.id;
    if (tona.oktafRelatif <= -1) return PilihanInstrumen.demung.id;
    if (tona.oktafRelatif >= 1) return PilihanInstrumen.peking.id;
    return PilihanInstrumen.saron.id;
  }

  String _assetPath(Tona tona) {
    return 'assets/audio/${_instrumenUntuk(tona)}_${_artikulasi.id}_${tona.angka}.flac';
  }
}

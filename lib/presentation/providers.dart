import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/services.dart';
import '../services/audio_service.dart';
import '../services/local_storage.dart';
import '../services/pitch_service.dart';

final audioProvider = Provider<AudioPort>((ref) => JustAudioService());
final pitchProvider = Provider<PitchPort>((ref) => RecordPitchService());
final storageProvider = Provider<StoragePort>((ref) => LocalStorageService());
final assetRepositoryProvider = Provider((ref) => AssetJsonRepository());

final appControllerProvider =
    StateNotifierProvider<AppController, AsyncValue<AppState>>((ref) {
      return AppController(ref);
    });

class AppState {
  final List<ProfilTuning> profilTuning;
  final ProgresPengguna progres;
  final Pengaturan pengaturan;
  final List<KesalahanParsing> kesalahanParsing;

  const AppState({
    required this.profilTuning,
    required this.progres,
    required this.pengaturan,
    this.kesalahanParsing = const [],
  });

  ProfilTuning profilAktif() {
    return profilTuning.firstWhere(
      (profil) => profil.id == pengaturan.profilTuningId,
      orElse: () => profilTuning.first,
    );
  }

  AppState copyWith({
    List<ProfilTuning>? profilTuning,
    ProgresPengguna? progres,
    Pengaturan? pengaturan,
    List<KesalahanParsing>? kesalahanParsing,
  }) {
    return AppState(
      profilTuning: profilTuning ?? this.profilTuning,
      progres: progres ?? this.progres,
      pengaturan: pengaturan ?? this.pengaturan,
      kesalahanParsing: kesalahanParsing ?? this.kesalahanParsing,
    );
  }
}

class AppController extends StateNotifier<AsyncValue<AppState>> {
  final Ref ref;

  AppController(this.ref) : super(const AsyncValue.loading()) {
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final storage = ref.read(storageProvider);
      final repo = ref.read(assetRepositoryProvider);
      final settings = await storage.muatPengaturan();
      final tuningResult = await repo.muatProfilTuning();
      final progress = await storage.muatProgres();
      final current = AppState(
        profilTuning: tuningResult.data,
        progres: progress,
        pengaturan: settings.copyWith(
          profilTuningId:
              tuningResult.data.any((p) => p.id == settings.profilTuningId)
              ? settings.profilTuningId
              : tuningResult.data.first.id,
        ),
        kesalahanParsing: tuningResult.kesalahan,
      );
      state = AsyncValue.data(current);
      await _applyAudioSettings(current);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updatePengaturan(Pengaturan next) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(pengaturan: next);
    state = AsyncValue.data(updated);
    await ref.read(storageProvider).simpanPengaturan(next);
    await _applyAudioSettings(updated);
  }

  /// Mencatat satu ronde game (level dicapai + streak saat itu) ke progres.
  Future<void> catatRondeGame(
    String gameId, {
    required int level,
    required int streak,
    required int missStreak,
    required int skor,
    required bool benar,
    bool simpanLevelAktif = true,
  }) async {
    final current = state.value;
    if (current == null) return;
    final progres = current.progres.catatRonde(
      gameId,
      level: level,
      streak: streak,
      missStreak: missStreak,
      skor: skor,
      benar: benar,
      simpanLevelAktif: simpanLevelAktif,
    );
    await ref.read(storageProvider).simpanProgres(progres);
    state = AsyncValue.data(current.copyWith(progres: progres));
  }

  Future<void> resetProgres() async {
    final current = state.value;
    if (current == null) return;
    await ref.read(storageProvider).resetProgres();
    state = AsyncValue.data(
      current.copyWith(progres: ProgresPengguna.kosong()),
    );
  }

  Future<void> _applyAudioSettings(AppState app) async {
    final audio = ref.read(audioProvider);
    await audio.muatProfilTuning(app.profilAktif());
    await audio.setInstrumen(app.pengaturan.instrumen);
    await audio.setArtikulasi(app.pengaturan.artikulasi);
  }
}

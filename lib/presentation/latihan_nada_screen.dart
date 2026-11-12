import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/adaptive.dart';
import '../domain/latihan_nada.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'widgets.dart';

enum ModeSetNada { nadaHilang, harmoni }

enum FaseSet { input, hasil }

const Map<int, String> _solfeg = {1: 'da', 2: 'mi', 3: 'na', 4: 'ti', 5: 'la'};

class SetNadaState {
  final int level;
  final int streak;
  final int missStreak;
  final int ronde;
  final List<int> urutan;
  final Set<int> target;
  final Set<int> jawaban;
  final FaseSet fase;
  final int? skorTerakhir;
  final bool adaptif;
  final bool acuanDimainkan;

  const SetNadaState({
    required this.level,
    required this.streak,
    required this.missStreak,
    required this.ronde,
    required this.urutan,
    required this.target,
    required this.jawaban,
    required this.fase,
    this.skorTerakhir,
    this.adaptif = true,
    this.acuanDimainkan = false,
  });

  const SetNadaState.awal()
    : level = 1,
      streak = 0,
      missStreak = 0,
      ronde = 0,
      urutan = const [],
      target = const {},
      jawaban = const {},
      fase = FaseSet.input,
      skorTerakhir = null,
      adaptif = true,
      acuanDimainkan = false;

  SetNadaState copyWith({
    int? level,
    int? streak,
    int? missStreak,
    int? ronde,
    List<int>? urutan,
    Set<int>? target,
    Set<int>? jawaban,
    FaseSet? fase,
    int? skorTerakhir,
    bool? adaptif,
    bool? acuanDimainkan,
    bool bersihkanSkor = false,
  }) {
    return SetNadaState(
      level: level ?? this.level,
      streak: streak ?? this.streak,
      missStreak: missStreak ?? this.missStreak,
      ronde: ronde ?? this.ronde,
      urutan: urutan ?? this.urutan,
      target: target ?? this.target,
      jawaban: jawaban ?? this.jawaban,
      fase: fase ?? this.fase,
      skorTerakhir: bersihkanSkor ? null : (skorTerakhir ?? this.skorTerakhir),
      adaptif: adaptif ?? this.adaptif,
      acuanDimainkan: acuanDimainkan ?? this.acuanDimainkan,
    );
  }
}

class SetNadaController extends StateNotifier<SetNadaState> {
  final Ref ref;
  final ModeSetNada mode;
  final int? levelDrill;
  final Random _r = Random();
  AdaptivePolicy get _policy => AdaptivePolicy(
    minLevel: mode == ModeSetNada.harmoni ? 2 : 1,
    maxLevel: levelMaksSetNada,
    passScore: 100,
  );

  SetNadaController(this.ref, this.mode, this.levelDrill)
    : super(const SetNadaState.awal()) {
    final gameId = mode == ModeSetNada.nadaHilang ? 'nada_hilang' : 'harmoni';
    final stat = ref.read(appControllerProvider).value?.progres.game[gameId];
    final levelMin = mode == ModeSetNada.harmoni ? 2 : 1;
    state = state.copyWith(
      adaptif: levelDrill == null,
      level: levelDrill ?? (stat?.levelAktif ?? levelMin).clamp(levelMin, 5),
      streak: levelDrill == null ? stat?.streakAktif ?? 0 : 0,
      missStreak: levelDrill == null ? stat?.missStreakAktif ?? 0 : 0,
    );
  }

  void mulai() {
    if (mode == ModeSetNada.nadaHilang) {
      final soal = buatNadaHilang(state.level, _r);
      state = state.copyWith(
        urutan: soal.urutan,
        target: soal.hilang,
        jawaban: {},
        fase: FaseSet.input,
        ronde: state.ronde + 1,
        acuanDimainkan: false,
        bersihkanSkor: true,
      );
      putar();
    } else {
      state = state.copyWith(
        urutan: const [],
        target: buatHarmoni(state.level, _r),
        jawaban: {},
        fase: FaseSet.input,
        ronde: state.ronde + 1,
        acuanDimainkan: false,
        bersihkanSkor: true,
      );
      putar();
    }
  }

  /// Mainkan acuan tangga nada sekali; tombol akan grey-out setelahnya.
  Future<void> putarAcuanSekali() async {
    if (state.acuanDimainkan) return;
    state = state.copyWith(acuanDimainkan: true);
    await putarTangga();
  }

  Future<void> putar() async {
    final audio = ref.read(audioProvider);
    if (mode == ModeSetNada.nadaHilang) {
      final kejadian = [
        for (final angka in state.urutan)
          KejadianMelodi(
            tona: state.target.contains(angka) ? null : Tona(angka: angka),
            ketuk: 1,
          ),
      ];
      await audio.putarMelodi(kejadian, bpm: 120);
    } else {
      await audio.putarSerentak([
        for (final angka in state.target) Tona(angka: angka),
      ]);
    }
  }

  Future<void> putarTangga() async {
    await ref
        .read(audioProvider)
        .putarUrutan(nadaAcuan(), jeda: const Duration(milliseconds: 280));
  }

  void toggle(int angka) {
    if (state.fase != FaseSet.input) return;
    final next = {...state.jawaban};
    if (!next.add(angka)) next.remove(angka);
    state = state.copyWith(jawaban: next);
  }

  void kirim() {
    if (state.fase != FaseSet.input || state.jawaban.isEmpty) return;
    final skor = skorSetNada(state.target, state.jawaban);
    final next = _policy.apply(
      level: state.level,
      streak: state.streak,
      missStreak: state.missStreak,
      score: skor,
      adaptif: state.adaptif,
    );
    state = state.copyWith(
      fase: FaseSet.hasil,
      skorTerakhir: skor,
      level: next.level,
      streak: next.streak,
      missStreak: next.missStreak,
    );
    final gameId = mode == ModeSetNada.nadaHilang ? 'nada_hilang' : 'harmoni';
    unawaited(
      ref
          .read(appControllerProvider.notifier)
          .catatRondeGame(
            gameId,
            level: next.level,
            streak: next.streak,
            missStreak: next.missStreak,
            skor: skor,
            benar: skor >= 100,
            simpanLevelAktif: state.adaptif,
          ),
    );
  }

  void lanjut() => mulai();
}

typedef SetNadaArgs = ({ModeSetNada mode, int? levelDrill});

final setNadaProvider =
    StateNotifierProvider.family<SetNadaController, SetNadaState, SetNadaArgs>(
      (ref, args) => SetNadaController(ref, args.mode, args.levelDrill),
    );

class LatihanNadaScreen extends ConsumerStatefulWidget {
  final ModeSetNada mode;
  final int? levelDrill;

  const LatihanNadaScreen({super.key, required this.mode, this.levelDrill});

  @override
  ConsumerState<LatihanNadaScreen> createState() => _LatihanNadaScreenState();
}

class _LatihanNadaScreenState extends ConsumerState<LatihanNadaScreen> {
  SetNadaArgs get _args => (mode: widget.mode, levelDrill: widget.levelDrill);
  bool _mulai = false;

  void _mulaiLatihan() {
    setState(() => _mulai = true);
    ref.read(setNadaProvider(_args).notifier).mulai();
  }

  String get _judul => widget.mode == ModeSetNada.nadaHilang
      ? 'Tebak Nada Hilang'
      : 'Tebak Harmoni';

  String get _instruksi => widget.mode == ModeSetNada.nadaHilang
      ? 'Da-mi-na-ti-la dimainkan, tetapi ada nada yang hilang. Pilih nada yang hilang.'
      : 'Beberapa nada dibunyikan serentak. Pilih nada-nada yang kamu dengar.';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setNadaProvider(_args));
    final notifier = ref.read(setNadaProvider(_args).notifier);
    final mode = widget.mode;
    final title = widget.levelDrill == null ? _judul : 'Practice $_judul';
    return LatihanPopScope(
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: _mulai
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StatusGame(
                    level: state.level,
                    streak: state.streak,
                    ronde: state.ronde,
                  ),
                  const SizedBox(height: 12),
                  InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _instruksi,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: notifier.putar,
                              icon: const Icon(Icons.replay),
                              label: Text(
                                mode == ModeSetNada.harmoni
                                    ? 'Putar Harmoni'
                                    : 'Putar Ulang',
                              ),
                            ),
                            if (mode == ModeSetNada.harmoni)
                              OutlinedButton.icon(
                                onPressed: notifier.putarTangga,
                                icon: const Icon(Icons.straighten),
                                label: const Text('Putar Acuan'),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: state.acuanDimainkan
                                    ? null
                                    : notifier.putarAcuanSekali,
                                icon: const Icon(Icons.straighten),
                                label: const Text('Putar Acuan'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PilihNada(state: state, onToggle: notifier.toggle),
                  const SizedBox(height: 12),
                  if (state.fase == FaseSet.input)
                    FilledButton.icon(
                      onPressed: state.jawaban.isEmpty ? null : notifier.kirim,
                      icon: const Icon(Icons.check),
                      label: const Text('Kirim'),
                    )
                  else
                    _HasilSet(state: state, onLanjut: notifier.lanjut),
                ],
              )
            : LatihanIntro(
                judul: title,
                jenis: mode == ModeSetNada.harmoni
                    ? 'Dengar nada serentak'
                    : 'Dengar urutan nada',
                deskripsi: mode == ModeSetNada.harmoni
                    ? 'Pilih nada yang terdengar bersama.'
                    : 'Dengar da-mi-na-ti-la. Pilih nada yang hilang.',
                poin: mode == ModeSetNada.harmoni
                    ? const ['Da', 'Mi', 'Na', 'Ti', 'La']
                    : const ['Urutan', 'Nada hilang'],
                onMulai: _mulaiLatihan,
              ),
      ),
    );
  }
}

class _PilihNada extends StatelessWidget {
  final SetNadaState state;
  final ValueChanged<int> onToggle;

  const _PilihNada({required this.state, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const hijau = Color(0xFF2E7D32);
    const merah = Color(0xFFC62828);
    const oranye = Color(0xFFEF6C00);
    final selesai = state.fase == FaseSet.hasil;
    return InfoCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          for (var angka = 1; angka <= 5; angka++)
            Builder(
              builder: (context) {
                final dipilih = state.jawaban.contains(angka);
                final diTarget = state.target.contains(angka);
                Color bg = scheme.surfaceContainerHighest;
                Color fg = scheme.onSurface;
                if (selesai) {
                  if (diTarget && dipilih) {
                    bg = hijau;
                    fg = Colors.white;
                  } else if (diTarget && !dipilih) {
                    bg = oranye;
                    fg = Colors.white;
                  } else if (!diTarget && dipilih) {
                    bg = merah;
                    fg = Colors.white;
                  }
                } else if (dipilih) {
                  bg = scheme.primary;
                  fg = scheme.onPrimary;
                }
                return GestureDetector(
                  onTap: selesai ? null : () => onToggle(angka),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 60,
                    height: 72,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (dipilih || (selesai && (diTarget || dipilih)))
                          BoxShadow(
                            color: bg.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$angka',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                        Text(
                          _solfeg[angka]!,
                          style: TextStyle(fontSize: 12, color: fg),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HasilSet extends StatelessWidget {
  final SetNadaState state;
  final VoidCallback onLanjut;

  const _HasilSet({required this.state, required this.onLanjut});

  @override
  Widget build(BuildContext context) {
    final skor = state.skorTerakhir ?? 0;
    final benar = skor >= 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: InfoCard(
            child: Row(
              children: [
                Icon(
                  benar ? Icons.celebration : Icons.info_outline,
                  color: benar
                      ? const Color(0xFF2E7D32)
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  benar ? 'Tepat! Skor $skor' : 'Skor $skor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onLanjut,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Lanjut'),
        ),
      ],
    );
  }
}

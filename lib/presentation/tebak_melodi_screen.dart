import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/logic.dart';
import '../domain/adaptive.dart';
import '../domain/melodi.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'widgets.dart';

enum FaseMelodi { input, hasil }

class TebakMelodiState {
  final int level;
  final int streak;
  final int missStreak;
  final int ronde;
  final List<SimbolNot> target;
  final List<SimbolNot> jawaban;
  final FaseMelodi fase;
  final List<HasilBandingNot>? hasil;
  final int? skorTerakhir;
  final int durasiBeam;
  final bool adaptif;

  const TebakMelodiState({
    required this.level,
    required this.streak,
    required this.missStreak,
    required this.ronde,
    required this.target,
    required this.jawaban,
    required this.fase,
    this.hasil,
    this.skorTerakhir,
    this.durasiBeam = 0,
    this.adaptif = true,
  });

  const TebakMelodiState.awal()
    : level = 1,
      streak = 0,
      missStreak = 0,
      ronde = 0,
      target = const [],
      jawaban = const [],
      fase = FaseMelodi.input,
      hasil = null,
      skorTerakhir = null,
      durasiBeam = 0,
      adaptif = true;

  TebakMelodiState copyWith({
    int? level,
    int? streak,
    int? missStreak,
    int? ronde,
    List<SimbolNot>? target,
    List<SimbolNot>? jawaban,
    FaseMelodi? fase,
    List<HasilBandingNot>? hasil,
    int? skorTerakhir,
    int? durasiBeam,
    bool? adaptif,
    bool bersihkanHasil = false,
  }) {
    return TebakMelodiState(
      level: level ?? this.level,
      streak: streak ?? this.streak,
      missStreak: missStreak ?? this.missStreak,
      ronde: ronde ?? this.ronde,
      target: target ?? this.target,
      jawaban: jawaban ?? this.jawaban,
      fase: fase ?? this.fase,
      hasil: bersihkanHasil ? null : (hasil ?? this.hasil),
      skorTerakhir: bersihkanHasil ? null : (skorTerakhir ?? this.skorTerakhir),
      durasiBeam: durasiBeam ?? this.durasiBeam,
      adaptif: adaptif ?? this.adaptif,
    );
  }
}

class TebakMelodiController extends StateNotifier<TebakMelodiState> {
  final Ref ref;
  final int? levelDrill;
  final GeneratorMelodi _gen = GeneratorMelodi();
  static const _policy = AdaptivePolicy(
    minLevel: 1,
    maxLevel: KesulitanMelodi.levelMaks,
    passScore: 85,
  );

  TebakMelodiController(this.ref, this.levelDrill)
    : super(const TebakMelodiState.awal()) {
    final stat = ref
        .read(appControllerProvider)
        .value
        ?.progres
        .game['tebak_melodi'];
    state = state.copyWith(
      adaptif: levelDrill == null,
      level: levelDrill ?? stat?.levelAktif ?? 1,
      streak: levelDrill == null ? stat?.streakAktif ?? 0 : 0,
      missStreak: levelDrill == null ? stat?.missStreakAktif ?? 0 : 0,
    );
  }

  void mulai() {
    final k = KesulitanMelodi.untukLevel(state.level);
    state = state.copyWith(
      target: _gen.buat(k),
      jawaban: const [],
      fase: FaseMelodi.input,
      ronde: state.ronde + 1,
      durasiBeam: 0,
      bersihkanHasil: true,
    );
    putar();
  }

  Future<void> putar() async {
    if (state.target.isEmpty) return;
    await ref
        .read(audioProvider)
        .putarMelodi(kejadianMelodi(state.target), metronome: true);
  }

  /// Memutar nada acuan standar (da mi na ti la da_ageung mi na ti la).
  Future<void> putarAcuan() async {
    await ref
        .read(audioProvider)
        .putarUrutan(nadaAcuan(), jeda: const Duration(milliseconds: 280));
  }

  void tambahNada(int angka) {
    if (state.fase != FaseMelodi.input) return;
    state = state.copyWith(
      jawaban: [
        ...state.jawaban,
        SimbolNot.nada(angka, beam: state.durasiBeam),
      ],
    );
  }

  void tambahIstirahat() {
    if (state.fase != FaseMelodi.input) return;
    state = state.copyWith(
      jawaban: [
        ...state.jawaban,
        SimbolNot.istirahat(beam: state.durasiBeam),
      ],
    );
  }

  void tambahPerpanjangan() {
    if (state.fase != FaseMelodi.input || state.jawaban.isEmpty) return;
    state = state.copyWith(
      jawaban: [...state.jawaban, const SimbolNot.perpanjangan()],
    );
  }

  void ubahOktafTerakhir(int delta) {
    if (state.fase != FaseMelodi.input || state.jawaban.isEmpty) return;
    final last = state.jawaban.last;
    if (last.jenis != JenisSimbol.nada) return;
    final oktaf = (last.oktafRelatif + delta).clamp(-1, 1);
    final next = [...state.jawaban]
      ..[state.jawaban.length - 1] = last.copyWith(oktafRelatif: oktaf);
    state = state.copyWith(jawaban: next);
  }

  /// Ganti mode durasi input (♩ -> ♪ -> ♬). Not berikutnya memakai durasi ini.
  void siklusDurasi() {
    if (state.fase != FaseMelodi.input) return;
    state = state.copyWith(durasiBeam: (state.durasiBeam + 1) % 3);
  }

  void hapusTerakhir() {
    if (state.fase != FaseMelodi.input || state.jawaban.isEmpty) return;
    state = state.copyWith(
      jawaban: state.jawaban.sublist(0, state.jawaban.length - 1),
    );
  }

  void bersihkan() {
    if (state.fase != FaseMelodi.input) return;
    state = state.copyWith(jawaban: const []);
  }

  void kirim() {
    if (state.fase != FaseMelodi.input || state.jawaban.isEmpty) return;
    final hasil = bandingkanMelodi(state.target, state.jawaban);
    final skor = skorMelodi(hasil);
    final next = _policy.apply(
      level: state.level,
      streak: state.streak,
      missStreak: state.missStreak,
      score: skor,
      adaptif: state.adaptif,
    );
    state = state.copyWith(
      fase: FaseMelodi.hasil,
      hasil: hasil,
      skorTerakhir: skor,
      level: next.level,
      streak: next.streak,
      missStreak: next.missStreak,
    );
    unawaited(
      ref
          .read(appControllerProvider.notifier)
          .catatRondeGame(
            'tebak_melodi',
            level: next.level,
            streak: next.streak,
            missStreak: next.missStreak,
            skor: skor,
            benar: skor >= 85,
            simpanLevelAktif: state.adaptif,
          ),
    );
  }

  void lanjut() => mulai();
}

final tebakMelodiProvider =
    StateNotifierProvider.family<TebakMelodiController, TebakMelodiState, int?>(
      (ref, levelDrill) => TebakMelodiController(ref, levelDrill),
    );

class TebakMelodiScreen extends ConsumerStatefulWidget {
  final int? levelDrill;

  const TebakMelodiScreen({super.key, this.levelDrill});

  @override
  ConsumerState<TebakMelodiScreen> createState() => _TebakMelodiScreenState();
}

class _TebakMelodiScreenState extends ConsumerState<TebakMelodiScreen> {
  bool _mulai = false;

  void _mulaiLatihan() {
    setState(() => _mulai = true);
    ref.read(tebakMelodiProvider(widget.levelDrill).notifier).mulai();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tebakMelodiProvider(widget.levelDrill));
    final notifier = ref.read(tebakMelodiProvider(widget.levelDrill).notifier);
    final title = widget.levelDrill == null
        ? 'Tebak Melodi'
        : 'Practice Tebak Melodi';
    return LatihanPopScope(
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: _mulai
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatusBar(state: state),
                  const SizedBox(height: 12),
                  if (state.fase == FaseMelodi.input) ...[
                    InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dengarkan melodi, lalu tulis notasinya.',
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
                                label: const Text('Putar Ulang'),
                              ),
                              OutlinedButton.icon(
                                onPressed: notifier.putarAcuan,
                                icon: const Icon(Icons.straighten),
                                label: const Text('Putar Acuan'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jawabanmu',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: JianpuView(simbol: state.jawaban, size: 34),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Keypad(notifier: notifier, durasiBeam: state.durasiBeam),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: state.jawaban.isEmpty ? null : notifier.kirim,
                      icon: const Icon(Icons.check),
                      label: const Text('Kirim'),
                    ),
                  ] else
                    _HasilArea(state: state, notifier: notifier),
                ],
              )
            : LatihanIntro(
                judul: title,
                jenis: 'Dengar lalu tulis',
                deskripsi:
                    'Dengarkan satu melodi pendek. Tulis dengan notasi angka.',
                poin: const ['1-5', 'Istirahat', 'Oktaf'],
                onMulai: _mulaiLatihan,
              ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final TebakMelodiState state;
  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String label) => Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(Icons.trending_up, 'Level ${state.level}'),
        chip(Icons.local_fire_department, 'Streak ${state.streak}'),
        chip(Icons.flag, 'Ronde ${state.ronde}'),
      ],
    );
  }
}

class _HasilArea extends StatelessWidget {
  final TebakMelodiState state;
  final TebakMelodiController notifier;
  const _HasilArea({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    const hijau = Color(0xFF2E7D32);
    const merah = Color(0xFFC62828);
    final hasil = state.hasil ?? const [];
    final warnaJawaban = [
      for (var i = 0; i < state.jawaban.length; i++)
        (i < hasil.length && hasil[i].benar) ? hijau : merah,
    ];
    final warnaTarget = [for (final _ in state.target) hijau];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skor ${state.skorTerakhir ?? 0}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text('Jawabanmu', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Center(
                child: JianpuView(
                  simbol: state.jawaban,
                  warna: warnaJawaban,
                  size: 34,
                ),
              ),
              const Divider(height: 24),
              Text(
                'Jawaban benar',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Center(
                child: JianpuView(
                  simbol: state.target,
                  warna: warnaTarget,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: notifier.putar,
              icon: const Icon(Icons.replay),
              label: const Text('Putar'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: notifier.lanjut,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Lanjut'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  final TebakMelodiController notifier;
  final int durasiBeam;
  const _Keypad({required this.notifier, required this.durasiBeam});

  @override
  Widget build(BuildContext context) {
    Widget tombol(String label, VoidCallback onTap, {Color? warna}) {
      return SizedBox(
        width: 58,
        height: 48,
        child: FilledButton.tonal(
          style: warna == null
              ? null
              : FilledButton.styleFrom(backgroundColor: warna),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
      );
    }

    Widget tombolIkon(IconData ikon, VoidCallback onTap) {
      return SizedBox(
        width: 58,
        height: 48,
        child: FilledButton.tonal(
          onPressed: onTap,
          child: Icon(ikon, size: 20),
        ),
      );
    }

    return InfoCard(
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in [1, 2, 3, 4, 5])
                tombol('$n', () => notifier.tambahNada(n)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tombol('0', notifier.tambahIstirahat),
              tombol('·', notifier.tambahPerpanjangan),
              tombol(
                ['♩', '♪', '♬'][durasiBeam],
                notifier.siklusDurasi,
                warna: Theme.of(context).colorScheme.secondaryContainer,
              ),
              tombolIkon(
                Icons.keyboard_arrow_up,
                () => notifier.ubahOktafTerakhir(1),
              ),
              tombolIkon(
                Icons.keyboard_arrow_down,
                () => notifier.ubahOktafTerakhir(-1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tombolIkon(Icons.backspace_outlined, notifier.hapusTerakhir),
              tombolIkon(Icons.delete_sweep_outlined, notifier.bersihkan),
            ],
          ),
        ],
      ),
    );
  }
}

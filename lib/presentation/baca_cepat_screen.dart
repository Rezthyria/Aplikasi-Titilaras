import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/adaptive.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'widgets.dart';

/// Arah baca cepat (bisa di-toggle dalam layar):
/// - [notasiKeNada]: muncul notasi angka, tekan tombol daminatila yang tepat.
/// - [nadaKeNotasi]: muncul nama daminatila, tekan tombol angka yang tepat.
enum ModeBaca { notasiKeNada, nadaKeNotasi }

enum FaseBaca { main, hasil }

const Map<int, String> _solfeg = {1: 'da', 2: 'mi', 3: 'na', 4: 'ti', 5: 'la'};

String _namaOktaf(int oktaf) => switch (oktaf) {
  < 0 => 'ageung',
  > 0 => 'alit',
  _ => 'tengah',
};

class BacaCepatState {
  final ModeBaca mode;
  final int level;
  final int streak;
  final int missStreak;
  final int ronde;
  final Tona target;
  final FaseBaca fase;
  final int sisaDetik;
  final int totalDetik;
  final bool? benarTerakhir;
  final bool adaptif;

  const BacaCepatState({
    required this.mode,
    required this.level,
    required this.streak,
    required this.missStreak,
    required this.ronde,
    required this.target,
    required this.fase,
    required this.sisaDetik,
    required this.totalDetik,
    this.benarTerakhir,
    this.adaptif = true,
  });

  const BacaCepatState.awal()
    : mode = ModeBaca.notasiKeNada,
      level = 1,
      streak = 0,
      missStreak = 0,
      ronde = 0,
      target = const Tona(angka: 1),
      fase = FaseBaca.main,
      sisaDetik = 7,
      totalDetik = 7,
      benarTerakhir = null,
      adaptif = true;

  BacaCepatState copyWith({
    ModeBaca? mode,
    int? level,
    int? streak,
    int? missStreak,
    int? ronde,
    Tona? target,
    FaseBaca? fase,
    int? sisaDetik,
    int? totalDetik,
    bool? benarTerakhir,
    bool? adaptif,
    bool bersihkanHasil = false,
  }) {
    return BacaCepatState(
      mode: mode ?? this.mode,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      missStreak: missStreak ?? this.missStreak,
      ronde: ronde ?? this.ronde,
      target: target ?? this.target,
      fase: fase ?? this.fase,
      sisaDetik: sisaDetik ?? this.sisaDetik,
      totalDetik: totalDetik ?? this.totalDetik,
      benarTerakhir: bersihkanHasil
          ? null
          : (benarTerakhir ?? this.benarTerakhir),
      adaptif: adaptif ?? this.adaptif,
    );
  }
}

class BacaCepatController extends StateNotifier<BacaCepatState> {
  final Ref ref;
  final int? levelDrill;
  final Random _r = Random();
  Timer? _timer;
  static const _policy = AdaptivePolicy(minLevel: 1, maxLevel: 5);

  BacaCepatController(this.ref, this.levelDrill)
    : super(const BacaCepatState.awal()) {
    final stat = ref.read(appControllerProvider).value?.progres.game[gameId];
    state = state.copyWith(
      adaptif: levelDrill == null,
      level: levelDrill ?? stat?.levelAktif ?? 1,
      streak: levelDrill == null ? stat?.streakAktif ?? 0 : 0,
      missStreak: levelDrill == null ? stat?.missStreakAktif ?? 0 : 0,
    );
  }

  static const _waktuLevel = [7, 6, 5, 4, 3];
  int _waktu(int level) => _waktuLevel[(level - 1).clamp(0, 4)];
  List<int> _oktaf(int level) => level <= 2 ? const [0] : const [-1, 0, 1];

  String get gameId =>
      state.mode == ModeBaca.notasiKeNada ? 'baca_cepat' : 'baca_reverse';

  void gantiMode(ModeBaca m) {
    _timer?.cancel();
    final id = m == ModeBaca.notasiKeNada ? 'baca_cepat' : 'baca_reverse';
    final stat = ref.read(appControllerProvider).value?.progres.game[id];
    state = state.copyWith(
      mode: m,
      level: levelDrill ?? stat?.levelAktif ?? 1,
      streak: levelDrill == null ? stat?.streakAktif ?? 0 : 0,
      missStreak: levelDrill == null ? stat?.missStreakAktif ?? 0 : 0,
    );
    mulai();
  }

  void mulai() {
    _timer?.cancel();
    final okts = _oktaf(state.level);
    final target = Tona(
      angka: _r.nextInt(5) + 1,
      oktafRelatif: okts[_r.nextInt(okts.length)],
    );
    final waktu = _waktu(state.level);
    state = state.copyWith(
      target: target,
      fase: FaseBaca.main,
      sisaDetik: waktu,
      totalDetik: waktu,
      ronde: state.ronde + 1,
      bersihkanHasil: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final sisa = state.sisaDetik - 1;
      if (sisa <= 0) {
        t.cancel();
        _selesai(null);
      } else {
        state = state.copyWith(sisaDetik: sisa);
      }
    });
  }

  void jawab(Tona t) {
    if (state.fase != FaseBaca.main) return;
    unawaited(ref.read(audioProvider).putarTona(t));
    _timer?.cancel();
    _selesai(t);
  }

  void _selesai(Tona? jawab) {
    final benar =
        jawab != null &&
        jawab.angka == state.target.angka &&
        jawab.oktafRelatif == state.target.oktafRelatif;
    final next = _policy.apply(
      level: state.level,
      streak: state.streak,
      missStreak: state.missStreak,
      score: benar ? 100 : 0,
      adaptif: state.adaptif,
    );
    state = state.copyWith(
      fase: FaseBaca.hasil,
      benarTerakhir: benar,
      level: next.level,
      streak: next.streak,
      missStreak: next.missStreak,
    );
    unawaited(
      ref
          .read(appControllerProvider.notifier)
          .catatRondeGame(
            gameId,
            level: next.level,
            streak: next.streak,
            missStreak: next.missStreak,
            skor: benar ? 100 : 0,
            benar: benar,
            simpanLevelAktif: state.adaptif,
          ),
    );
  }

  void lanjut() => mulai();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final bacaCepatProvider = StateNotifierProvider.autoDispose
    .family<BacaCepatController, BacaCepatState, int?>(
      (ref, levelDrill) => BacaCepatController(ref, levelDrill),
    );

class BacaCepatScreen extends ConsumerStatefulWidget {
  final int? levelDrill;

  const BacaCepatScreen({super.key, this.levelDrill});

  @override
  ConsumerState<BacaCepatScreen> createState() => _BacaCepatScreenState();
}

class _BacaCepatScreenState extends ConsumerState<BacaCepatScreen> {
  bool _mulai = false;

  void _mulaiLatihan() {
    setState(() => _mulai = true);
    ref.read(bacaCepatProvider(widget.levelDrill).notifier).mulai();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bacaCepatProvider(widget.levelDrill));
    final notifier = ref.read(bacaCepatProvider(widget.levelDrill).notifier);
    final title = widget.levelDrill == null
        ? 'Baca Cepat'
        : 'Practice Baca Cepat';
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
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Notasi → Nada'),
                        selected: state.mode == ModeBaca.notasiKeNada,
                        onSelected: (_) =>
                            notifier.gantiMode(ModeBaca.notasiKeNada),
                      ),
                      ChoiceChip(
                        label: const Text('Nada → Angka'),
                        selected: state.mode == ModeBaca.nadaKeNotasi,
                        onSelected: (_) =>
                            notifier.gantiMode(ModeBaca.nadaKeNotasi),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TimerBar(sisa: state.sisaDetik, total: state.totalDetik),
                  const SizedBox(height: 12),
                  _Stimulus(state: state),
                  const SizedBox(height: 12),
                  _Tombol15(
                    mode: state.mode,
                    level: state.level,
                    aktif: state.fase == FaseBaca.main,
                    onTap: notifier.jawab,
                  ),
                  const SizedBox(height: 12),
                  if (state.fase == FaseBaca.hasil)
                    _HasilBaca(state: state, onLanjut: notifier.lanjut),
                ],
              )
            : LatihanIntro(
                judul: title,
                jenis: 'Baca cepat',
                deskripsi:
                    'Lihat notasi atau nama nada. Pilih jawaban sebelum waktu habis.',
                poin: const ['Notasi', 'Nama nada', 'Oktaf'],
                onMulai: _mulaiLatihan,
              ),
      ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  final int sisa;
  final int total;
  const _TimerBar({required this.sisa, required this.total});

  @override
  Widget build(BuildContext context) {
    final v = total == 0 ? 0.0 : sisa / total;
    final warna = v > 0.4
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFFC62828);
    return Row(
      children: [
        const Icon(Icons.timer_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: warna,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${sisa}s', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Stimulus extends StatelessWidget {
  final BacaCepatState state;
  const _Stimulus({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = state.target;
    return InfoCard(
      child: Center(
        child: state.mode == ModeBaca.notasiKeNada
            ? JianpuView(
                simbol: [SimbolNot.nada(t.angka, oktafRelatif: t.oktafRelatif)],
                size: 56,
              )
            : Column(
                children: [
                  Text(
                    _solfeg[t.angka]!,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('oktaf ${_namaOktaf(t.oktafRelatif)}'),
                ],
              ),
      ),
    );
  }
}

class _Tombol15 extends StatelessWidget {
  final ModeBaca mode;
  final int level;
  final bool aktif;
  final ValueChanged<Tona> onTap;
  const _Tombol15({
    required this.mode,
    required this.level,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget baris(int oktaf) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              child: Text(
                _namaOktaf(oktaf),
                style: const TextStyle(fontSize: 11),
              ),
            ),
            for (var angka = 1; angka <= 5; angka++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: aktif
                        ? () => onTap(Tona(angka: angka, oktafRelatif: oktaf))
                        : null,
                    child: Text(
                      mode == ModeBaca.notasiKeNada
                          ? _solfeg[angka]!
                          : '$angka',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final oktaf = level <= 2 ? const [0] : const [1, 0, -1];
    return InfoCard(child: Column(children: [for (final o in oktaf) baris(o)]));
  }
}

class _HasilBaca extends StatelessWidget {
  final BacaCepatState state;
  final VoidCallback onLanjut;
  const _HasilBaca({required this.state, required this.onLanjut});

  @override
  Widget build(BuildContext context) {
    final benar = state.benarTerakhir ?? false;
    final t = state.target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoCard(
          child: Row(
            children: [
              Icon(
                benar ? Icons.check_circle : Icons.cancel,
                color: benar
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  benar
                      ? 'Benar!'
                      : 'Salah/terlambat. Jawaban: ${_solfeg[t.angka]} (${t.angka}) oktaf ${_namaOktaf(t.oktafRelatif)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
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

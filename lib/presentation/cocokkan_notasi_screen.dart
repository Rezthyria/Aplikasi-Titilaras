import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../domain/adaptive.dart';
import '../domain/logic.dart';
import '../domain/melodi.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'widgets.dart';

enum FaseCocokkan { input, hasil }

class OpsiCocokkan {
  final String id;
  final List<SimbolNot> simbol;

  const OpsiCocokkan({required this.id, required this.simbol});
}

class CocokkanNotasiState {
  final int level;
  final int streak;
  final int missStreak;
  final int ronde;
  final List<SimbolNot> target;
  final List<OpsiCocokkan> opsi;
  final String kunciId;
  final String? pilihanId;
  final FaseCocokkan fase;
  final bool adaptif;

  const CocokkanNotasiState({
    required this.level,
    required this.streak,
    required this.missStreak,
    required this.ronde,
    required this.target,
    required this.opsi,
    required this.kunciId,
    this.pilihanId,
    required this.fase,
    this.adaptif = true,
  });

  const CocokkanNotasiState.awal()
    : level = 1,
      streak = 0,
      missStreak = 0,
      ronde = 0,
      target = const [],
      opsi = const [],
      kunciId = '',
      pilihanId = null,
      fase = FaseCocokkan.input,
      adaptif = true;

  CocokkanNotasiState copyWith({
    int? level,
    int? streak,
    int? missStreak,
    int? ronde,
    List<SimbolNot>? target,
    List<OpsiCocokkan>? opsi,
    String? kunciId,
    String? pilihanId,
    FaseCocokkan? fase,
    bool? adaptif,
    bool bersihkanPilihan = false,
  }) {
    return CocokkanNotasiState(
      level: level ?? this.level,
      streak: streak ?? this.streak,
      missStreak: missStreak ?? this.missStreak,
      ronde: ronde ?? this.ronde,
      target: target ?? this.target,
      opsi: opsi ?? this.opsi,
      kunciId: kunciId ?? this.kunciId,
      pilihanId: bersihkanPilihan ? null : (pilihanId ?? this.pilihanId),
      fase: fase ?? this.fase,
      adaptif: adaptif ?? this.adaptif,
    );
  }
}

class CocokkanNotasiController extends StateNotifier<CocokkanNotasiState> {
  final Ref ref;
  final int? levelDrill;
  final Random _r = Random();
  late final GeneratorMelodi _gen = GeneratorMelodi(_r);
  static const _policy = AdaptivePolicy(
    minLevel: 1,
    maxLevel: KesulitanMelodi.levelMaks,
  );

  CocokkanNotasiController(this.ref, this.levelDrill)
    : super(const CocokkanNotasiState.awal()) {
    final stat = ref
        .read(appControllerProvider)
        .value
        ?.progres
        .game['cocokkan_notasi'];
    state = state.copyWith(
      adaptif: levelDrill == null,
      level: levelDrill ?? stat?.levelAktif ?? 1,
      streak: levelDrill == null ? stat?.streakAktif ?? 0 : 0,
      missStreak: levelDrill == null ? stat?.missStreakAktif ?? 0 : 0,
    );
  }

  int _jumlahOpsi(int level) => switch (level.clamp(1, 5)) {
    1 => 2,
    2 => 3,
    3 => 4,
    4 => 4,
    _ => 5,
  };

  void mulai() {
    final target = _gen.buat(KesulitanMelodi.untukLevel(state.level));
    final opsi = <OpsiCocokkan>[OpsiCocokkan(id: 'A', simbol: target)];
    final seen = <String>{_kunci(target)};
    final count = _jumlahOpsi(state.level);
    var guard = 0;
    while (opsi.length < count && guard < 80) {
      guard++;
      final mutant = _mutasi(target, state.level);
      final key = _kunci(mutant);
      if (key == _kunci(target) || !seen.add(key)) continue;
      opsi.add(
        OpsiCocokkan(id: String.fromCharCode(65 + opsi.length), simbol: mutant),
      );
    }
    while (opsi.length < count) {
      final extra = _gen.buat(KesulitanMelodi.untukLevel(state.level));
      final key = _kunci(extra);
      if (seen.add(key)) {
        opsi.add(
          OpsiCocokkan(
            id: String.fromCharCode(65 + opsi.length),
            simbol: extra,
          ),
        );
      }
    }
    opsi.shuffle(_r);
    state = state.copyWith(
      target: target,
      opsi: opsi,
      kunciId: opsi.firstWhere((o) => _kunci(o.simbol) == _kunci(target)).id,
      fase: FaseCocokkan.input,
      ronde: state.ronde + 1,
      bersihkanPilihan: true,
    );
  }

  String _kunci(List<SimbolNot> simbol) =>
      simbol.map((s) => s.toString()).join('|');

  List<SimbolNot> _mutasi(List<SimbolNot> sumber, int level) {
    final hasil = [...sumber];
    final candidates = [
      for (var i = 0; i < hasil.length; i++)
        if (hasil[i].jenis != JenisSimbol.perpanjangan) i,
    ];
    if (candidates.isEmpty) return hasil;
    final idx = candidates[_r.nextInt(candidates.length)];
    final s = hasil[idx];
    final modePool = level <= 2
        ? const [_MutasiMode.nada, _MutasiMode.urutan]
        : level == 3
        ? const [_MutasiMode.nada, _MutasiMode.rest, _MutasiMode.urutan]
        : const [
            _MutasiMode.nada,
            _MutasiMode.oktaf,
            _MutasiMode.rest,
            _MutasiMode.durasi,
            _MutasiMode.urutan,
          ];
    final mode = modePool[_r.nextInt(modePool.length)];
    switch (mode) {
      case _MutasiMode.nada:
        if (s.jenis == JenisSimbol.nada) {
          final delta = _r.nextBool() ? 1 : -1;
          var next = (s.angka + delta).clamp(1, 5);
          if (next == s.angka) next = s.angka == 1 ? 2 : 4;
          hasil[idx] = s.copyWith(angka: next);
        } else {
          hasil[idx] = SimbolNot.nada(_r.nextInt(5) + 1, beam: s.beam);
        }
      case _MutasiMode.oktaf:
        if (s.jenis == JenisSimbol.nada) {
          final options = [-1, 0, 1]..remove(s.oktafRelatif);
          hasil[idx] = s.copyWith(
            oktafRelatif: options[_r.nextInt(options.length)],
          );
        }
      case _MutasiMode.rest:
        hasil[idx] = s.jenis == JenisSimbol.istirahat
            ? SimbolNot.nada(_r.nextInt(5) + 1, beam: s.beam)
            : SimbolNot.istirahat(beam: s.beam);
      case _MutasiMode.durasi:
        if (s.jenis == JenisSimbol.nada) {
          hasil[idx] = s.copyWith(beam: (s.beam + 1) % 2);
        } else if (s.jenis == JenisSimbol.istirahat) {
          hasil[idx] = SimbolNot.istirahat(beam: (s.beam + 1) % 2);
        }
      case _MutasiMode.urutan:
        if (candidates.length >= 2) {
          final idx2 = candidates.firstWhere((i) => i != idx);
          final temp = hasil[idx];
          hasil[idx] = hasil[idx2];
          hasil[idx2] = temp;
        }
    }
    return hasil;
  }

  Future<void> putar(OpsiCocokkan opsi) async {
    await ref
        .read(audioProvider)
        .putarMelodi(kejadianMelodi(opsi.simbol), metronome: true);
  }

  Future<void> putarAcuan() async {
    await ref
        .read(audioProvider)
        .putarUrutan(nadaAcuan(), jeda: const Duration(milliseconds: 280));
  }

  void pilih(String id) {
    if (state.fase != FaseCocokkan.input) return;
    final benar = id == state.kunciId;
    final next = _policy.apply(
      level: state.level,
      streak: state.streak,
      missStreak: state.missStreak,
      score: benar ? 100 : 0,
      adaptif: state.adaptif,
    );
    state = state.copyWith(
      pilihanId: id,
      fase: FaseCocokkan.hasil,
      level: next.level,
      streak: next.streak,
      missStreak: next.missStreak,
    );
    unawaited(
      ref
          .read(appControllerProvider.notifier)
          .catatRondeGame(
            'cocokkan_notasi',
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
}

enum _MutasiMode { nada, oktaf, rest, durasi, urutan }

final cocokkanNotasiProvider =
    StateNotifierProvider.family<
      CocokkanNotasiController,
      CocokkanNotasiState,
      int?
    >((ref, levelDrill) => CocokkanNotasiController(ref, levelDrill));

class CocokkanNotasiScreen extends ConsumerStatefulWidget {
  final int? levelDrill;

  const CocokkanNotasiScreen({super.key, this.levelDrill});

  @override
  ConsumerState<CocokkanNotasiScreen> createState() =>
      _CocokkanNotasiScreenState();
}

class _CocokkanNotasiScreenState extends ConsumerState<CocokkanNotasiScreen> {
  bool _mulai = false;

  void _mulaiLatihan() {
    setState(() => _mulai = true);
    ref.read(cocokkanNotasiProvider(widget.levelDrill).notifier).mulai();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cocokkanNotasiProvider(widget.levelDrill));
    final notifier = ref.read(
      cocokkanNotasiProvider(widget.levelDrill).notifier,
    );
    final title = widget.levelDrill == null
        ? 'Cocokkan Notasi'
        : 'Practice Cocokkan Notasi';
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
                          'Pilih bunyi yang sesuai dengan notasi.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: JianpuView(simbol: state.target, size: 34),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: notifier.putarAcuan,
                          icon: const Icon(Icons.straighten),
                          label: const Text('Putar Acuan'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final opsi in state.opsi)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OpsiAudioCard(
                        opsi: opsi,
                        fase: state.fase,
                        kunciId: state.kunciId,
                        pilihanId: state.pilihanId,
                        onPlay: () => notifier.putar(opsi),
                        onPick: () => notifier.pilih(opsi.id),
                      ),
                    ),
                  if (state.fase == FaseCocokkan.hasil) ...[
                    const SizedBox(height: 2),
                    _HasilCocokkan(state: state, onLanjut: notifier.lanjut),
                  ],
                ],
              )
            : LatihanIntro(
                judul: title,
                jenis: 'Baca lalu dengar',
                deskripsi: 'Baca notasi angka. Pilih bunyi yang cocok.',
                poin: const ['Notasi', 'Pilihan bunyi'],
                onMulai: _mulaiLatihan,
              ),
      ),
    );
  }
}

class _OpsiAudioCard extends StatelessWidget {
  final OpsiCocokkan opsi;
  final FaseCocokkan fase;
  final String kunciId;
  final String? pilihanId;
  final VoidCallback onPlay;
  final VoidCallback onPick;

  const _OpsiAudioCard({
    required this.opsi,
    required this.fase,
    required this.kunciId,
    required this.pilihanId,
    required this.onPlay,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final selesai = fase == FaseCocokkan.hasil;
    final benar = opsi.id == kunciId;
    final dipilih = opsi.id == pilihanId;
    final scheme = Theme.of(context).colorScheme;
    Color? bg;
    if (selesai && benar) bg = const Color(0xFF2E7D32).withValues(alpha: 0.16);
    if (selesai && dipilih && !benar) {
      bg = const Color(0xFFC62828).withValues(alpha: 0.16);
    }
    return InfoCard(
      padding: const EdgeInsets.all(12),
      child: ColoredBox(
        color: bg ?? Colors.transparent,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Text(
                opsi.id,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Dengar ${opsi.id}',
              onPressed: onPlay,
              icon: const Icon(LucideIcons.volume2),
            ),
            const Spacer(),
            if (selesai)
              Icon(
                benar
                    ? Icons.check_circle
                    : (dipilih ? Icons.cancel : Icons.radio_button_unchecked),
                color: benar
                    ? const Color(0xFF2E7D32)
                    : (dipilih ? const Color(0xFFC62828) : scheme.outline),
              )
            else
              FilledButton(onPressed: onPick, child: const Text('Pilih')),
          ],
        ),
      ),
    );
  }
}

class _HasilCocokkan extends StatelessWidget {
  final CocokkanNotasiState state;
  final VoidCallback onLanjut;

  const _HasilCocokkan({required this.state, required this.onLanjut});

  @override
  Widget build(BuildContext context) {
    final benar = state.pilihanId == state.kunciId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoCard(
          child: Row(
            children: [
              Icon(
                benar ? Icons.check_circle : Icons.info_outline,
                color: benar
                    ? const Color(0xFF2E7D32)
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  benar
                      ? 'Tepat.'
                      : 'Belum tepat. Bunyi yang cocok adalah ${state.kunciId}.',
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

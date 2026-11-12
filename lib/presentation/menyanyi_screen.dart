import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/adaptive.dart';
import '../domain/logic.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'widgets.dart';

const Map<int, String> _solfeg = {1: 'da', 2: 'mi', 3: 'na', 4: 'ti', 5: 'la'};

/// Latihan menyanyikan melodi yang diberikan, dinilai lewat deteksi pitch
/// (pitch-class, oktaf bebas). Dua mode: dipandu (lihat & dengar tiap nada)
/// dan tidak dipandu (acuan diputar dulu, lalu nyanyikan dari ingatan).
class MenyanyiScreen extends ConsumerStatefulWidget {
  const MenyanyiScreen({super.key});

  @override
  ConsumerState<MenyanyiScreen> createState() => _MenyanyiScreenState();
}

class _MenyanyiScreenState extends ConsumerState<MenyanyiScreen> {
  final Random _r = Random();
  int _level = 1;
  int _streak = 0;
  int _missStreak = 0;
  int _ronde = 0;
  bool _dipandu = true;

  List<int> _melodi = [];
  int _index = 0;
  bool _selesai = false;
  bool _adaMelesat = false;

  StreamSubscription<HasilPitch>? _sub;
  bool _mendeteksi = false;
  bool _ditolak = false;
  bool _menutupRonde = false;
  bool _mulai = false;
  HasilPitch? _terakhir;
  int _cocok = 0;
  static const _policy = AdaptivePolicy(
    minLevel: 1,
    maxLevel: 5,
    passScore: 100,
    failScore: 50,
  );

  @override
  void initState() {
    super.initState();
    final stat = ref
        .read(appControllerProvider)
        .value
        ?.progres
        .game['menyanyi'];
    _level = stat?.levelAktif ?? 1;
    _streak = stat?.streakAktif ?? 0;
    _missStreak = stat?.missStreakAktif ?? 0;
  }

  @override
  void dispose() {
    _sub?.cancel();
    ref.read(pitchProvider).hentikanDeteksi();
    super.dispose();
  }

  void _buatRonde() {
    final oldSub = _sub;
    if (oldSub != null) unawaited(oldSub.cancel());
    _sub = null;
    unawaited(ref.read(pitchProvider).hentikanDeteksi());
    final melodi = _buatMelodi(_level);
    setState(() {
      _melodi = melodi;
      _index = 0;
      _selesai = false;
      _adaMelesat = false;
      _menutupRonde = false;
      _mendeteksi = false;
      _terakhir = null;
      _cocok = 0;
      _ronde += 1;
    });
  }

  void _mulaiLatihan() {
    setState(() => _mulai = true);
    _buatRonde();
  }

  List<int> _buatMelodi(int level) {
    final panjang = switch (level.clamp(1, 5)) {
      1 => 3,
      2 => 4,
      3 => 5,
      4 => 6,
      _ => 7,
    };
    final maxLompat = level <= 2 ? 1 : (level <= 4 ? 2 : 3);
    final melodi = <int>[];
    var derajat = _r.nextInt(5) + 1;
    for (var i = 0; i < panjang; i++) {
      melodi.add(derajat);
      final kandidat = <int>[
        for (var d = -maxLompat; d <= maxLompat; d++)
          if (d != 0 && (derajat + d) >= 1 && (derajat + d) <= 5) d,
      ];
      final step = kandidat[_r.nextInt(kandidat.length)];
      derajat = (derajat + step).clamp(1, 5);
    }
    return melodi;
  }

  Future<void> _mulaiDeteksi() async {
    if (_mendeteksi) return;
    final pitch = ref.read(pitchProvider);
    final ok = await pitch.mintaIzinMikrofon();
    if (!mounted) return;
    if (!ok) {
      setState(() => _ditolak = true);
      return;
    }
    final app = ref.read(appControllerProvider).value!;
    await _sub?.cancel();
    _sub = null;
    await pitch.hentikanDeteksi();
    setState(() {
      _ditolak = false;
      _mendeteksi = true;
      _terakhir = null;
      _cocok = 0;
    });
    _sub = pitch
        .mulaiDeteksi(app.profilAktif(), app.pengaturan.toleransiCents)
        .listen(_onPitch);
    if (_dipandu) _dengarTarget();
  }

  void _onPitch(HasilPitch h) {
    if (!mounted) return;
    setState(() => _terakhir = h);
    if (_selesai || _index >= _melodi.length) return;
    final cocok = h.tepat && h.tonaTerdekat?.angka == _melodi[_index];
    if (cocok) {
      _cocok += 1;
      if (_cocok >= 2) {
        _cocok = 0;
        final next = _index + 1;
        setState(() => _index = next);
        if (next >= _melodi.length) {
          _selesaiRonde();
        } else if (_dipandu) {
          _dengarTarget();
        }
      }
    } else if (!h.tepat) {
      _cocok = 0;
    }
  }

  Future<void> _selesaiRonde() async {
    if (_menutupRonde) return;
    _menutupRonde = true;
    await _sub?.cancel();
    _sub = null;
    await ref.read(pitchProvider).hentikanDeteksi();
    final skor = _adaMelesat ? 60 : 100;
    final next = _policy.apply(
      level: _level,
      streak: _streak,
      missStreak: _missStreak,
      score: skor,
      adaptif: true,
    );
    _level = next.level;
    _streak = next.streak;
    _missStreak = next.missStreak;
    if (mounted) {
      setState(() {
        _selesai = true;
        _mendeteksi = false;
      });
    }
    unawaited(
      ref
          .read(appControllerProvider.notifier)
          .catatRondeGame(
            'menyanyi',
            level: _level,
            streak: _streak,
            missStreak: _missStreak,
            skor: skor,
            benar: !_adaMelesat,
          ),
    );
  }

  void _lewati() {
    if (_index >= _melodi.length || _menutupRonde) return;
    _adaMelesat = true;
    _cocok = 0;
    setState(() => _index += 1);
    if (_index >= _melodi.length) unawaited(_selesaiRonde());
  }

  Future<void> _putarAcuan() async {
    await ref
        .read(audioProvider)
        .putarUrutan(nadaAcuan(), jeda: const Duration(milliseconds: 280));
  }

  Future<void> _dengarTarget() async {
    if (_index < _melodi.length) {
      await ref.read(audioProvider).putarTona(Tona(angka: _melodi[_index]));
    }
  }

  @override
  Widget build(BuildContext context) {
    const hijau = Color(0xFF2E7D32);
    final scheme = Theme.of(context).colorScheme;
    final warna = [
      for (var i = 0; i < _melodi.length; i++)
        if (i < _index)
          hijau
        else if (i == _index && _dipandu && _mendeteksi)
          scheme.primary
        else
          scheme.onSurface.withValues(alpha: 0.35),
    ];
    final simbol = [for (final a in _melodi) SimbolNot.nada(a)];

    return LatihanPopScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Latihan Menyanyikan Nada')),
        body: _mulai
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StatusGame(level: _level, streak: _streak, ronde: _ronde),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Dipandu'),
                        selected: _dipandu,
                        onSelected: _mendeteksi
                            ? null
                            : (_) => setState(() => _dipandu = true),
                      ),
                      ChoiceChip(
                        label: const Text('Tidak dipandu'),
                        selected: !_dipandu,
                        onSelected: _mendeteksi
                            ? null
                            : (_) => setState(() => _dipandu = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dipandu
                              ? 'Nyanyikan tiap nada yang disorot. Pakai laras ${ref.watch(appControllerProvider).value!.profilAktif().nama}.'
                              : 'Nyanyikan seluruh melodi sendiri (tanpa sorotan). Gunakan Putar Acuan untuk menyetel nada.',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: JianpuView(
                            simbol: simbol,
                            warna: warna,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _putarAcuan,
                              icon: const Icon(Icons.straighten),
                              label: const Text('Putar Acuan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_ditolak)
                    InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Izin mikrofon diperlukan untuk latihan ini.',
                          ),
                          TextButton.icon(
                            onPressed: openAppSettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Buka Pengaturan Izin'),
                          ),
                        ],
                      ),
                    ),
                  if (_selesai)
                    _HasilNyanyi(adaMelesat: _adaMelesat, onLanjut: _buatRonde)
                  else if (!_mendeteksi)
                    FilledButton.icon(
                      onPressed: _mulaiDeteksi,
                      icon: const Icon(Icons.mic),
                      label: const Text('Mulai Menyanyi'),
                    )
                  else
                    Column(
                      children: [
                        InfoCard(
                          child: Column(
                            children: [
                              Text(
                                'Nada ${_index + 1} dari ${_melodi.length}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _terakhir == null
                                    ? 'Mendengarkan...'
                                    : (_terakhir!.tonaTerdekat == null
                                          ? 'Belum terdengar'
                                          : _terakhir!.tepat
                                          ? 'Terdengar: ${_solfeg[_terakhir!.tonaTerdekat!.angka] ?? '-'}'
                                          : 'Terdengar: ${_solfeg[_terakhir!.tonaTerdekat!.angka] ?? '-'} - belum pas'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (_dipandu)
                              OutlinedButton.icon(
                                onPressed: _dengarTarget,
                                icon: const Icon(Icons.music_note),
                                label: const Text('Dengar Nada Ini'),
                              ),
                            TextButton.icon(
                              onPressed: _lewati,
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Lewati nada'),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              )
            : LatihanIntro(
                judul: 'Menyanyi',
                jenis: 'Nyanyikan nada',
                deskripsi:
                    'Ikuti melodi dengan suara. Mikrofon menilai ketepatan nada.',
                poin: const ['Da-mi-na-ti-la', 'Nada acuan', 'Mikrofon'],
                onMulai: _mulaiLatihan,
              ),
      ),
    );
  }
}

class _HasilNyanyi extends StatelessWidget {
  final bool adaMelesat;
  final VoidCallback onLanjut;
  const _HasilNyanyi({required this.adaMelesat, required this.onLanjut});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoCard(
          child: Row(
            children: [
              Icon(
                adaMelesat ? Icons.info_outline : Icons.celebration,
                color: adaMelesat
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  adaMelesat ? 'Ada nada yang dilewati.' : 'Semua nada tepat.',
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
          label: const Text('Melodi Berikutnya'),
        ),
      ],
    );
  }
}

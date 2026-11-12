import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/logic.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'baca_cepat_screen.dart';
import 'cocokkan_notasi_screen.dart';
import 'latihan_nada_screen.dart';
import 'menyanyi_screen.dart';
import 'tebak_melodi_screen.dart';
import 'widgets.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return app.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Aplikasi belum dapat dimuat: $error'),
          ),
        ),
      ),
      data: (data) {
        final pages = const [
          LatihanMenuScreen(),
          ProgressScreen(),
          PengaturanScreen(),
        ];
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final keluar = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Keluar aplikasi?'),
                content: const Text('Apakah kamu yakin ingin keluar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
            if (keluar == true) {
              await SystemNavigator.pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Belajar Titilaras Sunda')),
            body: SafeArea(
              child: Column(
                children: [
                  if (data.kesalahanParsing.isNotEmpty)
                    MaterialBanner(
                      content: Text(
                        'Sebagian materi belum dapat dimuat: ${data.kesalahanParsing.map((e) => e.namaBerkas).join(', ')}',
                      ),
                      actions: const [SizedBox.shrink()],
                    ),
                  Expanded(child: pages[_index]),
                ],
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note),
                  label: 'Latihan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events),
                  label: 'Progres',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Pengaturan',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LatihanMenuScreen extends ConsumerWidget {
  const LatihanMenuScreen({super.key});

  void _main(BuildContext context, Widget Function(int? levelDrill) builder) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => builder(null)));
  }

  void _drill(BuildContext context, Widget Function(int? levelDrill) builder) {
    const labels = {
      1: 'Sangat Mudah',
      2: 'Mudah',
      3: 'Sedang',
      4: 'Sulit',
      5: 'Sangat Sulit',
    };
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih tingkat Practice',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            for (final e in labels.entries)
              ListTile(
                leading: CircleAvatar(child: Text('${e.key}')),
                title: Text(e.value),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => builder(e.key)));
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _GameItem(
        icon: LucideIcons.listMusic,
        judul: 'Tebak Melodi',
        deskripsi: 'Dengarkan pola nada lalu tulis notasi angkanya.',
        onPlay: () => _main(context, (l) => TebakMelodiScreen(levelDrill: l)),
        onPractice: () =>
            _drill(context, (l) => TebakMelodiScreen(levelDrill: l)),
      ),
      _GameItem(
        icon: LucideIcons.badgeQuestionMark,
        judul: 'Nada Hilang',
        deskripsi: 'Cari nada yang hilang dari rangkaian da-mi-na-ti-la.',
        onPlay: () => _main(
          context,
          (l) => LatihanNadaScreen(mode: ModeSetNada.nadaHilang, levelDrill: l),
        ),
        onPractice: () => _drill(
          context,
          (l) => LatihanNadaScreen(mode: ModeSetNada.nadaHilang, levelDrill: l),
        ),
      ),
      _GameItem(
        icon: LucideIcons.audioLines,
        judul: 'Tebak Harmoni',
        deskripsi: 'Dengarkan beberapa nada serentak lalu pilih isinya.',
        onPlay: () => _main(
          context,
          (l) => LatihanNadaScreen(mode: ModeSetNada.harmoni, levelDrill: l),
        ),
        onPractice: () => _drill(
          context,
          (l) => LatihanNadaScreen(mode: ModeSetNada.harmoni, levelDrill: l),
        ),
      ),
      _GameItem(
        icon: LucideIcons.zap,
        judul: 'Baca Cepat',
        deskripsi: 'Cocokkan notasi, nama nada, dan register dengan cepat.',
        onPlay: () => _main(context, (l) => BacaCepatScreen(levelDrill: l)),
        onPractice: () =>
            _drill(context, (l) => BacaCepatScreen(levelDrill: l)),
      ),
      _GameItem(
        icon: LucideIcons.bookOpen,
        judul: 'Cocokkan Notasi',
        deskripsi:
            'Baca notasi, dengarkan pilihan bunyi, lalu pilih yang cocok.',
        onPlay: () =>
            _main(context, (l) => CocokkanNotasiScreen(levelDrill: l)),
        onPractice: () =>
            _drill(context, (l) => CocokkanNotasiScreen(levelDrill: l)),
      ),
      _GameItem(
        icon: LucideIcons.mic,
        judul: 'Menyanyi',
        deskripsi: 'Nyanyikan melodi dan cek ketepatan nada dari mikrofon.',
        onPlay: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MenyanyiScreen())),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionHeader(title: 'Latihan'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 16,
                  childAspectRatio: columns == 3 ? 0.9 : 0.76,
                ),
                itemBuilder: (context, index) =>
                    FadeInUp(child: _GameCard(item: items[index])),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameItem {
  final IconData icon;
  final String judul;
  final String deskripsi;
  final VoidCallback onPlay;
  final VoidCallback? onPractice;

  const _GameItem({
    required this.icon,
    required this.judul,
    required this.deskripsi,
    required this.onPlay,
    this.onPractice,
  });
}

class _GameCard extends StatelessWidget {
  final _GameItem item;

  const _GameCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onPlay,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.86)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Column(
              children: [
                _RoundExerciseIcon(icon: item.icon),
                const SizedBox(height: 12),
                Text(
                  item.judul,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    item.deskripsi,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: item.onPlay,
                        icon: const Icon(LucideIcons.play, size: 16),
                        label: const Text('Play'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                    if (item.onPractice != null) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Practice',
                        onPressed: item.onPractice,
                        icon: const Icon(LucideIcons.dumbbell, size: 18),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundExerciseIcon extends StatelessWidget {
  final IconData icon;

  const _RoundExerciseIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = scheme.primary;
    final ring = scheme.secondary;
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: ring, width: 4),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 42, color: scheme.onPrimary),
    );
  }
}

class SuaraSendiriScreen extends ConsumerStatefulWidget {
  const SuaraSendiriScreen({super.key});

  @override
  ConsumerState<SuaraSendiriScreen> createState() => _SuaraSendiriScreenState();
}

class _SuaraSendiriScreenState extends ConsumerState<SuaraSendiriScreen> {
  StreamSubscription<HasilPitch>? _sub;
  HasilPitch? _latest;
  bool _denied = false;

  @override
  void dispose() {
    _sub?.cancel();
    ref.read(pitchProvider).hentikanDeteksi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider).value!;
    return Scaffold(
      appBar: AppBar(title: const Text('Latihan Suara Sendiri')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nyanyikan satu nada',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Gunakan laras ${app.profilAktif().nama}. Toleransi: ${_toleranceLabel(app.pengaturan.toleransiCents)}.',
                ),
                const SizedBox(height: 16),
                if (_denied)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Izin mikrofon diperlukan untuk latihan ini. Latihan lain tetap dapat digunakan.',
                      ),
                      TextButton.icon(
                        onPressed: openAppSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Buka Pengaturan Izin'),
                      ),
                    ],
                  ),
                FilledButton.icon(
                  onPressed: () => _start(app),
                  icon: const Icon(Icons.mic),
                  label: const Text('Mulai Deteksi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_latest != null)
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _latest!.pesan,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_latest!.tonaTerdekat != null)
                    Text(
                      'Nada dikenali: ${_latest!.tonaTerdekat!.solfeg} (${_latest!.tonaTerdekat!.angka})',
                    ),
                  if (_latest!.frekuensiHz != null)
                    Text(
                      'Frekuensi: ${_latest!.frekuensiHz!.toStringAsFixed(1)} Hz',
                    ),
                  if (_latest!.selisihCents != null)
                    Text(
                      'Selisih: ${_latest!.selisihCents!.toStringAsFixed(1)} cents',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _start(AppState app) async {
    final pitch = ref.read(pitchProvider);
    final granted = await pitch.mintaIzinMikrofon();
    if (!mounted) return;
    if (!granted) {
      setState(() => _denied = true);
      return;
    }
    setState(() => _denied = false);
    await _sub?.cancel();
    _sub = pitch
        .mulaiDeteksi(app.profilAktif(), app.pengaturan.toleransiCents)
        .listen((event) {
          if (mounted) setState(() => _latest = event);
        });
  }
}

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const Map<String, ({String nama, IconData ikon})> _game = {
    'tebak_melodi': (nama: 'Tebak Melodi', ikon: LucideIcons.listMusic),
    'nada_hilang': (nama: 'Nada Hilang', ikon: LucideIcons.badgeQuestionMark),
    'harmoni': (nama: 'Tebak Harmoni', ikon: LucideIcons.audioLines),
    'baca_cepat': (nama: 'Baca Cepat: Notasi ke Nada', ikon: LucideIcons.zap),
    'baca_reverse': (
      nama: 'Baca Cepat: Nada ke Angka',
      ikon: LucideIcons.target,
    ),
    'cocokkan_notasi': (nama: 'Cocokkan Notasi', ikon: LucideIcons.bookOpen),
    'menyanyi': (nama: 'Menyanyi', ikon: LucideIcons.mic),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider).value!;
    final progres = app.progres;
    final stats = progres.game;
    final totalRonde = progres.totalRonde;
    final totalBenar = stats.values.fold(
      0,
      (sum, stat) => sum + stat.totalBenar,
    );
    final totalSkor = stats.values.fold(0, (sum, stat) => sum + stat.totalSkor);
    final bestStreak = stats.values.fold(
      0,
      (maxValue, stat) =>
          stat.streakTerbaik > maxValue ? stat.streakTerbaik : maxValue,
    );
    final bestLevel = stats.values.fold(
      1,
      (maxValue, stat) =>
          stat.levelTertinggi > maxValue ? stat.levelTertinggi : maxValue,
    );
    final avgScore = totalRonde == 0 ? 0 : (totalSkor / totalRonde).round();
    final accuracy = totalRonde == 0
        ? 0
        : (totalBenar * 100 / totalRonde).round();
    final daily = _gabungAktivitas(stats.values);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionHeader(
          title: 'Progres',
          subtitle:
              'Ringkasan latihan, grafik mingguan, dan performa tiap mode.',
        ),
        if (stats.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: InfoCard(
              child: Text(
                'Belum ada permainan dimainkan. Mulai dari menu Latihan.',
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _ProgressSummary(
              totalRonde: totalRonde,
              accuracy: accuracy,
              avgScore: avgScore,
              bestLevel: bestLevel,
              bestStreak: bestStreak,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas 7 Hari',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _WeeklyActivityChart(daily: daily),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Text(
              'Per Mode',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final entry in _game.entries)
            if (stats[entry.key] != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: FadeInUp(
                  child: _ModeStatCard(
                    name: entry.value.nama,
                    icon: entry.value.ikon,
                    stat: stats[entry.key]!,
                  ),
                ),
              ),
        ],
      ],
    );
  }

  static Map<String, int> _gabungAktivitas(Iterable<StatGame> stats) {
    final hasil = <String, int>{};
    for (final stat in stats) {
      for (final entry in stat.aktivitasHarian.entries) {
        hasil[entry.key] = (hasil[entry.key] ?? 0) + entry.value;
      }
    }
    return hasil;
  }
}

class _ProgressSummary extends StatelessWidget {
  final int totalRonde;
  final int accuracy;
  final int avgScore;
  final int bestLevel;
  final int bestStreak;

  const _ProgressSummary({
    required this.totalRonde,
    required this.accuracy,
    required this.avgScore,
    required this.bestLevel,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatTile(
                width: width,
                icon: LucideIcons.circlePlay,
                label: 'Ronde',
                value: '$totalRonde',
              ),
              _StatTile(
                width: width,
                icon: LucideIcons.target,
                label: 'Akurasi',
                value: '$accuracy%',
              ),
              _StatTile(
                width: width,
                icon: LucideIcons.chartNoAxesColumn,
                label: 'Skor rata-rata',
                value: '$avgScore',
              ),
              _StatTile(
                width: width,
                icon: LucideIcons.trophy,
                label: 'Level/Streak',
                value: '$bestLevel / $bestStreak',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width.clamp(130, 260),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  final Map<String, int> daily;

  const _WeeklyActivityChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];
    final values = [for (final day in days) daily[_tanggalKeyUi(day)] ?? 0];
    final maxValue = values.fold(1, (max, v) => v > max ? v : max);
    final scheme = Theme.of(context).colorScheme;
    const labels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return SizedBox(
      height: 156,
      child: CustomPaint(
        painter: _WeeklyChartPainter(
          values: values,
          labels: [for (final day in days) labels[day.weekday % 7]],
          maxValue: maxValue,
          lineColor: scheme.primary,
          gridColor: scheme.outlineVariant,
          textColor: scheme.onSurfaceVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final int maxValue;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  const _WeeklyChartPainter({
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 26.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 24.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final textStyle = TextStyle(color: textColor, fontSize: 11);
    for (var i = 0; i <= 4; i++) {
      final y = chart.bottom - chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      _text(
        canvas,
        '${(maxValue * i / 4).round()}',
        Offset(0, y - 7),
        textStyle,
      );
    }
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = chart.left + chart.width * i / (values.length - 1);
      final y = chart.bottom - chart.height * (values[i] / maxValue);
      points.add(Offset(x, y));
      _text(canvas, labels[i], Offset(x - 12, chart.bottom + 6), textStyle);
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dotPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  void _text(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor;
  }
}

class _ModeStatCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final StatGame stat;

  const _ModeStatCard({
    required this.name,
    required this.icon,
    required this.stat,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniIcon(icon: icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${stat.akurasiPersen}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatusGame(
            level: stat.levelTertinggi,
            streak: stat.streakTerbaik,
            ronde: stat.totalRonde,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stat.akurasiPersen / 100,
              minHeight: 8,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text('Skor rata-rata ${stat.rataRataSkor}'),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;

  const _MiniIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
      child: Icon(icon, color: scheme.onPrimary, size: 22),
    );
  }
}

String _tanggalKeyUi(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

class PengaturanScreen extends ConsumerWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider).value!;
    final settings = app.pengaturan;
    final notifier = ref.read(appControllerProvider.notifier);
    return ListView(
      children: [
        const SectionHeader(
          title: 'Pengaturan',
          subtitle: 'Atur instrumen, artikulasi, tema, dan toleransi suara.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InfoCard(
            child: Column(
              children: [
                DropdownButtonFormField<PilihanInstrumen>(
                  initialValue: settings.instrumen,
                  decoration: const InputDecoration(
                    labelText: 'Instrumen',
                    helperText:
                        'Otomatis: oktaf rendah Demung, tengah Saron, tinggi Peking.',
                  ),
                  items: [
                    for (final instrumen in PilihanInstrumen.values)
                      DropdownMenuItem(
                        value: instrumen,
                        child: Text(instrumen.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      notifier.updatePengaturan(
                        settings.copyWith(instrumen: value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Artikulasi>(
                  initialValue: settings.artikulasi,
                  decoration: const InputDecoration(
                    labelText: 'Artikulasi',
                    helperText:
                        'Open: nada dibiarkan bergetar. Tengkep: nada ditekep.',
                  ),
                  items: [
                    for (final artikulasi in Artikulasi.values)
                      DropdownMenuItem(
                        value: artikulasi,
                        child: Text(artikulasi.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      notifier.updatePengaturan(
                        settings.copyWith(artikulasi: value),
                      );
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.tema == ModeTema.gelap,
                  title: const Text('Tema gelap'),
                  onChanged: (value) => notifier.updatePengaturan(
                    settings.copyWith(
                      tema: value ? ModeTema.gelap : ModeTema.terang,
                    ),
                  ),
                ),
                _ToleranceSetting(
                  value: settings.toleransiCents,
                  onChanged: (value) => notifier.updatePengaturan(
                    settings.copyWith(toleransiCents: value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToleranceSetting extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ToleranceSetting({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = _toleranceLevel(value);
    return DropdownButtonFormField<String>(
      initialValue: current,
      decoration: const InputDecoration(labelText: 'Toleransi suara'),
      items: const [
        DropdownMenuItem(value: 'rendah', child: Text('Rendah')),
        DropdownMenuItem(value: 'sedang', child: Text('Sedang')),
        DropdownMenuItem(value: 'tinggi', child: Text('Tinggi')),
        DropdownMenuItem(value: 'sangat_tinggi', child: Text('Sangat tinggi')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(_toleranceCents(value));
      },
    );
  }
}

String _toleranceLevel(double cents) {
  if (cents <= 35) return 'rendah';
  if (cents <= 60) return 'sedang';
  if (cents <= 90) return 'tinggi';
  return 'sangat_tinggi';
}

String _toleranceLabel(double cents) {
  return switch (_toleranceLevel(cents)) {
    'rendah' => 'Rendah',
    'sedang' => 'Sedang',
    'tinggi' => 'Tinggi',
    _ => 'Sangat tinggi',
  };
}

double _toleranceCents(String level) {
  return switch (level) {
    'rendah' => 30,
    'sedang' => 50,
    'tinggi' => 80,
    _ => 110,
  };
}

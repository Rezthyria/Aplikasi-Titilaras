import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../domain/logic.dart';
import '../domain/models.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.06),
              scheme.surface,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Animasi masuk lembut (fade + naik) untuk konten statis. Dipakai sekali saat
/// pertama dibangun agar layar tidak terasa terlalu datar.
class FadeInUp extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeInUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class NotasiAngkaView extends StatelessWidget {
  final Tona tona;
  final ModeNotasi mode;
  final double size;

  const NotasiAngkaView({
    super.key,
    required this.tona,
    required this.mode,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final numberStyle = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1,
    );
    final dotStyle = TextStyle(
      fontSize: (size * 0.48).clamp(10, 18),
      fontWeight: FontWeight.w800,
      height: 0.7,
    );
    final dotCount = tona.oktafRelatif.abs();
    final dots = List.filled(dotCount, '.').join();
    return SizedBox(
      width: size + 16,
      height: size + 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 12,
            child: Text(
              tona.oktafRelatif < 0 ? dots : '',
              style: dotStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Text('${tona.angka}', style: numberStyle),
          SizedBox(
            height: 12,
            child: Text(
              tona.oktafRelatif > 0 ? dots : '',
              style: dotStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class NotasiSequenceView extends StatelessWidget {
  final List<Tona> urutan;
  final ModeNotasi mode;
  final double size;

  const NotasiSequenceView({
    super.key,
    required this.urutan,
    required this.mode,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.55))),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 6,
        children: [
          Text('|', style: Theme.of(context).textTheme.titleLarge),
          for (final tona in urutan)
            NotasiAngkaView(tona: tona, mode: mode, size: size),
          Text('|', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class DaminatilaSequenceView extends StatelessWidget {
  final List<Tona> urutan;

  const DaminatilaSequenceView({super.key, required this.urutan});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tona in urutan)
          Chip(
            label: Text('${tona.angka} ${tona.solfeg}'),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class TonaFrequencyRow extends StatelessWidget {
  final ProfilTuning profil;
  final TonaTuning entry;
  final ModeNotasi mode;

  const TonaFrequencyRow({
    super.key,
    required this.profil,
    required this.entry,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final hz = frekuensiTona(Tona(angka: entry.angka), profil);
    return ListTile(
      dense: true,
      leading: NotasiAngkaView(
        tona: Tona(angka: entry.angka),
        mode: mode,
        size: 20,
      ),
      title: Text('${entry.nama} (${Tona(angka: entry.angka).solfeg})'),
      subtitle: Text(
        '${entry.cents.toStringAsFixed(0)} cents dari ${profil.nadaDasar}',
      ),
      trailing: Text('${hz.toStringAsFixed(2)} Hz'),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;

  const ProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 100) / 100,
        minHeight: 10,
      ),
    );
  }
}

class FallingRhythmPanel extends StatefulWidget {
  final PolaIrama pola;

  const FallingRhythmPanel({super.key, required this.pola});

  @override
  State<FallingRhythmPanel> createState() => _FallingRhythmPanelState();
}

class _FallingRhythmPanelState extends State<FallingRhythmPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _RhythmPainter(
              progress: _controller.value,
              pola: widget.pola,
              color: Theme.of(context).colorScheme.primary,
              lineColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        },
      ),
    );
  }
}

class _RhythmPainter extends CustomPainter {
  final double progress;
  final PolaIrama pola;
  final Color color;
  final Color lineColor;

  _RhythmPainter({
    required this.progress,
    required this.pola,
    required this.color,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = color.withValues(alpha: 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bg,
    );
    final targetY = size.height * 0.78;
    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      Paint()
        ..color = lineColor
        ..strokeWidth = 2,
    );
    final paint = Paint()..color = color;
    for (final ketuk in pola.ketukan) {
      final x = size.width * (0.18 + (ketuk.beat % 4) / 4 * 0.68);
      final y = ((progress + ketuk.beat / 4) % 1.0) * size.height;
      canvas.drawCircle(Offset(x, y), 13, paint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${ketuk.angka}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 9));
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pola != pola;
  }
}

/// Renderer notasi angka (jianpu Sunda) untuk deret [SimbolNot].
///
/// - Beam (garis durasi) digambar di ATAS angka (konvensi Sunda).
/// - Titik oktaf: rendah di atas (di bawah beam), tinggi di bawah angka.
/// - Titik perpanjangan `·` dan istirahat `0` dirender sebagai sel tersendiri.
/// - Garis birama `|` otomatis tiap 4 ketuk; [warna] memberi warna per simbol
///   (mis. hijau benar / merah salah) saat umpan balik.
class JianpuView extends StatelessWidget {
  final List<SimbolNot> simbol;
  final List<Color>? warna;
  final double size;

  const JianpuView({
    super.key,
    required this.simbol,
    this.warna,
    this.size = 30,
  });

  Color _warna(int i, Color base) =>
      (warna != null && i < warna!.length) ? warna![i] : base;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    if (simbol.isEmpty) {
      return Text(
        '—',
        style: TextStyle(fontSize: size, color: base.withValues(alpha: 0.4)),
      );
    }
    final bars = indeksBirama(simbol).toSet();
    final birama = <List<int>>[];
    var current = <int>[];
    for (var i = 0; i < simbol.length; i++) {
      current.add(i);
      if (bars.contains(i)) {
        birama.add(current);
        current = [];
      }
    }
    if (current.isNotEmpty) birama.add(current);

    final children = <Widget>[_bar(base)];
    for (final ruas in birama) {
      children.addAll(_segmen(ruas, base));
      children.add(_bar(base));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: children,
      ),
    );
  }

  /// Membangun segmen satu birama: not seperdelapan/seperenambelas berurutan
  /// dikelompokkan dengan beam menyatu.
  List<Widget> _segmen(List<int> ruas, Color base) {
    final hasil = <Widget>[];
    var i = 0;
    while (i < ruas.length) {
      final idx = ruas[i];
      final s = simbol[idx];
      final berbeam = s.jenis != JenisSimbol.perpanjangan && s.beam > 0;
      if (berbeam) {
        final grup = <int>[idx];
        var j = i + 1;
        while (j < ruas.length) {
          final n = simbol[ruas[j]];
          if (n.jenis != JenisSimbol.perpanjangan && n.beam > 0) {
            grup.add(ruas[j]);
            j++;
          } else {
            break;
          }
        }
        hasil.add(_grupBeam(grup, base));
        i = j;
      } else {
        hasil.add(_isiSel(idx, base));
        i++;
      }
    }
    return hasil;
  }

  Widget _bar(Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      '|',
      style: TextStyle(fontSize: size * 1.15, color: color),
    ),
  );

  Widget _grupBeam(List<int> grup, Color base) {
    final maxBeam = grup
        .map((i) => simbol[i].beam)
        .reduce((a, b) => a > b ? a : b);
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var b = 0; b < maxBeam; b++)
            Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 2),
              color: base,
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (final i in grup) _isiSel(i, base)],
          ),
        ],
      ),
    );
  }

  /// Satu sel TANPA beam sendiri (beam digambar oleh grup bila ada).
  Widget _isiSel(int i, Color base) {
    final s = simbol[i];
    final color = _warna(i, base);
    final numStyle = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1,
      color: color,
    );
    var glyph = '·';
    var lowDots = 0;
    var highDots = 0;
    switch (s.jenis) {
      case JenisSimbol.nada:
        glyph = '${s.angka}';
        if (s.oktafRelatif < 0) lowDots = s.oktafRelatif.abs();
        if (s.oktafRelatif > 0) highDots = s.oktafRelatif;
      case JenisSimbol.istirahat:
        glyph = '0';
      case JenisSimbol.perpanjangan:
        glyph = '·';
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size * 0.34,
            child: lowDots > 0
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: _dots(lowDots, color),
                  )
                : null,
          ),
          Text(glyph, style: numStyle),
          SizedBox(
            height: size * 0.42,
            child: highDots > 0 ? _dots(highDots, color) : null,
          ),
        ],
      ),
    );
  }

  Widget _dots(int count, Color color) => Text(
    '•' * count,
    style: TextStyle(
      fontSize: size * 0.42,
      height: 1,
      fontWeight: FontWeight.w900,
      color: color,
    ),
  );
}

class StatusGame extends StatelessWidget {
  final int level;
  final int streak;
  final int ronde;

  const StatusGame({
    super.key,
    required this.level,
    required this.streak,
    required this.ronde,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );

    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(Icons.trending_up, 'Lv $level', scheme.primary),
        chip(
          Icons.local_fire_department,
          'Naik $streak/5',
          const Color(0xFFEF6C00),
        ),
        chip(Icons.flag_outlined, 'Ronde $ronde', scheme.secondary),
      ],
    );
  }
}

Future<bool> konfirmasiKeluarLatihan(BuildContext context) async {
  final keluar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Keluar latihan?'),
      content: const Text('Sesi ini akan berhenti.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Tetap di sini'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  return keluar == true;
}

class LatihanPopScope extends StatelessWidget {
  final Widget child;

  const LatihanPopScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await konfirmasiKeluarLatihan(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}

class LatihanIntro extends StatelessWidget {
  final String judul;
  final String jenis;
  final String deskripsi;
  final List<String> poin;
  final VoidCallback onMulai;

  const LatihanIntro({
    super.key,
    required this.judul,
    required this.jenis,
    required this.deskripsi,
    required this.poin,
    required this.onMulai,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 22),
        child: Column(
          children: [
            Text(
              'LATIHAN',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 2,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              jenis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const Spacer(flex: 2),
            Text(
              deskripsi,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(flex: 2),
            if (poin.isNotEmpty) ...[
              Text(
                'Isi latihan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in poin)
                    Chip(
                      label: Text(item),
                      backgroundColor: scheme.primary,
                      labelStyle: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onMulai,
                child: const Text('Mulai'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pemilih mode game: Adaptif (level menyesuaikan) atau Drill level tetap
/// (Mudah/Sedang/Sulit).
class PemilihMode extends StatelessWidget {
  final bool adaptif;
  final int level;
  final int mudah;
  final int sedang;
  final int sulit;
  final VoidCallback onAdaptif;
  final ValueChanged<int> onDrill;

  const PemilihMode({
    super.key,
    required this.adaptif,
    required this.level,
    required this.mudah,
    required this.sedang,
    required this.sulit,
    required this.onAdaptif,
    required this.onDrill,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Adaptif'),
          selected: adaptif,
          onSelected: (_) => onAdaptif(),
        ),
        ChoiceChip(
          label: const Text('Mudah'),
          selected: !adaptif && level == mudah,
          onSelected: (_) => onDrill(mudah),
        ),
        ChoiceChip(
          label: const Text('Sedang'),
          selected: !adaptif && level == sedang,
          onSelected: (_) => onDrill(sedang),
        ),
        ChoiceChip(
          label: const Text('Sulit'),
          selected: !adaptif && level == sulit,
          onSelected: (_) => onDrill(sulit),
        ),
      ],
    );
  }
}

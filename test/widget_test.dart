import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aplikasi_titilaras/domain/models.dart';
import 'package:aplikasi_titilaras/presentation/widgets.dart';

void main() {
  testWidgets('NotasiAngkaView menaruh titik oktaf rendah di atas angka', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotasiAngkaView(
            tona: Tona(angka: 2, oktafRelatif: -1),
            mode: ModeNotasi.angka,
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('.'), findsOneWidget);
    // Konvensi Sunda: oktaf rendah -> titik di ATAS angka.
    final dotY = tester.getCenter(find.text('.')).dy;
    final numberY = tester.getCenter(find.text('2')).dy;
    expect(dotY, lessThan(numberY));
  });

  testWidgets('NotasiAngkaView menaruh titik oktaf tinggi di bawah angka', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotasiAngkaView(
            tona: Tona(angka: 2, oktafRelatif: 1),
            mode: ModeNotasi.angka,
          ),
        ),
      ),
    );

    final dotY = tester.getCenter(find.text('.')).dy;
    final numberY = tester.getCenter(find.text('2')).dy;
    expect(dotY, greaterThan(numberY));
  });

  testWidgets(
    'JianpuView merender angka, istirahat, perpanjangan, dan birama',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JianpuView(
              simbol: [
                SimbolNot.nada(1),
                SimbolNot.perpanjangan(),
                SimbolNot.nada(3, beam: 1),
                SimbolNot.istirahat(),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('·'), findsOneWidget);
      expect(find.text('|'), findsWidgets); // ada garis birama
    },
  );
}

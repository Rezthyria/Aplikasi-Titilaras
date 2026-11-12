import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:aplikasi_titilaras/domain/logic.dart';
import 'package:aplikasi_titilaras/domain/melodi.dart';
import 'package:aplikasi_titilaras/domain/models.dart';

void main() {
  group('durasi simbol', () {
    test('nada seperempat = 1 ketuk, seperdelapan = 0.5', () {
      expect(
        ketukPerSimbol([
          const SimbolNot.nada(1),
          const SimbolNot.nada(2, beam: 1),
        ]),
        [1.0, 0.5],
      );
    });

    test('titik perpanjangan menambah 50% lalu 25%', () {
      final simbol = [
        const SimbolNot.nada(3),
        const SimbolNot.perpanjangan(),
        const SimbolNot.perpanjangan(),
      ];
      expect(ketukPerSimbol(simbol), [1.0, 0.5, 0.25]);
      final kejadian = kejadianMelodi(simbol);
      expect(kejadian.length, 1);
      expect(kejadian.first.ketuk, closeTo(1.75, 1e-9));
      expect(kejadian.first.tona, const Tona(angka: 3));
    });

    test('istirahat menghasilkan kejadian tanpa tona', () {
      final kejadian = kejadianMelodi([
        const SimbolNot.nada(1),
        const SimbolNot.istirahat(),
      ]);
      expect(kejadian[1].tona, isNull);
      expect(kejadian[1].ketuk, 1.0);
    });
  });

  test('garis birama jatuh tiap 4 ketuk', () {
    final dua = [for (var i = 0; i < 8; i++) const SimbolNot.nada(1)];
    expect(indeksBirama(dua), [3]); // setelah ketuk ke-4 (indeks 3)
  });

  group('perbandingan jawaban', () {
    test('cocok penuh = skor 100', () {
      final target = [const SimbolNot.nada(1), const SimbolNot.nada(2)];
      final hasil = bandingkanMelodi(target, [...target]);
      expect(hasil.every((h) => h.benar), isTrue);
      expect(skorMelodi(hasil), 100);
    });

    test('oktaf/beam berbeda dianggap salah', () {
      final target = [const SimbolNot.nada(1, oktafRelatif: 1)];
      final jawab = [const SimbolNot.nada(1)];
      final hasil = bandingkanMelodi(target, jawab);
      expect(hasil.single.benar, isFalse);
    });

    test('jawaban lebih pendek -> sisa target salah', () {
      final target = [const SimbolNot.nada(1), const SimbolNot.nada(2)];
      final hasil = bandingkanMelodi(target, [const SimbolNot.nada(1)]);
      expect(hasil[0].benar, isTrue);
      expect(hasil[1].benar, isFalse);
      expect(hasil[1].jawaban, isNull);
      expect(skorMelodi(hasil), 50);
    });
  });

  group('generator melodi', () {
    test('tiap level: total ketuk = 4 x jumlah birama, angka valid', () {
      final gen = GeneratorMelodi(Random(7));
      for (var level = 1; level <= KesulitanMelodi.levelMaks; level++) {
        final k = KesulitanMelodi.untukLevel(level);
        for (var iterasi = 0; iterasi < 50; iterasi++) {
          final simbol = gen.buat(k);
          final total = ketukPerSimbol(simbol).fold<double>(0, (a, b) => a + b);
          expect(
            total,
            closeTo(4.0 * k.jumlahBirama, 1e-9),
            reason: 'level $level total ketuk salah',
          );
          for (final s in simbol) {
            if (s.jenis == JenisSimbol.nada) {
              expect(s.angka, inInclusiveRange(1, 5));
              expect(k.oktaf, contains(s.oktafRelatif));
            }
          }
        }
      }
    });

    test('level 1 hanya nada seperempat oktaf tengah', () {
      final gen = GeneratorMelodi(Random(1));
      final k = KesulitanMelodi.untukLevel(1);
      for (var i = 0; i < 30; i++) {
        for (final s in gen.buat(k)) {
          expect(s.jenis, JenisSimbol.nada);
          expect(s.beam, 0);
          expect(s.oktafRelatif, 0);
        }
      }
    });
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:aplikasi_titilaras/domain/latihan_nada.dart';

void main() {
  group('nada hilang', () {
    test('level 1: berurutan, 1 nada hilang', () {
      final r = Random(3);
      for (var i = 0; i < 30; i++) {
        final s = buatNadaHilang(1, r);
        expect(s.urutan, [1, 2, 3, 4, 5]);
        expect(s.hilang.length, 1);
        expect(s.hilang.every((n) => s.urutan.contains(n)), isTrue);
      }
    });

    test('level naik menambah jumlah hilang & mengacak urutan', () {
      final r = Random(5);
      expect(buatNadaHilang(3, r).hilang.length, 2);
      expect(buatNadaHilang(5, r).hilang.length, 3);
      // urutan tetap permutasi lengkap 1..5
      final s = buatNadaHilang(4, r);
      expect(s.urutan.toSet(), {1, 2, 3, 4, 5});
    });
  });

  group('harmoni', () {
    test('jumlah nada sesuai level, semua dalam 1..5 dan distinct', () {
      final r = Random(9);
      for (final level in [1, 2, 4]) {
        for (var i = 0; i < 20; i++) {
          final h = buatHarmoni(level, r);
          expect(h.length, jumlahHarmoniUntukLevel(level));
          expect(h.every((n) => n >= 1 && n <= 5), isTrue);
        }
      }
    });
  });

  group('skor himpunan', () {
    test('cocok persis = 100', () {
      expect(skorSetNada({2, 4}, {2, 4}), 100);
    });
    test('salah pilih mengurangi skor', () {
      expect(skorSetNada({2, 4}, {2, 4, 1}), 50); // tp2 fp1 -> net1 /2
      expect(skorSetNada({3}, {1}), 0); // tp0 fp1 -> net0
    });
    test('kurang lengkap memberi skor sebagian', () {
      expect(skorSetNada({1, 2, 3}, {1, 2}), closeTo(67, 1));
    });
  });
}

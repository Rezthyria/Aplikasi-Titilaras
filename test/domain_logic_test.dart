import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, setUpAll, test;

import 'package:aplikasi_titilaras/core/theme/app_theme.dart';
import 'package:aplikasi_titilaras/core/theme/contrast.dart';
import 'package:aplikasi_titilaras/data/repositories.dart';
import 'package:aplikasi_titilaras/domain/logic.dart';
import 'package:aplikasi_titilaras/domain/adaptive.dart';
import 'package:aplikasi_titilaras/domain/models.dart';

void main() {
  late List<ProfilTuning> profiles;
  late List<UnitBelajar> units;

  setUpAll(() {
    profiles = Directory('assets/tuning')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .map((file) {
          return ProfilTuning.fromJson(
            Map<String, Object?>.from(
              jsonDecode(file.readAsStringSync()) as Map,
            ),
          );
        })
        .toList();
    units = Directory('assets/content')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .map((file) {
          return UnitBelajar.fromJson(
            Map<String, Object?>.from(
              jsonDecode(file.readAsStringSync()) as Map,
            ),
          );
        })
        .toList();
  });

  Glados<int>().test(
    'Feature: titilaras-sunda, Property 9: angka selalu memetakan suku kata solfeg',
    (input) {
      final angka = input.abs() % 5 + 1;
      final expected = {1: 'da', 2: 'mi', 3: 'na', 4: 'ti', 5: 'la'};
      expect(Tona(angka: angka).solfeg, expected[angka]);
    },
  );

  test(
    'Feature: titilaras-sunda, Property 5: rasio kontras tema bawaan >= 4.5',
    () {
      for (final pair in AppTheme.contrastPairs()) {
        expect(
          contrastRatio(pair.foreground, pair.background),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  test(
    'Feature: titilaras-sunda, Property 1: round-trip profil tuning dan konten',
    () {
      for (final profile in profiles) {
        final roundTrip = ProfilTuning.fromJson(profile.toJson());
        expect(roundTrip.toJson(), profile.toJson());
      }
      for (final unit in units) {
        final roundTrip = UnitBelajar.fromJson(unit.toJson());
        expect(roundTrip.toJson(), unit.toJson());
      }
    },
  );

  test(
    'Feature: titilaras-sunda, Property 3 dan 6: konten valid dan bebas istilah asing',
    () {
      const forbidden = [
        'Ear Training',
        'Rhythm Hero',
        'Guitar Hero',
        'Perfect Ear',
      ];
      for (final unit in units) {
        expect(unit.bab, isNotEmpty);
        for (final term in forbidden) {
          expect(jsonEncode(unit.toJson()), isNot(contains(term)));
        }
        for (final bab in unit.bab) {
          expect(bab.judul, isNotEmpty);
          expect(bab.tujuan, isNotEmpty);
          expect(bab.latihan, isNotEmpty);
          for (final latihan in bab.latihan) {
            expect(latihan.soal, isNotEmpty);
            for (final soal in latihan.soal) {
              expect(soal.prompt, isNotEmpty);
              expect(soal.kunciJawaban, isNotEmpty);
              if (latihan.konfigLoop.modeInput == ModeInput.pilihOpsi) {
                expect(soal.pilihan, isNotEmpty);
              }
            }
          }
        }
      }
    },
  );

  test('Feature: titilaras-sunda: konten latihan cukup dan ritme nonaktif', () {
    final allExercises = units
        .expand((unit) => unit.bab)
        .expand((bab) => bab.latihan);
    final totalQuestions = allExercises.fold<int>(
      0,
      (total, latihan) => total + latihan.soal.length,
    );
    expect(totalQuestions, greaterThanOrEqualTo(115));
    expect(
      allExercises.map((latihan) => latihan.jenis),
      isNot(contains(JenisLatihan.ketukIrama)),
    );
    for (final bab in units.expand((unit) => unit.bab)) {
      expect(bab.prasyaratBabId, isEmpty);
    }
  });

  test(
    'Feature: titilaras-sunda: aset audio FLAC tersedia untuk semua nada konten',
    () {
      final audioFiles = Directory('assets/audio')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toSet();

      String instrumenUntuk(int octave) {
        if (octave <= -1) return 'demung';
        if (octave >= 1) return 'peking';
        return 'saron';
      }

      void expectToneAsset(Tona tone) {
        final instrumen = instrumenUntuk(tone.oktafRelatif);
        for (final artikulasi in ['muka', 'tengkep']) {
          final name = '${instrumen}_${artikulasi}_${tone.angka}.flac';
          expect(
            audioFiles,
            contains(name),
            reason: 'Sample $name tidak ada untuk oktaf ${tone.oktafRelatif}',
          );
        }
      }

      for (final unit in units) {
        for (final bab in unit.bab) {
          for (final latihan in bab.latihan) {
            for (final soal in latihan.soal) {
              final stimulus = soal.stimulus;
              switch (stimulus.jenis) {
                case JenisStimulus.tona:
                  expectToneAsset(stimulus.tona!);
                case JenisStimulus.urutanTona:
                  for (final tone in stimulus.urutanTona) {
                    expectToneAsset(tone);
                  }
                case JenisStimulus.laras:
                  final profile = profiles.firstWhere(
                    (item) => item.laras == stimulus.laras,
                  );
                  for (final tone in profile.tangga(ArahTangga.menurun)) {
                    expectToneAsset(tone);
                  }
                case JenisStimulus.polaIrama:
                  fail('Latihan ritme belum diaktifkan untuk versi ini.');
              }
            }
          }
        }
      }
    },
  );

  test(
    'Feature: titilaras-sunda, Property 11: frekuensi diturunkan dari cents profil',
    () {
      final salendro = profiles.firstWhere(
        (profile) => profile.id == 'salendro',
      );
      final tugu = frekuensiTona(const Tona(angka: 1), salendro);
      expect(
        tugu,
        closeTo(salendro.frekuensiNadaDasarHz * math.pow(2, 947 / 1200), 0.01),
      );
      final low = frekuensiTona(
        const Tona(angka: 1, oktafRelatif: -1),
        salendro,
      );
      final high = frekuensiTona(
        const Tona(angka: 1, oktafRelatif: 1),
        salendro,
      );
      expect(low, closeTo(tugu / 2, 0.001));
      expect(high, closeTo(tugu * 2, 0.001));
    },
  );

  test('Feature: titilaras-sunda: titik oktaf mengikuti notasi Sunda', () {
    // Oktaf rendah: titik di atas angka.
    expect(const Tona(angka: 2, oktafRelatif: -1).notasiAngka, '.\n2');
    // Oktaf tinggi: titik di bawah angka.
    expect(const Tona(angka: 2, oktafRelatif: 1).notasiAngka, '2\n.');
  });

  Glados<int>().test(
    'Feature: titilaras-sunda, Property 12: offset cents mengalikan frekuensi semua tona',
    (input) {
      final profile = profiles.firstWhere((item) => item.id == 'salendro');
      final cents = (input % 401) - 200.0;
      final base = frekuensiTona(const Tona(angka: 2), profile);
      final shifted = frekuensiTona(
        const Tona(angka: 2),
        profile,
        offsetCents: cents,
      );
      expect(shifted, closeTo(base * math.pow(2, cents / 1200), 0.0001));
    },
  );

  test(
    'Feature: titilaras-sunda, Property 14: pitch target dipetakan ke tona terdekat',
    () {
      final profile = profiles.firstWhere((item) => item.id == 'salendro');
      final target = frekuensiTona(const Tona(angka: 3), profile);
      final result = petakanPitchKeTona(target, profile, 50);
      expect(result.tepat, isTrue);
      expect(result.tonaTerdekat, const Tona(angka: 3));
    },
  );

  test('Feature: titilaras-sunda: NSDF mengenali nada salendro lintas oktaf '
      'dalam rentang vokal', () {
    final salendro = profiles.firstWhere((item) => item.id == 'salendro');
    const sr = 44100;
    const window = 2048;
    List<double> nadaSintetis(double hz) => [
      for (var i = 0; i < window; i++)
        math.sin(2 * math.pi * hz * i / sr) +
            0.4 * math.sin(2 * math.pi * 2 * hz * i / sr) +
            0.2 * math.sin(2 * math.pi * 3 * hz * i / sr),
    ];

    var diuji = 0;
    for (final oktaf in [-1, 0, 1]) {
      for (final entry in salendro.tonaTengah) {
        final hz = frekuensiTona(
          Tona(angka: entry.angka, oktafRelatif: oktaf),
          salendro,
        );
        if (hz < 70 || hz > 700) continue; // di luar rentang deteksi vokal
        final estimasi = estimasiPitchAutokorelasi(nadaSintetis(hz), sr);
        expect(estimasi, isNotNull, reason: 'gagal deteksi $hz Hz');
        // frekuensi terdeteksi harus dekat (< 15 cents)
        expect(
          (1200 * math.log(estimasi! / hz) / math.ln2).abs(),
          lessThan(15),
          reason: 'estimasi $estimasi Hz untuk $hz Hz',
        );
        final hasil = petakanPitchKeTona(estimasi, salendro, 50);
        expect(
          hasil.tepat,
          isTrue,
          reason: 'angka ${entry.angka} oktaf $oktaf ($hz Hz) tidak tepat',
        );
        expect(hasil.tonaTerdekat!.angka, entry.angka);
        diuji++;
      }
    }
    expect(diuji, greaterThanOrEqualTo(6));
  });

  test('Feature: titilaras-sunda: deteksi pitch menolak senyap', () {
    final salendro = profiles.firstWhere((item) => item.id == 'salendro');
    final senyap = List<double>.filled(2048, 0);
    expect(estimasiPitchAutokorelasi(senyap, 44100), isNull);
    expect(
      petakanPitchKeTona(null, salendro, 50).pesan,
      'Suara belum terdeteksi',
    );
  });

  test(
    'Feature: titilaras-sunda, Property 26: parser memuat konten valid dan mencatat yang rusak',
    () {
      final valid = jsonEncode(units.first.toJson());
      final result = parseKontenJsonFiles({
        'valid.json': valid,
        'rusak.json': '{',
      });
      expect(result.data.length, 1);
      expect(result.kesalahan.single.namaBerkas, 'rusak.json');
    },
  );

  test('Feature: titilaras-sunda: pengaturan tahan data rusak', () {
    final settings = Pengaturan.fromJson({
      'toleransiCents': 9999,
      'modeNotasi': 'solfeg',
    });
    expect(settings.toleransiCents, Pengaturan.bawaan().toleransiCents);

    final progress = ProgresPengguna.kosong(rusak: true);
    expect(progress.game, isEmpty);
    expect(progress.tidakDapatDipulihkan, isTrue);
  });

  test('Feature: titilaras-sunda: statistik game tersimpan & round-trip', () {
    var progres = const ProgresPengguna();
    progres = progres.catatRonde(
      'tebak_melodi',
      level: 3,
      streak: 2,
      missStreak: 0,
      skor: 100,
      benar: true,
      waktu: DateTime(2026, 7, 3),
    );
    progres = progres.catatRonde(
      'tebak_melodi',
      level: 2,
      streak: 0,
      missStreak: 1,
      skor: 40,
      benar: false,
      waktu: DateTime(2026, 7, 3),
    );
    final stat = progres.game['tebak_melodi']!;
    expect(stat.levelTertinggi, 3);
    expect(stat.streakTerbaik, 2);
    expect(stat.levelAktif, 2);
    expect(stat.missStreakAktif, 1);
    expect(stat.totalRonde, 2);
    expect(stat.totalBenar, 1);
    expect(stat.rataRataSkor, 70);
    expect(stat.akurasiPersen, 50);
    expect(progres.totalRonde, 2);
    final roundTrip = ProgresPengguna.fromJson(progres.toJson());
    expect(roundTrip.game['tebak_melodi']!.levelTertinggi, 3);
    expect(roundTrip.game['tebak_melodi']!.levelAktif, 2);
  });

  test('Feature: titilaras-sunda: level adaptif naik setelah 5 streak', () {
    const policy = AdaptivePolicy(minLevel: 1, maxLevel: 5);
    var state = const AdaptiveState(level: 1, streak: 0, missStreak: 0);

    for (var i = 0; i < 4; i++) {
      state = policy.apply(
        level: state.level,
        streak: state.streak,
        missStreak: state.missStreak,
        score: 100,
        adaptif: true,
      );
      expect(state.level, 1);
    }

    state = policy.apply(
      level: state.level,
      streak: state.streak,
      missStreak: state.missStreak,
      score: 100,
      adaptif: true,
    );

    expect(state.level, 2);
    expect(state.streak, 0);
  });

  test('Feature: titilaras-sunda: level adaptif turun setelah 2 miss', () {
    const policy = AdaptivePolicy(minLevel: 1, maxLevel: 5);
    var state = const AdaptiveState(level: 3, streak: 0, missStreak: 0);

    state = policy.apply(
      level: state.level,
      streak: state.streak,
      missStreak: state.missStreak,
      score: 0,
      adaptif: true,
    );
    expect(state.level, 3);

    state = policy.apply(
      level: state.level,
      streak: state.streak,
      missStreak: state.missStreak,
      score: 0,
      adaptif: true,
    );

    expect(state.level, 2);
    expect(state.missStreak, 0);
  });
}

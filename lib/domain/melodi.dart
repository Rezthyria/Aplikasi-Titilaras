import 'dart:math';

import 'models.dart';

/// Konfigurasi tingkat kesulitan untuk generator melodi.
class KesulitanMelodi {
  final int level;
  final int jumlahBirama;
  final bool pakaiIstirahat;
  final bool pakaiSeperdelapan;
  final bool pakaiSeperdelapanRapat;
  final bool pakaiTitik;
  final int maxLompatan;
  final List<int> oktaf;

  const KesulitanMelodi({
    required this.level,
    required this.jumlahBirama,
    required this.pakaiIstirahat,
    required this.pakaiSeperdelapan,
    required this.pakaiSeperdelapanRapat,
    required this.pakaiTitik,
    required this.maxLompatan,
    required this.oktaf,
  });

  static const int levelMaks = 5;

  static KesulitanMelodi untukLevel(int level) {
    final l = level.clamp(1, levelMaks);
    return switch (l) {
      1 => const KesulitanMelodi(
        level: 1,
        jumlahBirama: 1,
        pakaiIstirahat: false,
        pakaiSeperdelapan: false,
        pakaiSeperdelapanRapat: false,
        pakaiTitik: false,
        maxLompatan: 1,
        oktaf: [0],
      ),
      2 => const KesulitanMelodi(
        level: 2,
        jumlahBirama: 1,
        pakaiIstirahat: true,
        pakaiSeperdelapan: false,
        pakaiSeperdelapanRapat: false,
        pakaiTitik: false,
        maxLompatan: 2,
        oktaf: [0],
      ),
      3 => const KesulitanMelodi(
        level: 3,
        jumlahBirama: 1,
        pakaiIstirahat: true,
        pakaiSeperdelapan: true,
        pakaiSeperdelapanRapat: false,
        pakaiTitik: false,
        maxLompatan: 2,
        oktaf: [0],
      ),
      4 => const KesulitanMelodi(
        level: 4,
        jumlahBirama: 2,
        pakaiIstirahat: true,
        pakaiSeperdelapan: true,
        pakaiSeperdelapanRapat: true,
        pakaiTitik: false,
        maxLompatan: 3,
        oktaf: [0, -1, 1],
      ),
      _ => const KesulitanMelodi(
        level: 5,
        jumlahBirama: 2,
        pakaiIstirahat: true,
        pakaiSeperdelapan: true,
        pakaiSeperdelapanRapat: true,
        pakaiTitik: true,
        maxLompatan: 4,
        oktaf: [0, -1, 1],
      ),
    };
  }
}

/// Token ritme penyusun satu birama (4 ketuk).
enum _Token { seperempat, seperdelapan, istirahat, titik }

/// Generator melodi salendro (angka 1..5) + ritme, terparametrik kesulitan.
/// Setiap birama berdurasi 4 ketuk.
class GeneratorMelodi {
  final Random _r;

  GeneratorMelodi([Random? random]) : _r = random ?? Random();

  // Template birama (masing-masing total 4 ketuk).
  static const _q = _Token.seperempat;
  static const _e = _Token.seperdelapan;
  static const _r0 = _Token.istirahat;
  static const _d = _Token.titik;

  static const List<List<_Token>> _dasar = [
    [_q, _q, _q, _q],
  ];
  static const List<List<_Token>> _istirahat = [
    [_q, _q, _q, _r0],
    [_r0, _q, _q, _q],
    [_q, _r0, _q, _q],
  ];
  static const List<List<_Token>> _delapan = [
    [_e, _e, _q, _q, _q],
    [_q, _e, _e, _q, _q],
    [_q, _q, _e, _e, _q],
    [_q, _q, _q, _e, _e],
  ];
  static const List<List<_Token>> _delapanRapat = [
    [_e, _e, _e, _e, _q, _q],
    [_q, _q, _e, _e, _e, _e],
    [_e, _e, _q, _e, _e, _q],
  ];
  static const List<List<_Token>> _titik = [
    [_q, _d, _e, _q, _q],
    [_q, _q, _q, _d, _e],
    [_q, _q, _d, _e, _q],
  ];

  List<List<_Token>> _poolUntuk(KesulitanMelodi k) {
    final pool = <List<_Token>>[..._dasar];
    if (k.pakaiIstirahat) pool.addAll(_istirahat);
    if (k.pakaiSeperdelapan) pool.addAll(_delapan);
    if (k.pakaiSeperdelapanRapat) pool.addAll(_delapanRapat);
    if (k.pakaiTitik) pool.addAll(_titik);
    return pool;
  }

  List<SimbolNot> buat(KesulitanMelodi k) {
    final pool = _poolUntuk(k);
    final simbol = <SimbolNot>[];
    var derajat = _r.nextInt(5) + 1; // 1..5
    for (var b = 0; b < k.jumlahBirama; b++) {
      final template = pool[_r.nextInt(pool.length)];
      for (final token in template) {
        switch (token) {
          case _Token.seperempat:
            derajat = _derajatBerikut(derajat, k.maxLompatan);
            simbol.add(SimbolNot.nada(derajat, oktafRelatif: _oktaf(k)));
          case _Token.seperdelapan:
            derajat = _derajatBerikut(derajat, k.maxLompatan);
            simbol.add(
              SimbolNot.nada(derajat, oktafRelatif: _oktaf(k), beam: 1),
            );
          case _Token.istirahat:
            simbol.add(const SimbolNot.istirahat());
          case _Token.titik:
            simbol.add(const SimbolNot.perpanjangan());
        }
      }
    }
    return simbol;
  }

  int _derajatBerikut(int sekarang, int maxLompatan) {
    final lompatan = _r.nextInt(maxLompatan * 2 + 1) - maxLompatan;
    final next = (sekarang + lompatan).clamp(1, 5);
    if (next == sekarang && maxLompatan > 0) {
      // hindari nada kembar terlalu sering
      return (sekarang == 5 ? 4 : sekarang + 1);
    }
    return next;
  }

  int _oktaf(KesulitanMelodi k) {
    if (k.oktaf.length == 1) return k.oktaf.first;
    // mayoritas oktaf tengah
    if (_r.nextInt(100) < 70) return 0;
    return k.oktaf[_r.nextInt(k.oktaf.length)];
  }
}

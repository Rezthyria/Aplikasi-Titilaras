import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models.dart';

class KesalahanParsing {
  final String namaBerkas;
  final String pesan;

  const KesalahanParsing({required this.namaBerkas, required this.pesan});
}

class HasilMuat<T> {
  final List<T> data;
  final List<KesalahanParsing> kesalahan;

  const HasilMuat({required this.data, required this.kesalahan});
}

class AssetJsonRepository {
  Future<HasilMuat<ProfilTuning>> muatProfilTuning() async {
    final maps = await _loadMaps('assets/tuning/');
    return HasilMuat(
      data: [for (final item in maps.data) ProfilTuning.fromJson(item)],
      kesalahan: maps.kesalahan,
    );
  }

  Future<HasilMuat<UnitBelajar>> muatKonten() async {
    final maps = await _loadMaps('assets/content/');
    final units = <UnitBelajar>[];
    final errors = [...maps.kesalahan];
    for (final item in maps.data) {
      try {
        units.add(UnitBelajar.fromJson(item));
      } catch (error) {
        errors.add(
          KesalahanParsing(
            namaBerkas: (item['id'] ?? 'konten_tanpa_id').toString(),
            pesan: error.toString(),
          ),
        );
      }
    }
    return HasilMuat(data: units, kesalahan: errors);
  }

  Future<HasilMuat<Map<String, Object?>>> _loadMaps(String prefix) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final files =
        manifest
            .listAssets()
            .where((key) => key.startsWith(prefix) && key.endsWith('.json'))
            .toList()
          ..sort();
    final data = <Map<String, Object?>>[];
    final errors = <KesalahanParsing>[];
    for (final file in files) {
      try {
        final raw = await rootBundle.loadString(file);
        data.add(Map<String, Object?>.from(jsonDecode(raw) as Map));
      } catch (error) {
        errors.add(KesalahanParsing(namaBerkas: file, pesan: error.toString()));
      }
    }
    return HasilMuat(data: data, kesalahan: errors);
  }
}

HasilMuat<UnitBelajar> parseKontenJsonFiles(Map<String, String> files) {
  final units = <UnitBelajar>[];
  final errors = <KesalahanParsing>[];
  for (final entry in files.entries) {
    try {
      units.add(
        UnitBelajar.fromJson(
          Map<String, Object?>.from(jsonDecode(entry.value) as Map),
        ),
      );
    } catch (error) {
      errors.add(
        KesalahanParsing(namaBerkas: entry.key, pesan: error.toString()),
      );
    }
  }
  return HasilMuat(data: units, kesalahan: errors);
}

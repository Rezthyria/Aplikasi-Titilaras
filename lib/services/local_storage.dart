import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import '../domain/services.dart';

class LocalStorageService implements StoragePort {
  static const _settingsKey = 'pengaturan';
  static const _progressFile = 'progres_titilaras.json';

  @override
  Future<Pengaturan> muatPengaturan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw == null) return Pengaturan.bawaan();
      return Pengaturan.fromJsonString(raw);
    } catch (_) {
      return Pengaturan.bawaan();
    }
  }

  @override
  Future<void> simpanPengaturan(Pengaturan pengaturan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(pengaturan.toJson()));
  }

  @override
  Future<ProgresPengguna> muatProgres() async {
    try {
      final file = await _file();
      if (!await file.exists()) return ProgresPengguna.kosong();
      final raw = await file.readAsString();
      return ProgresPengguna.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return ProgresPengguna.kosong(rusak: true);
    }
  }

  @override
  Future<void> simpanProgres(ProgresPengguna progres) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(progres.toJson()));
  }

  @override
  Future<void> resetProgres() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_progressFile');
  }
}

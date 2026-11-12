import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../domain/logic.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class RecordPitchService implements PitchPort {
  AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  StreamController<HasilPitch>? _controller;
  Timer? _watchdog;
  DateTime? _lastChunkAt;
  int _restartAttempts = 0;
  bool _stopping = false;
  bool _izin = false;
  final List<double> _buffer = [];

  static const int _sampleRate = 44100;
  // ~46 ms window: cukup untuk >=2 periode nada terendah (70 Hz) dan responsif.
  static const int _windowSize = 2048;

  @override
  bool get izinDiberikan => _izin;

  @override
  Future<bool> mintaIzinMikrofon() async {
    final status = await Permission.microphone.request();
    _izin = status.isGranted;
    return _izin;
  }

  @override
  Stream<HasilPitch> mulaiDeteksi(ProfilTuning profil, double toleransiCents) {
    _restartAttempts = 0;
    final controller = StreamController<HasilPitch>.broadcast(
      onCancel: () {
        unawaited(hentikanDeteksi());
      },
    );
    _controller = controller;
    unawaited(_restart(profil, toleransiCents, controller));
    return controller.stream;
  }

  Future<void> _restart(
    ProfilTuning profil,
    double toleransiCents,
    StreamController<HasilPitch> controller,
  ) async {
    await _stopNativeRecorder();
    if (_controller != controller || controller.isClosed) return;
    if (!_izin) {
      controller.add(
        const HasilPitch(
          frekuensiHz: null,
          tonaTerdekat: null,
          selisihCents: null,
          tepat: false,
          pesan: 'Mikrofon belum aktif',
        ),
      );
      return;
    }
    try {
      _buffer.clear();
      _lastChunkAt = DateTime.now();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      _sub = stream.listen(
        (chunk) {
          if (_controller != controller || controller.isClosed) return;
          _lastChunkAt = DateTime.now();
          _restartAttempts = 0;
          _buffer.addAll(_pcm16ToDoubles(chunk));
          if (_buffer.length < _windowSize) return;
          // Jaga buffer tetap ramping; analisis window terbaru.
          if (_buffer.length > _windowSize * 2) {
            _buffer.removeRange(0, _buffer.length - _windowSize * 2);
          }
          final window = _buffer.sublist(_buffer.length - _windowSize);
          final hz = estimasiPitchAutokorelasi(window, _sampleRate);
          controller.add(petakanPitchKeTona(hz, profil, toleransiCents));
        },
        onError: (Object error) {
          if (!controller.isClosed) {
            controller.add(
              HasilPitch(
                frekuensiHz: null,
                tonaTerdekat: null,
                selisihCents: null,
                tepat: false,
                pesan: 'Mikrofon tersambung ulang',
              ),
            );
            unawaited(_restartAfterStall(profil, toleransiCents, controller));
          }
        },
      );
      _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
        final last = _lastChunkAt;
        if (last == null || _controller != controller || controller.isClosed) {
          return;
        }
        final age = DateTime.now().difference(last);
        if (age > const Duration(seconds: 3)) {
          unawaited(_restartAfterStall(profil, toleransiCents, controller));
        }
      });
    } catch (error) {
      if (controller.isClosed) return;
      controller.add(
        HasilPitch(
          frekuensiHz: null,
          tonaTerdekat: null,
          selisihCents: null,
          tepat: false,
          pesan: 'Mikrofon belum siap',
        ),
      );
      unawaited(_restartAfterStall(profil, toleransiCents, controller));
    }
  }

  Future<void> _restartAfterStall(
    ProfilTuning profil,
    double toleransiCents,
    StreamController<HasilPitch> controller,
  ) async {
    if (_restartAttempts >= 2 ||
        _controller != controller ||
        controller.isClosed) {
      return;
    }
    _restartAttempts += 1;
    await _resetRecorderInstance();
    if (_controller == controller && !controller.isClosed) {
      await _restart(profil, toleransiCents, controller);
    }
  }

  Future<void> _resetRecorderInstance() async {
    await _stopNativeRecorder();
    try {
      await _recorder.dispose();
    } catch (_) {
      // Jika native recorder sudah lepas, lanjut buat instance baru.
    }
    _recorder = AudioRecorder();
  }

  List<double> _pcm16ToDoubles(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    final result = <double>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      result.add(view.getInt16(i, Endian.little) / 32768.0);
    }
    return result;
  }

  @override
  Future<void> hentikanDeteksi() async {
    final controller = _controller;
    _controller = null;
    await _stopNativeRecorder();
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  Future<void> _stopNativeRecorder() async {
    if (_stopping) return;
    _stopping = true;
    _watchdog?.cancel();
    _watchdog = null;
    _lastChunkAt = null;
    await _sub?.cancel();
    _sub = null;
    _buffer.clear();
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      // Recorder plugin kadang melempar saat stream sudah berhenti di sisi native.
    } finally {
      _stopping = false;
    }
  }
}

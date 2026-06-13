import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LoggerImpl {
  LoggerImpl([this.filename]) {
    _initialize();
  }

  final String? filename;
  IOSink? _sink;
  bool _isReady = false;

  Future<void> _initialize() async {
    try {
      final dir = await getApplicationSupportDirectory();

      final logFilename = filename == null ? 'app.log' : 'app_$filename.log';
      final file = File('${dir.path}/$logFilename');
      _sink = file.openWrite(mode: FileMode.append);

      _isReady = true;
    } catch (_) {
      _sink = null;
      _isReady = false;
    }
  }

  void log(String message) {
    if (!_isReady) {
      return;
    }

    _sink?.writeln('${DateTime.now().toIso8601String()} $message');
  }

  Future<void> flush() async {
    if (!_isReady) {
      return;
    }

    await _sink?.flush();
  }

  Future<void> dispose() async {
    if (!_isReady) {
      return;
    }

    await flush();
    await _sink?.close();
    _sink = null;
    _isReady = false;
  }
}

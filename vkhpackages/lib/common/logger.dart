import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:vkhpackages/common/utils.dart';

class LogEntry {
  final DateTime timestamp;
  final String? level;
  final String? tag;
  final String message;

  LogEntry({
    required this.timestamp,
    this.level,
    this.tag,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': Utils().convertTimestampToDbKey(timestamp),
    'level': level ?? "INFO",
    'tag': tag ?? "",
    'message': message,
  };

  factory LogEntry.fromJson(String id, Map<String, dynamic> json) {
    return LogEntry(
      timestamp: Utils().convertDbKeyToTimestamp(json['timestamp']),
      level: json['level'] ?? "INFO",
      tag: json['tag'] ?? "",
      message: json['message'],
    );
  }
}

class Logger {
  // Private named constructor
  Logger._internal() {
    // Initialization logic here
  }

  static final Logger _instance = Logger._internal();

  factory Logger() => _instance;

  late Database _db;
  final _store = intMapStoreFactory.store('logs');

  Future<void> init(String app) async {
    if (kIsWeb) {
      _db = await databaseFactoryWeb.openDatabase('$app.log');
    } else {
      final dir = await getApplicationDocumentsDirectory();

      final dbPath = join(dir.path, '$app.log.db');

      _db = await databaseFactoryIo.openDatabase(dbPath);
    }
  }

  Future<void> _log({
    required String level,
    String tag = "",
    required String msg,
  }) async {
    DateTime timestamp = DateTime.now();
    int id = timestamp.microsecondsSinceEpoch;

    final entry = LogEntry(timestamp: timestamp, tag: tag, message: msg);

    await _store.record(id).put(_db, entry.toJson());
  }

  Future<void> info({String tag = "", required String msg}) async {
    await _log(level: "INFO", tag: tag, msg: msg);
  }

  Future<void> warning({String tag = "", required String msg}) async {
    await _log(level: "WARNING", tag: tag, msg: msg);
  }

  Future<void> error({String tag = "", required String msg}) async {
    await _log(level: "ERROR", tag: tag, msg: msg);
  }
}

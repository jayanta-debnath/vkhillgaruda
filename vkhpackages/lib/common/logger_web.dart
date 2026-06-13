import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class LoggerImpl {
  LoggerImpl([this.filename]) {
    _initialize();
  }

  static const String _databaseName = 'vkh_logger';
  static const String _storeName = 'logs';
  static const int _databaseVersion = 1;

  final String? filename;
  web.IDBDatabase? _database;
  final List<Future<void>> _pendingWrites = [];
  bool _isReady = false;

  Future<void> _initialize() async {
    try {
      final request = web.window.indexedDB.open(
        _databaseName,
        _databaseVersion,
      );

      request.onupgradeneeded =
          ((web.Event _) {
            final database = request.result as web.IDBDatabase;
            if (!database.objectStoreNames.contains(_storeName)) {
              database.createObjectStore(
                _storeName,
                web.IDBObjectStoreParameters(
                  keyPath: 'id'.toJS,
                  autoIncrement: true,
                ),
              );
            }
          }).toJS;

      await _waitForRequest(request);

      _database = request.result as web.IDBDatabase;
      _isReady = true;
    } catch (_) {
      _database = null;
      _isReady = false;
    }
  }

  void log(String message) {
    if (!_isReady) {
      return;
    }

    final pendingWrite = _write(message);
    _pendingWrites.add(pendingWrite);
    unawaited(
      pendingWrite.whenComplete(() {
        _pendingWrites.remove(pendingWrite);
      }),
    );
  }

  Future<void> _write(String message) async {
    final database = _database;
    if (!_isReady || database == null) {
      return;
    }

    try {
      final transaction = database.transaction(_storeName.toJS, 'readwrite');
      final store = transaction.objectStore(_storeName);
      store.add(
        {
          'filename': filename ?? 'app',
          'timestamp': DateTime.now().toIso8601String(),
          'message': message,
        }.jsify(),
      );

      await _waitForTransaction(transaction);
    } catch (_) {
      _isReady = false;
    }
  }

  Future<void> flush() async {
    if (!_isReady) {
      return;
    }

    await Future.wait(_pendingWrites.toList());
  }

  Future<void> dispose() async {
    if (!_isReady) {
      return;
    }

    await flush();
    _database?.close();
    _database = null;
    _isReady = false;
  }

  Future<void> _waitForRequest(web.IDBRequest request) {
    final completer = Completer<void>();

    late JSFunction successListener;
    late JSFunction errorListener;

    void finish([Object? error]) {
      request.removeEventListener('success', successListener);
      request.removeEventListener('error', errorListener);
      if (completer.isCompleted) {
        return;
      }
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    }

    successListener =
        ((web.Event _) {
          finish();
        }).toJS;
    errorListener =
        ((web.Event _) {
          finish(request.error?.message ?? 'IndexedDB request failed');
        }).toJS;

    request.addEventListener('success', successListener);
    request.addEventListener('error', errorListener);

    return completer.future;
  }

  Future<void> _waitForTransaction(web.IDBTransaction transaction) {
    final completer = Completer<void>();

    late JSFunction completeListener;
    late JSFunction abortListener;
    late JSFunction errorListener;

    void finish([Object? error]) {
      transaction.removeEventListener('complete', completeListener);
      transaction.removeEventListener('abort', abortListener);
      transaction.removeEventListener('error', errorListener);
      if (completer.isCompleted) {
        return;
      }
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    }

    completeListener =
        ((web.Event _) {
          finish();
        }).toJS;
    abortListener =
        ((web.Event _) {
          finish(transaction.error?.message ?? 'IndexedDB transaction aborted');
        }).toJS;
    errorListener =
        ((web.Event _) {
          finish(transaction.error?.message ?? 'IndexedDB transaction failed');
        }).toJS;

    transaction.addEventListener('complete', completeListener);
    transaction.addEventListener('abort', abortListener);
    transaction.addEventListener('error', errorListener);

    return completer.future;
  }
}

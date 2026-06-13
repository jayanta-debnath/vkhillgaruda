import 'logger_stub.dart'
    if (dart.library.io) 'logger_io.dart'
    if (dart.library.js_interop) 'logger_web.dart';

class Logger extends LoggerImpl {
  Logger([super.filename]);
}

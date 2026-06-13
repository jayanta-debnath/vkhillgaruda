class LoggerImpl {
  LoggerImpl([this.filename]);

  final String? filename;

  void log(String message) {}

  Future<void> flush() async {}

  Future<void> dispose() async {}
}

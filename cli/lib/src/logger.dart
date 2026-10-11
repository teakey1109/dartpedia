import 'dart:io';
import 'package:logging/logging.dart';

Logger initFileLogger(String name) {
  hierarchicalLoggingEnabled = true;

  final logger = Logger(name);
  final now = DateTime.now();

  final scriptFile = File(Platform.script.toFilePath());
  final projectDir = scriptFile.parent.parent.path;

  final dir = Directory('$projectDir/logs');
  if (!dir.existsSync()) {
    dir.createSync();
  }

  final logFile = File(
    '${dir.path}/${now.year}_${now.month}_${now.day}_$name.txt',
  );

  logger.level = Level.ALL;

  logger.onRecord.listen((record) {
    final msg = '[${record.time} - ${record.loggerName}] ${record.level.name}: ${record.message}';
    logFile.writeAsStringSync('$msg\n', mode: FileMode.append);
  });

  return logger;
}
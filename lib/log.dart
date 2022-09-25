import 'package:intl/intl.dart';
import 'dart:developer' as dev;

class Log {
  static List<String> lines = [];
  static String get() {
    return lines.join("\n");
  }
}

void log(String arg) {
  dev.log(arg);
  final DateFormat format = DateFormat("hh:mm:ss.SSS");
  final String line = format.format(DateTime.now()) + " : " + arg;
  Log.lines.add(line);
}

void logError(String arg) {
  log("Error : " + arg);
}

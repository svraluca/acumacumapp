import 'package:logger/logger.dart';

class CustomLogger extends LogPrinter {
  final String className;

  CustomLogger({required this.className});
  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.defaultLevelColors[event.level]!;
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    return [color('$emoji $className - ${event.message}')];
  }
}

Logger getLogger(String className) => Logger(printer: CustomLogger(className: className));

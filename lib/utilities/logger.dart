import 'package:logger/logger.dart';

final logger = Logger(printer: ErmisPrinter());

class ErmisPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    return [event.message];
  }

}
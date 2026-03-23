import 'package:args/command_runner.dart';

class TranslateCommand extends Command {
  TranslateCommand() {
    argParser.addOption(
      "target",
      abbr: "t",
      help: "Path to the Dart file to translate",
      mandatory: true,
    );
  }

  @override
  String get description => "Translate Dart to Luau";

  @override
  String get name => "translate";

  @override
  void run() {
    print("Si funciono");
  }
}

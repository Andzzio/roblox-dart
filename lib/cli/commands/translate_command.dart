import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:roblox_dart/compiler/roblox_compiler.dart';

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
  Future<void> run() async {
    print("Starting...");
    final String? targetPath = argResults?["target"];

    if (targetPath == null) {
      print("Error: Not target file provided");
      return;
    }

    if (!targetPath.endsWith(".dart")) {
      print("Error: Target file must be a .dart file");
      return;
    }

    final file = File(targetPath);
    final bool fileExists = await file.exists();

    if (!fileExists) {
      print("File not Found");
      return;
    }

    await RobloxCompiler().compileFile(file);

    print("Translated!");
  }
}

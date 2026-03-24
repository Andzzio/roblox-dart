import 'package:args/command_runner.dart';
import 'package:roblox_dart/cli/command_manager.dart';

void main(List<String> arguments) {
  final runner = CommandRunner("roblox-dart", "Transpiler Dart to Luau Roblox");
  CommandManager(runner: runner)
    ..setupCommands()
    ..run(arguments);
}

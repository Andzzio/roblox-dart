import 'package:args/command_runner.dart';
import 'package:roblox_dart/cli/commands/init_command.dart';
import 'package:roblox_dart/cli/commands/translate_command.dart';
import 'package:roblox_dart/cli/commands/watch_command.dart';

class CommandManager {
  final CommandRunner runner;
  CommandManager({required this.runner});

  void setupCommands() {
    runner.addCommand(TranslateCommand());
    runner.addCommand(InitCommand());
    runner.addCommand(WatchCommand());
  }

  Future<void> run(List<String> args) async {
    await runner.run(args);
  }
}

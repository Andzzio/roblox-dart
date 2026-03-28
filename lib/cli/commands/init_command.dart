import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

class InitCommand extends Command {
  @override
  String get name => 'init';

  @override
  String get description => 'Creates a new roblox-dart project structure';

  @override
  Future<void> run() async {
    final cwd = Directory.current.path;
    final projectName = p.basename(cwd);

    for (final dir in [
      'src/server',
      'src/client',
      'src/shared',
      'out/include',
    ]) {
      Directory(p.join(cwd, dir)).createSync(recursive: true);
    }

    File(p.join(cwd, 'default.project.json')).writeAsStringSync(
      '{\n'
      '  "name": "$projectName",\n'
      '  "tree": {\n'
      '    "\$className": "DataModel",\n'
      '    "ServerScriptService": {\n'
      '      "\$className": "ServerScriptService",\n'
      '      "\$path": "out/server"\n'
      '    },\n'
      '    "StarterPlayer": {\n'
      '      "\$className": "StarterPlayer",\n'
      '      "StarterPlayerScripts": {\n'
      '        "\$className": "StarterPlayerScripts",\n'
      '        "\$path": "out/client"\n'
      '      }\n'
      '    },\n'
      '    "ReplicatedStorage": {\n'
      '      "\$className": "ReplicatedStorage",\n'
      '      "shared": { "\$path": "out/shared" },\n'
      '      "include": { "\$path": "out/include" }\n'
      '    }\n'
      '  }\n'
      '}\n',
    );

    final robloxDartPath = _getRobloxDartPath();

    File(p.join(cwd, 'pubspec.yaml')).writeAsStringSync(
      'name: $projectName\n'
      'description: A Roblox game built with roblox-dart\n'
      'version: 1.0.0\n'
      'environment:\n'
      '  sdk: ^3.0.0\n'
      'dependencies:\n'
      '  roblox_dart:\n'
      '    path: $robloxDartPath\n',
    );

    File(p.join(cwd, '.gitignore')).writeAsStringSync(
      'out/\n'
      '.dart_tool/\n'
      'pubspec.lock\n',
    );
    File(p.join(cwd, 'src/server/main.server.dart')).writeAsStringSync(
      "import 'package:roblox_dart/services.dart' show workspace;\n"
      "\n"
      "void main() {\n"
      "  workspace.gravity = 0;\n"
      "  print(\"Hello from roblox-dart!\");\n"
      "}\n",
    );

    print('Project "$projectName" created.');

    print('Running dart pub get...');
    final result = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: cwd);
    if (result.exitCode != 0) {
      print('Warning: dart pub get failed:\n${result.stderr}');
    } else {
      print('Dependencies installed.');
    }

    print('Run "roblox-dart watch" to start compiling.');
  }

  String _getRobloxDartPath() {
    final scriptUri = Platform.script;
    final scriptPath = scriptUri.toFilePath();
    return p.normalize(p.join(p.dirname(scriptPath), '..'));
  }
}

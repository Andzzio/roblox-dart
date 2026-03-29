import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:roblox_dart/version.dart';

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

    final info = _getRobloxDartInfo();
    final robloxDartPath = info['path'];
    final robloxDartVersion = info['version'];
    final usePathDependency = !_isPubCachePath(robloxDartPath!);

    File(p.join(cwd, 'pubspec.yaml')).writeAsStringSync(
      'name: $projectName\n'
      'description: A Roblox game built with roblox-dart\n'
      'publish_to: none\n'
      'version: 1.0.0\n'
      'environment:\n'
      '  sdk: ^3.0.0\n'
      'dependencies:\n'
      '  roblox_dart: ${usePathDependency ? '\n    path: $robloxDartPath' : '^$robloxDartVersion'}\n',
    );

    File(p.join(cwd, '.gitignore')).writeAsStringSync(
      'out/\n'
      '.dart_tool/\n'
      'pubspec.lock\n',
    );

    File(p.join(cwd, 'src/shared/shared.dart')).writeAsStringSync(
      "String greet(String who) {\n"
      "  return 'Hello, \$who, from roblox-dart!';\n"
      "}\n",
    );

    File(p.join(cwd, 'src/server/main.server.dart')).writeAsStringSync(
      "import '../shared/shared.dart';\n"
      "\n"
      "void main() {\n"
      "  print(greet('server'));\n"
      "}\n",
    );

    File(p.join(cwd, 'src/client/main.client.dart')).writeAsStringSync(
      "import '../shared/shared.dart';\n"
      "\n"
      "void main() {\n"
      "  print(greet('client'));\n"
      "}\n",
    );

    print('Project "$projectName" created.');

    print('Running dart pub get...');
    final result = await Process.run(
        'dart',
        [
          'pub',
          'get',
        ],
        workingDirectory: cwd);
    if (result.exitCode != 0) {
      print('Warning: dart pub get failed:\n${result.stderr}');
    } else {
      print('Dependencies installed.');
    }

    print('Run "roblox-dart watch" to start compiling.');
  }

  Map<String, String> _getRobloxDartInfo() {
    final scriptUri = Platform.script;
    final scriptPath = scriptUri.toFilePath();

    Directory current = Directory(p.dirname(scriptPath));
    while (true) {
      final pubspecFile = File(p.join(current.path, 'pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        if (content.contains('name: roblox_dart')) {
          final versionMatch = RegExp(r'^version:\s*([^\s]+)', multiLine: true)
              .firstMatch(content);
          final version = versionMatch?.group(1) ?? packageVersion;

          return {
            'path': current.path,
            'version': version,
          };
        }
      }
      final parent = current.parent;
      if (parent.path == current.path) break;
      current = parent;
    }

    return {
      'path': p.normalize(p.join(p.dirname(scriptPath), '..')),
      'version': packageVersion,
    };
  }

  bool _isPubCachePath(String path) {
    final normalized = p.normalize(path).toLowerCase();
    return normalized.contains('pub-cache') ||
        normalized.contains(p.join('pub', 'cache').toLowerCase()) ||
        normalized.contains('global_packages');
  }
}

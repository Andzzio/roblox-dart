import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:roblox_dart/compiler/compiler_logger.dart';
import 'package:roblox_dart/compiler/roblox_compiler.dart';

class WatchCommand extends Command {
  WatchCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show debug messages.',
      negatable: false,
    );
  }

  @override
  String get name => 'watch';

  @override
  String get description => 'Watches src/ and compiles to out/ for Rojo';

  @override
  Future<void> run() async {
    CompilerLogger.verbose = argResults?['verbose'] == true;

    final cwd = Directory.current.path;
    final srcDir = Directory(p.join(cwd, 'src'));

    if (!srcDir.existsSync()) {
      print('No src/ directory found. Run "roblox-dart init" first.');
      return;
    }

    final compiler = RobloxCompiler(projectRoot: cwd, sourceRoot: srcDir.path);

    print('Building...');
    final dartFiles = srcDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      await _compile(compiler, file, cwd);
    }

    print('Build complete. Watching for changes...');

    srcDir.watch(recursive: true).listen((event) async {
      if (!event.path.endsWith('.dart')) return;

      if (event.type == FileSystemEvent.modify ||
          event.type == FileSystemEvent.create) {
        print('Changed: ${p.relative(event.path, from: cwd)}');
        await _compile(compiler, File(event.path), cwd);
      }
    });

    await Completer<void>().future;
  }

  Future<void> _compile(RobloxCompiler compiler, File file, String cwd) async {
    try {
      await compiler.compileFile(file);
      print('✓ ${p.relative(file.path, from: cwd)}');
    } catch (e) {
      print('✗ ${p.relative(file.path, from: cwd)}: $e');
    }
  }
}

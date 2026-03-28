import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:roblox_dart/compiler/roblox_compiler.dart';

void main() {
  final compiler = RobloxCompiler(projectRoot: Directory.current.path);

  group('Traducción', () {
    final dartFiles = Directory('samples')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      test(p.basename(file.path), () async {
        await expectLater(() => compiler.compileFile(file), returnsNormally);
      });
    }
  });

  const standalone = [
    'mixin_test.luau',
    'physics.luau',
    'poo_test.luau',
    'enum_test.luau',
    'static_test.luau',
    'loop_test.luau',
    'map_test.luau',
    'getter_setter_test.luau',
    'hello_roblox.luau',
    'test_fibonacci_engine.luau',
    'test_combat.luau',
    'test_builder_cascade.luau',
    'collision_test.luau',
  ];

  group('Runtime', () {
    for (final name in standalone) {
      test(name, () async {
        final result = await Process.run('luau', ['out/samples/$name']);
        expect(result.exitCode, 0, reason: result.stderr.toString());
      });
    }
  });
}

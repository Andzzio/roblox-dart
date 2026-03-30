import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:roblox_dart/compiler/roblox_compiler.dart';

void main() {
  group('ImportVisitor y RojoResolver Cross-Boundary', () {
    late Directory tempDir;
    late RobloxCompiler compiler;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('roblox_dart_test_');

      final projectJson = File(p.join(tempDir.path, 'default.project.json'));
      projectJson.writeAsStringSync('''
{
  "name": "test_project",
  "tree": {
    "\$className": "DataModel",
    "ServerScriptService": {
      "server": { "\$path": "out/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "client": { "\$path": "out/client" }
      }
    },
    "ReplicatedStorage": {
      "shared": { "\$path": "out/shared" }
    }
  }
}
      ''');

      // Importante: RojoResolver solo carga particiones si el directorio físico referenciado existe en $path
      Directory(p.join(tempDir.path, 'out', 'client'))
          .createSync(recursive: true);
      Directory(p.join(tempDir.path, 'out', 'server'))
          .createSync(recursive: true);
      Directory(p.join(tempDir.path, 'out', 'shared'))
          .createSync(recursive: true);

      // Estructura de código src
      Directory(p.join(tempDir.path, 'src', 'client'))
          .createSync(recursive: true);
      Directory(p.join(tempDir.path, 'src', 'server'))
          .createSync(recursive: true);
      Directory(p.join(tempDir.path, 'src', 'shared'))
          .createSync(recursive: true);

      // Escribir archivos de prueba
      File(p.join(tempDir.path, 'src', 'shared', 'util.dart'))
          .writeAsStringSync('''
        String helper() => 'soy shared';
      ''');

      // Cliente importando de shared
      File(p.join(tempDir.path, 'src', 'client', 'main.client.dart'))
          .writeAsStringSync('''
        import '../shared/util.dart';
        void main() { helper(); }
      ''');

      // Server importando de shared
      File(p.join(tempDir.path, 'src', 'server', 'main.server.dart'))
          .writeAsStringSync('''
        import '../shared/util.dart';
        void main() { helper(); }
      ''');

      // Cliente importando a otro cliente (Mismo Boundary)
      File(p.join(tempDir.path, 'src', 'client', 'other.client.dart'))
          .writeAsStringSync('''
        import 'main.client.dart';
      ''');

      compiler = RobloxCompiler(projectRoot: tempDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('Cliente importando Modulo Shared (Cross-Boundary)', () async {
      final clientFile =
          File(p.join(tempDir.path, 'src', 'client', 'main.client.dart'));
      await compiler.compileFile(clientFile);

      final luauOut =
          File(p.join(tempDir.path, 'src', 'client', 'main.client.luau'));
      expect(luauOut.existsSync(), isTrue);

      final content = luauOut.readAsStringSync();
      // Verificamos que ya NO hay doble require y usa absolute Game:GetService
      expect(
          content,
          contains(
              '_RD.import(game:GetService("ReplicatedStorage"), "shared", "util")'));
      expect(content, isNot(contains('require(_RD.import')));
    });

    test('Servidor importando Modulo Shared (Cross-Boundary)', () async {
      final serverFile =
          File(p.join(tempDir.path, 'src', 'server', 'main.server.dart'));
      await compiler.compileFile(serverFile);

      final luauOut =
          File(p.join(tempDir.path, 'src', 'server', 'main.server.luau'));
      expect(luauOut.existsSync(), isTrue);

      final content = luauOut.readAsStringSync();
      expect(
          content,
          contains(
              '_RD.import(game:GetService("ReplicatedStorage"), "shared", "util")'));
    });

    test('Cliente importando a otro Script Cliente (Mismo Boundary)', () async {
      final otherClientFile =
          File(p.join(tempDir.path, 'src', 'client', 'other.client.dart'));
      await compiler.compileFile(otherClientFile);

      final luauOut =
          File(p.join(tempDir.path, 'src', 'client', 'other.client.luau'));
      expect(luauOut.existsSync(), isTrue);

      final content = luauOut.readAsStringSync();
      expect(content, contains('_RD.import(script, "Parent", "main")'));
    });
  });
}

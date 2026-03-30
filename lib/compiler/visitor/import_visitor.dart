import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:roblox_dart/compiler/compiler_logger.dart';
import 'package:roblox_dart/compiler/visitor/roblox_visitor_base.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/statement/luau_variable_declaration.dart';
import 'package:roblox_dart/rojo/rojo_resolver.dart';

mixin ImportVisitor on RobloxVisitorBase {
  String _resolveImportPath(String uri) {
    if (uri.startsWith('package:') || uri.startsWith('dart:')) {
      final cleanUri = uri.split('/').last.replaceAll('.dart', '');
      return '_RD.import(script, "Parent", "$cleanUri")';
    }

    if (currentFilePath != null &&
        projectRoot != null &&
        rojoResolver != null) {
      final currentDir = p.dirname(currentFilePath!);
      final importedSrcPath = p.normalize(p.join(currentDir, uri));

      final srcRoot = p.join(projectRoot!, 'src');
      final outRoot = p.join(projectRoot!, 'out');

      String srcToOut(String srcPath) {
        final rel = p.relative(srcPath, from: srcRoot);
        return p.join(outRoot, rel.replaceAll('.dart', '.luau'));
      }

      final fromRbx =
          rojoResolver!.getRbxPathFromFilePath(srcToOut(currentFilePath!));
      final toRbx =
          rojoResolver!.getRbxPathFromFilePath(srcToOut(importedSrcPath));

      if (fromRbx != null &&
          toRbx != null &&
          fromRbx.isNotEmpty &&
          toRbx.isNotEmpty) {
        if (fromRbx.first == toRbx.first) {
          final segments = RojoResolver.relative(fromRbx, toRbx);
          final args = segments.map((s) => '"$s"').join(', ');
          return '_RD.import(script, $args)';
        } else {
          final serviceName = toRbx.first;
          final rootExpr = 'game:GetService("$serviceName")';
          final restSegments = toRbx.skip(1).toList();

          if (restSegments.isEmpty) {
            return '_RD.import($rootExpr)';
          } else {
            final args = restSegments.map((s) => '"$s"').join(', ');
            return '_RD.import($rootExpr, $args)';
          }
        }
      }
    }
    final cleanUri = uri.replaceAll(RegExp(r'\.dart$'), '');
    final parts = cleanUri.split('/');
    final args = <String>[];

    for (final part in parts) {
      if (part == '..') {
        args.add('"Parent"');
      } else if (part != '.' && part.isNotEmpty) {
        args.add('"$part"');
      }
    }

    if (args.isEmpty) {
      return 'script';
    }

    return '_RD.import(script, ${args.join(', ')})';
  }

  @override
  LuauNode? visitImportDirective(ImportDirective node) {
    CompilerLogger.debug("Visiting ImportDirective: ${node.uri.stringValue}");
    final uri = node.uri.stringValue;
    if (uri == null) return null;

    String varName;
    if (node.prefix != null) {
      varName = node.prefix!.name;
    } else {
      final segments = uri.split('/');
      final fileName = segments.last.split('.').first;
      varName = fileName;

      int counter = 1;
      String originalName = varName;
      while (importedNames.contains(varName)) {
        counter++;
        varName = "$originalName$counter";
      }
    }
    importedNames.add(varName);

    if (uri == 'package:roblox_dart/services.dart') {
      final List<String> serviceNames = [];

      final showCombinators = node.combinators.whereType<ShowCombinator>();
      if (showCombinators.isNotEmpty) {
        for (final c in showCombinators) {
          serviceNames.addAll(c.shownNames.map((n) => n.name));
        }
      } else {
        final lib = node.libraryImport?.importedLibrary;
        if (lib != null) {
          serviceNames.addAll(
            lib.exportNamespace.definedNames2.keys.where(
              (n) => !n.startsWith('_') && !n.endsWith('='),
            ),
          );
        }
      }

      final buffer = StringBuffer();
      for (final name in serviceNames) {
        final serviceName = name[0].toUpperCase() + name.substring(1);
        buffer.writeln('local $name = game:GetService("$serviceName")');
      }
      return LuauLiteral(value: buffer.toString().trim());
    }

    if (uri.startsWith('package:roblox_dart/')) {
      return null;
    }

    final luauPath = _resolveImportPath(uri);
    String output = "local $varName = $luauPath\n";

    if (node.prefix == null) {
      final libraryImportElement = node.libraryImport;
      final importedLibrary = libraryImportElement?.importedLibrary;

      if (importedLibrary != null) {
        final names = importedLibrary.exportNamespace.definedNames2.keys;

        for (var name in names) {
          if (name != varName && !name.startsWith('_') && !name.endsWith('=')) {
            output += "local $name = $varName.$name\n";
          }
        }
      } else {
        CompilerLogger.debug(
          "No se pudo resolver la librería importada para '$varName' en análisis estático.",
        );
      }
    }

    return LuauLiteral(value: output);
  }

  @override
  LuauNode? visitExportDirective(ExportDirective node) {
    CompilerLogger.debug("Visiting ExportDirective: ${node.uri.stringValue}");
    final uri = node.uri.stringValue;
    if (uri == null) return null;

    final segments = uri.split('/');
    final fileName = segments.last.split('.').first;
    String varName = fileName;

    int counter = 1;
    String originalName = varName;
    while (importedNames.contains(varName)) {
      counter++;
      varName = "$originalName$counter";
    }
    importedNames.add(varName);

    final luauPath = _resolveImportPath(uri);

    try {
      final exportElement = node.libraryExport;
      if (exportElement != null) {
        final library = exportElement.exportedLibrary;
        if (library != null) {
          final names = library.exportNamespace.definedNames2.keys;
          for (var name in names) {
            exports.add("$varName.$name");
          }
        }
      }
    } catch (e) {
      CompilerLogger.debug(
        "Fallo al extraer las variables exportadas de '$varName': $e",
      );
    }

    return LuauVariableDeclaration(
      name: varName,
      initializer: LuauLiteral(value: luauPath),
    );
  }
}

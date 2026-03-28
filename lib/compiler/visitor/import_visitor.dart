import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:roblox_dart/compiler/compiler_logger.dart';
import 'package:roblox_dart/compiler/visitor/roblox_visitor_base.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/statement/luau_variable_declaration.dart';

mixin ImportVisitor on RobloxVisitorBase {
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

    String luauPath;
    if (uri.startsWith('package:') || uri.startsWith('dart:')) {
      final cleanUri = uri.split('/').last.replaceAll('.dart', '');
      luauPath = '_RD.import(script, "Parent", "$cleanUri")';
    } else {
      if (currentFilePath != null && projectRoot != null) {
        final currentDir = p.dirname(currentFilePath!);
        final importedFileAbsolute = p.normalize(p.join(currentDir, uri));
        String relPathStr = p
            .relative(importedFileAbsolute, from: currentDir)
            .replaceAll('.dart', '');

        final parts = relPathStr.split(p.separator);
        List<String> segments = ['"Parent"'];

        for (var part in parts) {
          if (part == '.') {
            continue;
          } else if (part == '..') {
            segments.add('"Parent"');
          } else {
            segments.add('"$part"');
          }
        }
        luauPath = '_RD.import(script, ${segments.join(", ")})';
      } else {
        final cleanUri = uri.replaceAll('.dart', '').replaceAll('/', '.');
        luauPath = '_RD.import(script, "Parent", "$cleanUri")';
      }
    }

    String output = "local $varName = require($luauPath)\n";

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

    String luauPath;
    if (currentFilePath != null && projectRoot != null) {
      final currentDir = p.dirname(currentFilePath!);
      final importedFileAbsolute = p.normalize(p.join(currentDir, uri));
      String relPathStr = p
          .relative(importedFileAbsolute, from: currentDir)
          .replaceAll('.dart', '');

      final parts = relPathStr.split(p.separator);
      List<String> segmentsList = ['"Parent"'];

      for (var part in parts) {
        if (part == '.') {
          continue;
        } else if (part == '..') {
          segmentsList.add('"Parent"');
        } else {
          segmentsList.add('"$part"');
        }
      }
      luauPath = '_RD.import(script, ${segmentsList.join(", ")})';
    } else {
      final cleanUri = uri.replaceAll('.dart', '').replaceAll('/', '.');
      luauPath = '_RD.import(script, "Parent", "$cleanUri")';
    }

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
      initializer: LuauLiteral(value: 'require($luauPath)'),
    );
  }
}

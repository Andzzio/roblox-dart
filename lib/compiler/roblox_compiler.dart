import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:roblox_dart/compiler/roblox_visitor.dart';
import 'package:path/path.dart' as p;

class RobloxCompiler {
  final AnalysisContextCollection collection;

  RobloxCompiler({required String projectRoot})
    : collection = AnalysisContextCollection(
        includedPaths: [p.normalize(p.absolute(projectRoot))],
      );

  Future<void> compileFile(File file) async {
    print("Analyzing source code...");

    final normalizedPath = p.normalize(file.absolute.path);
    final context = collection.contextFor(normalizedPath);

    final session = context.currentSession;
    final parseResult = await session.getResolvedUnit(normalizedPath);

    if (parseResult is! ResolvedUnitResult) {
      print("Error: Could not resolve file.");
      return;
    }

    final astRoot = parseResult.unit;

    print(
      "Source code analized! Found ${astRoot.declarations.length} declarations",
    );

    final visitor = RobloxVisitor();

    for (var dartNode in astRoot.declarations) {
      if (dartNode is ClassDeclaration) {
        final body = dartNode.body;
        if (body is BlockClassBody) {
          final members = body.members;
          for (var member in members) {
            if (member is FieldDeclaration) {
              final isStatic = member.isStatic;
              for (var variable in member.fields.variables) {
                visitor.allClassMembers.add(variable.name.lexeme);
                if (isStatic) visitor.staticClassMembers.add(variable.name.lexeme);
              }
            } else if (member is MethodDeclaration) {
              visitor.allClassMembers.add(member.name.lexeme);
              if (member.isStatic) visitor.staticClassMembers.add(member.name.lexeme);
            }
          }
        }
      }
    }

    String finalLuauCode = "";
    bool hasMain = false;
    List<String> forwardDeclarations = [];

    for (var dartNode in astRoot.declarations) {
      if (dartNode is FunctionDeclaration) {
        forwardDeclarations.add("local ${dartNode.name.lexeme}");
      }
    }

    if (forwardDeclarations.isNotEmpty) {
      finalLuauCode += forwardDeclarations.join("\n");
      finalLuauCode += "\n\n";
    }

    for (var directive in astRoot.directives) {
      try {
        final lego = directive.accept(visitor);
        if (lego != null) {
          finalLuauCode += lego.emit();
        }
      } catch (e) {
        print("CRASH during visit of directive: ${directive.toSource()}");
        print("ERROR: $e");
        rethrow;
      }
    }

    if (astRoot.directives.isNotEmpty) finalLuauCode += "\n";

    for (var dartNode in astRoot.declarations) {
      if (dartNode is FunctionDeclaration && dartNode.name.lexeme == "main") {
        hasMain = true;
      }
      try {
        final masterLego = dartNode.accept(visitor);
        if (masterLego != null) {
          finalLuauCode += masterLego.emit();
        }
      } catch (e) {
        print("CRASH during visit of: ${dartNode.toSource()}");
        print("ERROR: $e");
        rethrow;
      }
    }

    if (visitor.exports.isNotEmpty && !hasMain) {
      finalLuauCode += "\nlocal Exports = {\n";
      for (var export in visitor.exports) {
        if (export.contains('.')) {
          final parts = export.split('.');
          final name = parts.last;
          finalLuauCode += "    $name = $export,\n";
        } else {
          finalLuauCode += "    $export = $export,\n";
        }
      }
      finalLuauCode += "}\nreturn Exports\n";
    }

    if (hasMain) {
      finalLuauCode += "main()\n";
    }

    final String fileName = file.uri.pathSegments.last;
    final String luauFileName = fileName.replaceAll(".dart", ".luau");

    final String outPath = "out/$luauFileName";

    Directory("out").createSync(recursive: true);

    final outputFile = File(outPath);

    await outputFile.writeAsString(finalLuauCode);

    print("Luau code saved to $outPath");

    print("\n--- Luau Output ---\n");
    print(finalLuauCode);
  }
}

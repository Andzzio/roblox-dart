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

    for (var dartNode in astRoot.declarations) {
      if (dartNode is FunctionDeclaration && dartNode.name.lexeme == "main") {
        hasMain = true;
      }

      final masterLego = dartNode.accept(visitor);
      if (masterLego != null) {
        finalLuauCode += masterLego.emit();
      }
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

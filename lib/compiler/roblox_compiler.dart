import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:roblox_dart/compiler/roblox_visitor.dart';

class RobloxCompiler {
  Future<void> compileFile(File file) async {
    final String fileContent = await file.readAsString();
    print("Analazing source code...");

    final parseResult = parseString(content: fileContent);

    final astRoot = parseResult.unit;

    print(
      "Source code analized! Found ${astRoot.declarations.length} declarations",
    );

    final visitor = RobloxVisitor();
    astRoot.accept(visitor);

    print("\n--- Luau Output ---\n");
    print(visitor.luauOutput);
  }
}

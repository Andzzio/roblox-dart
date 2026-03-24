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

    final String fileName = file.uri.pathSegments.last;
    final String luauFileName = fileName.replaceAll(".dart", ".luau");

    final String outPath = "out/$luauFileName";

    Directory("out").createSync(recursive: true);

    final outputFile = File(outPath);

    await outputFile.writeAsString(visitor.luauOutput);

    print("Luau code saved to $outPath");

    print("\n--- Luau Output ---\n");
    print(visitor.luauOutput);
  }
}

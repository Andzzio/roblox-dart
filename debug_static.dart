import 'dart:io';
import 'package:roblox_dart/compiler/roblox_compiler.dart';

void main() async {
  final compiler = RobloxCompiler(projectRoot: Directory.current.path);
  final sourceFile = File('test/static_test.dart');

  print("Analyzing source code...");
  try {
    await compiler.compileFile(sourceFile);
    print("SUCCESS");
  } catch (e, stack) {
    print("ERROR: $e");
    print(stack);
  }
}

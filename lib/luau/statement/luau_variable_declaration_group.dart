import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/statement/luau_variable_declaration.dart';

class LuauVariableDeclarationGroup extends LuauNode {
  final List<LuauVariableDeclaration> declarations;

  LuauVariableDeclarationGroup({required this.declarations});

  @override
  String emit({int indent = 0}) {
    return declarations.map((decl) => decl.emit(indent: indent)).join();
  }
}

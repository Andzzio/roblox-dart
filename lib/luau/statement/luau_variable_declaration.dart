import 'package:roblox_dart/luau/luau_node.dart';

class LuauVariableDeclaration extends LuauNode {
  final String name;
  final String? type;
  final LuauNode? initializer;

  LuauVariableDeclaration({required this.name, this.type, this.initializer});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    final String typeStr = type != null ? ": $type" : "";

    if (initializer != null) {
      return "${tabs}local $name$typeStr = ${initializer!.emit()}\n\n";
    } else {
      return "${tabs}local $name$typeStr\n\n";
    }
  }
}

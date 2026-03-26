import 'package:roblox_dart/luau/luau_node.dart';

class LuauClass extends LuauNode {
  final String name;
  final LuauNode constructorCode;
  final List<LuauNode> methods;

  LuauClass({
    required this.name,
    required this.constructorCode,
    required this.methods,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    String output = "${tabs}local $name = {}\n";
    output += "$tabs$name.__index = $name\n\n";

    output += constructorCode.emit(indent: indent);
    output += "\n";

    for (var method in methods) {
      output += method.emit(indent: indent);
      output += "\n";
    }

    return output;
  }
}

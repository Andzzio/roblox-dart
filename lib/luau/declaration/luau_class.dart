import 'package:roblox_dart/luau/luau_node.dart';

class LuauClass extends LuauNode {
  final String name;
  final List<LuauNode> constructors;
  final List<LuauNode> methods;
  final List<LuauNode> staticFields;
  final String? superClassName;

  LuauClass({
    required this.name,
    required this.constructors,
    required this.methods,
    this.staticFields = const [],
    this.superClassName,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    String output = "";

    if (superClassName != null) {
      output += "${tabs}local $name = setmetatable({}, $superClassName)\n";
    } else {
      output += "${tabs}local $name = {}\n";
    }

    output += "$tabs$name.__index = $name\n\n";

    for (var constructorCode in constructors) {
      output += constructorCode.emit(indent: indent);
      output += "\n";
    }

    for (var method in methods) {
      output += method.emit(indent: indent);
      output += "\n";
    }

    for (var field in staticFields) {
      output += field.emit(indent: indent);
      output += "\n";
    }

    return output;
  }
}

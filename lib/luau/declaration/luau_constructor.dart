import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/luau_node.dart';

class LuauConstructor extends LuauNode {
  final String className;
  final List<LuauParameter> parameters;
  final List<LuauNode> body;
  final List<LuauNode> fieldInitializers;

  LuauConstructor({
    required this.className,
    required this.parameters,
    required this.body,
    required this.fieldInitializers,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String params = parameters.map((p) => p.emit()).join(", ");

    String output = "${tabs}function $className.new($params)\n";

    output += "$tabs\tlocal self = setmetatable({}, $className)\n\n";

    for (var field in fieldInitializers) {
      output += field.emit(indent: indent + 1);
    }

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    output += "\n$tabs\treturn self\n";
    output += "${tabs}end\n";

    return output;
  }
}

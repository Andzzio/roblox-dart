import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/declaration/luau_parameter.dart';

class LuauMethod extends LuauNode {
  final String className;
  final String methodName;
  final List<LuauParameter> parameters;
  final List<LuauNode> body;
  final bool isStatic;

  LuauMethod({
    required this.className,
    required this.methodName,
    required this.parameters,
    required this.body,
    this.isStatic = false,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String operator = isStatic ? "." : ":";

    final String params = parameters.map((p) => p.name).join(", ");

    String output = "${tabs}function $className$operator$methodName($params)\n";

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}end\n";
    return output;
  }
}

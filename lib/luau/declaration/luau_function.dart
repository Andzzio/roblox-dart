import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/declaration/luau_parameter.dart';

class LuauFunction extends LuauNode {
  final String name;
  final List<LuauNode> body;
  final List<LuauParameter> parameters;
  final String? returnType;

  LuauFunction({
    required this.name,
    required this.body,
    this.parameters = const [],
    this.returnType,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    final String paramText = parameters.map((p) => p.emit()).join(", ");

    final String retStr = returnType != null ? ": $returnType" : "";

    String output = "${tabs}local function $name($paramText)$retStr\n\n";

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}end\n\n";

    return output;
  }
}

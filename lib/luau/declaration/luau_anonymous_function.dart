import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/luau_node.dart';

class LuauAnonymousFunction extends LuauNode {
  final List<LuauParameter> parameters;
  final List<LuauNode> body;

  LuauAnonymousFunction({required this.parameters, required this.body});

  @override
  String emit({int indent = 0}) {
    String endTabs = "\t" * indent;

    String paramsString = parameters
        .map((p) => p.type != null ? "${p.name}: ${p.type}" : p.name)
        .join(", ");

    String output = "function($paramsString)\n";

    for (var node in body) {
      output += node.emit(indent: indent + 1);
      if (!output.endsWith("\n")) output += "\n";
    }

    output += "${endTabs}end";
    return output;
  }
}

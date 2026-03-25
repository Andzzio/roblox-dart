import 'package:roblox_dart/luau/luau_node.dart';

class LuauMapLiteral extends LuauNode {
  final Map<LuauNode, LuauNode> entries;
  LuauMapLiteral({required this.entries});

  @override
  String emit({int indent = 0}) {
    if (entries.isEmpty) return "{}";

    final String tabs = "\t" * indent;
    final String innerTabs = "\t" * (indent + 1);

    String output = "{\n";

    for (var entry in entries.entries) {
      output +=
          "$innerTabs[${entry.key.emit(indent: indent + 1)}] = ${entry.value.emit(indent: indent + 1)},\n";
    }

    output += "$tabs}";
    return output;
  }
}

import 'package:roblox_dart/luau/luau_node.dart';

class LuauFunction extends LuauNode {
  final String name;
  final List<LuauNode> body;

  LuauFunction({required this.name, required this.body});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    String output = "${tabs}local function $name()\n\n";

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}end\n\n";

    if (name == "main") {
      output += "$tabs$name()\n\n";
    }

    return output;
  }
}

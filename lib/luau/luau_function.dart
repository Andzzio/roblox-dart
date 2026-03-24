import 'package:roblox_dart/luau/luau_node.dart';

class LuauFunction extends LuauNode {
  final String name;
  final List<LuauNode> body;

  LuauFunction({required this.name, required this.body});

  @override
  String emit() {
    String output = "local function $name()\n\n";

    for (var node in body) {
      output += node.emit();
    }

    output += "end\n\n";

    if (name == "main") {
      output += "$name()\n\n";
    }

    return output;
  }
}

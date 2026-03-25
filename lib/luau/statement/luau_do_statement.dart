import 'package:roblox_dart/luau/luau_node.dart';

class LuauDoStatement extends LuauNode {
  final List<LuauNode> body;
  final LuauNode condition;

  LuauDoStatement({required this.body, required this.condition});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    String output = "${tabs}repeat\n\n";

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}until not (${condition.emit()})\n\n";

    return output;
  }
}

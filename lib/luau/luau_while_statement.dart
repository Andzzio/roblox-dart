import 'package:roblox_dart/luau/luau_node.dart';

class LuauWhileStatement extends LuauNode {
  final LuauNode condition;
  final List<LuauNode> body;

  LuauWhileStatement({required this.condition, required this.body});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    String output = "${tabs}while ${condition.emit()} do\n\n";

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}end\n\n";

    return output;
  }
}

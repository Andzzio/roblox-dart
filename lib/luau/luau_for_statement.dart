import 'package:roblox_dart/luau/luau_node.dart';

class LuauForStatement extends LuauNode {
  final LuauNode? initializer;
  final LuauNode? condition;
  final List<LuauNode> updaters;
  final List<LuauNode> body;

  LuauForStatement({
    this.initializer,
    this.condition,
    this.updaters = const [],
    required this.body,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String insideTabs = "\t" * (indent + 1);

    String output = "${tabs}do\n\n";

    if (initializer != null) {
      output += initializer!.emit(indent: indent + 1);
    }

    final condStr = condition != null ? condition!.emit() : "true";
    output += "${insideTabs}while $condStr do\n\n";

    for (var node in body) {
      output += node.emit(indent: indent + 2);
    }

    final String updateTabs = "\t" * (indent + 2);

    for (var node in updaters) {
      output += "$updateTabs${node.emit()}\n\n";
    }

    output += "${insideTabs}end\n\n";
    output += "${tabs}end\n\n";

    return output;
  }
}

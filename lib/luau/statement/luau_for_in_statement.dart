import 'package:roblox_dart/luau/luau_node.dart';

class LuauForInStatement extends LuauNode {
  final String itemName;
  final LuauNode list;
  final List<LuauNode> body;
  final bool usePairs;

  LuauForInStatement({
    required this.itemName,
    required this.list,
    required this.body,
    this.usePairs = false,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    final String iterator = usePairs ? "pairs" : "ipairs";

    String output =
        "${tabs}for _, $itemName in $iterator (${list.emit()}) do\n\n";

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}end\n\n";

    return output;
  }
}

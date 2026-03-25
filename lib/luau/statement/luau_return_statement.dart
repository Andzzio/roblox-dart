import 'package:roblox_dart/luau/luau_node.dart';

class LuauReturnStatement extends LuauNode {
  final LuauNode? expression;
  LuauReturnStatement({this.expression});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    if (expression != null) {
      return "${tabs}return ${expression!.emit()}\n\n";
    } else {
      return "${tabs}return\n\n";
    }
  }
}

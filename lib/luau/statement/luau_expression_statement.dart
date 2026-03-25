import 'package:roblox_dart/luau/luau_node.dart';

class LuauExpressionStatement extends LuauNode {
  final LuauNode expression;
  LuauExpressionStatement({required this.expression});
  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    return "$tabs${expression.emit()}\n\n";
  }
}

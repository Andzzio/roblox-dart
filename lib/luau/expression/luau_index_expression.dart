import 'package:roblox_dart/luau/luau_node.dart';

class LuauIndexExpression extends LuauNode {
  final LuauNode target;
  final LuauNode index;
  LuauIndexExpression({required this.target, required this.index});

  @override
  String emit({int indent = 0}) {
    return "${target.emit()}[${index.emit()}]";
  }
}

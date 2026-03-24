import 'package:roblox_dart/luau/luau_node.dart';

class LuauBinaryExpression extends LuauNode {
  final LuauNode left;
  final String operator;
  final LuauNode right;

  LuauBinaryExpression({
    required this.left,
    required this.operator,
    required this.right,
  });

  @override
  String emit() {
    return "${left.emit()} $operator ${right.emit()}";
  }
}

import 'package:roblox_dart/luau/luau_node.dart';

class LuauConditionalExpression extends LuauNode {
  final LuauNode condition;
  final LuauNode thenExpression;
  final LuauNode elseExpression;

  LuauConditionalExpression({
    required this.condition,
    required this.thenExpression,
    required this.elseExpression,
  });

  @override
  String emit({int indent = 0}) {
    return "if ${condition.emit()} then ${thenExpression.emit()} else ${elseExpression.emit()}";
  }
}

import 'package:roblox_dart/luau/luau_node.dart';

class LuauCallExpression extends LuauNode {
  final String methodName;
  final List<LuauNode> arguments;

  LuauCallExpression({required this.methodName, required this.arguments});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    final String argsText = arguments.map((arg) => arg.emit()).join(", ");
    return "$tabs$methodName($argsText)";
  }
}

import 'package:roblox_dart/luau/luau_node.dart';

class LuauCallExpression extends LuauNode {
  final String methodName;
  final List<LuauNode> arguments;

  LuauCallExpression({required this.methodName, required this.arguments});

  @override
  String emit() {
    final String argsText = arguments.map((arg) => arg.emit()).join(", ");
    return "\t$methodName($argsText)\n\n";
  }
}

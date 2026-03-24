import 'package:roblox_dart/luau/luau_node.dart';

class LuauCallExpression extends LuauNode {
  final String methodName;
  final String arguments;

  LuauCallExpression({required this.methodName, required this.arguments});

  @override
  String emit() {
    return "\t$methodName($arguments)\n\n";
  }
}

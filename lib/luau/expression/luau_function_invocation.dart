import 'package:roblox_dart/luau/luau_node.dart';

class LuauFunctionInvocation extends LuauNode {
  final LuauNode function;
  final List<LuauNode> arguments;

  LuauFunctionInvocation({required this.function, required this.arguments});

  @override
  String emit({int indent = 0}) {
    String argsString = arguments.map((a) => a.emit()).join(", ");
    return "${function.emit()}($argsString)";
  }
}

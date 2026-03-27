import 'package:roblox_dart/luau/luau_node.dart';

class LuauCallExpression extends LuauNode {
  final LuauNode? target;
  final String methodName;
  final List<LuauNode> arguments;
  final bool useColon;

  LuauCallExpression({
    required this.methodName,
    required this.arguments,
    this.target,
    this.useColon = false,
  });

  @override
  String emit({int indent = 0}) {
    final String argsText = arguments
        .map((arg) => arg.emit(indent: indent))
        .join(", ");

    if (target != null) {
      final operator = useColon ? ":" : ".";
      return "${target!.emit()}$operator$methodName($argsText)";
    }

    final operator = useColon ? ":" : "";
    return "$operator$methodName($argsText)";
  }
}

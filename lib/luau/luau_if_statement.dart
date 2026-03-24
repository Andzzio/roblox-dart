import 'package:roblox_dart/luau/luau_node.dart';

class LuauIfStatement extends LuauNode {
  final LuauNode condition;
  final List<LuauNode> thenBranch;
  final List<LuauNode> elseBranch;
  bool isElseIf;

  LuauIfStatement({
    required this.condition,
    required this.thenBranch,
    this.elseBranch = const [],
    this.isElseIf = false,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;

    String output = isElseIf
        ? "${tabs}elseif ${condition.emit()} then\n\n"
        : "${tabs}if ${condition.emit()} then\n\n";

    for (var node in thenBranch) {
      output += node.emit(indent: indent + 1);
    }

    if (elseBranch.isNotEmpty) {
      if (elseBranch.length == 1 && elseBranch.first is LuauIfStatement) {
        output += elseBranch.first.emit(indent: indent);
      } else {
        output += "${tabs}else\n\n";

        for (var node in elseBranch) {
          output += node.emit(indent: indent + 1);
        }
      }
    }

    if (!isElseIf) {
      output += "${tabs}end\n\n";
    }
    return output;
  }
}

import 'package:roblox_dart/luau/luau_node.dart';

class LuauNumericForStatement extends LuauNode {
  final String variable;
  final LuauNode start;
  final LuauNode end;
  final LuauNode? step;
  final List<LuauNode> body;
  LuauNumericForStatement({
    required this.variable,
    required this.start,
    required this.end,
    this.step,
    required this.body,
  });
  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String stepStr = step != null ? ", ${step!.emit()}" : "";

    String output =
        "${tabs}for $variable = ${start.emit()}, ${end.emit()}$stepStr do\n";

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}end\n\n";
    return output;
  }
}

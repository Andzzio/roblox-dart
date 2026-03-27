import 'package:roblox_dart/luau/luau_node.dart';

class LuauContinueStatement extends LuauNode {
  final List<LuauNode>? updaters;

  LuauContinueStatement({this.updaters});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    String output = "";

    if (updaters != null) {
      for (var updater in updaters!) {
        output += "$tabs${updater.emit(indent: indent)}\n";
      }
    }

    output += "${tabs}continue\n";

    return output;
  }
}

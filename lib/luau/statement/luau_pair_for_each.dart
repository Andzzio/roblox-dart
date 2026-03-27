import 'package:roblox_dart/luau/luau_node.dart';

class LuauPairForEach extends LuauNode {
  final LuauNode target;
  final LuauNode callback;

  LuauPairForEach({required this.target, required this.callback});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String innerTabs = "\t" * (indent + 1);

    final String cbCode = callback.emit(indent: indent + 1);

    return "${tabs}for _k, _v in pairs(${target.emit()}) do\n"
        "$innerTabs($cbCode)(_k, _v)\n"
        "${tabs}end\n";
  }
}

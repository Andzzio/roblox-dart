import 'package:roblox_dart/luau/luau_node.dart';

class LuauListLiteral extends LuauNode {
  final List<LuauNode> elements;
  LuauListLiteral({required this.elements});

  @override
  String emit({int indent = 0}) {
    if (elements.isEmpty) return "{}";

    final String tabs = "\t" * indent;
    final String innerTabs = "\t" * (indent + 1);

    String output = "{\n";

    for (var element in elements) {
      output += "$innerTabs${element.emit(indent: indent + 1)},\n";
    }

    output += "$tabs}";
    return output;
  }
}

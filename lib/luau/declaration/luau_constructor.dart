import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/luau_node.dart';

class LuauConstructor extends LuauNode {
  final String className;
  final String constructorName;
  final List<LuauParameter> parameters;
  final List<LuauNode> body;
  final List<LuauNode> fieldInitializers;
  final String? customSelfInitialization;
  final bool isFactory;

  LuauConstructor({
    required this.className,
    required this.constructorName,
    required this.parameters,
    required this.body,
    required this.fieldInitializers,
    this.customSelfInitialization,
    this.isFactory = false,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String params = parameters.map((p) => p.emit()).join(", ");

    String output = "${tabs}function $className.$constructorName($params)\n";

    if (!isFactory) {
      if (customSelfInitialization != null) {
        output += "$tabs\tlocal self = $customSelfInitialization\n";
        output += "$tabs\tsetmetatable(self, $className)\n\n";
      } else {
        output += "$tabs\tlocal self = setmetatable({}, $className)\n\n";
      }
    }

    for (var field in fieldInitializers) {
      output += "${field.emit(indent: indent + 1)}\n";
    }

    for (var node in body) {
      output += node.emit(indent: indent + 1);
    }

    if (!isFactory) {
      output += "\n$tabs\treturn self\n";
    }
    output += "${tabs}end\n";

    return output;
  }
}

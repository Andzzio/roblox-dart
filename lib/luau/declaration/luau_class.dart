import 'package:roblox_dart/luau/luau_node.dart';

class LuauClass extends LuauNode {
  final String name;
  final List<LuauNode> constructors;
  final List<LuauNode> methods;
  final List<LuauNode> staticFields;
  final List<LuauNode> mixinInjections;
  final String? superClassName;

  LuauClass({
    required this.name,
    required this.constructors,
    required this.methods,
    this.staticFields = const [],
    this.mixinInjections = const [],
    this.superClassName,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String innerTabs = "\t" * (indent + 1);

    String output = "";

    if (superClassName != null) {
      output += "${tabs}local $name = setmetatable({}, $superClassName)\n";
    } else {
      output += "${tabs}local $name = {}\n";
    }

    output += "$tabs$name.__index = function(self, key)\n";
    output += "${innerTabs}local getter = $name[\"get_\" .. tostring(key)]\n";
    output += "${innerTabs}if getter then\n";
    output += "$innerTabs\treturn getter(self)\n";
    output += "${innerTabs}end\n";
    output += "${innerTabs}return $name[key]\n";
    output += "${tabs}end\n\n";

    output += "$tabs$name.__newindex = function(self, key, value)\n";
    output += "${innerTabs}local setter = $name[\"set_\" .. tostring(key)]\n";
    output += "${innerTabs}if setter then\n";
    output += "$innerTabs\tsetter(self, value)\n";
    output += "${innerTabs}else\n";
    output += "$innerTabs\trawset(self, key, value)\n";
    output += "${innerTabs}end\n";
    output += "${tabs}end\n\n";

    output += "$tabs$name.__tostring = function(self)\n";
    output += "${innerTabs}if self.toString then return self:toString() end\n";
    output += "${innerTabs}return \"$name\"\n";
    output += "${tabs}end\n\n";

    for (var constructorCode in constructors) {
      output += constructorCode.emit(indent: indent);
      output += "\n";
    }

    for (var method in methods) {
      output += method.emit(indent: indent);
      output += "\n";
    }

    for (var field in staticFields) {
      output += field.emit(indent: indent);
      output += "\n";
    }

    for (var injection in mixinInjections) {
      output += injection.emit(indent: indent);
      output += "\n";
    }

    return output;
  }
}

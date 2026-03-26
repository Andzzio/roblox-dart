import 'package:roblox_dart/luau/luau_node.dart';

class LuauEnum extends LuauNode {
  final String name;
  final List<String> constants;

  LuauEnum({required this.name, required this.constants});

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String innerTabs = "\t" * (indent + 1);

    String output = "${tabs}local $name\n";
    output += "${tabs}do\n";
    output += "${innerTabs}local _mt = {\n";
    output += "$innerTabs\t__tostring = function(self) return self._name end\n";
    output += "$innerTabs}\n";
    output += "${innerTabs}local function _create(cname, index)\n";
    output +=
        "$innerTabs\tlocal obj = { index = index, _name = \"$name.\" .. cname }\n";
    output += "$innerTabs\tsetmetatable(obj, _mt)\n";
    output += "$innerTabs\ttable.freeze(obj)\n";
    output += "$innerTabs\treturn obj\n";
    output += "${innerTabs}end\n\n";

    output += "$innerTabs$name = {}\n";

    for (int i = 0; i < constants.length; i++) {
      final constant = constants[i];
      output += "$innerTabs$name.$constant = _create(\"$constant\", $i)\n";
      output += "$innerTabs$name[$i] = $name.$constant\n";
    }

    output += "\n${innerTabs}table.freeze($name)\n";
    output += "${tabs}end\n\n";

    return output;
  }
}

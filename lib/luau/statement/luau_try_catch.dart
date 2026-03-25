import 'package:roblox_dart/luau/luau_node.dart';

class LuauTryCatch extends LuauNode {
  final List<LuauNode> tryBody;
  final String? errorName;
  final List<LuauNode> catchBody;

  LuauTryCatch({
    required this.tryBody,
    this.errorName,
    required this.catchBody,
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String err = errorName ?? "_err";

    String output = "${tabs}local _ok, _luau_err = pcall(function()\n\n";

    for (var node in tryBody) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}end)\n\n";

    if (catchBody.isNotEmpty) {
      output += "${tabs}if not _ok then\n\n";
      output += "$tabs\tlocal $err = _luau_err\n\n";
      for (var node in catchBody) {
        output += node.emit(indent: indent + 1);
      }
      output += "${tabs}end\n\n";
    }

    return output;
  }
}

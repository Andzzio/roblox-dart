import 'package:roblox_dart/luau/luau_node.dart';

class LuauTryCatch extends LuauNode {
  final List<LuauNode> tryBody;
  final String? errorName;
  final List<LuauNode> catchBody;
  final List<LuauNode> finallyBody;

  LuauTryCatch({
    required this.tryBody,
    this.errorName,
    required this.catchBody,
    this.finallyBody = const [],
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String err = errorName ?? "_err";
    String output = "";
    output += "${tabs}do\n";
    final innerTabs = "$tabs\t";
    output += "${innerTabs}local _hasReturned = false\n";
    output += "${innerTabs}local _returnValue = nil\n";
    output += "${innerTabs}local _hasBroken = false\n";
    output += "${innerTabs}local _hasContinued = false\n\n";
    output += "${innerTabs}local _ok, _luau_err = pcall(function()\n";
    for (var node in tryBody) {
      output += node.emit(indent: indent + 2);
    }
    output += "${innerTabs}end)\n\n";
    if (catchBody.isNotEmpty) {
      output += "${innerTabs}if not _ok then\n";
      output += "$innerTabs\tlocal $err = _luau_err\n";
      for (var node in catchBody) {
        output += node.emit(indent: indent + 2);
      }
      output += "${innerTabs}end\n\n";
    }
    if (finallyBody.isNotEmpty) {
      for (var node in finallyBody) {
        output += node.emit(indent: indent + 1);
      }
      output += "\n";
    }
    output += "${innerTabs}if _hasReturned then return _returnValue end\n";
    output += "${tabs}end\n";
    return output;
  }
}

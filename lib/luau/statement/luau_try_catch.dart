import 'package:roblox_dart/luau/luau_node.dart';

class LuauTryCatch extends LuauNode {
  final List<LuauNode> tryBody;
  final String? errorName;
  final List<LuauNode> catchBody;
  final List<LuauNode> finallyBody; // ¡Nuevo!

  LuauTryCatch({
    required this.tryBody,
    this.errorName,
    required this.catchBody,
    this.finallyBody = const [], // ¡Nuevo!
  });

  @override
  String emit({int indent = 0}) {
    final String tabs = "\t" * indent;
    final String err = errorName ?? "_err";

    String output = "";

    // 1. Declarar banderas de estado para este scope
    output += "${tabs}local _hasReturned = false\n";
    output += "${tabs}local _returnValue = nil\n";
    output += "${tabs}local _hasBroken = false\n";
    output += "${tabs}local _hasContinued = false\n\n";

    output += "${tabs}local _ok, _luau_err = pcall(function()\n";

    for (var node in tryBody) {
      output += node.emit(indent: indent + 1);
    }

    output += "${tabs}end)\n\n";

    // 2. Catch
    if (catchBody.isNotEmpty) {
      output += "${tabs}if not _ok then\n";
      output += "$tabs\tlocal $err = _luau_err\n";
      for (var node in catchBody) {
        output += node.emit(indent: indent + 1);
      }
      output += "${tabs}end\n\n";
    }

    // 3. Finally
    if (finallyBody.isNotEmpty) {
      for (var node in finallyBody) {
        output += node.emit(indent: indent);
      }
      output += "\n";
    }

    // 4. Propagación de estado (Se evalúa después del try/catch/finally)
    output += "${tabs}if _hasReturned then return _returnValue end\n";
    output += "${tabs}if _hasBroken then break end\n";
    output += "${tabs}if _hasContinued then continue end\n\n";

    return output;
  }
}

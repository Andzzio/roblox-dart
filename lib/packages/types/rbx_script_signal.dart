import 'package:roblox_dart/packages/types/rbx_script_connection.dart';

class RBXScriptSignal<T extends Function> {
  external RBXScriptConnection connect(T callback);
  external RBXScriptConnection once(T callback);
  external void wait();
}

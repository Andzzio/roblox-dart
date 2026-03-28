import 'package:roblox_dart/compiler/macros/roblox/roblox_type_macro.dart';

class Vector3Macros extends RobloxTypeMacro {
  const Vector3Macros();

  @override
  String? resolveStaticProperty(String property) {
    return 'Vector3.$property';
  }
}

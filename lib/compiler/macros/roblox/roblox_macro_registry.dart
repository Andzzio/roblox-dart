import 'package:roblox_dart/compiler/macros/roblox/roblox_type_macro.dart';
import 'package:roblox_dart/compiler/macros/roblox/vector3_macros.dart';

class RobloxMacroRegistry {
  static const Map<String, RobloxTypeMacro> _registry = {
    'Vector3': Vector3Macros(),
    'CFrame': RobloxTypeMacro(),
    'Color3': RobloxTypeMacro(),
    'UDim2': RobloxTypeMacro(),
    'Instance': RobloxTypeMacro(),
    'BasePart': RobloxTypeMacro(),
    'Humanoid': RobloxTypeMacro(),
    'Workspace': RobloxTypeMacro(),
    'Players': RobloxTypeMacro(),
    'RBXScriptSignal': RobloxTypeMacro(),
    'RBXScriptConnection': RobloxTypeMacro()
  };

  static bool isRobloxType(String? typeName) =>
      typeName != null && _registry.containsKey(typeName);

  static String? resolveMethod(
    String typename,
    String method,
    String target,
    List<String> args,
  ) =>
      _registry[typename]?.resolveMethod(method, target, args);

  static String? resolveStaticProperty(String typename, String property) =>
      _registry[typename]?.resolveStaticProperty(property);

  static String? resolveProperty(
    String typename,
    String property,
    String target,
  ) =>
      _registry[typename]?.resolveProperty(property, target);
}

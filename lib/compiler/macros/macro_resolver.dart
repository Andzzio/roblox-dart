import 'package:analyzer/dart/element/type.dart';
import 'package:roblox_dart/compiler/macros/list_macros.dart';
import 'package:roblox_dart/compiler/macros/roblox/roblox_macro_registry.dart';
import 'package:roblox_dart/compiler/macros/string_macros.dart';
import 'package:roblox_dart/compiler/macros/type_macros.dart';

class MacroResolver {
  static String? resolveMethod(
    DartType? type,
    String method,
    String target,
    List<String> args,
  ) {
    if (type == null) return null;

    if (type.isDartCoreList) {
      return ListMacros.resolve(method, target, args);
    }
    if (type.isDartCoreString) {
      return StringMacros.resolve(method, target, args);
    }
    if (type.isDartCoreInt || type.isDartCoreDouble) {
      return TypeMacros.resolve(method, target, args);
    }
    final typeName = _typeName(type);
    if (typeName != null) {
      return RobloxMacroRegistry.resolveMethod(typeName, method, target, args);
    }
    return null;
  }

  static String? resolveProperty(
    DartType? type,
    String property,
    String target,
  ) {
    if (type == null) return null;
    if ((type.isDartCoreList || type.isDartCoreString) &&
        property == 'length') {
      return '#$target';
    }
    final typeName = _typeName(type);
    if (typeName != null) {
      return RobloxMacroRegistry.resolveProperty(typeName, property, target);
    }
    return null;
  }

  static String? resolveStaticProperty(String typeName, String property) {
    return RobloxMacroRegistry.resolveStaticProperty(typeName, property);
  }

  static bool isRobloxType(DartType? type) {
    if (type == null) return false;
    return RobloxMacroRegistry.isRobloxType(_typeName(type));
  }

  static String? _typeName(DartType type) {
    final name = type.element?.name;
    if (name != null && RobloxMacroRegistry.isRobloxType(name)) {
      return name;
    }

    if (type is InterfaceType) {
      for (final supertype in type.allSupertypes) {
        final superName = supertype.element.name;
        if (RobloxMacroRegistry.isRobloxType(superName)) {
          return superName;
        }
      }
    }

    return name;
  }
}

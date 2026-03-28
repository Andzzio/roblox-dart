class RobloxTypeMacro {
  const RobloxTypeMacro();

  String? resolveMethod(String method, String target, List<String> args) {
    return '$target:${_toPascalCase(method)}(${args.join(',')})';
  }

  String? resolveProperty(String property, String target) {
    return '$target.${_toPascalCase(property)}';
  }

  String? resolveStaticProperty(String property) => null;

  static String _toPascalCase(String camel) {
    if (camel.isEmpty) return camel;
    return camel[0].toUpperCase() + camel.substring(1);
  }
}

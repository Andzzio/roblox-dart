class TypeMacros {
  static const Map<String, String Function(String, List<String>)> _macros = {
    "toString": _toString,
    "parse": _parse,
    "toInt": _toInt,
  };

  static String? resolve(String method, String target, List<String> args) {
    return _macros[method]?.call(target, args);
  }

  static String _toString(String t, List<String> _) => "tostring($t)";
  static String _parse(String _, List<String> a) => "tonumber(${a[0]})";
  static String _toInt(String t, List<String> _) => "math.floor($t)";
}

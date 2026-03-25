class StringMacros {
  static const Map<String, String Function(String, List<String>)> _macros = {
    "toUpperCase": _toUpperCase,
    "toLowerCase": _toLowerCase,
    "contains": _contains,
    "startsWith": _startsWith,
    "endsWith": _endsWith,
    "trim": _trim,
    "substring": _substring,
    "indexOf": _indexOf,
    "toString": _toString,
  };

  static String? resolve(String method, String target, List<String> args) {
    return _macros[method]?.call(target, args);
  }

  static String _toUpperCase(String t, List<String> _) => "string.upper($t)";
  static String _toLowerCase(String t, List<String> _) => "string.lower($t)";
  static String _contains(String t, List<String> a) =>
      "string.find($t, ${a[0]}) ~= nil";
  static String _startsWith(String t, List<String> a) =>
      "string.sub($t, 1, #${a[0]}) == ${a[0]}";
  static String _endsWith(String t, List<String> a) =>
      "string.sub($t, -#${a[0]}) == ${a[0]}";
  static String _trim(String t, List<String> _) =>
      'string.match($t, "^%s*(.-)%s*\$")';
  static String _substring(String t, List<String> a) {
    if (a.length == 2) {
      return "string.sub($t, ${a[0]} + 1, ${a[1]})";
    }
    return "string.sub($t, ${a[0]} + 1)";
  }

  static String _indexOf(String t, List<String> a) =>
      "(string.find($t, ${a[0]}) or 0) - 1";
  static String _toString(String t, List<String> _) => "tostring($t)";
}

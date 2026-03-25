class ListMacros {
  static const Map<String, String Function(String, List<String>)> _macros = {
    "add": _add,
    "removeAt": _removeAt,
    "clear": _clear,
    "indexOf": _indexOf,
  };

  static String? resolve(String method, String target, List<String> args) {
    return _macros[method]?.call(target, args);
  }

  static String _add(String t, List<String> a) => "table.insert($t, ${a[0]})";
  static String _removeAt(String t, List<String> a) =>
      "table.remove($t, ${a[0]} + 1)";
  static String _clear(String t, List<String> _) => "table.clear($t)";
  static String _indexOf(String t, List<String> a) =>
      "(function() for i, v in ipairs($t) do if v == ${a[0]} then return i - 1 end end return -1 end)()";
}

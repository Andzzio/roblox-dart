class LuauParameter {
  final String name;
  final String? type;

  LuauParameter({required this.name, this.type});

  String emit() {
    return type != null ? "$name: $type" : name;
  }
}

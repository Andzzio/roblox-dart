import 'package:roblox_dart/luau/luau_node.dart';

class LuauLiteral extends LuauNode {
  final String value;

  LuauLiteral({required this.value});

  @override
  String emit() {
    return value;
  }
}

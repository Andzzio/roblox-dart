import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/luau_node.dart';

class ParameterResult {
  final List<LuauParameter> fnParams;
  final List<LuauNode> unpackers;
  final List<LuauNode> fieldAssignments;
  final bool hasNamed;

  ParameterResult(
    this.fnParams,
    this.unpackers,
    this.fieldAssignments,
    this.hasNamed,
  );
}

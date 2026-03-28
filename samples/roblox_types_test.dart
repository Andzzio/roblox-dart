import 'package:roblox_dart/services.dart' show workspace;
import 'package:roblox_dart/roblox.dart';

void main() {
  workspace.gravity = 0;

  final pos = Vector3(1, 2, 3);
  final mag = pos.magnitude;
  final u = pos.unit;

  print(mag);
  print(u);

  final goal = Vector3(4, 5, 6);
  final lerped = pos.lerp(goal, 0.5);
  final d = pos.dot(goal);

  print(lerped);
  print(d);

  final zero = Vector3.zero;
  print(zero);

  final part = Instance("Part");
  part.clone();
  part.destroy();

  final child = part.findFirstChild("Handle");
  print(child);

  part.destroy();
}

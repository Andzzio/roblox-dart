import 'package:roblox_dart/roblox.dart';
import 'package:roblox_dart/services.dart' show workspace;

void main() {
  final part = Instance.of<Part>();
  part.parent = workspace;

  final connection = part.touched.connect((BasePart hit) {
    print(hit.name);
  });

  final connection2 =
      part.touchEnded.connect((BasePart hit) => print(hit.name));

  part.touched.once((BasePart hit) {
    print("touched once: ${hit.name}");
  });

  part.touched.wait();

  connection.disconnect();
  connection2.disconnect();
}

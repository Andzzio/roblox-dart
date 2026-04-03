import 'package:roblox_dart/packages/types/instance.dart';
import 'package:roblox_dart/packages/types/base_part.dart';

class Workspace extends Instance {
  external factory Workspace();

  external double get gravity;
  external set gravity(double value);
  external Instance? get currentCamera;
  external set currentCamera(Instance? value);
  external Instance get terrain;
  external bool get streamingEnabled;
  external double get distributedGameTime;
  external bool get allowThirdPartySales;

  external List<BasePart> getPartsInPart(BasePart part);
  external Instance? findPartOnRay(dynamic ray,
      [Instance? ignoreDescendantsInstance]);
}

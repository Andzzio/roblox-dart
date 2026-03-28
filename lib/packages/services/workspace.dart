import 'package:roblox_dart/packages/types/instance.dart';

class Workspace extends Instance {
  external factory Workspace();

  external double get gravity;
  external set gravity(double value);
  external Instance? get currentCamera;
  external set currentCamera(Instance? value);
  external Instance get terrain;
  external bool get streamingEnabled;
}

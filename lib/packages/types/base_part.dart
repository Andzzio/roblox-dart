import 'package:roblox_dart/packages/types/instance.dart';
import 'package:roblox_dart/packages/types/rbx_script_signal.dart';
import 'package:roblox_dart/packages/types/vector3.dart';
import 'package:roblox_dart/packages/types/cframe.dart';
import 'package:roblox_dart/packages/types/color3.dart';

abstract class BasePart extends Instance {
  external BasePart([Instance? parent]);

  external Vector3 get position;
  external set position(Vector3 value);
  external Vector3 get size;
  external set size(Vector3 value);
  external CFrame get cFrame;
  external set cFrame(CFrame value);
  external Color3 get color;
  external set color(Color3 value);

  external double get transparency;
  external set transparency(double value);
  external bool get anchored;
  external set anchored(bool value);
  external bool get canCollide;
  external set canCollide(bool value);
  external bool get castShadow;
  external set castShadow(bool value);
  external bool get massless;
  external set massless(bool value);

  external Vector3 get velocity;
  external set velocity(Vector3 value);
  external Vector3 get rotVelocity;
  external set rotVelocity(Vector3 value);

  external void applyImpulse(Vector3 impulse);
  external void applyAngularImpulse(Vector3 impulse);
  external Vector3 getVelocityAtPosition(Vector3 position);

  external RBXScriptSignal<Function(BasePart)> get touched;
  external RBXScriptSignal<Function(BasePart)> get touchEnded;
}

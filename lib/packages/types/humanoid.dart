import 'package:roblox_dart/packages/types/instance.dart';
import 'package:roblox_dart/packages/types/rbx_script_signal.dart';
import 'package:roblox_dart/packages/types/vector3.dart';

class Humanoid extends Instance {
  external factory Humanoid();

  external double get health;
  external set health(double value);
  external double get maxHealth;
  external set maxHealth(double value);
  external double get walkSpeed;
  external set walkSpeed(double value);
  external double get jumpPower;
  external set jumpPower(double value);
  external double get jumpHeight;
  external set jumpHeight(double value);
  external bool get useJumpPower;
  external set useJumpPower(bool value);

  external String get displayName;
  external set displayName(String value);
  external bool get autoRotate;
  external set autoRotate(bool value);

  external Vector3 get moveDirection;
  external Vector3 get walkToPart;
  external Vector3 get cameraOffset;
  external set cameraOffset(Vector3 value);

  external bool isDead();
  external void takeDamage(double amount);
  external void moveTo(Vector3 position);
  external void changeState(int state);

  external void setStateEnabled(int state, bool enabled);
  external bool getStateEnabled(int state);
  external void equipTool(Instance tool);
  external void unequipTools();

  external RBXScriptSignal<Function()> get died;
  external RBXScriptSignal<Function(double, double)> get healthChanged;
  external RBXScriptSignal<Function(int, int)> get stateChanged;
  external RBXScriptSignal<Function(double)> get running;
  external RBXScriptSignal<Function(bool)> get jumping;
  external RBXScriptSignal<Function(bool)> get climbing;
  external RBXScriptSignal<Function(bool)> get freeFalling;
  external RBXScriptSignal<Function(Vector3)> get moveToFinished;
}

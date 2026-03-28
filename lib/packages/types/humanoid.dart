import 'package:roblox_dart/packages/types/instance.dart';
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
  external String get displayName;
  external set displayName(String value);

  external bool isDead();
  external void takeDamage(double amount);
  external void moveTo(Vector3 position);
  external void changeState(int state);
}

import 'package:roblox_dart/packages/types/vector3.dart';

class CFrame {
  external CFrame(double x, double y, double z);

  external Vector3 get position;
  external Vector3 get lookVector;
  external Vector3 get rightVector;
  external Vector3 get upVector;
  external double get x;
  external double get y;
  external double get z;

  external CFrame lerp(CFrame goal, double alpha);
  external CFrame inverse();
  external CFrame toWorldSpace(CFrame cf);
  external CFrame toObjectSpace(CFrame cf);
  external Vector3 pointToWorldSpace(Vector3 v);
  external Vector3 pointToObjectSpace(Vector3 v);

  external static CFrame lookAt(Vector3 at, Vector3 lookAt);
  external static CFrame fromEulerAnglesXYZ(double rx, double ry, double rz);

  external CFrame operator +(Vector3 other);
  external CFrame operator -(Vector3 other);
  external CFrame operator *(CFrame other);
}

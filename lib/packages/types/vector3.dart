class Vector3 {
  external double get x;
  external double get y;
  external double get z;

  external Vector3(double x, double y, double z);

  external static Vector3 get zero;
  external static Vector3 get one;
  external static Vector3 get xAxis;
  external static Vector3 get yAxis;
  external static Vector3 get zAxis;
  external double get magnitude;
  external Vector3 get unit;

  external Vector3 lerp(Vector3 goal, double alpha);
  external double dot(Vector3 other);
  external Vector3 cross(Vector3 other);

  external bool fuzzyEq(Vector3 other, [double epsilon]);
  external Vector3 abs();
  external Vector3 ceil();
  external Vector3 floor();
  external Vector3 max(Vector3 other);
  external Vector3 min(Vector3 other);
}

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

  external Vector3 lerp(Vector3 goal, double alpha);
  external double dot(Vector3 other);
  external Vector3 cross(Vector3 other);

  external double get magnitude;
  external Vector3 get unit;
}

class Instance {
  external String name;
  external String className;
  external dynamic parent;

  external Instance(String className, [dynamic parent]);

  external void destroy();
  external Instance? waitForChild(String childName, [double? timeOut]);
  external Instance clone();
}

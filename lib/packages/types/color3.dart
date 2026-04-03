class Color3 {
  external Color3(double r, double g, double b);

  external double get r;
  external double get g;
  external double get b;

  external Color3 lerp(Color3 goal, double alpha);

  external static Color3 fromRGB(int r, int g, int b);
  external static Color3 fromHSV(double h, double s, double v);
  external List<double> toHSV();
  external static Color3 get red;
  external static Color3 get green;
  external static Color3 get blue;
  external static Color3 get white;
  external static Color3 get black;
}

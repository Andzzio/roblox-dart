class UDim2 {
  external UDim2(double xScale, double xOffset, double yScale, double yOffset);

  external double get x;
  external double get y;

  external UDim2 lerp(UDim2 goal, double alpha);

  external static UDim2 fromScale(double x, double y);
  external static UDim2 fromOffset(double x, double y);

  external UDim2 operator +(UDim2 other);
  external UDim2 operator -(UDim2 other);
}

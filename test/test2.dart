double div(double a, double b) {
  if (b == 0) return 0;
  return a / b;
}

void main() {
  final double result = div(10, 2);
  print(result);
}

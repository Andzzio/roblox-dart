void main() {
  var salute = (String name) {
    print("Hello $name");
  };

  salute("André");

  var cuadrado = (int n) => n * n;

  print(cuadrado(5));

  executeOperation(10, 20, (p0, p1) => p0 + p1);
}

void executeOperation(int a, int b, int Function(int, int) operation) {
  int result = operation(a, b);
  print(result);
}

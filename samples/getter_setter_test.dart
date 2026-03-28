class Person {
  String _name;
  Person(this._name);
  String get name => _name;
  set name(String value) {
    _name = value;
  }
}

void main() {
  final p = Person("André");
  print(p.name);
  p.name = "André Fixed";
  print(p.name);
}

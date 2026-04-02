import 'inheritance_crossfile_test.dart';

class Player extends Human {
  Player(super.name, super.age);

  void greet() {
    print("Hello, I am $name and I am $age years old.");
  }
}

void main() {
  final p = Player("André", 19);
  p.greet();
}

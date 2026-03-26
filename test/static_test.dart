abstract class Animal {
  void makeContext();
}

class Person extends Animal {
  static String species = "Human";
  static int count = 0;

  String name;

  Person({required this.name}) {
    count++;
  }

  @override
  void makeContext() {
    print("Person: $name, Species: $species");
  }

  static void printCount() {
    print("Total People: $count");
  }
  
  factory Person.singleton(String name) {
    return Person(name: name);
  }
}

void main() {
  final p = Person(name: "André");
  p.makeContext();
  Person.printCount();
  print("Direct Static: ${Person.species}");
  
  final p2 = Person.singleton("Factory André");
  p2.makeContext();
}

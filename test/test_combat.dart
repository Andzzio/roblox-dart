abstract class Character {
  final String _name;
  late int _health;
  final int _maxHealth;

  static int totalCharactersCreated = 0;

  Character(String name, int maxHealth) : _name = name, _maxHealth = maxHealth {
    _health = _maxHealth;
    totalCharactersCreated++;
  }

  String get name => _name;
  int get health => _health;
  bool get isAlive => _health > 0;

  set health(int value) {
    if (value < 0) {
      _health = 0;
    } else if (value > _maxHealth) {
      _health = _maxHealth;
    } else {
      _health = value;
    }
  }

  void takeDamage(int amount) {
    health -= amount;
    print("$_name took $amount damage!\nRemaining HP: $_health / $_maxHealth");
  }

  static void printGlobalStats() {
    print("Total characters spawned in the world: $totalCharactersCreated");
  }
}

class Warrior extends Character {
  int armor;
  List<String> inventory = ["Iron Sword", "Wooden Shield"];

  Warrior(super.name, super.maxHealth, this.armor);

  @override
  void takeDamage(int amount) {
    int reducedDamage = amount - armor;
    if (reducedDamage < 0) {
      reducedDamage = 0;
    }

    print("`$name` uses armor!\nBlocked ${amount - reducedDamage} damage.");

    super.takeDamage(reducedDamage);
  }

  void lootItem(String item) {
    inventory.add(item);
    print("$name looted: $item. Total items: ${inventory.length}");
  }
}

void main() {
  print("=== RPG BATTLE SIMULATION ===\n");

  Character.printGlobalStats();

  final hero = Warrior("Arthur", 100, 5);
  final boss = Warrior("Dark Knight", 250, 10);

  print("\n--- Battle Starts ---");

  boss.takeDamage(30);

  hero.takeDamage(120);

  print("\n--- Battle Results ---");
  if (!hero.isAlive) {
    print("Hero `${hero.name}` has fallen in battle...");
  } else {
    print("Hero `${hero.name}` survived!");
  }

  hero.lootItem("Health Potion");

  print("\n");
  Character.printGlobalStats();
}

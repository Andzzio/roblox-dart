enum ItemRarity { common, rare, epic, legendary }

class Modifier {
  final String name;
  final double multiplier;

  Modifier(this.name, this.multiplier);
}

class Weapon {
  String name;
  int baseDamage;
  ItemRarity rarity;

  Modifier? activeModifier;
  Map<String, int> statBonuses = {};

  Weapon.forged(this.name, this.baseDamage, this.rarity);

  void applyModifier(Modifier mod) {
    activeModifier = mod;
    print("Applied modifier: ${mod.name} (x${mod.multiplier})");
  }

  void addBonus(String stat, int value) {
    statBonuses[stat] = (statBonuses[stat] ?? 0) + value;
  }

  int calculateDamage() {
    final double mult = activeModifier?.multiplier ?? 1.0;
    return (baseDamage * mult).toInt();
  }
}

class Player {
  final String username;
  Weapon? equippedWeapon;

  Player(this.username);

  void equip(Weapon w) {
    equippedWeapon = w;
    print("\n$username equipped `${w.name}`!");
  }

  void attack() {
    final int dmg = equippedWeapon?.calculateDamage() ?? 0;

    if (dmg > 0) {
      print("$username attacks for $dmg damage!");
    } else {
      print("$username punches the air helplessly...");
    }
  }
}

void main() {
  print("=== FORGE & CASCADE TEST ===");

  final noob = Player("Andzzio");

  noob.attack();

  final epicSword = Weapon.forged("Dragon Blade", 50, ItemRarity.epic)
    ..applyModifier(Modifier("Fire Aspect", 1.5))
    ..addBonus("STR", 10)
    ..addBonus("AGI", 5);

  noob.equip(epicSword);

  noob.attack();

  print("\n--- Weapon Details ---");

  print("Rarity: ${epicSword.rarity.name}");

  print("Bonuses:");
  epicSword.statBonuses.forEach((key, value) {
    print("\t+ $value to $key");
  });
}

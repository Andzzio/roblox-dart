void main() {
  int hp = 100;
  final int damage = 25;

  final int finalHp = hp - damage;

  final bool isAlive = finalHp > 0 ? true : false;

  print("Player has $finalHp HP");

  final String name = "Roblox";

  print("$name has $finalHp HP");

  if (finalHp > 50 && isAlive) {
    print("Left more than 50 HP and alive");
  } else if (finalHp <= 50 && finalHp > 25 && isAlive) {
    print("Left less than 50 HP and more than 25 HP and alive");
  } else if (finalHp <= 25 && isAlive) {
    print("Left less than 25 HP and alive");
  } else {
    print("Player is dead");
  }

  print(finalHp);
}

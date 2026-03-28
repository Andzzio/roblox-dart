class Player {
  final String name;
  int hp;
  late bool isAlive;

  Player({required this.name, required this.hp}) {
    isAlive = hp > 0 ? true : false;
  }

  String get info => "Name: $name,\nHP: $hp,\nIsAlive: $isAlive";

  void takeDamage(int damage) {
    hp -= damage;
    if (hp < 0) {
      hp = 0;
    }
    isAlive = hp > 0 ? true : false;
  }
}

void main() {
  final player = Player(name: "John Doe", hp: 100);
  print(player.info);
  player.takeDamage(50);
  print(player.info);
  player.takeDamage(50);
  print(player.info);
}

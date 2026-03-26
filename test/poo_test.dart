class Entity {
  String name;
  int hp;

  Entity(this.name, {this.hp = 100});

  Entity.boss(String name) : this(name, hp: 500);

  void takeDamage(int damage) {
    hp -= damage;
    print("$name received $damage of damage. HP remaining: $hp");
  }
}

class Player extends Entity {
  int level;

  Player(super.name, {this.level = 1}) : super(hp: 150);

  @override
  void takeDamage(int damage) {
    print("The player is being attacked!");
    super.takeDamage(damage);
  }

  void levelUp() {
    level++;
    print("¡$name subió al nivel $level!");
  }
}

void main() {
  final boss = Entity.boss("King Slime");
  final pro = Player("André", level: 10);
  pro.takeDamage(20);
  boss.takeDamage(50);
  pro.levelUp();
}

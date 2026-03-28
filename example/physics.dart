class Vector2D {
  double x;
  double y;

  Vector2D(this.x, this.y);
}

abstract class Particle {
  final String id;
  Vector2D _position;
  Vector2D velocity;

  static int totalParticles = 0;

  Particle(this.id, double startX, double startY, this.velocity)
    : _position = Vector2D(startX, startY) {
    totalParticles++;
  }

  // ignore: unnecessary_getters_setters
  Vector2D get position => _position;

  set position(Vector2D newPos) {
    _position = newPos;
  }

  void update(double deltaTime) {
    _position.x += velocity.x * deltaTime;
    _position.y += velocity.y * deltaTime;
  }
}

class BouncingParticle extends Particle {
  final double bounds;
  int bounceCount = 0;

  BouncingParticle(
    super.id,
    super.startX,
    super.startY,
    super.velocity,
    this.bounds,
  );

  @override
  void update(double deltaTime) {
    super.update(deltaTime);

    bool bounced = false;

    if (position.x > bounds || position.x < -bounds) {
      velocity.x = -velocity.x;
      bounced = true;
    }

    if (position.y > bounds || position.y < -bounds) {
      velocity.y = -velocity.y;
      bounced = true;
    }

    if (bounced) {
      bounceCount++;
      print("`$id` bounced!\nTotal bounces for this particle: $bounceCount");
    }
  }
}

class PhysicsWorld {
  final List<Particle> _particles = [];

  void spawnParticle(Particle p) {
    _particles.add(p);
  }

  void simulateStep(double deltaTime) {
    for (int i = 0; i < _particles.length; i++) {
      final particle = _particles[i];

      if (particle.velocity.x == 0 && particle.velocity.y == 0) {
        continue;
      }

      particle.update(deltaTime);
    }
  }

  void printStatus() {
    print("\n--- World Status ---");
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      print("Particle `${p.id}` -> X: ${p.position.x}, Y: ${p.position.y}");
    }
  }
}

void main() {
  print("=== 2D PHYSICS SIMULATION ===\n");

  final world = PhysicsWorld();

  world.spawnParticle(
    BouncingParticle("Alpha", 0.0, 0.0, Vector2D(10.0, 5.0), 20.0),
  );
  world.spawnParticle(
    BouncingParticle("Beta", 18.0, 0.0, Vector2D(5.0, 0.0), 20.0),
  );
  world.spawnParticle(
    BouncingParticle("Gamma", -5.0, -5.0, Vector2D(0.0, 0.0), 20.0),
  );

  print("Simulating 3 steps...");

  for (int step = 1; step <= 3; step++) {
    print("\nStep $step:");
    world.simulateStep(1.0);
  }

  world.printStatus();
  print("\nTotal particles in memory: ${Particle.totalParticles}");
}

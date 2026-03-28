mixin Logger {
  void log(String message) {
    print("[LOG]: $message");
  }
}

class SecurityException implements Exception {
  final String cause;
  SecurityException(this.cause);

  @override
  String toString() => "SecurityException: $cause";
}

class Vault with Logger {
  static Vault? _instance;

  int _balance = 1000;
  bool _isLocked = true;

  factory Vault() {
    _instance ??= Vault._internal();
    return _instance!;
  }

  Vault._internal() {
    log("Vault system initialized.");
  }

  void unlock(String password) {
    if (password != "dart2luau") {
      throw SecurityException("Invalid password attempt.");
    }
    _isLocked = false;
    log("Vault unlocked successfully.");
  }

  void withdraw(int amount) {
    if (_isLocked) {
      throw SecurityException("Cannot withdraw, vault is locked.");
    }
    if (amount > _balance) {
      throw SecurityException("Insufficient funds.");
    }

    _balance -= amount;
    log("Withdrew $amount. Remaining: $_balance");
  }
}

void main() {
  print("=== VAULT SECURITY TEST ===\n");

  final myVault = Vault();

  print("--- Attempt 1: Hacker ---");
  try {
    myVault.unlock("1234");
    myVault.withdraw(500);
  } catch (e) {
    print("Caught an error -> $e");
  } finally {
    print("Hacker attempt finished.\n");
  }

  print("--- Attempt 2: Owner ---");
  try {
    final sameVault = Vault();
    sameVault.unlock("dart2luau");
    sameVault.withdraw(1500);
  } catch (e) {
    print("Caught an error -> $e");
  } finally {
    print("Owner attempt finished.");
  }
}

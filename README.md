# roblox-dart

**Write Dart. Ship Luau.**

Because Luau is fine, but Dart is home.

`roblox-dart` is a Dart-to-Luau transpiler for Roblox development. Write your game logic in Dart — with real classes, null safety, and a proper type system — and compile it to idiomatic Luau that runs natively in Roblox Studio.

Inspired by [roblox-ts](https://roblox-ts.com). Built for Dart developers who want to feel at home on Roblox.

> **⚠️ Early development.** roblox-dart is functional but not production-ready. APIs will change, edge cases exist, and not every Dart or Roblox feature is supported yet. Use it for personal projects, experiments, and contributions — not for shipped games. Feedback and PRs are very welcome.

---

## How it works

```dart
// src/server/main.server.dart
import 'package:roblox_dart/services.dart' show workspace;
import 'package:roblox_dart/roblox.dart';

void main() {
  workspace.gravity = 0;

  final part = Instance("Part");
  part.parent = workspace;

  final pos = Vector3(0, 10, 0);
  final goal = Vector3(0, 0, 0);
  final lerped = pos.lerp(goal, 0.5);
}
```

Compiles to:

```lua
local workspace = game:GetService("Workspace")

function main()
  workspace.Gravity = 0

  local part = Instance.new("Part")
  part.Parent = workspace

  local pos = Vector3.new(0, 10, 0)
  local goal = Vector3.new(0, 0, 0)
  local lerped = pos:Lerp(goal, 0.5)
end

main()
```

---

## Installation

**Requirements:** [Dart SDK](https://dart.dev/get-dart) 3.0+, [Rojo](https://rojo.space) 7+

```bash
dart pub global activate --source path /path/to/roblox-dart
```

Make sure `~/.pub-cache/bin` is in your PATH:

```bash
# bash/zsh — add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.pub-cache/bin:$PATH"
```

---

## Quick start

```bash
# Create a new project
mkdir my-game && cd my-game
roblox-dart init

# Start compiling
roblox-dart watch
```

Then open Roblox Studio, connect Rojo, and start building.

---

## Commands

| Command | Description |
|---------|-------------|
| `roblox-dart init` | Creates project structure, `default.project.json`, and runs `dart pub get` |
| `roblox-dart watch` | Compiles all files in `src/` and watches for changes |
| `roblox-dart translate -t <file>` | Translates a single Dart file to Luau |

---

## File conventions

File naming determines the Roblox script type — same convention as roblox-ts:

| File | Luau output | Roblox type |
|------|-------------|-------------|
| `foo.server.dart` | `foo.server.luau` | `Script` (server) |
| `foo.client.dart` | `foo.client.luau` | `LocalScript` (client) |
| `foo.dart` | `foo.luau` | `ModuleScript` |

---

## Project structure

`roblox-dart init` generates this structure:

```
my-game/
├── default.project.json   ← Rojo config
├── pubspec.yaml
├── src/
│   ├── server/            → ServerScriptService
│   ├── client/            → StarterPlayer.StarterPlayerScripts
│   └── shared/            → ReplicatedStorage.shared
└── out/                   ← compiled Luau (gitignored)
    ├── include/           → ReplicatedStorage.include (RuntimeLib)
    ├── server/
    ├── client/
    └── shared/
```

---

## Roblox API

### Services

```dart
import 'package:roblox_dart/services.dart' show workspace, players;

workspace.gravity = 0;
final local = players.localPlayer;
```

### Types

```dart
import 'package:roblox_dart/roblox.dart';

// Value types
final v = Vector3(1, 2, 3);
final mag = v.magnitude;        // → v.Magnitude
final u = v.unit;               // → v.Unit
final d = v.dot(other);         // → v:Dot(other)
final l = v.lerp(goal, 0.5);    // → v:Lerp(goal, 0.5)
final zero = Vector3.zero;      // → Vector3.zero

final cf = CFrame(0, 5, 0);
final color = Color3.fromRGB(255, 0, 0);
final size = UDim2.fromScale(1, 0.5);

// Instances
final part = Instance("Part");
part.parent = workspace;
part.name = "MyPart";
final child = part.findFirstChild("Handle");   // → part:FindFirstChild("Handle")
part.destroy();                                 // → part:Destroy()
```

### Supported types

| Type | Status |
|------|--------|
| `Vector3` | ✅ |
| `CFrame` | ✅ |
| `Color3` | ✅ |
| `UDim2` | ✅ |
| `Instance` | ✅ |
| `BasePart` | ✅ |
| `Humanoid` | ✅ |
| `Workspace` | ✅ |
| `Players` | ✅ |
| `TweenService` | 🔜 |
| `RemoteEvent` | 🔜 |
| `RBXScriptSignal` | 🔜 |

---

## Language features

| Feature | Status |
|---------|--------|
| Classes + inheritance | ✅ |
| Mixins | ✅ |
| Static members | ✅ |
| Getters / setters | ✅ |
| Factory constructors | ✅ |
| Null safety (`?.`, `??`, `??=`) | ✅ |
| Generics (basic) | ✅ |
| Enums | ✅ |
| Closures / lambdas | ✅ |
| `async` / `await` | 🔜 |
| Extension methods | 🔜 |

---

## Adding new Roblox types

The type system is designed to scale. Adding a new type takes three steps:

**1. Create the stub** (`lib/packages/types/tween_service.dart`):
```dart
import 'package:roblox_dart/packages/types/instance.dart';

class TweenService extends Instance {
  external factory TweenService();
  external Tween create(Instance instance, TweenInfo tweenInfo, Map<String, dynamic> propertyTable);
}
```

**2. Register it** (`lib/compiler/macros/roblox/roblox_macro_registry.dart`):
```dart
'TweenService': RobloxTypeMacro(),
```

**3. Export it** (`lib/services.dart`):
```dart
TweenService get tweenService => throw UnimplementedError('Transpiler only');
```

All methods automatically translate `camelCase` → `PascalCase` with the correct `:` or `.` separator. No extra mapping needed.

---

## Architecture

```
Dart source
    ↓  analyzer (dart:analyzer)
    AST
    ↓  RobloxVisitor (visitor pattern)
    ↓    ExpressionVisitor  → MacroResolver → RobloxMacroRegistry
    ↓    StatementVisitor
    ↓    ImportVisitor      → game:GetService() for services
    ↓    ClassVisitor       → metatables + inheritance
    Luau AST nodes
    ↓  emit()
    Luau source
```

---

## Contributing

Issues and PRs welcome at [github.com/Andzzio/roblox-dart](https://github.com/Andzzio/roblox-dart).

---

_Built by someone who loves Dart and Roblox, but prefers not to write Luau._

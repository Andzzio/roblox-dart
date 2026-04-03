## 0.1.0

- Initial release
- Dart-to-Luau transpiler with Rojo integration
- Roblox API stubs: Vector3, CFrame, Color3, UDim2, Instance, BasePart, Humanoid
- Services: Workspace, Players
- CLI commands: init, watch, translate

## 0.1.1

- Added 'publish_to: none' to generated projects to prevent pub.dev errors.
- Improved path detection for roblox_dart dependency in 'init' command.

## 0.1.2

- Adaptive dependency detection: `init` now automatically chooses between `path` (Dev) and `version` (User) based on installation environment.
- Dynamic version detection in `init` command based on internal pubspec.
- Project cleanliness: ensured all generated projects avoid hardcoded cache paths.

## 0.1.3

- Internal refactor: version management moved to `lib/version.dart` for maximum reliability.
- Robust fallback mechanism for version detection across all operating systems.

## 0.1.4

- Improved `init` command template: Now generates a complete Client-Server-Shared project structure.
- Added `src/shared/shared.dart` and example communication between server and client in the default template.
- Refined project bootstrapping for a more professional developer experience.

## 0.1.5

- Native `Rojo` resolution: `init` and `import` now respect the `default.project.json` path structure.
- Smarter imports: Automatically generates relative Roblox paths (e.g. `script.Parent.Shared`) across client/server boundaries.
- Optimized performance: Improved compiler initialization with one-time project config parsing.
- Refined internal architecture of the visitor pattern.

## 0.1.6

- Resolved fatal double `require()` chain-nesting bug on luau module resolution emitted by `import` directives.
- **Cross-Boundary Service Injection:** Extracted Roblox-TS parity routing. Path compilation strictly evaluates `default.project.json` service nodes and automatically builds native entry points (`game:GetService(...)`) when traversing between Client, Server, and Shared scopes.
- Improved robust AST path parser: Segments are deeply walked mapping relations like `..` strictly as independent `"Parent"` instances to prevent runtime Luau failures.
- Added foundational integration test suit `import_visitor_test.dart` for compiling AST nodes internally safely.

## 0.1.7

- Fixed critical `RojoResolver` regression preventing `game:GetService(...)` cross-boundary emission natively on fresh compilations: The resolution system was wrongfully discarding `$path` mappings if output `out/` directories did not physically exist prior to the transpilation process.

## 0.1.8

- Fixed inherited field resolution across files: `visitClassDeclaration` now correctly populates `currentClassMembers` with supertype fields and methods using the analyzer 12.x API (`declaredFragment?.element` + `type.element`). Previously, a silent `NoSuchMethodError` on `declaredElement` caused the catch block to swallow the error, leaving inherited identifiers like `name` and `age` emitting bare variables instead of `self.name` and `self.age`.
- Fixed `watch` command caché bug: Each file change now creates a fresh `RobloxCompiler` instance, preventing the `AnalysisContextCollection` from returning stale cached ASTs on recompilation.

## 0.1.9

- Added `RBXScriptSignal<T>` and `RBXScriptConnection` stubs with `connect`, `once`, `wait` and `disconnect` support.
- Added `touched` and `touchEnded` events to `BasePart`.
- Added `Instance.of<T>()` — idiomatic Dart pattern for instantiating Roblox types with full linter support and autocompletion.
- Added `Part` stub as instanciable subtype of `BasePart`.
- Fixed lambda indentation — callbacks now emit correctly indented `end` and body.
- Fixed `=>` void lambdas — no longer emits unnecessary `return` for void expressions.
- Automatic PascalCase resolution for any subtype of `Instance` — new types added to stubs automatically inherit Roblox macro behavior without manual registry entries.

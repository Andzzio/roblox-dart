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

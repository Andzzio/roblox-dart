# 🎯 Roblox-Dart

An experimental **Dart-to-Luau** transpiler for the Roblox ecosystem.

The main goal of this project is to allow developers to leverage Dart's strict typing and modern syntax, transforming the code into native and optimized Luau scripts ready to be consumed by Roblox Studio.

## 🚀 Current Status (Early MVP)

This project is actively under development. Currently, the transpiler is capable of:
- Parsing Dart source code using the official `analyzer` package.
- Converting the Dart syntax tree into a custom intermediate Luau AST.
- Support for Global Method Invocations (e.g., `print()`, `wait()`).
- Support for Dynamic Math Operations (automatic operator mapping).
- Support for modern String Interpolation.

## 🏗️ Architecture

The transpiler utilizes a solid architecture based on the **Visitor Pattern (Double Dispatch)**:
1. **CLI:** Catches the arguments using the `args` package.
2. **Analyzer:** Generates the official Dart `CompilationUnit`.
3. **Visitor:** Recursively travels the Dart tree and assemblies structured blocks (`LuauFunction`, `LuauCallExpression`, etc).
4. **Emitter:** The resulting `LuauNode`s print themselves into a formatted `.luau` file.

---
*Built by someone who loves Dart and Roblox, but absolutely hates Luau.*

# 🎯 Roblox-Dart

An experimental **Dart-to-Luau** transpiler for the Roblox ecosystem.

The main goal of this project is to allow developers to leverage Dart's strict typing and modern syntax, transforming the code into native and optimized Luau scripts ready to be consumed by Roblox Studio.

## 🚀 Current Status (Pro-Level POO & Modules)

This project has reached a significant level of maturity, supporting advanced Dart features:

### 🏗️ Object-Oriented Programming (OOP)

- **Full Inheritance:** Support for `extends` and `super()`.
- **Mixins:** Using `with` for class composition.
- **Static Members:** `static` fields and methods with correct initialization.
- **Factory Constructors:** `factory` constructors for patterns like Singleton.
- **Named Parameters:** Named parameters with `required` support (using `assert` in Luau).
- **Getters & Setters:** Automatic redirection to private/protected members.

### 📦 Module System

- **Smart Imports:** Translation from `import` to `require()` with relative path support.
- **Destructuring:** Automatic destructuring of imported members.
- **Automatic Exporting:** Each `.dart` file generates a Luau export table.

## 🛠️ Architecture

The transpiler uses an advanced **Visitor Pattern** over the official Dart AST:

1. **Directives:** Processes `import` and `export`, generating module infrastructure.
2. **Declarations:** Processes Classes and Functions, collecting members for exportation.
3. **Emitter:** Generates clean Luau code, with zero decorative comments, production-ready.

---

_Built by someone who loves Dart and Roblox, but absolutely hates Luau._

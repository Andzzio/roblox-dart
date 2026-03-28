# 🎯 roblox_dart

**Because I really, really hate Luau.**

I love building on Roblox, but let's be honest: Luau can be a pain. I wanted the strict typing, the modern syntax, and the sheer developer joy that comes with **Dart**, so I started building `roblox_dart`. 

This isn't an enterprise product or a production-ready suite. It's a personal mission to make Dart a viable option for Roblox development. It's a work-in-progress, a bit experimental, and born out of pure Luau-induced frustration.

---

## 🛠️ What's working so far?

I've been teaching this transpiler how to handle the stuff we actually use every day. It's not just about changing syntax; it's about semantic parity.

### 🏗️ Proper OOP in a Classless World
Luau doesn't have classes—at least not real ones. `roblox_dart` maps Dart's rich class system to Luau's metatables.
- **Inheritance:** We've got `extends` and `super()` working, including method overrides that actually resolve correctly.
- **Mixins:** Using `with` to keep code modular. It's like Lego for your logic, without the Luau boilerplate.
- **Static Members:** Handled with a reliable initialization order so you don't run into "nil" errors when accessing class-level fields.
- **Factory Constructors:** Implementing patterns like Singletons is actually clean now.

### 📦 A Sane Module System
Managing `require()` calls in Luau and keeping track of relative paths is a headache. 
- **Automatic Imports:** The transpiler converts Dart `import` directives into fully resolved Luau `require()` calls.
- **Destructuring:** It handles named imports intelligently, pulling only what you need into the local scope.
- **Self-Generating Exports:** Every `.dart` file automatically becomes a self-contained module with a clean export table at the end.

### ⚡ Safety & Type Integrity
- **Sound Null Safety:** Luau's "maybe-nil" variables are the source of 90% of crashes. By using Dart's strict null-safety, we catch those errors at the transpilation step.
- **Named Parameters:** First-class support for `required` and optional named parameters, guarded by Luau assertion patterns.

---

## 🧠 The Architecture

It's not magic—it's just a lot of AST (Abstract Syntax Tree) walking.
I use the official Dart `analyzer` to pull apart the code and a **Visitor Pattern** to put it back together as idiomatic Luau. 

1. **The Analysis Phase:** We use Dart's own compiler tools to understand the code's structure, types, and directives.
2. **The Transformation Phase:** This is where the translation happens—mapping Dart syntactic sugar into Luau-equivalent patterns.
3. **The Synthesis Phase:** Generating clean, human-readable Luau code that stays close to your original logic.

## 🏠 The End Goal

More than anything, I just want to feel **comfortable**.

I want to build on Roblox without losing the safety of Dart’s types or the elegance of its OOP. The goal is to create an environment where I can write code that feels "right"—where Null Safety catches my mistakes before they happen, and where classes actually behave like classes. It's about bringing that sense of home into the Roblox world.

---

_Built by someone who loves Dart and Roblox, but absolutely hates Luau._

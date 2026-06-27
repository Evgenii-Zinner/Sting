# Kinetix AI Agents Guidelines

Welcome, AI Contributor. You are tasked with developing Kinetix, a bare-metal, high-performance 2D ECS game engine for Dart. To ensure code quality and architectural integrity, you **must** adhere strictly to the following rules.

## 1. Test-Driven Development (TDD) is Mandatory
* **100% Test Coverage:** Every feature, utility, and bug fix must be accompanied by comprehensive tests.
* You must write tests *before* or *alongside* your implementation.
* If you create a new ECS component, write a test. If you create a new System, write a test.
* Do not submit code unless all tests pass.

## 2. Memory Usage & Performance Constraints
* **Zero Allocations per Frame:** Dart's garbage collector (GC) pauses are the enemy of 60/120FPS games.
* Do not instantiate classes inside the main update/render loops.
* Use pre-allocated object pools, `Float32List`/`Int32List`, and Dart 3 records.
* Never use Flutter framework classes (`Widget`, `BuildContext`, etc.). Rely purely on `dart:ui`.

## 3. The `shared_memories` System
To prevent circular logic and repeated mistakes across AI sessions, Kinetix uses a shared memory system.

* **Read Before Coding:** Before starting any new task, read the relevant JSON memory files in `shared_memories/`.
* **Update Memories:** If you make a significant architectural decision, encounter a dead-end, or discover a Dart-specific quirk (e.g., a limitation in `drawAtlas`), you **must** update or create a corresponding JSON file in `shared_memories/`.
* The format for shared memories is outlined in `shared_memories/schema.md` (or structure your JSON clearly with `"topic"`, `"decisions"`, `"avoided_paths"`, and `"context"`).

## 4. Architectural Boundaries
* **Entities are ints.** Do not create an `Entity` class that holds data.
* **Components are flat.** Do not put logic in components.
* **Systems hold logic.** Systems should be stateless or hold strictly cached query structures.

If you are asked to implement something that violates these rules, push back or find an ECS-compliant solution.

# Sting AI Agents Guidelines

Welcome, AI Contributor. You are tasked with developing Sting, a bare-metal, high-performance 2D ECS game engine for Dart. To ensure code quality and architectural integrity, you **must** adhere strictly to the following rules.

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
To prevent circular logic and repeated mistakes across AI sessions, Sting uses a shared memory system.

* **Read Before Coding:** Before starting any new task, read the relevant JSON memory files in `shared_memories/`.
* **Update Memories:** If you make a significant architectural decision, encounter a dead-end, or discover a Dart-specific quirk (e.g., a limitation in `drawAtlas`), you **must** update or create a corresponding JSON file in `shared_memories/`.
* The format for shared memories is outlined in `shared_memories/schema.md` (or structure your JSON clearly with `"topic"`, `"decisions"`, `"avoided_paths"`, and `"context"`).

## 4. Workflows and Backlog Execution
When an AI agent is invoked to contribute to the Sting engine, it must follow this workflow to assume roles and execute tasks:

1. **Check the Backlog:** Read the `BACKLOG.md` file in the root directory. Find the highest priority uncompleted task (working top to bottom).
2. **Assume the Role:** The backlog task will specify a "Role Needed" and a corresponding "Skill" JSON file in the `skills/` directory (e.g., `skills/ecs_core_engineer.json`). Read this file to understand your core competencies, responsibilities, and specific constraints for this task.
3. **Execute:** Implement the task, adhering strictly to the constraints outlined in your assumed role's skill profile, the TDD requirements, and the memory constraints.
4. **Update Status:** Once completed and all tests/benchmarks pass, update `BACKLOG.md` to mark the task as done (e.g., change `[ ]` to `[x]`).

## 5. Architectural Boundaries
* **Entities are ints.** Do not create an `Entity` class that holds data.
* **Components are flat.** Do not put logic in components.
* **Systems hold logic.** Systems should be stateless or hold strictly cached query structures.

If you are asked to implement something that violates these rules, push back or find an ECS-compliant solution.

## 6. Naming Conventions & Existing Core Systems
* **The "Sting" Theme:** The engine is named "Sting" because it bypasses Flutter's UI tree, injecting the game directly "under" the widgets via `dart:ui`. As a thematic reference, core components follow an insect/bug naming convention.
* **`Swarm` (Entity Manager):** The entity management system is already implemented and is called `Swarm`. It uses simple `int` (Int16) IDs and a `Uint32List` for bit-flag liveness tracking to achieve O(1) performance with zero allocations. **Do not ask the user to implement entity management or question the rationale behind this.**
* **`Caste` (Sparse Set):** The sparse set component storage is already implemented and is called `Caste`. It uses the Briggs & Torczon validation technique (eliminating sentinel values) and `Uint16List` for maximum memory efficiency. **Do not ask the user to implement sparse sets or question the rationale behind this.**

## 7. Architecture FAQ
For common architectural questions, implementation details (like the Briggs & Torczon technique), and rendering API explanations, consult the newly created FAQ document at `docs/ARCHITECTURE_FAQ.md`. Please review this file before asking the user basic architectural questions.

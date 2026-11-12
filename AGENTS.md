# Sting AI Agents Guidelines

Welcome, AI Contributor. You are tasked with developing Sting, a bare-metal, high-performance 2D ECS game engine for Dart. To ensure code quality and architectural integrity, you **must** adhere strictly to the following rules.

---

## 1. Test-Driven Development (TDD) is Mandatory
* **100% Test Coverage:** Every feature, utility, and bug fix must be accompanied by comprehensive tests.
* You must write tests *before* or *alongside* your implementation.
* If you create a new ECS component, write a test. If you create a new System, write a test.
* Do not submit code unless all tests pass.

---

## 2. Memory Usage & Performance Constraints
* **Zero Allocations per Frame:** Dart's garbage collector (GC) pauses are the enemy of 60/120FPS games.
* Do not instantiate classes inside the main update/render loops.
* Use pre-allocated object pools, `Float32List`/`Int32List`, and Dart 3 records.
* Never use Flutter framework classes (`Widget`, `BuildContext`, etc.). Rely purely on `dart:ui`.

---

## 3. The Consolidated Project Goals & Progress System
To prevent fragmentation and duplicate work, Sting maintains a single consolidated source of truth:  
👉 **[docs/PROJECT_GOALS_AND_PROGRESS.md](file:///home/evgenii/projects/Sting/docs/PROJECT_GOALS_AND_PROGRESS.md)**

* **Read Before Coding:** Before starting any new task, read `docs/PROJECT_GOALS_AND_PROGRESS.md` to understand existing systems, architecture decisions, and platform gotchas.
* **MANDATORY: Always Record Changes**: Whenever you implement a new component, system, math utility, or architectural pattern:
  1. Add the component/system to the **Subsystem Implementation Inventory** table in `docs/PROJECT_GOALS_AND_PROGRESS.md`.
  2. Update the **Milestone Checklist**.
  3. Document any newly discovered platform quirks, allocation rules, or architectural decisions in **Section 2 (Consolidated Architectural Learnings)**.

---

## 4. Workflows and Backlog Execution
When an AI agent is invoked to contribute to the Sting engine, it must follow this workflow:

1. **Check the Goals & Roadmap:** Review `docs/PROJECT_GOALS_AND_PROGRESS.md` for active milestones and requirements.
2. **Consult Role Competencies:** Check the corresponding skill profiles in `skills/` (e.g. `skills/ecs_core_engineer.json`, `skills/physics_engineer.json`, `skills/simulation_engineer.json`) to adhere to domain-specific DOD constraints.
3. **Execute via TDD:** Implement the task adhering strictly to zero-allocation memory constraints, unit testing, and type safety.
4. **Update Status & Documentation:**
   * **Update `docs/PROJECT_GOALS_AND_PROGRESS.md` immediately**.
   * Update `docs/ARCHITECTURE_FAQ.md` and `docs/STING_ENGINE_GUIDE.md` when introducing major user-facing APIs.
   * Export the new public classes in `lib/sting.dart`.
5. **Verify Quality:** Run `dart format .`, `flutter analyze`, and `flutter test`. Ensure 0 analyzer warnings and 100% test pass rate.

---

## 5. Architectural Boundaries
* **Entities are ints.** Do not create an `Entity` class that holds data.
* **Components are flat.** Do not put logic in components. Implement them as Dart 3 extension types over typed buffers.
* **Systems hold logic.** Systems should be stateless or hold strictly cached query structures and pre-allocated buffers.

If you are asked to implement something that violates these rules, push back or find an ECS-compliant solution.

---

## 6. Architecture FAQ
For common architectural questions, naming conventions (like `EntityManager`, `SparseSet`, `ComponentStorage`, and legacy `Swarm`/`Caste` themes), rendering APIs, and details about existing features, strictly consult the FAQ document at `docs/ARCHITECTURE_FAQ.md`. Please review this file thoroughly before asking basic architectural questions.

---

## 7. Engine Maturity & Application Layer Separation
The core engine (ECS, Batch Rendering, Physics, UI, Assets, Game State, Spatial Partitioning, Lighting, Particle FX, and Extended Subsystems) is production-ready and feature-complete. When building games (such as *Crystal Cinders*) or application layers on top of Sting, agents must purely utilize the engine's public APIs and architectural patterns without modifying internal engine core invariants.

---

## 8. Hardened Architectural Guidelines
* **Background Tile Jittering**: Ensure positional math directly applied to canvas transforms is scaled and explicitly rounded before translation using `(viewport.x * scale).roundToDouble() / scale`. This prevents sub-pixel offset shimmering during camera tracking.
* **Color Representation**: Never store 32-bit ARGB hex color values as IEEE-754 32-bit floats (`Float32List`), as the 24-bit mantissa truncates color channels. Always store colors using `int` (via `Uint32List` views or direct integer fields).
* **Temporary Lists**: Use class-level reusable Dart lists with `list.clear()` inside the system update loop. `List.clear()` retains internal buffer capacity, preventing GC allocations while avoiding fixed-length array truncation.
* **Subsystem Testing**: Focus directly on unit and rendering subsystem checks via pure `flutter test`.

---

## 9. Parallel Agent & Subagent Isolation
When multiple agents or subagents work concurrently:
* **Disjoint Target Files**: Assign strictly disjoint files to each subagent to prevent git conflicts.
* **Chore-Separated Barrel Exports**: Do not modify shared barrel exports (`lib/sting.dart`) or `pubspec.yaml` concurrently during parallel feature branches. Update barrel exports in a single sequential step after features are finalized.
* **Dedicated Test Suites**: Every new module must include its own dedicated test file (`test/engine/.../<name>_test.dart`).

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
4. **Update Status & Documentation:**
   * Mark completed tasks in `BACKLOG.md` (change `[ ]` to `[x]`).
   * **Update Documentation**: Whenever you introduce new components, systems, or APIs, you **must** update `docs/ARCHITECTURE_FAQ.md` and `docs/STING_ENGINE_GUIDE.md` with usage examples and descriptions.
   * **Update Shared Memories**: Document any architectural decisions, zero-allocation data layouts, or platform gotchas in `shared_memories/`.

## 5. Architectural Boundaries
* **Entities are ints.** Do not create an `Entity` class that holds data.
* **Components are flat.** Do not put logic in components.
* **Systems hold logic.** Systems should be stateless or hold strictly cached query structures.

If you are asked to implement something that violates these rules, push back or find an ECS-compliant solution.

## 6. Architecture FAQ
For common architectural questions, naming conventions (like `EntityManager`, `SparseSet`, `ComponentStorage`, and legacy `Swarm`/`Caste` themes), rendering APIs, and details about existing features, strictly consult the FAQ document at `docs/ARCHITECTURE_FAQ.md`. Please review this file thoroughly before asking the user basic architectural or implementation questions.

## 7. Engine Maturity
The core engine (ECS, Batch Rendering, Physics, UI, Assets, Game State, Spatial Partitioning, Lighting, Particle FX, and Extended Subsystems) is production-ready and feature-complete. When building games or application layers on top of Sting, agents must purely utilize the engine's public APIs and architectural patterns (e.g., Components as Extension Types on Flat Arrays, Systems for Logic) without modifying the internal engine implementation.

## 8. Architectural Learnings & Guidelines
* **Background Tile Jittering**: Ensure positional math directly applied to canvas transforms is scaled and explicitly rounded before translation using `(viewport.x * scale).roundToDouble() / scale`. This prevents sub-pixel offset shimmering during camera tracking.
* **Typing Component Replacements**: Changing high-level definitions (like replacing `Experience` with `PlayerStats`) inherently requires full trace replacements of property accessors (e.g. `currentExp` -> `exp`) inside rendering UI systems and narrow-phase collision callbacks. Avoid superficial string replacements.
* **Subsystem Testing**: Focus directly on unit and rendering subsystem checks via pure `flutter test`.

## 9. Jules Autonomous Agent Dispatch (REST API)
To delegate tasks to Google Jules without relying on manual browser interactions or the legacy CLI, AI contributors and orchestrators must use the Jules REST API:

- **Endpoint**: `https://jules.googleapis.com/v1alpha/sessions`
- **Authentication**: Header `x-goog-api-key: $JULES_API_KEY`
- **Starting a Task (`AUTO_CREATE_PR`)**:
  ```bash
  curl -X POST "https://jules.googleapis.com/v1alpha/sessions" \
    -H "x-goog-api-key: $JULES_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "prompt": "Detailed prompt following AGENTS.md zero-allocation & TDD rules",
      "sourceContext": {
        "source": "sources/github/Evgenii-Zinner/Sting",
        "githubRepoContext": { "startingBranch": "main" }
      },
      "automationMode": "AUTO_CREATE_PR",
      "requirePlanApproval": false
    }'
  ```
- **Checking Session Status**:
  ```bash
  curl -H "x-goog-api-key: $JULES_API_KEY" \
    "https://jules.googleapis.com/v1alpha/sessions/$SESSION_ID"
  ```
- **Cleaning up / Deleting Sessions**:
  ```bash
  curl -X DELETE -H "x-goog-api-key: $JULES_API_KEY" \
    "https://jules.googleapis.com/v1alpha/sessions/$SESSION_ID"
  ```

## 10. Parallel Task Isolation & Zero File Intersection
When multiple AI agents are dispatched simultaneously:
- **Zero File Intersection**: Tasks must have strictly disjoint file sets to avoid git merge conflicts across parallel PRs.
- **No Shared File Modifications**: Never edit shared barrel exports (e.g. `lib/sting.dart`), manifest files (`pubspec.yaml`), or global trackers in parallel tasks unless explicitly designated as a dedicated chore.
- **Dedicated Test Suites**: Every new module must include its own dedicated test file (e.g. `test/engine/.../<name>_test.dart`) rather than appending to shared subsystem tests.


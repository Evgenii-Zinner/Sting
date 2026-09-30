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
To delegate tasks to Google Jules without relying on manual browser interactions or the CLI (which lacks auto-PR and session management capabilities), AI contributors must use the Jules REST API:

- **Endpoint**: `https://jules.googleapis.com/v1alpha/sessions`
- **Authentication**: Header `x-goog-api-key: $env:JULES_API_KEY`
- **Starting a Task (`AUTO_CREATE_PR`)**:
  ```powershell
  $headers = @{ 'x-goog-api-key' = $env:JULES_API_KEY }
  $body = @{
    prompt = "Detailed prompt following AGENTS.md zero-allocation & TDD rules"
    sourceContext = @{
      source = "sources/github/Evgenii-Zinner/Sting"
      githubRepoContext = @{ startingBranch = "main" }
    }
    automationMode = "AUTO_CREATE_PR"
  } | ConvertTo-Json -Depth 5

  $session = Invoke-RestMethod -Uri "https://jules.googleapis.com/v1alpha/sessions" -Method Post -Headers $headers -ContentType "application/json" -Body $body
  ```
- **Checking Session Status**:
  ```powershell
  $resp = Invoke-RestMethod -Uri "https://jules.googleapis.com/v1alpha/sessions/$sessionId" -Headers $headers -Method Get
  # Inspect $resp.state ('IN_PROGRESS', 'COMPLETED', etc.) and $resp.outputs.pullRequest.url
  ```
- **Cleaning up / Deleting Sessions**:
  ```powershell
  Invoke-RestMethod -Uri "https://jules.googleapis.com/v1alpha/sessions/$sessionId" -Headers $headers -Method Delete
  ```
- **Rule**: Do not use `jules.exe` CLI for automated dispatch, as it does not support `AUTO_CREATE_PR` or session deletion.

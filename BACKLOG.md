# Sting Engine Backlog (Phase 1)

This backlog breaks down Phase 1 of the Sting Engine roadmap into highly granular tasks. AI Agents should select the highest priority task (from top to bottom), assume the required role, and execute the task adhering strictly to the `AGENTS.md` guidelines (TDD, zero allocations per frame).

## 1. Setup raw `dart:ui` window hook

* [x] **Task 1.1: Initialize PlatformDispatcher Hook**
  * **Role Needed:** Rendering Engineer
  * **Skill:** `skills/rendering_engineer.json`
  * **Description:** Create the minimal boilerplate to hook into `PlatformDispatcher.instance.onBeginFrame` and `PlatformDispatcher.instance.onDrawFrame`. Prove that the loop is ticking via a simple console log or counter. Ensure no Flutter framework elements are imported.
  * **Acceptance Criteria:** A runnable Dart entry point that receives VSync callbacks successfully.

* [ ] **Task 1.2: Basic Canvas Clear**
  * **Role Needed:** Rendering Engineer
  * **Skill:** `skills/rendering_engineer.json`
  * **Description:** Inside `onDrawFrame`, use `PictureRecorder`, `Canvas`, and `SceneBuilder` to clear the screen to a solid color (e.g., black) and submit the frame to the `PlatformDispatcher`.
  * **Acceptance Criteria:** Running the app displays a solid black screen.

## 2. Implement basic Entity ID generator and Component storage

* [ ] **Task 2.1: Entity ID Management**
  * **Role Needed:** ECS Core Engineer
  * **Skill:** `skills/ecs_core_engineer.json`
  * **Description:** Implement a `World` or `Registry` class capable of generating unique `int` IDs. Implement recycling for destroyed entity IDs.
  * **Acceptance Criteria:** `createEntity()` returns unique ints. `destroyEntity(id)` recycles the ID. 100% test coverage.

* [ ] **Task 2.2: Sparse Set Data Structure (Ints)**
  * **Role Needed:** ECS Core Engineer
  * **Skill:** `skills/ecs_core_engineer.json`
  * **Description:** Implement a generic (or explicitly typed for Phase 1) Sparse Set data structure in Dart using arrays/lists. It must map an Entity ID (int) to an index in a dense array.
  * **Acceptance Criteria:** Ability to add, remove, and check existence of an entity in the sparse set in O(1) time. 100% test coverage.

* [ ] **Task 2.3: Component Storage Integration**
  * **Role Needed:** ECS Core Engineer
  * **Skill:** `skills/ecs_core_engineer.json`
  * **Description:** Integrate the Sparse Set with component data arrays (e.g., storing `Position` data). Create mechanisms to attach a component to an entity.
  * **Acceptance Criteria:** Can attach, retrieve, and remove components from an entity. No object allocations during retrieval. 100% test coverage.

## 3. Implement Query engine

* [ ] **Task 3.1: Single Component Query Iteration**
  * **Role Needed:** ECS Core Engineer
  * **Skill:** `skills/ecs_core_engineer.json`
  * **Description:** Implement a way to iterate over all entities that possess a specific component (e.g., all entities in the Position sparse set).
  * **Acceptance Criteria:** Fast linear iteration over dense component data. 100% test coverage.

* [ ] **Task 3.2: Multi-Component Query Iteration (Join)**
  * **Role Needed:** ECS Core Engineer
  * **Skill:** `skills/ecs_core_engineer.json`
  * **Description:** Implement a query system to find entities that have *both* Component A and Component B (e.g., Position and Velocity). Use the sparse sets to perform fast intersections.
  * **Acceptance Criteria:** Can correctly identify entities with multiple specific components and iterate their data simultaneously. 100% test coverage.

## 4. Implement Render System (Sprite Component + `drawAtlas`)

* [ ] **Task 4.1: Position and Sprite Components**
  * **Role Needed:** Systems Architect
  * **Skill:** `skills/systems_architect.json`
  * **Description:** Design the flat memory structures for `Position` (x, y) and `Sprite` (texture rect, color, transform) components using Dart 3 records, extension types, or `Float32List`.
  * **Acceptance Criteria:** Memory layouts defined and tested.

* [ ] **Task 4.2: Asset Loader and Atlas Setup**
  * **Role Needed:** Rendering Engineer
  * **Skill:** `skills/rendering_engineer.json`
  * **Description:** Implement a basic utility to load a raw image asset into a `dart:ui.Image` without Flutter's `AssetBundle`.
  * **Acceptance Criteria:** Can load a PNG/JPG into memory as an Image object.

* [ ] **Task 4.3: drawAtlas Render System**
  * **Role Needed:** Rendering Engineer
  * **Skill:** `skills/rendering_engineer.json`
  * **Description:** Implement a System that queries entities with `Position` and `Sprite` components. It should build the `RSTransform` and `Rect` arrays required by `Canvas.drawAtlas` and issue a single draw call for all sprites.
  * **Acceptance Criteria:** Displays multiple sprites on screen via the ECS using a single `drawAtlas` call.

## 5. Implement spatial hashing for basic bounds checking

* [ ] **Task 5.1: Spatial Hash Grid Implementation**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Implement a 2D spatial hash grid. Entities can be inserted into cells based on their (x,y) position. Must use flat arrays/pre-allocated lists to avoid allocation during updates.
  * **Acceptance Criteria:** Can insert, update, and query entities within a specific bounding box or radius. 100% test coverage.

* [ ] **Task 5.2: Spatial Hash Update System**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Implement an ECS System that queries all entities with `Position` and updates their location in the Spatial Hash Grid every frame.
  * **Acceptance Criteria:** Grid accurately reflects entity positions as they move. Benchmark to prove zero allocations per tick.

* [ ] **Task 5.3: Broad-phase Collision Query**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Provide an API to query the spatial hash for "potential collisions" (entities occupying the same or adjacent cells).
  * **Acceptance Criteria:** Accurately returns candidate pairs for narrow-phase collision. 100% test coverage.

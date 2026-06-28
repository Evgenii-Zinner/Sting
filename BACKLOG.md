# Sting Engine Backlog (Phase 3)

This backlog breaks down Phase 3 of the Sting Engine roadmap into highly granular tasks. AI Agents should select the highest priority task (from top to bottom), assume the required role, and execute the task adhering strictly to the `AGENTS.md` guidelines (TDD, zero allocations per frame).

Phase 1 (Core ECS, Spatial Hash, Rendering) and Phase 2 (Game Loop, Input System, Kinematics, Narrow-Phase Collision) have been successfully completed.

## 10. Sprite Animation System

* [x] **Task 10.1: SpriteAnimation Component**
  * **Role Needed:** Animation Engineer
  * **Skill:** `skills/animation_engineer.json`
  * **Description:** Create an ECS component (`SpriteAnimation`) mapped to a `Float32List` that holds animation state (current frame index, frame duration, elapsed time).
  * **Acceptance Criteria:** `SpriteAnimation` component works with `ComponentCaste`. 100% test coverage. Zero allocations.

* [ ] **Task 10.2: Animation System**
  * **Role Needed:** Animation Engineer
  * **Skill:** `skills/animation_engineer.json`
  * **Description:** Implement an `AnimationSystem` that queries `Query2<Sprite, SpriteAnimation>`. It updates the elapsed time by `dt` and transitions the `Sprite`'s source rect to the next frame when duration is met.
  * **Acceptance Criteria:** Sprites update their visual frames over time based on `dt`. 100% test coverage. Zero allocations per frame.

## 11. Physics Collision Resolution

* [x] **Task 11.1: Simple Resolution System**
  * **Role Needed:** Physics Resolution Engineer
  * **Skill:** `skills/physics_resolution_engineer.json`
  * **Description:** Create a system that handles collision resolution (separating overlapping entities) based on callbacks from the `CollisionSystem`.
  * **Acceptance Criteria:** Overlapping entities with rigid body properties are separated correctly without massive jitter. 100% test coverage. Zero allocations.

## 12. Scene Management and Spawning

* [x] **Task 12.1: Entity Prefabs/Spawning**
  * **Role Needed:** Scene Architect
  * **Skill:** `skills/scene_architect.json`
  * **Description:** Create a utility or factory pattern that allows creating standard entity "prefabs" (e.g., an enemy with Position, Velocity, BoundingBox, and Sprite) easily without violating ECS bounds.
  * **Acceptance Criteria:** Prefabs can be instantiated cleanly. 100% test coverage. No per-frame GC pauses.

## 6. Game Loop and Time System

* [x] **Task 6.1: Delta Time Calculation**
  * **Role Needed:** Game Loop Engineer
  * **Skill:** `skills/game_loop_engineer.json`
  * **Description:** Implement a robust `dt` (delta time) tracking mechanism within the `PlatformDispatcher.instance.onBeginFrame` and `onDrawFrame` hook.
  * **Acceptance Criteria:** A `Time` object/system correctly calculates the duration between frames and provides a safe `dt` float (capped to avoid massive jumps on lag) to be passed into ECS Systems. 100% test coverage.

## 7. Input System (Raw pointer events)

* [x] **Task 7.1: Pointer Data Packet Hook**
  * **Role Needed:** Input Engineer
  * **Skill:** `skills/input_engineer.json`
  * **Description:** Hook into `PlatformDispatcher.instance.onPointerDataPacket`. Translate `PointerDataPacket` into an internal array of active touches/clicks without instantiating high-level Gesture objects.
  * **Acceptance Criteria:** Can correctly track X/Y coordinates of current down/move/up events in flat arrays. 100% test coverage.

## 8. Kinematics System (Velocity)

* [x] **Task 8.1: Velocity Component**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Create a `Velocity` component (dx, dy) using Dart 3 extension types on a `Float32List`, identical to the `Position` component structure.
  * **Acceptance Criteria:** `Velocity` component is flat, zero-allocation, and works with `ComponentCaste`. 100% test coverage.

* [x] **Task 8.2: Movement System**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Create a System that queries `Query2<Position, Velocity>` and updates `Position` based on `Velocity * dt` every frame.
  * **Acceptance Criteria:** Entities with Velocity move correctly over time. Zero allocations per tick. 100% test coverage.

## 9. Narrow-Phase Collision

* [x] **Task 9.1: Bounding Boxes and Circle Colliders**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Implement AABB-AABB and Circle-Circle intersection math functions. These should take raw floats (x, y, w, h or x, y, r), not objects.
  * **Acceptance Criteria:** Math functions correctly return true/false for overlaps. 100% test coverage.

* [x] **Task 9.2: Collision System Hookup**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Implement a System that uses the `SpatialHashGrid` broad-phase query from Phase 1, combined with the narrow-phase math from Task 9.1, to accurately detect actual entity overlaps.
  * **Acceptance Criteria:** Can query the ECS and correctly identify which specific entities are overlapping on a pixel-perfect (or shape-perfect) level. Zero allocations per tick. 100% test coverage.

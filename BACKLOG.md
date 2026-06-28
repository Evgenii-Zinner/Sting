# Sting Engine Backlog (Phase 2)

This backlog breaks down Phase 2 of the Sting Engine roadmap into highly granular tasks. AI Agents should select the highest priority task (from top to bottom), assume the required role, and execute the task adhering strictly to the `AGENTS.md` guidelines (TDD, zero allocations per frame).

Phase 1 (Core ECS, Spatial Hash, Rendering) has been successfully completed.

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

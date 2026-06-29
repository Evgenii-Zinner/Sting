# Sting Engine Backlog

This backlog breaks down the Sting Engine roadmap into highly granular tasks. AI Agents should select the highest priority task (from top to bottom), assume the required role, and execute the task adhering strictly to the `AGENTS.md` guidelines (TDD, zero allocations per frame).

Phase 1 through Phase 5 have been successfully completed and reviewed by the AI Architector. The engine is fully operational with DOD ECS, zero-allocation physics, spatial hashing, batch rendering, tilemaps, and particle systems.

## Upcoming Milestones (Phase 7)

*Note: Phase 7 will focus on Audio Enhancements, Game State Management, and preparing core logic systems. Following Phase 7, it is estimated that roughly 1-2 more phases (like Phase 8 for Prototype Assembly) will be needed to complete the first full game prototype.*

## 20. Audio Enhancements

* [ ] **Task 20.1: Extended Audio Event Queue**
  * **Role Needed:** Audio Engineer
  * **Skill:** `skills/audio_engineer.json`
  * **Description:** Upgrade the `Int32List` audio event queue to support additional playback parameters like `volume`, `pitch`, and `loop` status using integer encoding (fixed-point math or bitpacking) to stay within primitive array bounds.
  * **Acceptance Criteria:** Audio dispatcher handles enhanced parameters without heap allocations. 100% test coverage.

## 21. Game State Management

* [ ] **Task 21.1: Game State Component & System**
  * **Role Needed:** Gameplay Logic Engineer
  * **Skill:** `skills/gameplay_engineer.json`
  * **Description:** Implement a global state component (e.g., via a singleton entity or state flag) and a system to manage high-level game states (Menu, Playing, Paused, GameOver). Ensure systems can pause updates based on state.
  * **Acceptance Criteria:** The engine can smoothly transition between states and pause game logic without GC allocations. 100% test coverage.

## Completed Phase 6 Tasks

## 17. Audio System

* [x] **Task 17.1: Audio Event Queue**
  * **Role Needed:** Audio Engineer
  * **Skill:** `skills/audio_engineer.json`
  * **Description:** Implement a flat `Int32List`-based ring buffer for dispatching sound events without instantiating `SoundEvent` objects per frame.
  * **Acceptance Criteria:** Audio dispatcher handles multi-voice queuing strictly within primitive bounds. 100% test coverage.

* [x] **Task 17.2: Audio System Processing**
  * **Role Needed:** Audio Engineer
  * **Skill:** `skills/audio_engineer.json`
  * **Description:** Implement an `AudioSystem` that reads from the audio event queue and interacts with a low-level audio package or FFI bindings. Map pre-allocated playback handles to entities.
  * **Acceptance Criteria:** The system can process queued audio events in bulk without heap allocations. 100% test coverage.

## 18. UI Framework

* [x] **Task 18.1: UI Bounding Box System**
  * **Role Needed:** UI Rendering Engineer
  * **Skill:** `skills/ui_rendering_engineer.json`
  * **Description:** Expand the UI subsystem with screen-space AABB tracking (`UICaste`) linked to pointer slots to detect button presses without Flutter gestures.
  * **Acceptance Criteria:** Accurately routes pointer events to UI component intersections using zero-allocation logic mapped to screen coordinates. 100% test coverage.

* [x] **Task 18.2: Complex UI Rendering**
  * **Role Needed:** UI Rendering Engineer
  * **Skill:** `skills/ui_rendering_engineer.json`
  * **Description:** Extend UI rendering to support interactive elements (buttons, panels) using cached `ParagraphBuilder` and `Path` objects. Elements should only rebuild upon state changes (dirty-flagged).
  * **Acceptance Criteria:** UI elements render correctly and only re-allocate when explicitly flagged as dirty. 100% test coverage.

## 19. Asset Management and Streaming

* [x] **Task 19.1: Chunk-Based Asset Manager**
  * **Role Needed:** Asset Streaming Engineer
  * **Skill:** `skills/asset_streaming_engineer.json`
  * **Description:** Implement a chunk-based memory manager for streaming large sprite sheets and maps instead of loading them fully into memory upfront.
  * **Acceptance Criteria:** Can load and unload chunks into memory dynamically based on spatial requirements. 100% test coverage.

* [x] **Task 19.2: Isolate-Based Asset Streaming**
  * **Role Needed:** Asset Streaming Engineer
  * **Skill:** `skills/asset_streaming_engineer.json`
  * **Description:** Implement asset streaming via background isolates, passing raw pixel buffers using `TransferableTypedData` into the main isolate. Use `decodeImageFromPixels` to construct images to avoid main thread blocking.
  * **Acceptance Criteria:** Assets stream seamlessly without causing GC pauses or stuttering on the main thread. 100% test coverage.

## Completed Phase 5 Tasks

## 15. Tilemap System

* [x] **Task 15.1: Tilemap Component**
  * **Role Needed:** Tilemap Engineer
  * **Skill:** `skills/tilemap_engineer.json`
  * **Description:** Create an ECS component (`Tilemap`) to manage tile layout and metadata. This should use a flat array structure, such as `Int32List`, to store tile types and maintain zero allocations per frame.
  * **Acceptance Criteria:** `Tilemap` component works with `ComponentCaste`. 100% test coverage. Zero allocations.

* [x] **Task 15.2: Tilemap Render System**
  * **Role Needed:** Tilemap Engineer
  * **Skill:** `skills/tilemap_engineer.json`
  * **Description:** Implement a `TilemapRenderSystem` that iterates over the `Tilemap` component array and draws tiles to the canvas effectively using `dart:ui` without per-frame object instantiation.
  * **Acceptance Criteria:** Tiles render correctly based on layout data. 100% test coverage. Zero allocations per frame.

## 16. Particle System

* [x] **Task 16.1: Particle Emitter Component**
  * **Role Needed:** Particle Engineer
  * **Skill:** `skills/particle_engineer.json`
  * **Description:** Create an ECS component (`ParticleEmitter`) utilizing flat TypedData arrays (like `Float32List`, `Int32List`) to store state (positions, velocities, colors, lifespans) for massive amounts of particles efficiently.
  * **Acceptance Criteria:** Component works with `ComponentCaste` and uses flat arrays for particle state. 100% test coverage. Zero allocations per frame.

* [x] **Task 16.2: Particle System Update & Render**
  * **Role Needed:** Particle Engineer
  * **Skill:** `skills/particle_engineer.json`
  * **Description:** Implement a `ParticleSystem` to update particle physics/lifespans and render them rapidly (e.g., via batching). Avoid creating any per-particle objects during the update and render loops.
  * **Acceptance Criteria:** Particles update and render based on emitter configuration. 100% test coverage. Zero allocations per frame.

## Completed Phase 4 Tasks

## 13. Camera System

* [x] **Task 13.1: Viewport Component**
  * **Role Needed:** Camera Engineer
  * **Skill:** `skills/camera_engineer.json`
  * **Description:** Create an ECS component (`Viewport`) mapped to a `Float32List` to store camera offsets (x, y) and zoom level.
  * **Acceptance Criteria:** `Viewport` component works with `ComponentCaste`. 100% test coverage. Zero allocations.

* [x] **Task 13.2: Camera System**
  * **Role Needed:** Camera Engineer
  * **Skill:** `skills/camera_engineer.json`
  * **Description:** Implement a `CameraSystem` that updates the `Viewport` based on a target entity's `Position`. Ensure it integrates smoothly with `SpriteRenderSystem` to offset the rendered world.
  * **Acceptance Criteria:** The rendered world shifts according to the camera's coordinates without instantiating objects per frame. 100% test coverage.

## 14. Basic UI Rendering

* [x] **Task 14.1: TextRender Component**
  * **Role Needed:** UI Rendering Engineer
  * **Skill:** `skills/ui_rendering_engineer.json`
  * **Description:** Create an ECS component (`TextRender`) to store basic text string references (like scores or labels) alongside position properties for screen-space rendering.
  * **Acceptance Criteria:** Component is efficiently structured. 100% test coverage. Zero allocations per frame.

* [x] **Task 14.2: Text Render System**
  * **Role Needed:** UI Rendering Engineer
  * **Skill:** `skills/ui_rendering_engineer.json`
  * **Description:** Implement a `TextRenderSystem` that uses `dart:ui.ParagraphBuilder` to draw `TextRender` components directly to the canvas, overriding world coordinates to stay static on screen.
  * **Acceptance Criteria:** Text is rendered to the screen efficiently using `dart:ui` only. 100% test coverage.

## Completed Phase 3 Tasks

## 10. Sprite Animation System

* [x] **Task 10.1: SpriteAnimation Component**
  * **Role Needed:** Animation Engineer
  * **Skill:** `skills/animation_engineer.json`
  * **Description:** Create an ECS component (`SpriteAnimation`) mapped to a `Float32List` that holds animation state (current frame index, frame duration, elapsed time).
  * **Acceptance Criteria:** `SpriteAnimation` component works with `ComponentCaste`. 100% test coverage. Zero allocations.

* [x] **Task 10.2: Animation System**
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

## Completed Phase 2 Tasks

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

## Completed Phase 1 Tasks

* [x] **Setup raw `dart:ui` window hook**
* [x] **Implement basic Entity ID generator and Component storage (Sparse set)**
* [x] **Implement Query engine**
* [x] **Implement Render System (Sprite Component + `drawAtlas`)**
* [x] **Implement spatial hashing for basic bounds checking**

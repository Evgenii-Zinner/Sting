# Sting Engine Backlog

This backlog breaks down the Sting Engine roadmap into highly granular tasks. AI Agents should select the highest priority task (from top to bottom), assume the required role, and execute the task adhering strictly to the `AGENTS.md` guidelines (TDD, zero allocations per frame).

Phase 1 through Phase 7 have been successfully completed and reviewed by the AI Architector. The engine is fully operational with DOD ECS, zero-allocation physics, spatial hashing, batch rendering, tilemaps, particle systems, audio event queuing, and high-level game state management.

## Upcoming Milestones (Phase 8: Prototype Assembly / Showcase)

*Note: The engine core is deemed mature and ready for game development. Phase 8 will focus on assembling a Bullet Haven game showcase using the engine's public APIs. No core engine changes are anticipated, only game-specific logic construction.*

## 22. MVP: Bullet Haven Prototype

* [x] **Task 22.1: Asset Generation Script**
  * **Role Needed:** Asset Generator
  * **Skill:** `skills/asset_generator.json`
  * **Description:** Create standalone scripts to procedurally generate placeholder graphic assets (sprite sheets for player, enemies, projectiles, and tilemaps).
  * **Acceptance Criteria:** Scripts can be executed to output necessary PNG files suitable for engine consumption.

* [x] **Task 22.2: MVP Game Setup & Game State**
  * **Role Needed:** Gameplay Scripter
  * **Skill:** `skills/gameplay_scripter.json`
  * **Description:** Set up the main entry point for the showcase game inside `showcase/`. Configure the initial global state (Menu, Playing) and initialize necessary ECS systems strictly using the public engine API.
  * **Acceptance Criteria:** Game launches into a functional Menu state and transitions into Playing state correctly. 100% test coverage.

* [x] **Task 22.3: Player Prefab & Movement**
  * **Role Needed:** Gameplay Scripter
  * **Skill:** `skills/gameplay_scripter.json`
  * **Description:** Assemble a player character using existing prefabs/components. Hook up input handling using the engine's raw pointer input system to move the player correctly.
  * **Acceptance Criteria:** Player entity moves smoothly according to input on screen. Zero per-frame allocations during movement. 100% test coverage.

* [x] **Task 22.4: Enemy Spawner System**
  * **Role Needed:** Gameplay Scripter
  * **Skill:** `skills/gameplay_scripter.json`
  * **Description:** Create a logic system to spawn enemy entities at intervals outside the viewport, tracking towards the player.
  * **Acceptance Criteria:** Enemies spawn correctly and move towards the player without causing GC spikes. 100% test coverage.

* [x] **Task 22.5: Auto-Firing Logic**
  * **Role Needed:** Gameplay Scripter
  * **Skill:** `skills/gameplay_scripter.json`
  * **Description:** Implement auto-firing logic for the player. Find the nearest enemy and instantiate projectile prefabs aimed in their direction.
  * **Acceptance Criteria:** Projectiles are fired correctly based on intervals and target proximity. Zero allocations during firing. 100% test coverage.

* [x] **Task 22.6: Damage & Score UI**
  * **Role Needed:** Gameplay Scripter
  * **Skill:** `skills/gameplay_scripter.json`
  * **Description:** Hook up collision resolution to apply damage to enemies/player. Manage death states, update score, and render the score via the UI Bounding Box System.
  * **Acceptance Criteria:** Health depletes correctly, scores update, and UI renders changes efficiently. 100% test coverage.

## 23. Engine Stabilization & Visual Regression (Phase 9)

* [x] **Task 23.1: Audit Engine Subsystems**
  * **Role Needed:** AI Orchestrator / QA SDET Engineer
  * **Skill:** `skills/qa_sdet_engineer.json`
  * **Description:** Audit existing subsystems, especially components and rendering logic written during the on-the-fly MVP creation, to ensure they strictly adhere to our zero-allocation standards. Revert or formalize any temporary hacks into proper Engine APIs.
  * **Acceptance Criteria:** Engine code strictly complies with `AGENTS.md` rules.

* [x] **Task 23.2: E2E Deterministic Setup**
  * **Role Needed:** E2E Test Engineer
  * **Skill:** `skills/e2e_test_engineer.json`
  * **Description:** Update `test_main.dart` to freeze RNG seeds entirely, disable random enemy spawners, and manually place key entities (player, enemies, gems) at exact coordinates so the simulation always resolves to an identical state. Expand `getGameState` JS interop to expose these elements.
  * **Acceptance Criteria:** Repeated runs of `test_main.dart` produce the exact same internal positions down to the float precision.

* [x] **Task 23.3: Playwright Visual Regression Tests**
  * **Role Needed:** E2E Test Engineer
  * **Skill:** `skills/e2e_test_engineer.json`
  * **Description:** Implement the actual Playwright tests inside `test/e2e/`. The tests should await the `<flutter-view>`, call the `getGameState()` JS function to assert logic is correct, and capture visual snapshots of the canvas to serve as visual contracts for future engine updates.
  * **Acceptance Criteria:** `npx playwright test` succeeds consistently on CI/CD with valid snapshot verifications.

## Completed Phase 7 Tasks

## 20. Audio Enhancements

* [x] **Task 20.1: Extended Audio Event Queue**
  * **Role Needed:** Audio Engineer
  * **Skill:** `skills/audio_engineer.json`
  * **Description:** Upgrade the `Int32List` audio event queue to support additional playback parameters like `volume`, `pitch`, and `loop` status using integer encoding (fixed-point math or bitpacking) to stay within primitive array bounds.
  * **Acceptance Criteria:** Audio dispatcher handles enhanced parameters without heap allocations. 100% test coverage.

## 21. Game State Management

* [x] **Task 21.1: Game State Component & System**
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

## 20. Cross-Platform & Web Support (Phase 9)

* [x] **Task 20.1: Base64 Asset Embedding**
  * **Role Needed:** Cross Platform Engineer
  * **Skill:** `skills/cross_platform_engineer.json`
  * **Description:** Create a tool in `tools/` that converts all showcase assets (PNGs, etc.) into Dart files containing base64 string constants. Modify `AssetLoader` to decode these strings via `base64Decode` and `instantiateImageCodec` if `dart:io` is unavailable (e.g., on Web), bypassing isolates and file system access.
  * **Acceptance Criteria:** Assets load successfully on Flutter Web using embedded strings. 100% test coverage.

* [x] **Task 20.2: Fixed Timestep Game Loop**
  * **Role Needed:** Cross Platform Engineer
  * **Skill:** `skills/cross_platform_engineer.json`
  * **Description:** Refactor the `Time` system and engine loop to use a fixed timestep accumulator (e.g., 60 updates per second) to decouple logic updates from the variable `onBeginFrame` refresh rate, ensuring deterministic physics across 60Hz and 120Hz devices.
  * **Acceptance Criteria:** Physics and movement logic run deterministically regardless of the actual frame rate. 100% test coverage.

* [x] **Task 20.3: Virtual Resolution and Aspect Ratio Scaling**
  * **Role Needed:** Cross Platform Engineer
  * **Skill:** `skills/cross_platform_engineer.json`
  * **Description:** Implement a virtual resolution system in the rendering pipeline. The canvas must scale to fit the physical device dimensions while maintaining a fixed aspect ratio (via letterboxing/pillarboxing) so the game renders identically across all screens.
  * **Acceptance Criteria:** Game renders consistently on different screen sizes and ratios. 100% test coverage.

* [x] **Task 20.4: E2E Visual Testing with Playwright**
  * **Role Needed:** QA Engineer
  * **Skill:** `skills/qa_engineer.json`
  * **Description:** Setup an E2E testing environment using Playwright (via a `package.json` and a test script in `test/e2e/`). The test should launch a local web server serving the compiled web build, load the canvas, and capture a visual snapshot to compare against a baseline. Tests must explicitly ensure visibility and proper rendering of the player, UI elements, ground tiles, and enemies.
  * **Acceptance Criteria:** Playwright tests successfully run, capture canvas snapshots, verify rendering of player, UI, tiles, and enemies, and fail on visual regressions.

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

## 24. Integration Testing Pivot (Phase 10)

* [x] **Task 24.1: Cleanup E2E Artifacts**
  * **Role Needed:** QA Engineer
  * **Skill:** `skills/qa_engineer.json`
  * **Description:** Remove the problematic Playwright E2E environment. Delete `playwright.config.ts`, `package.json`, `package-lock.json`, the `test/e2e/` directory, `showcase/lib/test_main.dart`, and `docs/E2E_TESTING_GUIDE.md`. The focus is shifting to programmatic internal integration tests rather than visual snapshots.
  * **Acceptance Criteria:** E2E files are successfully removed from the repository.

* [x] **Task 24.2: Robust Subsystem Integration Testing**
  * **Role Needed:** QA SDET Engineer
  * **Skill:** `skills/qa_sdet_engineer.json`
  * **Description:** Write programmatic internal integration tests (e.g. using `flutter_test` and `MockCanvas`) to verify the ECS pipeline, physics updates, and rendering output directly. This avoids the flakiness of rendering against an opaque `<flutter-view>` canvas and guarantees correct internal states.
  * **Acceptance Criteria:** A new suite of robust integration tests is implemented in `test/`, successfully covering core game logic and render pipeline callbacks. 100% pass rate.

## 25. Advanced N-Body Physics Engine (Phase 11)

* [x] **Task 25.1: Gravitational Components**
  * **Role Needed:** Astrophysics Engineer
  * **Skill:** `skills/astrophysics_engineer.json`
  * **Description:** Create necessary ECS components such as `Mass` to work alongside `Position` and `Velocity`. These components must be mapped to flat array structures (`Float32List`) maintaining zero-allocation constraints.
  * **Acceptance Criteria:** `Mass` component works with `ComponentCaste`. 100% test coverage. Zero allocations.

* [x] **Task 25.2: Zero-Allocation Barnes-Hut Quadtree**
  * **Role Needed:** Astrophysics Engineer
  * **Skill:** `skills/astrophysics_engineer.json`
  * **Description:** Implement a Quadtree spatial partitioning data structure using purely flat arrays (`Int32List`, `Float32List`) to store node bounds, centers of mass, total mass, and indices, without instantiating objects per node.
  * **Acceptance Criteria:** Quadtree accurately subdivides space and summarizes masses. Zero object instantiations per frame. 100% test coverage.

* [x] **Task 25.3: Gravity System Implementation**
  * **Role Needed:** Astrophysics Engineer
  * **Skill:** `skills/astrophysics_engineer.json`
  * **Description:** Create a System that builds the Quadtree every frame and applies the Barnes-Hut algorithm to calculate and apply gravitational forces to the `Velocity` of all interacting bodies.
  * **Acceptance Criteria:** 1,000+ entities exhibit correct gravitational attraction. Time complexity is O(N log N). Zero per-frame allocations during the update loop. 100% test coverage.

## 26. Star System Showcase MVP (Phase 12)

* [x] **Task 26.1: Star System Simulation & Logic Setup**
  * **Role Needed:** Gameplay Scripter
  * **Skill:** `skills/gameplay_scripter.json`
  * **Description:** Create a new showcase game in a dedicated directory (`showcase_starsystem/`) to demonstrate the new N-Body physics mechanics. Utilize `GravitySystem`, `MovementSystem`, `SpriteRenderSystem`, and `GameStateSystem`. Implement logic to spawn an initial central star and some orbiting planets.
  * **Acceptance Criteria:** Showcase successfully initializes and simulates multiple orbiting celestial bodies using the new `Mass` component and `GravitySystem`. Must strictly use existing public APIs without modifying the core engine `lib/`. 100% test coverage for app-level systems. Zero per-frame allocations.

* [x] **Task 26.2: Interactive Configuration and Spawner UI**
  * **Role Needed:** UI Rendering Engineer
  * **Skill:** `skills/ui_rendering_engineer.json`
  * **Description:** Implement interactive UI components using `ComplexUI` and `UIBoundingBox` within the Star System showcase. The UI must allow the player to add new bodies (planets or asteroids) and tweak their initial velocities or masses to see how they affect the star system.
  * **Acceptance Criteria:** User can interact with UI elements on screen to dynamically spawn new entities with `Mass`, `Position`, and `Velocity`. UI interaction must correctly use the `UISystem` without Flutter widgets. Zero per-frame allocations during the render loop.

## 27. Phase 13: Popular Engine Features & Quality of Life

* [x] **Task 27.1: Parallax Scrolling System**
  * **Role Needed:** Rendering Engineer
  * **Skill:** `skills/rendering_engineer.json`
  * **Description:** Implement a zero-allocation parallax scrolling background system, enabling multiple layers with different scroll speeds relative to the main viewport.
  * **Acceptance Criteria:** Parallax layers scroll seamlessly without per-frame memory allocation. 100% test coverage.

* [x] **Task 27.2: Virtual Joypad UI Component**
  * **Role Needed:** UI Rendering Engineer
  * **Skill:** `skills/ui_rendering_engineer.json`
  * **Description:** Implement a built-in virtual joypad system for touchscreens using `ComplexUI` and `UIBoundingBox`. It must translate raw multi-touch screen coordinates into normalized analog vectors.
  * **Acceptance Criteria:** Virtual joypad correctly tracks thumb movement, normalizes vectors, and avoids object instantiations per touch event. 100% test coverage.

* [x] **Task 27.3: Auto-Detect Control Schemes & Input Mapping**
  * **Role Needed:** Input Engineer
  * **Skill:** `skills/input_engineer.json`
  * **Description:** Implement an Input Mapping system that auto-detects available input sources (keyboard, mouse, physical gamepad, touch/virtual joypad) across all cross-platform targets and automatically applies the appropriate control scheme bindings without per-frame allocations.
  * **Acceptance Criteria:** System dynamically adapts to available physical inputs and maps them to abstract game actions seamlessly. 100% test coverage.

* [x] **Task 27.4: Ultra-Fast 2D Lighting (No Raytracing)**
  * **Role Needed:** Rendering Engineer
  * **Skill:** `skills/rendering_engineer.json`
  * **Description:** Introduce a high-performance 2D lighting system avoiding expensive raytracing. Explore using 1D shadow mapping or fast polygonal shadow casting techniques (e.g. self-transparent shadow meshes) combined with `dart:ui` custom shaders, maintaining single-batch atlas rendering efficiency.
  * **Acceptance Criteria:** Real-time 2D lights and shadows render extremely fast without per-frame GC allocations or standard raycasting performance hits. 100% test coverage.

## 28. Phase 13 Showcase Integration

* [x] **Task 28.1: Bullet Haven Showcase Integration**
  * **Role Needed:** Gameplay Scripter
  * **Skill:** `skills/gameplay_scripter.json`
  * **Description:** Integrate `ParallaxSystem`, `VirtualJoypadSystem`, and `InputMappingSystem` into the Bullet Haven showcase (`showcase/lib/main.dart`). Use existing components and engine public APIs to implement parallax background, touch virtual joypad controls, and input mapping correctly.
  * **Acceptance Criteria:** The Bullet Haven showcase utilizes the newly implemented engine features correctly. 100% test coverage.

* [x] **Task 28.2: Star System Showcase Integration**
  * **Role Needed:** Gameplay Scripter
  * **Skill:** `skills/gameplay_scripter.json`
  * **Description:** Integrate `ParallaxSystem`, `VirtualJoypadSystem`, and `InputMappingSystem` into the Star System showcase (`showcase_starsystem/lib/main.dart`). Use existing components and engine public APIs to implement parallax background, touch virtual joypad controls for camera, and input mapping appropriately.
  * **Acceptance Criteria:** The Star System showcase utilizes the newly implemented engine features correctly. 100% test coverage.

* [x] **Task 28.3: Showcase Integration & System Tests**
  * **Role Needed:** QA SDET Engineer
  * **Skill:** `skills/qa_sdet_engineer.json`
  * **Description:** Write programmatic internal integration and system tests for the `showcase` and `showcase_starsystem` targets. Ensure that the integrated `ParallaxSystem`, `VirtualJoypadSystem`, and `InputMappingSystem` operate correctly in tandem with the core game loop and ECS state without UI flakiness.
  * **Acceptance Criteria:** Comprehensive integration and system tests are implemented for both showcases, verifying accurate rendering offsets, proper touch input vector mapping, and correct control scheme adaptation. 100% test coverage for integration points.

## 29. Phase 14: Advanced Features, Tooling & Production Readiness

* [x] **Task 29.1: World-Space Anchored UI (Immersive UI)**
  * **Role Needed:** Gameplay UI Engineer
  * **Skill:** `skills/gameplay_ui_engineer.json`
  * **Description:** Implement a world-space UI component (e.g. `WorldUI`) and rendering system that translates entity world coordinates to viewport screen-space coordinates, enabling floating health bars, damage numbers, and indicators that track moving objects without per-frame allocations.
  * **Acceptance Criteria:** Floating UI elements correctly track world-space moving entities on screen. Zero per-frame allocations during movement and rendering. 100% test coverage.

* [x] **Task 29.2: Component Extension Type Code Generator**
  * **Role Needed:** Tooling Engineer
  * **Skill:** `skills/tooling_engineer.json`
  * **Description:** Develop a command-line utility in `tools/` that parses a simplified component schema (JSON or YAML) and automatically generates the zero-allocation Dart 3 extension types on typed arrays (`Float32List`, `ByteData`), reducing manual boilerplate and index offset mistakes.
  * **Acceptance Criteria:** Tool successfully parses schemas and generates valid, lint-clean Dart files. Generated components operate correctly with Caste storage. 100% test coverage for parser and generator logic.

* [x] **Task 29.3: Dedicated Memory Architecture & Limits Guide**
  * **Role Needed:** Systems Architect
  * **Skill:** `skills/systems_architect.json`
  * **Description:** Write a detailed document `docs/MEMORY_LIMITS.md` explaining Sting's static memory model, the Swarm max entity count (65,535), Caste preallocation constraints, memory reuse patterns, and best practices for sizing component caches during game startup.
  * **Acceptance Criteria:** Documentation is clear, accurate, matches the codebase limits, and is stored in `docs/MEMORY_LIMITS.md`.

* [x] **Task 29.4: Cross-Platform Native Audio Integration**
  * **Role Needed:** Audio Engineer
  * **Skill:** `skills/audio_engineer.json`
  * **Description:** Replace the static mocked `AudioBindings` with a real cross-platform audio player backend (e.g., integrating `soloud` or another FFI/native audio library) that consumes the flat bit-packed audio queue without per-frame heap allocations.
  * **Acceptance Criteria:** Real audio files are loaded and played on multiple platforms (iOS, Android, Web, Windows/macOS) directly consuming the preallocated ring buffer. Zero per-frame allocations. 100% test coverage.

## 30. Phase 15: General-Purpose Simulator & AI Systems

* [x] **Task 30.1: Hexagonal Grid Mathematics Library**
  * **Role Needed:** Hex Grid Engineer
  * **Skill:** `skills/hex_grid_engineer.json`
  * **Description:** Implement axial hexagonal math utilities in `lib/engine/math/hex_math.dart`. Include conversions `gridToWorld` and `worldToGrid` for pointy-topped and flat-topped hexagons, `hexDistance` calculations, and neighbor lookups.
  * **Acceptance Criteria:** Math library functions operate without allocations, returning correct coordinates and distances. 100% test coverage.

* [x] **Task 30.2: HexTilemap Component**
  * **Role Needed:** Hex Grid Engineer
  * **Skill:** `skills/hex_grid_engineer.json`
  * **Description:** Create an ECS component `HexTilemap` in `lib/engine/components/hex_tilemap.dart` backed by a flat `Int32List` array. Implement 1D index mapping coordinates `(q, r)` offset by the radius.
  * **Acceptance Criteria:** Component works with `ComponentCaste`. 100% test coverage. Zero allocations.

* [x] **Task 30.3: HexTilemap Render System**
  * **Role Needed:** Hex Grid Engineer
  * **Skill:** `skills/hex_grid_engineer.json`
  * **Description:** Implement a `HexTilemapRenderSystem` in `lib/engine/systems/hex_tilemap_render_system.dart`. Use `Canvas.drawRawAtlas` with pre-allocated Float32List transform and rect arrays to translate axial coordinates into pointy-topped hexes.
  * **Acceptance Criteria:** Batched hexagonal grid renders correctly without any heap allocations. 100% test coverage.

* [x] **Task 30.4: Circular MovementQueue Component**
  * **Role Needed:** AI & Pathfinding Engineer
  * **Skill:** `skills/ai_pathfinding_engineer.json`
  * **Description:** Create a component `MovementQueue` in `lib/engine/components/movement_queue.dart` representing a waypoint queue backed by a flat circular `Int32List`.
  * **Acceptance Criteria:** Waypoints can be enqueued/dequeued correctly without per-frame allocations. 100% test coverage.

* [ ] **Task 30.5: A* Grid Pathfinder System**
  * **Role Needed:** AI & Pathfinding Engineer
  * **Skill:** `skills/ai_pathfinding_engineer.json`
  * **Description:** Implement `GridPathfinder` inside `lib/engine/systems/pathfinding_system.dart` which solves A* routes on both rectangular and hexagonal grid structures and writes the path directly to the `MovementQueue`. Use pre-allocated static node pools.
  * **Acceptance Criteria:** System calculates paths correctly without per-frame allocations. 100% test coverage.

* [ ] **Task 30.6: Utility AI Component**
  * **Role Needed:** AI & Pathfinding Engineer
  * **Skill:** `skills/ai_pathfinding_engineer.json`
  * **Description:** Create a component `UtilityAI` in `lib/engine/components/utility_ai.dart` storing task ID, target entity, parameter coordinates, and parallel Float32List slices for tension and damping.
  * **Acceptance Criteria:** Component integrates with `ComponentCaste` and uses flat buffers. 100% test coverage. Zero allocations.

* [ ] **Task 30.7: Utility AI Bidding System**
  * **Role Needed:** AI & Pathfinding Engineer
  * **Skill:** `skills/ai_pathfinding_engineer.json`
  * **Description:** Implement a `UtilityAISystem` in `lib/engine/systems/utility_ai_system.dart` to calculate actions utility bids, update tension/damping arrays, and update the active task ID with hysteresis.
  * **Acceptance Criteria:** Decision engine updates active tasks and handles bids without heap allocations. 100% test coverage.

* [ ] **Task 30.8: Cross-Platform Shader Asset Loader**
  * **Role Needed:** Graphics Pipeline Engineer
  * **Skill:** `skills/graphics_pipeline_engineer.json`
  * **Description:** Implement fragment shader asset loading in `AssetLoader` on both Native and Web platforms. On Web, support fetching shader programs asynchronously using HTTP or loading from embedded base64 strings to ensure complete platform compatibility.
  * **Acceptance Criteria:** Programs load correctly on all target environments (native and Web/CanvasKit). 100% test coverage.

* [ ] **Task 30.9: ShaderMaterial Component & Custom Uniforms**
  * **Role Needed:** Graphics Pipeline Engineer
  * **Skill:** `skills/graphics_pipeline_engineer.json`
  * **Description:** Create a `ShaderMaterial` component in `lib/engine/components/shader_material.dart` storing the shader program and a contiguous `Float32List` uniforms buffer.
  * **Acceptance Criteria:** Component wraps shader states and uniform slices. 100% test coverage. Zero allocations.

* [ ] **Task 30.10: Batched Shader Render System Integration**
  * **Role Needed:** Graphics Pipeline Engineer
  * **Skill:** `skills/graphics_pipeline_engineer.json`
  * **Description:** Integrate `ShaderMaterial` into the batch render systems (e.g. `SpriteRenderSystem` or a custom system) to bind uniforms and apply custom shaders to the canvas paint brush during render calls.
  * **Acceptance Criteria:** Shaders render custom visual effects without per-frame allocations. 100% test coverage.

* [x] **Task 30.11: GridDiffusion Component & System**
  * **Role Needed:** Simulation Engineer
  * **Skill:** `skills/simulation_engineer.json`
  * **Description:** Create `GridDiffusion` component and `DiffusionSystem` to compute numerical cellular diffusion (heat/gas dispersion) on rectangular and hexagonal grids using double-buffered float lists.
  * **Acceptance Criteria:** Diffusion updates correctly without causing per-frame allocations. 100% test coverage.

* [ ] **Task 30.12: Porting Showcase Integration & Subsystem Tests**
  * **Role Needed:** QA SDET Engineer
  * **Skill:** `skills/qa_sdet_engineer.json`
  * **Description:** Write comprehensive integration tests verifying the interaction of the new hexagonal tilemaps, pathfinding queue, utility AI decision engine, and diffusion/shader pipelines in tandem.
  * **Acceptance Criteria:** Test suite executes successfully, verifying correct behavior and confirming zero allocations per frame. 100% pass rate.




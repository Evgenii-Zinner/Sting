# Architecture FAQ

Welcome to the Sting Engine Architecture FAQ. Please review these questions and answers before beginning work or asking architectural questions to the user.

## Core Concepts

### Q: Why is the engine named "Sting"?
**A:** The engine bypasses the typical Flutter widget tree (`runApp`, `BuildContext`, etc.) entirely. It works directly with `dart:ui` (`PlatformDispatcher`, `Canvas`, etc.). The name "Sting" refers to the engine's ability to inject a game directly "under" the widgets, operating closer to the bare metal. Because of this, many core components use insect/bug-themed naming conventions.

### Q: What is the "Zero Allocations per Frame" rule?
**A:** Dart uses a Garbage Collector (GC). If you create new objects inside the main update or render loops, the GC will eventually need to clean them up. This causes GC pauses (stutters) that ruin 60/120 FPS game experiences.
**Rule:** You must *never* instantiate new objects inside loops that run every frame.
* Use pre-allocated pools.
* Use `Float32List`, `Int32List`, and other `TypedData` structures instead of Lists of objects.
* Use Dart 3 records for multiple returns and lightweight data passing, as they don't allocate on the heap.

### Q: Why do we use `dart:ui` directly instead of Flutter widgets?
**A:** Flutter widgets carry significant overhead meant for building responsive UIs, not for rendering tens of thousands of moving entities every frame. By using `dart:ui` directly (specifically `Canvas.drawAtlas` for sprites), Sting talks almost directly to Impeller/Skia, maximizing rendering performance.

## Entity Component System (ECS)

### Q: What is `EntityManager` (formerly `Swarm`)?
**A:** `EntityManager` is Sting's Entity Manager.
* Entities are strictly integers (`int`). There is no `Entity` object.
* `EntityManager` manages the allocation and recycling of these integer IDs.
* It is constrained to `Int16` limits (65,535 max entities) to cap memory usage.
* It uses a `Uint32List` of bit-flags to track entity liveness (1 bit per entity). This enables fast, O(1) liveness checks and prevents double frees without creating any objects.

### Q: What is `SparseSet` and `ComponentStorage` (formerly `Caste`)?
**A:** `SparseSet` is Sting's Sparse Set implementation for component index mapping, and `ComponentStorage<T>` couples a `SparseSet` with dense typed data arrays.
* It maps sparse entity IDs to dense component array indices.
* It uses `Uint16List` arrays for maximum memory efficiency, since entity limits are `Int16`.

### Q: Why does `SparseSet` use the Briggs & Torczon validation technique?
**A:** Traditional sparse sets initialize the sparse array with a sentinel value (like `-1`) to denote "empty". Briggs & Torczon validation uses an uninitialized sparse array and checks back against the dense array to verify validity.
* **Benefit:** It eliminates the need to initialize the sparse array or use sentinel values.
* **Benefit:** It makes clearing the entire set an O(1) operation—you simply reset the `count` of items to 0.

## Component Data

### Q: How should I store component data?
**A:** Components should be "flat". They should not contain logic. Where possible, use typed data arrays (`Float32List`, `Int32List`) aligned with the dense indices in the `Caste` to store component data. This provides excellent cache locality and avoids object allocation. Dart 3 extension types over typed arrays (`ByteData`, `Float32List`) are heavily used for multi-field components (like `Sprite`).

## Testing

### Q: I need to test a `dart:ui` rendering feature, but it's hard to verify exact pixels. What do I do?
**A:** Testing raw `dart:ui` logic (like Canvas drawing) can be difficult to verify visually in automated tests.
* The priority is to test that the execution completes without throwing exceptions or generating errors.
* Do not spend time generating dummy images for exact pixel verification unless explicitly required.
* Document any testing limitations related to rendering in the `shared_memories/rendering_limitations.json` file.

## Core Subsystems Overview

* **ECS Architecture:** `EntityManager` and `ComponentStorage` operate without per-frame allocations, utilizing Briggs & Torczon validation and contiguous array layout.
* **Query Engine:** Callback queries (`Query1`, `Query2`, `Query3`) process multi-component interactions directly over dense arrays without instantiating `Iterable` objects.
* **Rendering Subsystem:** `SpriteRenderSystem` packages internal flat arrays via `.sublistView()` directly into `Canvas.drawRawAtlas`. Texture loading relies on pure `dart:ui` raw images.
* **Broad-Phase Physics:** `SpatialHashGrid` limits bounds checking iterations safely with a 1D internal index hash from 2D coordinates.
* **Narrow-Phase Physics:** Accurate AABB and Circle intersections that accept primitive unboxed floats and heavily rely on `entityA >= entityB` early exits to eliminate duplicate checks.
* **Kinematics & Motion:** Eulerian and Verlet integration via `MovementSystem` querying `Position` and `Velocity` components directly over arrays.
* **Collision Resolution:** Positional separation (`SimpleResolutionSystem`) provides callbacks that hook into `CollisionSystem` for immediate reaction to overlapping queries.
* **Sprite Animations:** Managed via `SpriteAnimation` component and `AnimationSystem` updating sprite source rects over time.
* **Camera System:** Zero-allocation `Viewport` component backed by `Float32List` with a `CameraSystem` that properly transforms canvas rendering offsets.
* **Tilemap System:** High-throughput 2D tilemaps drawn using `Tilemap` component and `TilemapRenderSystem` using flat typed arrays.
* **Particle System:** Data-oriented particle emitter utilizing flat `Float32List`/`Int32List` arrays to drive massive particle counts without allocations.
* **Audio Dispatcher:** Flat queue (`Int32List`) ring-buffer audio event dispatcher supporting volume, pitch, and looping parameters without creating event objects.
* **Game State Management:** High-level game states (Menu, Playing, Paused, GameOver) managed via global state flags, enabling clean state transitions and selective subsystem pausing.
* **Asset Management & Streaming:** Chunk-based memory manager streaming asset data via background isolates, transferring raw pixel buffers to avoid main-thread blocking.

## Extended Subsystems & Modular Features

### 1. HeightMap & Continuous Terrain Queries
* **Component:** `HeightMap` (`lib/engine/components/height_map.dart`) backed by a flat `Float32List`.
* **Capabilities:** Supports arbitrary grid resolution, bilinear elevation sampling, and gradient/normal extraction across continuous coordinates without allocations.

### 2. Slope Kinematics & Incline Physics
* **Components:** `SlopeModifier` (`lib/engine/components/slope_modifier.dart`) storing friction, uphill drag, downhill acceleration, and sliding thresholds.
* **System:** `SlopePhysicsSystem` (`lib/engine/systems/slope_physics_system.dart`) queries `HeightMap`, `Position`, and `Velocity` to apply gravity sliding, deceleration on steep inclines, and slope deflection.

### 3. Asset Management & Cross-Platform Loading
* **Module:** `AssetManager` (`lib/engine/assets/asset_manager.dart`) and `AssetLoader` (`asset_loader_io.dart`, `asset_loader_web.dart`, `asset_loader_stub.dart`).
* **Design:** Provides zero-allocation runtime image lookup by key, platform-agnostic byte loading, and asynchronous texture cache management without Flutter's `AssetBundle`.

### 4. Interactive Draggable Windows & Buttons UI
* **Components:** `UIWindow` and `UIButton` (`lib/engine/components/ui_window.dart`, `ui_button.dart`).
* **System:** `UIWindowSystem` (`lib/engine/systems/ui_window_system.dart`).
* **Features:** Window drag bars with clamp bounds, hover/pressed state tracking, disabled button states, and zero-allocation immediate-mode canvas rendering with cached `Paint` objects.

### 5. Sci-Fi Radial Intent Dial UI
* **Component:** `RadialDial` (`lib/engine/components/radial_dial.dart`) storing active segment count, selection angle, deadzone radius, and active item state.
* **System:** `RadialDialSystem` (`lib/engine/systems/radial_dial_system.dart`) renders segmented radial wheels and maps analog/pointer angles to intent slots.

### 6. Zero-Allocation Progress Bar
* **Component:** `ProgressBar` (`lib/engine/components/progress_bar.dart`) storing 16 layout, color, and interpolation configurations directly in flat `Float32List`.
* **System:** `ProgressBarRenderSystem` (`lib/engine/systems/progress_bar_render_system.dart`) features smooth visual-value lag interpolation, world-space (over entity head) and screen-space rendering, and pixel-snapped rendering.

### 7. Tactical Radar & Minimap System
* **Component:** `RadarDisplay` (`lib/engine/components/radar_display.dart`) backed by `Float32List(10)` with a `Uint32List` view for 32-bit ARGB color precision.
* **System:** `RadarSystem` (`lib/engine/systems/radar_system.dart`) sweeps radar beams across entities and draws circular blips on a tactical minimap overlay without per-frame allocations.

### 8. Fog of War & Discovery Grid
* **Component:** `DiscoveryGrid` (`lib/engine/components/discovery_grid.dart`) backed by a flat `Uint8List` tracking exploration states (`0 = Unexplored`, `1 = Explored/Dim`, `2 = Visible`).
* **System:** `FogOfWarSystem` (`lib/engine/systems/fog_of_war_system.dart`) performs viewport-culled tile rendering and radius-based revelation around player entities.

### 9. Capsule Corridor Logistics & Flow Fields
* **Component:** `CapsuleCorridor` (`lib/engine/components/capsule_corridor.dart`) backed by `Float32List(11)` representing pill-shaped transport lanes with directional speed.
* **System:** `CapsuleCorridorSystem` (`lib/engine/systems/capsule_corridor_system.dart`) queries intersecting entities and accelerates them along the corridor line with zero allocations.

### 10. Ground Trail & Desire Path Feedback
* **Components:** `GroundTrailField`, `TrailEmitter`, `TrailFeedback` (`lib/engine/components/`).
* **System:** `GroundTrailSystem` (`lib/engine/systems/ground_trail_system.dart`) simulates cumulative foot-traffic wear on terrain with exponential decay and provides speed boost feedback when following established paths.


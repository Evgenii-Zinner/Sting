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

### Q: What is `Swarm`?
**A:** `Swarm` is Sting's Entity Manager.
* Entities are strictly integers (`int`). There is no `Entity` object.
* `Swarm` manages the allocation and recycling of these integer IDs.
* It is constrained to `Int16` limits (65,535 max entities) to cap memory usage.
* It uses a `Uint32List` of bit-flags to track entity liveness (1 bit per entity). This enables fast, O(1) liveness checks and prevents double frees without creating any objects.

### Q: What is `Caste`?
**A:** `Caste` is Sting's Sparse Set implementation for component storage. In the insect theme, a "caste" is a specific group within a swarm (e.g., all entities that have a `Position` component).
* It maps sparse entity IDs to dense component array indices.
* It uses `Uint16List` arrays for maximum memory efficiency, since entity limits are `Int16`.

### Q: Why does `Caste` use the Briggs & Torczon validation technique?
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

## Phase 1 Completions

* **ECS Architecture:** `Swarm` (Entity manager) and `Caste` (Component sparse set) operate without per-frame allocations, utilizing Briggs & Torczon validation and contiguous array layout.
* **Query Engine:** Callbacks are used over returning iterables to process multi-component interactions (`Query1`, `Query2`) to prevent allocations.
* **Rendering:** `SpriteRenderSystem` directly packages internal flat arrays via `.sublistView()` into `Canvas.drawRawAtlas`. No Flutter AssetBundle is needed, loading relies on dart:io raw images.
* **Physics (Broad Phase):** `SpatialHashGrid` limits bounds checking iterations safely with a 1D internal index hash from 2D coordinates.

## Phase 2 Completions

* **Game Loop & Time:** Uses `PlatformDispatcher.instance.onBeginFrame` to calculate a capped `dt` safely without Flutter Tickers.
* **Input System:** Uses `PlatformDispatcher.instance.onPointerDataPacket` mapped directly to `Float32List`/`Int32List` arrays for zero-allocation multi-touch tracking.
* **Kinematics:** Eulerian integration via `MovementSystem` querying `Position` and `Velocity` components directly over arrays.
* **Narrow-Phase Physics:** Accurate AABB and Circle intersections that accept primitive unboxed floats and heavily rely on `entityA >= entityB` early exits to eliminate duplicate checks.

## Phase 3 Completions

* **Sprite Animations:** Managed via `SpriteAnimation` component and `AnimationSystem` updating Sprite source rects over time.
* **Physics Resolution Integration:** Simple positional separation (`SimpleResolutionSystem`) provides callbacks that are hooked into the `CollisionSystem`. The resolution acts in immediate response to overlapping queries, removing the need for a massive unified "Physics System". Continuous Collision Detection (CCD) is intentionally omitted under the YAGNI principle for this iteration.
* **Scene Management / Spawning:** Implemented zero-allocation `Prefab` factories for clean entity assembly.

## Phase 4 Completions

* **Camera System:** Implemented a zero-allocation `Viewport` component using `Float32List` and a `CameraSystem` that properly transforms canvas rendering offsets to simulate a follow camera.
* **Basic UI Rendering:** Added `TextRender` component and `TextRenderSystem` which directly draws to `Canvas` using `dart:ui.ParagraphBuilder` while caching layouts strictly on state change to avoid per-frame allocations.

## Phase 5 Completions

* **Tilemap System:** Added support for drawing efficient tilemaps using `Tilemap` component and `TilemapRenderSystem` using flat arrays (`Int32List`).
* **Particle System:** Implemented a Data-Oriented particle emitter utilizing flat TypedData arrays to drive massive particle counts strictly avoiding per-frame allocations.

## Phase 6 Completions

* **Audio System:** Implemented an event-driven audio dispatcher built around flat queues (`Int32List`) without instantiating `SoundEvent` objects per frame. Note: Low-level audio is mocked using a static `AudioBindings` class due to the lack of an actual audio package.
* **Advanced UI Rendering Framework:** Extended UI beyond simple text to interactive elements using screen-space AABB collisions via `UICaste` and layered rendering via cached `ParagraphBuilder` and `Path` objects.
* **Asset Management and Streaming:** Built a chunk-based memory manager for streaming asset data via background isolates, using `TransferableTypedData` to pass raw pixels to the main thread for image construction (`decodeImageFromPixels`) to avoid blocking.

## Phase 7 Completions

* **Audio System Enhancements:** Upgraded the `Int32List` audio event queue to support additional playback parameters like volume, pitch, and loop using integer encoding.
* **Game State Management:** Implemented high-level game states (Menu, Playing, Paused, GameOver) utilizing a global state component and system, ensuring smooth state transitions and selective logic pausing without GC allocations.

## Phase 8 Details (Prototype Assembly / Showcase)
Phase 8 is currently in progress. The focus is on assembling a Bullet Haven MVP game showcase using the fully mature engine APIs. The engine core is considered feature-complete for MVP game development, and no internal modifications to the core `lib/` source code are permitted—only application-level logic built on top (e.g., inside `showcase/`). If an engine feature is discovered to be missing, it must be flagged for an engine developer rather than modifying the core during scripting. All placeholder assets are procedurally generated to avoid manual art dependencies.

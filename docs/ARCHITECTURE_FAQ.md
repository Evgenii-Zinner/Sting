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
**A:** Components should be "flat". They should not contain logic. Where possible, use typed data arrays (`Float32List`, `Int32List`) aligned with the dense indices in the `Caste` to store component data. This provides excellent cache locality and avoids object allocation.

## Testing

### Q: I need to test a `dart:ui` rendering feature, but it's hard to verify exact pixels. What do I do?
**A:** Testing raw `dart:ui` logic (like Canvas drawing) can be difficult to verify visually in automated tests.
* The priority is to test that the execution completes without throwing exceptions or generating errors.
* Do not spend time generating dummy images for exact pixel verification unless explicitly required.
* Document any testing limitations related to rendering in the `shared_memories/rendering_limitations.json` file.

## Upcoming Features (Phase 1 Backlog)

### Component Storage Integration
* **Expectation:** Integrate the Sparse Set (`Caste`) with actual component data arrays (e.g., `Position`).
* **Constraint:** You must provide a mechanism to attach, retrieve, and remove component data mapped to an entity with **zero object allocations** during retrieval operations.

### Query Engine
* **Single Component (Iteration):** Must provide extremely fast linear iteration over dense component data (e.g., iterating through all active entities in a specific `Caste`).
* **Multi-Component (Join):** Must implement a query system to find entities possessing multiple specific components (e.g., `Position` and `Velocity`). This must utilize the sparse sets to perform fast intersections.

### Render System (`drawAtlas`)
* **Flat Components:** `Position` (x, y) and `Sprite` (texture rect, color, transform) components must be designed as flat memory structures. Use Dart 3 records, extension types, or `Float32List`. Do not create heavy objects.
* **Asset Loading:** Must implement a basic utility to load raw image assets into a `dart:ui.Image` bypassing Flutter's `AssetBundle`.
* **Rendering System:** A System must query entities with `Position` and `Sprite` components, building the required `RSTransform` and `Rect` arrays to issue a single `Canvas.drawAtlas` call to render all sprites simultaneously.

### Spatial Hashing (Bounds Checking)
* **2D Grid Implementation:** A spatial hash grid must be implemented for broad-phase collision detection.
* **Zero Allocation Constraint:** Entities must be inserted into cells based on their (x,y) position using flat arrays or pre-allocated lists. The Spatial Hash Update System must prove zero allocations per tick via benchmarking.
* **Broad-phase Querying:** Must provide an API to query the spatial hash for potential collisions (entities occupying the same or adjacent cells) to feed into a narrow-phase collision system.

# Sting Engine Design Document

## 1. Overview
Sting is a bare-metal 2D game engine built in Dart. It bypasses the Flutter UI framework (Widgets, BuildContext, runApp) entirely to achieve maximum performance. The engine connects directly to the Dart UI bindings (`dart:ui`) to render via Impeller/Skia and uses a strict, data-oriented Entity Component System (ECS) to manage massive entity counts.

## 2. Core Architecture

### 2.1 The Main Loop
The engine operates outside the standard Flutter lifecycle. It hooks directly into the platform windowing system via `PlatformDispatcher`:
* `PlatformDispatcher.instance.onBeginFrame`: Triggered by the platform's VSync. Used for core simulation steps (physics, ECS systems update). Delta time (`dt`) is calculated here, capped to avoid physics anomalies on lag spikes.
* `PlatformDispatcher.instance.onDrawFrame`: Used to record drawing commands and submit the final scene to the GPU.
* **Pointer Data Hooks**: `PlatformDispatcher.instance.onPointerDataPacket` is hooked directly for input events without instantiating Flutter's high-level gesture classes.

### 2.2 Data-Oriented ECS
To support massive entity counts (e.g., tens of thousands of particles, bullets, or boids), Sting relies on memory efficiency and CPU cache locality.
* **Entities**: Managed by the `Swarm` system, entities are strictly `int` IDs. They are constrained to `Int16` limits (65,535 max entities) and tracked via bit-flags (`Uint32List`) for O(1) liveness checks and zero allocations.
* **Components**: Components are flat data structures. Utilizing Dart 3 extension types over typed data arrays (`Float32List`, `Int32List`, `ByteData`), multiple primitive fields are packed contiguously. This achieves zero-cost abstraction with strict cache locality. Standard objects are only permitted when packaging UI elements (like `dart:ui.Paragraph`) that are updated only upon dirty flags.
* **Systems**: Systems contain all the logic and are completely stateless. They iterate over arrays of components using Queries and mutate data in bulk.

## 3. Subsystem Breakdown

### 3.1 ECS Core (`Swarm` and `Caste`)
* **Entity Management (`Swarm`)**: Generates sequential integer IDs and safely recycles destroyed IDs to prevent leaks.
* **Component Storage (`Caste`)**: Uses a Sparse Set architecture utilizing the Briggs & Torczon validation technique. This eliminates the need for array initialization or sentinel values, enabling rapid O(1) clears and maximum memory efficiency with `Uint16List` arrays.
* **Queries**: Fast iteration over specific combinations of components. Multi-component queries optimize execution by iterating over the smallest dense array and performing O(1) lookups in larger sparse arrays via callback functions, strictly preventing iterator object allocations.

### 3.2 Rendering Engine (`dart:ui` Bindings)
* **Batch Rendering**: Massive sprite rendering relies heavily on `Canvas.drawRawAtlas`. Using `.sublistView()` on flat arrays avoids per-frame allocations associated with `Canvas.drawAtlas` which otherwise requires new `Rect` and `RSTransform` objects.
* **Viewport System**: Offsets are rendered seamlessly by saving, translating, and scaling canvas states directly inside rendering systems, sidestepping custom camera objects.
* **Asset Loading**: Flutter `AssetBundle` is bypassed entirely for pure `dart:io` and `dart:ui.instantiateImageCodec` image parsing, cleanly disposing of codecs immediately to prevent native memory leaks.

### 3.3 Physics and Kinematics
* **Broad-phase collision detection**: Implements a highly efficient `SpatialHashGrid` storing entity IDs in cell buckets via flat 1D index mapping to prevent `Iterable` instantiation during collision detection.
* **Narrow-phase math**: Strictly accepts raw primitive unboxed floats (e.g., `x`, `y`, `width`, `height`, `radius`) to evaluate bounding boxes (AABB) and circle constraints.
* **Collision Resolution**: Utilizes a `SimpleResolutionSystem` providing callbacks for positional separation without massive continuous collision detection (CCD) architectures, honoring YAGNI.

## 4. Memory Management & Dart Specifics
* **Records and Patterns**: Extensively use Dart 3 records for multiple returns and lightweight data passing without allocating objects on the heap.
* **Extension Types**: Use extension types on `int` or `Float32List` to provide a zero-cost abstraction layer for strictly typed IDs and data structs.
* **Zero Allocation per Frame**: The core loop and system ticks strictly maintain zero heap allocations per frame to prevent GC pauses. Arrays are pre-allocated and pooled.

## 5. Future Architectural Enhancements (Planned Features)
While Phases 1 through 5 implement core rendering, ECS, physics, tilemaps, and particle systems, the engine should scale organically. New systems must follow DOD and zero-allocation constraints:

### 5.1 Data-Oriented Audio System
* **Implementation Plan**: An audio event dispatcher built around flat queues (`Int32List`). Instead of instantiating `SoundEvent` objects, audio requests (sound ID, volume, pitch, pan) will be pushed into ring buffers and processed in bulk by an `AudioSystem` directly interacting with a low-level audio package or FFI bindings.
* **Memory Strategy**: Limit concurrent audio voices. Pre-allocate playback handles and map them to entities.

### 5.2 Advanced UI Rendering Framework
* **Implementation Plan**: Beyond simple static text, interactive UI (buttons, menus, panels) will utilize a specialized `UICaste` focusing on screen-space AABB collisions and layered rendering.
* **Memory Strategy**: Hit-testing bounding boxes for UI will use flat `Float32List` arrays synchronized with input pointer slots. Complex UI rendering objects (`ParagraphBuilder`, `Path`) will be strictly cached on components and dirty-flagged for rebuilding only upon state shifts.

### 5.3 Asset Management and Streaming
* **Implementation Plan**: Instead of fully loading enormous sprite sheets and maps into memory up front, implement a chunk-based memory manager.
* **Memory Strategy**: Stream data via background isolates, passing raw pixel buffers via `TransferableTypedData` into the main isolate to construct images via `decodeImageFromPixels` securely avoiding main thread blocking or large native GC bursts.

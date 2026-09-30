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

## 3.4 Advanced Subsystems

### 3.4.1 Data-Oriented Audio System
* **Implementation**: An audio event dispatcher built around flat queues (`Int32List`). Instead of instantiating `SoundEvent` objects, audio requests (sound ID, volume, pitch, pan) are pushed into ring buffers and processed in bulk by the `AudioSystem`. Pre-allocated playback handles map to entities.

### 3.4.2 UI Rendering Framework
* **Implementation**: A specialized `UICaste` focusing on screen-space AABB collisions and layered rendering is used for interactive UI. Hit-testing bounding boxes for UI use flat `Float32List` arrays synchronized with input pointer slots. Complex UI rendering objects (`ParagraphBuilder`, `Path`) are strictly cached on components and dirty-flagged for rebuilding only upon state shifts.

### 3.4.3 Asset Management and Streaming
* **Implementation**: A chunk-based memory manager dynamically streams large sprite sheets and maps. Background isolates load and stream raw pixel buffers via `TransferableTypedData` into the main isolate, constructing images securely via `decodeImageFromPixels` avoiding main thread blocking.

### 3.4.4 Game State Management
* **Implementation**: A global state management system utilizes ECS concepts with a singleton entity / state flags to manage high-level game loops (Menu, Playing, Paused, GameOver). Logic systems selectively update based on the current state.

### 3.5 Extended Subsystems

### 3.5.1 Terrain Elevation & Slope Kinematics
* **Implementation**: `HeightMap` stores 2.5D topographic elevation data in a contiguous 1D `Float32List`. Sub-tile world coordinates query elevation and surface normal gradient vectors via bilinear interpolation. The `SlopePhysicsSystem` reads entity `Position` and `Velocity`, applying directional acceleration, gravity assist, and uphill/downhill friction modifiers based on the entity's `SlopeModifier` component without runtime allocations.

### 3.5.2 Tactical Radar & Minimap System
* **Implementation**: `RadarDisplay` and `RadarSystem` project entities from world space to radar screen space using pre-calculated scale ratios and center offsets. Radar sweeps are rendered using scalar angular progression, and blips are drawn using zero-allocation entity queries with 32-bit ARGB packed colors.

### 3.5.3 Dynamic Fog of War
* **Implementation**: `DiscoveryGrid` tracks unexplored, shrouded/explored, and currently visible tiles via compact 1D `Uint8List` byte arrays. `FogOfWarSystem` projects observer entity vision cones onto the grid using radius-squared comparisons, clearing shroud and masking unexplored sectors without generating vector clipping paths.

### 3.5.4 Ground Trail & Desire Paths
* **Implementation**: `GroundTrailField` records movement heatmaps across a 2D scalar grid (`Float32List`). Entities deposit footstep intensity that decays smoothly over time via an exponential decay pass (`intensity -= decayRate * dt`), visualizing natural desire paths across terrains and corridors.

### 3.5.5 Capsule Corridor Logistics
* **Implementation**: `CapsuleCorridor` connects logistics node networks via flat numerical node indices. The `LogisticsSystem` transports cargo capsules along corridors with configurable capacities, transfer speeds, and directional flow (unidirectional or bidirectional) using normalized progression scalars `t in [0.0, 1.0]`.

### 3.5.6 Interactive UI Suite
* **Implementation**:
  * **Draggable Windows & Buttons (`UIWindow`, `UIButton`)**: Zero-allocation window docking, drag-handling via pointer tracking, and hierarchical button hit-testing.
  * **Progress Bar Component (`ProgressBar`)**: Render system for health, energy, and reload indicators with cached `RRect` bounds.
  * **Sci-Fi Radial Intent Dial (`RadialDial`)**: Screen-space radial action selector with angular sector highlighting and intent selection using unboxed primitive trigonometry (`atan2`, distance checks).

## 5. Future Architectural Enhancements (Planned Features)
While the engine currently implements all core foundational and extended subsystems, future architectural enhancements are planned to introduce highly-requested features commonly found in modern 2D engines (like Godot, Bevy, and Defold), provided they adhere strictly to our zero-allocation constraints:
* **Parallax Scrolling System**: A layered background system implementing efficient multi-speed offset updates strictly via flat arrays and integrated cleanly into the `Renderer`.
* **Auto-Detect Input Mapping & Control Schemes**: An abstraction layer mapping raw physical input (keys, pointers, touch, physical gamepads) to abstract game actions, automatically adapting to the target platform and available inputs without per-frame allocations.
* **Virtual Joypad UI**: An integrated on-screen joystick solution mapped to `ComplexUI` bounds for multi-touch vector normalization, aimed specifically at mobile and touch-enabled devices.
* **Ultra-Fast 2D Lighting (No Raytracing)**: High-performance 2D lighting pipelines completely avoiding standard raytracing techniques. Will explore performant alternatives like 1D shadow mapping or fast polygonal self-transparent shadow meshes via `dart:ui` custom shaders to maintain single-batch rendering efficiency.

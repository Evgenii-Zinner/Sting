# Sting Engine Design Document

## 1. Overview
Sting is a bare-metal 2D game engine built in Dart. It bypasses the Flutter UI framework (Widgets, BuildContext, runApp) entirely to achieve maximum performance. The engine connects directly to the Dart UI bindings (`dart:ui`) to render via Impeller/Skia and uses a strict, data-oriented Entity Component System (ECS) to manage massive entity counts.

## 2. Core Architecture

### 2.1 The Main Loop
The engine operates outside the standard Flutter lifecycle. It hooks directly into the platform windowing system via `PlatformDispatcher`:
* `PlatformDispatcher.instance.onBeginFrame`: Triggered by the platform's VSync. Used for core simulation steps (physics, ECS systems update).
* `PlatformDispatcher.instance.onDrawFrame`: Used to record drawing commands and submit the final scene to the GPU.

### 2.2 Data-Oriented ECS
To support massive entity counts (e.g., tens of thousands of particles, bullets, or boids), Sting relies on memory efficiency and CPU cache locality.
* **Entities**: Entities are strictly `int` IDs. No objects or classes represent entities.
* **Components**: Components are flat data structures. To maximize performance in Dart, component data will heavily utilize typed data arrays (e.g., `Float32List`, `Float64List`, `Int32List`) where possible, or minimal data classes.
* **Systems**: Systems contain the logic. They iterate over arrays of components using Queries and mutate data in bulk.

## 3. Subsystem Breakdown

### 3.1 ECS Core
* **World/Registry**: Manages entity IDs (allocation, recycling) and component storage.
* **Queries**: Fast iteration over specific combinations of components. Should support filtering (e.g., Entities with `Position` and `Velocity`, but without `Static`).
* **Archetypes / Sparse Sets**: The underlying data structure for component storage. *Decision pending based on profiling: Sparse Sets are easier to implement in Dart, but Archetypes provide better linear iteration performance.*

### 3.2 Rendering Engine (`dart:ui` Bindings)
* **Canvas & PictureRecorder**: Systems will record drawing commands to a `Picture`.
* **SceneBuilder**: Assembles pictures and raw data into a renderable `Scene`.
* **Batch Rendering (`drawAtlas`)**: For massive sprite rendering, the engine will extensively use `Canvas.drawAtlas` which allows drawing thousands of textured quads in a single draw call.

### 3.3 Spatial Hashing / Physics
* Broad-phase collision detection using grid-based spatial hashing to support massive entity interactions (O(1) or O(n) proximity checks instead of O(n^2)).
* Simple AABB (Axis-Aligned Bounding Box) and Circle collision resolution components.

## 4. Memory Management & Dart Specifics
* **Records and Patterns**: Extensively use Dart 3 records for multiple returns and lightweight data passing without allocating objects on the heap.
* **Extension Types**: Use extension types on `int` or `Float32List` to provide a zero-cost abstraction layer for strictly typed IDs and data structs.
* **Zero Allocation per Frame**: The core loop and system ticks must strive for zero heap allocations per frame to prevent GC pauses. Arrays should be pre-allocated and pooled.

## 5. Development Roadmap (Phase 1)
1. Setup raw `dart:ui` window hook.
2. Implement basic Entity ID generator and Component storage (Sparse set).
3. Implement Query engine.
4. Implement Render System (Sprite Component + `drawAtlas`).
5. Implement spatial hashing for basic bounds checking.

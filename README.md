# Sting

A bare-metal, high-performance 2D Entity Component System (ECS) game engine for Dart, designed for massive entity counts and uncompromising 60/120 FPS performance.

## Core Philosophy

* **Zero Flutter Framework Overhead**: Sting does not use `runApp()`, `Widgets`, or `BuildContext`. It binds directly to `PlatformDispatcher.instance.onBeginFrame` and `dart:ui` to talk directly to the underlying graphics engine (Impeller/Skia).
* **Strict ECS Architecture**: Data-oriented Entity Component System. Entities are pure `int` IDs (constrained to 16-bit space for optimal cache locality). Components are flat Dart 3 extension types on contiguous typed arrays (`Float32List`, `Int32List`, `ByteData`). Systems are stateless query processors.
* **Zero Allocations per Frame**: The runtime game loop enforces zero heap allocations per frame, eliminating garbage collector (GC) pauses during active gameplay.

## Tech Stack

* **Language**: Dart 3.x (utilizing Records, Patterns, and Extension Types for zero-cost abstractions and ergonomics).
* **Rendering**: Pure `dart:ui` (`Canvas`, `PictureRecorder`, `SceneBuilder`, `drawRawAtlas` for batched sprite rendering).
* **Target Platforms**: Cross-platform (Desktop, Mobile, Web).

## Engine Subsystems

### Core Engine
* **Entity Management (`EntityManager`)**: 16-bit entity generation and recycling with O(1) bit-flag liveness verification.
* **Sparse Set Component Storage (`SparseSet` / `ComponentStorage`)**: Briggs & Torczon sparse set architecture ensuring contiguous cache-line iteration and O(1) random access.
* **Query Engine**: Zero-allocation multi-component queries iterating directly over the smallest dense storage.
* **Batch Sprite Rendering (`BatchedSpriteRenderSystem`)**: High-throughput sprite rendering via `Canvas.drawRawAtlas`.
* **Spatial Partitioning (`SpatialHashGrid`)**: 2D spatial hash grid mapping entities to 1D buckets for O(1) broad-phase spatial queries.
* **Kinematics & Physics**: Eulerian and Verlet integration with unboxed primitive narrow-phase collisions (AABB, Circle) and resolution.
* **Hierarchical State Machine**: Global game loop state management (Menu, Playing, Paused, GameOver).
* **Audio Dispatcher**: Ring-buffered flat audio event queue processed in bulk without per-frame event allocations.

### Extended Subsystems
* **Terrain & Slope Kinematics (`SlopePhysicsSystem`, `HeightMap`)**: 2D heightmap elevation grid with bilinear sub-tile interpolation and directional slope modifiers affecting velocity and friction.
* **Tactical Radar & Minimap (`RadarSystem`, `RadarDisplay`)**: Zero-allocation viewport/world-space radar projecting dynamic blips, sweep lines, and orientation indicators.
* **Dynamic Fog of War (`FogOfWarSystem`, `DiscoveryGrid`)**: Flat-array visibility and exploration grid supporting circular vision cones, explored shroud, and unexplored mask overlays.
* **Ground Trail & Desire Paths (`GroundTrailField`)**: Persistent trail heatmaps where moving entities deposit footstep intensity that decays over time, dynamically visualizing popular path routes.
* **Capsule Corridor Logistics (`CapsuleCorridor`, `LogisticsSystem`)**: Node-to-node logistics routes supporting bidirectional transit, capacity constraints, and directional flow speeds.
* **Interactive UI Suite**:
  * **Draggable Windows & Buttons (`UIWindow`, `UIButton`)**: Zero-allocation window docking, drag-handling, and hierarchical button click detection.
  * **Progress Bar Component (`ProgressBar`)**: Render system for health, energy, and reload bars with cached `RRect` bounds.
  * **Sci-Fi Radial Intent Dial (`RadialDial`)**: Screen-space radial action selector with interactive sector highlighting and intent selection.

## Documentation

* [Sting Engine Comprehensive Guide](file:///docs/STING_ENGINE_GUIDE.md) — Complete architectural overview, subsystem details, and concrete code examples.
* [Architecture FAQ](file:///docs/ARCHITECTURE_FAQ.md) — Common architectural patterns, terminology evolutions, and FAQ.
* [Memory Limits & Architecture Guide](file:///docs/MEMORY_LIMITS.md) — Zero-allocation constraints, pre-allocation guidelines, and cache sizing.
* [Engine Design Document](file:///docs/DESIGN.md) — Foundational design specification and future roadmap.
* [Contributor Guidelines](file:///AGENTS.md) — Workflow instructions and zero-allocation TDD rules for contributors and AI agents.

## Project Structure

* `docs/` — Architectural documentation, engine guides, and memory limits.
* `lib/` — Engine source code (`core/`, `components/`, `systems/`, `rendering/`, `ui/`, `logistics/`).
* `test/` — Comprehensive test suite (100% test coverage enforced).
* `shared_memories/` — Shared memory knowledge base tracking architectural decisions and avoided pitfalls.


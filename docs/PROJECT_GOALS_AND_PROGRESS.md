# Sting Engine: Project Goals, Architectural Rules & Progress Tracker

> **Notice for All AI Agents & Contributors**:  
> This file is the **single consolidated source of truth** for Sting's engine goals, architectural constraints, proven engineering decisions, and implementation progress.  
> Whenever you implement new systems, components, or math utilities, or make architectural decisions, you **MUST** update this file.

---

## 1. Project Vision & Core Philosophy

**Sting** is a bare-metal, high-performance 2D Data-Oriented ECS game engine implemented in Dart using pure `dart:ui`. It is engineered specifically for complex, high-density simulation games (autonomous swarms, frozen planet logistics, flat-top hex thermodynamics, indirect god-games like *Crystal Cinders*).

### Non-Negotiable Core Tenets

1. **Zero Per-Frame Heap Allocations**:
   - Dart's Garbage Collector (GC) pauses cause frame drops at 60/120 FPS.
   - No object or collection instantiation inside main update or render loops (`update()`, `render()`, event handlers).
   - Use pre-allocated typed arrays (`Float32List`, `Int32List`, `Uint32List`), unboxed primitive doubles/ints, Dart 3 records, and object pools.
2. **Pure `dart:ui` Direct Pipeline**:
   - Never import or use Flutter framework widgets (`Widget`, `StatefulWidget`, `BuildContext`, `InheritedWidget`).
   - Draw directly to `Canvas` via batch calls (`drawRawAtlas`, `drawRawPoints`, `drawVertices`).
3. **Data-Oriented Design (DOD)**:
   - **Entities are primitive integers (`int`)**: No `Entity` classes holding pointers.
   - **Components are flat data**: Implemented as Dart 3 `extension type` over contiguous typed buffers. Logic strictly belongs in Systems.
   - **Systems hold execution logic**: Stateless or holding cached queries and pre-allocated scratch buffers.
4. **Strict Test-Driven Development (TDD)**:
   - 100% test coverage for all ECS components, math routines, and simulation systems.
   - Every new module must include an accompanying dedicated unit test file.

---

## 2. Consolidated Architectural Learnings & Gotchas

*(Consolidated from architectural decisions across engine development)*

### A. Memory Management & Collections
* **Temporary Collections in Systems**:
  - To collect entities for destruction or deferred operations, declare class-level reusable Dart lists (e.g. `final List<int> _toDestroy = [];`) and invoke `_toDestroy.clear()` at the start of the frame.
  - Dart's `List.clear()` retains the underlying capacity buffer, eliminating GC allocations while safely expanding if a massive burst occurs.
  - Avoid fixed-size buffers (e.g. `Int32List(100)`) for event/action queues unless bounded by strict pool size, as exceeding capacity causes silent drops.
* **ARGB Color Packing Gotcha**:
  - **Never pack 32-bit ARGB hex colors into `Float32List`**! 32-bit integers exceed the 24-bit mantissa precision of IEEE-754 single-precision floats. Storing hex values as floats truncates alpha and red channel bits, corrupting colors.
  - Always store colors using `int` (via `Uint32List` views or typed int fields).

### B. Rendering & Canvas Performance
* **Sub-Pixel Shimmering / Jitter**:
  - When applying camera/viewport translation to the canvas, explicitly round the coordinates:
    $$\text{offset} = \frac{\text{round}(\text{viewport} \cdot \text{scale})}{\text{scale}}$$
  - Prevents sub-pixel aliasing and jittering during smooth camera tracking.
* **Cached UI Render Objects**:
  - UI text (`Paragraph`) and geometric shapes (`RRect`, `Path`) must be cached on components with dirty flags.
  - Rebuilding `Paragraph` or `Path` objects per frame causes severe GC thrashing.
* **Batch Vertex / Edge Rendering**:
  - Batch line segments using pre-allocated `Float32List` buffers with `Canvas.drawRawPoints(PointMode.lines, ...)` or `Canvas.drawVertices` instead of allocating multiple `Path` objects.

### C. Mathematics, Kinematics & Physics
* **Unboxed Vector Math**:
  - Hot simulation loops (SAT collision, continuous sampling, gravity, steering) must use primitive unboxed `double` coordinates `(x, y, dx, dy)` instead of instantiating `Vector2` heap objects.
* **2.5D Topographic Heightmaps**:
  - Topographic grids are stored in contiguous 1D flat buffers (`Float32List(width * height)`) rather than nested arrays (`List<List<double>>`) to eliminate pointer indirection and cache misses.
* **Barycentric Clamping & Edge Parameterization**:
  - Equilateral triangle barycentric coordinates $(W_A, W_B, W_C)$ must be normalized ($\sum W_i = 1$) and clamped to non-negative values.
  - Edge parameterizations from vertex $P_1$ to $P_2$ with $t \in [0, 1]$ map $W_1 = 1 - t$ and $W_2 = t$.

### D. Audio Decoupling & Pluggability
* **Pure Dart Audio Architecture**:
  - The engine core is decoupled from native audio FFI plugins (such as `flutter_soloud`).
  - `AudioBackend` defines a zero-allocation contract for drivers (`NullAudioBackend`, `MockBackend`, or platform-specific drivers).
  - `PluggableAudioManager` provides spatial distance attenuation and stereo panning without allocating heap objects.

### E. Hex Thermodynamics & Topological Networks
* **Bounded Thermal Diffusion**:
  - Hex grid thermal diffusion is modeled with ambient baseline $T_{\text{ambient}}$ and cooling dissipation rate $\lambda_{\text{cooling}}$:
    $$\Delta T = (T_{\text{neighbors\_avg}} - T) \cdot \text{diffusionRate} - (T - T_{\text{ambient}}) \cdot \text{coolingRate} \cdot dt$$
  - Ensures heat fields remain bounded rather than bleeding indefinitely into a lukewarm plane.
* **Topological Graph Logistics**:
  - `NetworkGraph` uses contiguous typed arrays with an $O(N)$ Union-Find disjoint-set solver to partition connected components.
  - `CollectiveResourcePoolSystem` aggregates resource inputs and line losses across disjoint subnetworks.
  - `StockpileBalanceCalculator` computes $O(N)$ averages and deficits/surpluses to guide hauler logistics.

### F. DRY & Zero-Allocation Rendering Unification
* **Unified Camera & Pixel-Grid Snapping**:
  - `Viewport.applyCamera` and `Viewport.snapToPixel` unify viewport transformations across `SpriteRenderSystem`, `TilemapRenderSystem`, `HexTilemapRenderSystem`, `HexEdgeRenderSystem`, and `LightRenderSystem`.
  - Canonical formula `(val * scale).roundToDouble() / scale` prevents fractional camera jitter and sprite texture shimmering.
* **Hex Mesh Zero-Allocation Iteration**:
  - `HexEdgeMesh` exposes a cached `uint32View` to `HexEdgeRenderSystem` avoiding repeated `asUint32List` view allocations per edge in hot render loops.
  - Pre-allocated `_processedEntities` set in `HexEdgeRenderSystem` eliminates per-frame heap allocations.
* **Component Deduplication & Symbol Cleanup**:
  - Unified duplicate `CellularGrid` into `lib/engine/components/cellular_grid.dart`.
  - Disambiguated enum collisions: `TilemapGridType` vs `PathfindingGridType`.
  - Unified `IndexedMinHeap` in `lib/engine/math/indexed_min_heap.dart` replacing duplicate internal heaps.
  - Cleaned all `hide` clauses from `lib/sting.dart`. All 170 public libraries compile with 0 analyzer issues and 0 DartDoc warnings.

### G. UI & Audio Zero-Allocation Hardening
* **Radar View Optimization**:
  - `RadarDisplay` exposes a cached `uint32View` getter and `RadarSystem._renderRadar` reads ARGB colors directly from it, eliminating repeated `asUint32List` view allocations per radar display per frame.
* **Subpixel Snapping in UI**:
  - `ProgressBarRenderSystem` world-space positioning unified with canonical `Viewport.snapToPixel`.
* **Complete Property DartDoc Coverage**:
  - Every property across `BarycentricTriangle`, `RadialDial`, `UIWindow`, `UIButton`, `UIBoundingBox`, `ProgressBar`, `FloatingText`, `AudioListener`, and `AudioEmitter` documented according to Effective Dart guidelines.

### H. AI, Kinematics & Clean Architecture Audit
* **Dead Stub Pruning (YAGNI)**:
  - Removed empty zero-byte stub `lib/engine/ai/steering_behaviors.dart` and its export in `lib/sting.dart`. All steering algorithms cleanly reside in `lib/engine/components/steering.dart` and `lib/engine/systems/steering_system.dart`.
* **Complete Kinematics & AI DartDoc Coverage**:
  - Added full doc coverage across `PotentialFieldSolver`, `UtilityAISystem`, `UtilityAI`, `EntityFSM`, `Steering`, and `FlockingAgent`.
* **Full Test Suite & Analyzer Cleanliness**:
  - 100% test pass rate across all 843 test cases (unit, system, integration, and performance regression suites).
  - 0 analyzer warnings, 0 DartDoc warnings, and 0 errors across all 169 public libraries.

---

## 3. Subsystem Implementation Inventory

| Subsystem | Components | Systems / Utilities | Tests | Status |
|---|---|---|---|---|
| **Core ECS** | `ComponentStorage`, `SparseSet`, `EntityPool`, `Prefab` | `EntityManager` (`Swarm`), `Query`, `Scene` | `test/engine/ecs/*` | **Complete** (100% Pass) |
| **Transform & Kinematics** | `Position`, `Velocity`, `Rotation`, `Scale`, `LocalTransform`, `Parent`, `PreferredVelocity` | `TransformSystem`, `MovementSystem`, `PhysicsResponseSystem` | `test/engine/components/*`, `test/engine/systems/*` | **Complete** (100% Pass) |
| **Physics & Collision** | `BoundingBox`, `CompoundBoundingBox`, `SlopeModifier`, `HeightMap` | `CollisionSystem`, `SlopePhysicsSystem`, `CompoundBoundingBoxSystem`, `SATCollision` | `test/engine/math/sat_collision_test.dart`, etc. | **Complete** (100% Pass) |
| **Spatial Partitioning** | `SpatialHashGrid` | `SpatialHashSystem`, `QuadTree2D` | `test/engine/systems/spatial_hash_system_test.dart`, etc. | **Complete** (100% Pass) |
| **Rendering & Camera** | `Sprite`, `SpriteAnimation`, `CameraFollow`, `CameraTrauma`, `Light`, `ShadowCaster`, `ShaderMaterial`, `NormalMapMaterial`, `TrailEmitter`, `TrailFeedback` | `SpriteRenderSystem`, `CameraSystem`, `CameraShakeSystem`, `LightRenderSystem`, `ParticleSystem` | `test/engine/systems/*render*_test.dart` | **Complete** (100% Pass) |
| **Tilemaps & Hex Edges** | `Tilemap`, `HexTilemap`, `HexEdgeMesh` | `TilemapRenderSystem`, `HexTilemapRenderSystem`, `HexEdgeRenderSystem` | `test/engine/systems/*hex*_test.dart` | **Complete** (100% Pass) |
| **Thermodynamics & Fields** | `GridDiffusion`, `CellularGrid`, `VectorField2D` | `DiffusionSystem`, `HexDiffusionCoolingSystem`, `MultiChannelDiffusionSystem`, `CellularSimulationSystem`, `ScalarFieldSampler`, `HexFieldSampler`, `FieldGradient`, `FieldSplatting`, `FieldSensorSystem`, `FieldEmissionSystem` | `test/engine/systems/*diffusion*_test.dart`, `test/engine/math/*field*_test.dart` | **Complete** (100% Pass) |
| **Logistics & Graphs** | `NetworkGraph`, `CapsuleCorridor` | `CollectiveResourcePoolSystem`, `StockpileBalanceCalculator`, `CapsuleCorridorSystem` | `test/engine/components/network_graph_test.dart`, `test/engine/systems/collective_resource_pool_system_test.dart`, `test/engine/math/stockpile_balance_calculator_test.dart` | **Complete** (100% Pass) |
| **AI & Steering** | `UtilityAI`, `Steering`, `FlockingAgent`, `EntityFSM`, `MovementQueue` | `UtilityAISystem`, `SteeringSystem`, `FlockingSystem`, `FSMSystem`, `RVOSystem`, `PotentialFieldSolver`, `FlowFieldSteeringSystem`, `NavMeshPathfinder`, `IndexedMinHeap` | `test/engine/ai/*`, `test/engine/math/indexed_min_heap_test.dart`, `test/engine/systems/*flocking*_test.dart` | **Complete** (100% Pass) |
| **UI Components** | `UIWindow`, `UIButton`, `ProgressBar`, `RadialDial`, `BarycentricTriangle`, `TextRender`, `FloatingText`, `RadarDisplay` | `UISystem`, `UIWindowSystem`, `ProgressBarRenderSystem`, `RadialDialSystem`, `BarycentricTriangleSystem`, `ComplexUIRenderSystem`, `TextRenderSystem`, `FloatingTextSystem`, `RadarSystem` | `test/engine/systems/*ui*_test.dart`, `test/engine/systems/barycentric_triangle_system_test.dart` | **Complete** (100% Pass) |
| **Audio** | `AudioEmitter`, `AudioListener`, `AudioEventQueue` | `AudioSystem`, `AudioSpatialSystem`, `PluggableAudioManager`, `AudioBackend` | `test/engine/audio/*`, `test/engine/systems/audio_spatial_system_test.dart` | **Complete** (100% Pass) |
| **Assets & Profiling** | `AssetManager`, `AssetLoader`, `ChunkManager` | `EngineProfiler` | `test/engine/assets/*`, `test/engine/profiling/*` | **Complete** (100% Pass) |

---

## 4. Current Milestone & Next Roadmap

### Milestone 1: Bare-Metal ECS & Batch 2D Rendering
- [x] Contiguous Typed Data ECS architecture.
- [x] Zero-allocation query iteration and component pools.
- [x] Batch sprite atlas renderer (`drawRawAtlas`) and camera tracking.

### Milestone 2: Swarm Logistics, Potential Fields & Cellular Simulation
- [x] Multi-goal wavefront `PotentialFieldSolver` & `FlowFieldSteeringSystem`.
- [x] Double-buffered `CellularGrid` & `CellularSimulationSystem`.
- [x] Multi-channel diffusion and spatial resonance.

### Milestone 3: Hex Thermodynamics, Bound Cooling & Topological Networks
- [x] Flat-top hex coordinate math (`HexMath`).
- [x] Bounded `HexDiffusionCoolingSystem` with cooling loss and ambient baseline.
- [x] Continuous `HexFieldSampler` zero-allocation field reader.
- [x] `NetworkGraph` contiguous array with $O(N)$ Union-Find partitioning.
- [x] `CollectiveResourcePoolSystem` multi-network resource solver.
- [x] `StockpileBalanceCalculator` $O(N)$ component stockpile balancer.
- [x] `HexEdgeMesh` and `HexEdgeRenderSystem` batch boundary/spine line renderer.

### Milestone 4: Pluggable Audio & Advanced UI Controls
- [x] Decouple engine from `flutter_soloud`; introduce `AudioBackend` & `PluggableAudioManager`.
- [x] 3-axis `BarycentricTriangle` component & `BarycentricTriangleSystem` with boundary clamping.

### Milestone 5: Game Layer Scaffolding (*Crystal Cinders*) [ACTIVE]
- [ ] Central barrel export synchronization in `lib/sting.dart`.
- [ ] Game scene integration connecting Hex Thermodynamics, Magistral Network Graphs, and Swarm Hauler entities.
- [ ] Macro-control hookups linking `BarycentricTriangle` priorities (Build / Heat / Gather) to autonomous agent behavior trees.

---

## 5. Mandatory Agent Protocol: Updating This Document

Whenever an AI agent or contributor touches the codebase:
1. **Document Every New Module**: Add new components, systems, or math kernels to the **Subsystem Implementation Inventory** table.
2. **Update Progress Checklists**: Keep the Milestone Roadmap accurate.
3. **Record Architectural Decisions**: If a critical design decision or platform gotcha is discovered, add it under **Section 2 (Consolidated Architectural Learnings)**.
4. **Enforce Zero Allocations**: Re-verify that all hot loops satisfy the non-negotiable memory rules before submitting.

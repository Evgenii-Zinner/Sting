# Sting Engine Requirements: Autonomous Swarm & Hex-Thermodynamics Support

This document specifies the engine-level (general-purpose, data-oriented, zero-allocation) features and extensions required in **Sting** to support games like *Crystal Cinders* (flat-top hex thermodynamics, collective networks, indirect colony control, and swarm logistics).

These components and systems belong strictly in the engine domain (`lib/engine/`) because they are decoupled from game mechanics and provide foundational primitives reusable by any hex-grid simulation, circuit/pipe logistics game, or swarm AI title.

---

## 1. Hex Thermodynamics & Field Diffusion (`GridDiffusion` Extensions)

### Context & Gap
The engine already provides `GridDiffusion` and `DiffusionSystem` with support for hexagonal neighborhoods (`isHexagonal: true`, odd-r offset layout). However, it operates as a closed, adiabatic system without cooling loss or continuous sink/injection dynamics.

### Requirements for Sting
1. **Ambient Baseline & Cooling Dissipation Rate**:
   - Add `ambientBaseline` (float) and `coolingRate` (float) to `GridDiffusion` or as configurable parameters in `DiffusionSystem`.
   - Each tick:
     $$\Delta T = (T_{\text{neighbors\_avg}} - T) \cdot \text{diffusionRate} - (T - T_{\text{ambient}}) \cdot \text{coolingRate} \cdot dt$$
   - Keeps thermal frontiers bounded instead of diffusing infinitely until the grid is a uniform lukewarm plane.
2. **Hex Heat Point Splatting / Hex Field Emitter**:
   - Add zero-allocation helper / system to inject heat into individual hex coordinates `(q, r)` or continuous positions `(x, y)` mapped via `HexMath.flatWorldToGrid`.
3. **Hex Field Sampler**:
   - Extend `ScalarFieldSampler` / `FieldSensorSystem` to sample hex grids using `HexMath.flatWorldToGrid` with zero heap allocations, allowing continuous moving agents to read local hex temperature and gradient vectors.

---

## 2. Graph & Network Collective Circuit System (`NetworkGraph` / `CollectiveResourcePool`)

### Context & Gap
In *Crystal Cinders*, **Heat Magistrals** are hard hex buildings that form a connected network with **collective pooled heat** (or power/fluids in other games). When segments connect, they share an energy/heat budget, and disconnected subnetworks form isolated components.

Currently, `CapsuleCorridor` only represents individual continuous 2D capsules without network topological connectivity or graph pooling.

### Requirements for Sting
1. **Generic Flat Graph Data Structure (`NetworkGraph`)**:
   - Represented as a flat ECS component or data struct backed by contiguous typed arrays (`Int32List` / `Int16List`).
   - Supports:
     - Nodes (discrete cell indices or entity IDs).
     - Edges (adjacent connections between nodes).
     - Component partitioning: Fast O(N) Disjoint-Set / Union-Find traversal to identify connected sub-graphs.
2. **Collective Pool Calculation**:
   - System that sums injections across all connected nodes in a sub-graph, computes total dissipation/maintenance draw, and outputs an effective per-node radiance/level.
   - Reusable for power grids, fluid pipelines, heat magistrals, and rail networks.

---

## 3. Barycentric Priority Triangle UI Component (`BarycentricTriangle`)

### Context & Gap
Sting provides `RadialDial`, `UIButton`, `UIWindow`, and `ProgressBar` in `lib/engine/components/`. For macro-control and indirect god-games, a 3-axis Barycentric Priority Triangle is a standard, highly expressive controller.

### Requirements for Sting
1. **Component Definition (`BarycentricTriangle`)**:
   - Flat Extension Type over `Float32List`:
     - `centerX`, `centerY`, `radius`, `rotation`
     - Weights: $W_A, W_B, W_C$ (summing to 1.0)
     - `puckX`, `puckY` (normalized or screen space)
     - `isDragging` (0.0 / 1.0)
     - Visual attributes: corner colors, puck color, stroke widths.
2. **System (`BarycentricTriangleSystem`)**:
   - Pointer hit-testing and dragging using `dart:ui` pointer coordinates.
   - Clamps puck position to the equilateral triangle boundary using barycentric coordinates $(w_A, w_B, w_C \ge 0, \sum w_i = 1)$.
   - Emits or stores updated weights directly in component memory for zero-allocation consumption by game systems.

---

## 4. Flat-Top Hex Marching / Boundary Line Rendering (`HexEdgeRenderSystem`)

### Context & Gap
`HexTilemapRenderSystem` batches atlas sprites for hex centers. However, games with road segments (Magistrals), territory boundaries, or frozen edge frontiers require rendering connected borders or outlines along hex edges without instantiating paths per frame.

### Requirements for Sting
1. **Batch Hex Edge Renderer**:
   - Pre-allocated vertex buffers or `Canvas.drawRawPoints` / `Canvas.drawVertices` to draw glowing boundary lines and magistral spines between neighboring hex centers `(q1, r1) -> (q2, r2)` in world space.

---

## 5. Settlement / Settlers-Style Edge Flow Balancing Primitives

### Context & Gap
Games with discrete logistics networks require edge balancing logic (comparing adjacent node deficits vs surpluses against network averages).

### Requirements for Sting
1. **Network Statistics Helper**:
   - Fast O(N) calculation of average stockpile values across connected nodes in a `NetworkGraph` to yield baseline targets for autonomous haulers without allocating collection objects.

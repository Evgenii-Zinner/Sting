# Sting Engine Backlog

This backlog breaks down the Sting Engine roadmap into highly granular tasks. AI Agents should select the highest priority task (from top to bottom), assume the required role, and execute the task adhering strictly to the `AGENTS.md` guidelines (TDD, zero allocations per frame).

Phase 1 through Phase 7 have been successfully completed and reviewed by the AI Architector. The engine is fully operational with DOD ECS, zero-allocation physics, spatial hashing, batch rendering, tilemaps, particle systems, audio event queuing, and high-level game state management.

## Completed Milestones & Phases

* [x] **Phase 1: Core ECS & Rendering Setup**
  * Setup raw `dart:ui` window hook
  * Implement basic Entity ID generator and Component storage (Sparse set)
  * Implement Query engine
  * Implement Render System (Sprite Component + `drawAtlas`)
  * Implement spatial hashing for basic bounds checking
* [x] **Phase 2: Game Loop, Time, Input & Kinematics**
  * Task 6.1: Delta Time Calculation
  * Task 7.1: Pointer Data Packet Hook
  * Task 8.1: Velocity Component
  * Task 8.2: Movement System
  * Task 9.1: Bounding Boxes and Circle Colliders
  * Task 9.2: Collision System Hookup
* [x] **Phase 3: Animations, Physics Resolution & Prefabs**
  * Task 10.1: SpriteAnimation Component
  * Task 10.2: Animation System
  * Task 11.1: Simple Resolution System
  * Task 12.1: Entity Prefabs/Spawning
* [x] **Phase 4: Viewport Camera & Text UI**
  * Task 13.1: Viewport Component
  * Task 13.2: Camera System
  * Task 14.1: TextRender Component
  * Task 14.2: Text Render System
* [x] **Phase 5: Tilemap & Particle Systems**
  * Task 15.1: Tilemap Component
  * Task 15.2: Tilemap Render System
  * Task 16.1: Particle Emitter Component
  * Task 16.2: Particle System Update & Render
* [x] **Phase 6: Audio Queue, Complex UI & Asset Streaming**
  * Task 17.1: Audio Event Queue
  * Task 17.2: Audio System Processing
  * Task 18.1: UI Bounding Box System
  * Task 18.2: Complex UI Rendering
  * Task 19.1: Chunk-Based Asset Manager
  * Task 19.2: Isolate-Based Asset Streaming
* [x] **Phase 7: Audio Enhancements & Game State**
  * Task 20.1: Extended Audio Event Queue
  * Task 21.1: Game State Component & System
* [x] **Phase 8: MVP Bullet Haven Showcase**
  * Task 22.1: Asset Generation Script
  * Task 22.2: MVP Game Setup & Game State
  * Task 22.3: Player Prefab & Movement
  * Task 22.4: Enemy Spawner System
  * Task 22.5: Auto-Firing Logic
  * Task 22.6: Damage & Score UI
* [x] **Phase 9: Cross-Platform, Web & Stabilization**
  * Task 20.1 (Web): Base64 Asset Embedding
  * Task 20.2 (Web): Fixed Timestep Game Loop
  * Task 20.3 (Web): Virtual Resolution and Aspect Ratio Scaling
  * Task 20.4 (Web): E2E Visual Testing with Playwright
  * Task 23.1: Audit Engine Subsystems
  * Task 23.2: E2E Deterministic Setup
  * Task 23.3: Playwright Visual Regression Tests
* [x] **Phase 10: Integration Testing Pivot**
  * Task 24.1: Cleanup E2E Artifacts
  * Task 24.2: Robust Subsystem Integration Testing
* [x] **Phase 11: Advanced N-Body Physics Engine**
  * Task 25.1: Gravitational Components
  * Task 25.2: Zero-Allocation Barnes-Hut Quadtree
  * Task 25.3: Gravity System Implementation
* [x] **Phase 12: Star System Showcase MVP**
  * Task 26.1: Star System Simulation & Logic Setup
  * Task 26.2: Interactive Configuration and Spawner UI
* [x] **Phase 13: Popular Engine Features & Quality of Life**
  * Task 27.1: Parallax Scrolling System
  * Task 27.2: Virtual Joypad UI Component
  * Task 27.3: Auto-Detect Control Schemes & Input Mapping
  * Task 27.4: Ultra-Fast 2D Lighting (No Raytracing)
  * Task 28.1: Bullet Haven Showcase Integration
  * Task 28.2: Star System Showcase Integration
  * Task 28.3: Showcase Integration & System Tests
* [x] **Phase 14: Advanced Features, Tooling & Production Readiness**
  * Task 29.1: World-Space Anchored UI (Immersive UI)
  * Task 29.2: Component Extension Type Code Generator
  * Task 29.3: Dedicated Memory Architecture & Limits Guide
  * Task 29.4: Cross-Platform Native Audio Integration
* [x] **Phase 15: General-Purpose Simulator & AI Systems**
  * Task 30.1: Hexagonal Grid Mathematics Library
  * Task 30.2: HexTilemap Component
  * Task 30.3: HexTilemap Render System
  * Task 30.4: Circular MovementQueue Component
  * Task 30.5: A* Grid Pathfinder System
  * Task 30.6: Utility AI Component
  * Task 30.7: Utility AI Bidding System
  * Task 30.8: Cross-Platform Shader Asset Loader
  * Task 30.9: ShaderMaterial Component & Custom Uniforms
  * Task 30.10: Batched Shader Render System Integration
  * Task 30.11: GridDiffusion Component & System
  * Task 30.12: Porting Showcase Integration & Subsystem Tests

## Active Milestone (Phase 16: Continuous 2D Space & Advanced Pathfinding/Avoidance)

* [ ] **Task 31.1: Spline & Polyline Library & Segment Query**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Implement a 2D spline (Bezier/Hermite) and polyline library with efficient segment queries (closest point on segment, distance to segment, capsule-sweep bounds checks) to support continuous roads and pipeline boundaries.
  * **Acceptance Criteria:** Mathematically correct segment projection and distance computation. 100% test coverage. Zero allocations per frame.

* [ ] **Task 31.2: Polygonal NavMesh & Pathfinding**
  * **Role Needed:** AI & Pathfinding Engineer
  * **Skill:** `skills/ai_pathfinding_engineer.json`
  * **Description:** Design a 2D polygonal navigation mesh (NavMesh) system that supports dynamic obstacle carving (cliffs, craters) and computes paths using A* over the dual graph or triangulation (e.g. Funnel algorithm).
  * **Acceptance Criteria:** Dynamic navigation mesh generation, obstacle carving, and pathfinding queries. 100% test coverage. Zero allocations per frame.

* [ ] **Task 31.3: Steering & Arrival Forces**
  * **Role Needed:** Physics and Math Engineer
  * **Skill:** `skills/physics_engineer.json`
  * **Description:** Implement continuous steering behaviors (Seek, Flee, and Arrive with deceleration thresholds) operating on entity position/velocity components.
  * **Acceptance Criteria:** Drones steer organically toward targets, slowing down on arrival without overshooting. 100% test coverage. Zero allocations per frame.

* [ ] **Task 31.4: Predictive RVO/ORCA Local Collision Avoidance**
  * **Role Needed:** AI & Pathfinding Engineer
  * **Skill:** `skills/ai_pathfinding_engineer.json`
  * **Description:** Implement predictive reciprocal collision avoidance (RVO/ORCA) in 2D continuous space to allow multiple drones to navigate narrow corridors without overlapping.
  * **Acceptance Criteria:** Multiple entities dynamically negotiate passing in narrow corridors without collision. 100% test coverage. Zero allocations per frame.

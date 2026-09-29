# PowerShell script to delegate 15 modular tasks to Jules CLI

$tasks = @(
    @{
        Name = "Task 1: Repository Hygiene & Linter Cleanup"
        Role = "Quality Assurance & Systems Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Quality Assurance & Systems Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter analyze and flutter test.

Task: Clean up remaining warnings, dead fields, and linter issues:
1. In lib/engine/math/nav_mesh_pathfinder.dart: Remove unused fields _portalLeft, _portalRight, and unused local variable bNext.
2. In pubspec.yaml: Remove leftover showcase assets under flutter.assets (keep test/assets/test_shader.frag).
3. In tools/: Remove obsolete showcase asset scripts (embed_assets.dart, embed_starsystem_assets.dart, generate_assets.dart, generate_combined_atlas.dart, generate_starsystem_assets.dart). Delete questions.md if present.
4. In tools/generate_components.dart: Wrap flow control statements in curly braces.
5. In lib/engine/components/complex_ui.dart and lib/engine/components/text_render.dart: Remove redundant unnecessary_getters_setters.
6. In test/integration/showcase_subsystem_test.dart: Rename to test/integration/engine_subsystem_test.dart and remove unused import of swarm.dart.
7. Clean up unused imports and variables in test/engine/components/hex_tilemap_test.dart (unused diameter), steering_test.dart, utility_ai_test.dart, hex_tilemap_render_system_test.dart, rvo_system_test.dart, and diffusion_system_test.dart (no_leading_underscores_for_local_identifiers).

Verify:
- flutter analyze returns 0 issues.
- flutter test passes all tests.
"@
    },
    @{
        Name = "Task 2: Binary Scene & Component Serialization System"
        Role = "Core ECS & Systems Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Core ECS & Systems Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement zero-allocation snapshot serialization and deserialization for Scene and ComponentCaste.
1. Create lib/engine/scene/scene_serializer.dart.
2. Implement binary serialization to ByteData / Uint8List that packs active entity count, entity IDs, and component caste memory buffers into a compact binary layout.
3. Implement deserialization that restores the Scene and registered ComponentCastes deterministically without JSON parsing or per-entity heap allocations.
4. Create comprehensive tests in test/engine/scene/scene_serializer_test.dart verifying round-trip serialization of scenes with Position, Velocity, and custom castes.

Verify:
- 100% test coverage. Zero runtime allocations.
"@
    },
    @{
        Name = "Task 3: Camera Deadzone & Smooth Lerp Follow System"
        Role = "Gameplay & Camera Systems Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Gameplay & Camera Systems Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement CameraFollow component and CameraFollowSystem.
1. Create lib/engine/components/camera_follow.dart using Float32List / Int32List backing or extension type:
   - targetEntity (int)
   - deadzoneWidth, deadzoneHeight (double)
   - lerpFactor (double, smoothing speed)
   - minX, minY, maxX, maxY (double, optional world bounds clamp)
2. Create lib/engine/systems/camera_follow_system.dart:
   - Updates Viewport position based on target entity position.
   - If entity moves inside deadzone rectangle, camera does not move. When outside, camera smoothly lerps toward entity.
   - Clamps camera viewport within world bounds (minX, minY, maxX, maxY).
   - Zero per-frame allocations.
3. Create test/engine/systems/camera_follow_system_test.dart with 100% test coverage.

Verify:
- flutter test passes cleanly.
"@
    },
    @{
        Name = "Task 4: SpatialHashGrid Collision Layer Bitmask Filtering"
        Role = "Physics and Math Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Physics and Math Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Enhance SpatialHashGrid with collision layer bitmask filtering.
1. In lib/engine/math/spatial_hash_grid.dart:
   - Add support for 32-bit integer layer masks.
   - Store layer mask per entity in an Int32List buffer.
   - Add/update insertPoint(int entity, double x, double y, [int layer = 1]) and insertAABB(int entity, double minX, double minY, double maxX, double maxY, [int layer = 1]).
   - Add optional parameter int mask = 0xFFFFFFFF to queryAABB, queryRadius, etc.
   - An entity is only added to the query results if (entityLayer & mask) != 0.
2. Ensure query scratch buffers maintain zero allocations.
3. Update and expand test/spatial_hash_grid_test.dart to test layer filtering thoroughly.

Verify:
- All existing and new tests pass. Zero allocations.
"@
    },
    @{
        Name = "Task 5: Zero-Allocation 2D Quadtree Spatial Index"
        Role = "Physics and Math Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Physics and Math Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement a zero-allocation 2D Quadtree spatial partitioning index.
1. Create lib/engine/math/quadtree2d.dart:
   - Node pool and entity index pool backed by flat Float32List and Int32List buffers (zero per-frame garbage).
   - Configurable maxEntitiesPerNode and maxDepth.
   - clear(): Resets node pool in O(1).
   - insert(int entity, double minX, double minY, double maxX, double maxY).
   - queryAABB(double minX, double minY, double maxX, double maxY, Int32List outEntities): Returns candidate entity count.
2. Create test/engine/math/quadtree2d_test.dart with comprehensive tests for subdivision, insertion, boundary queries, and zero allocation verification.

Verify:
- 100% test coverage. No heap allocations during queries.
"@
    },
    @{
        Name = "Task 6: Spline Trajectory Follower System"
        Role = "AI & Kinematics Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: AI & Kinematics Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement SplineFollower component and SplineFollowSystem.
1. Create lib/engine/components/spline_follower.dart:
   - Backed by Float32List / Int32List.
   - Stores currentDistance, speed, loopMode (0: once, 1: loop, 2: pingpong), direction (+1 or -1), alignRotation (bool flag).
2. Create lib/engine/systems/spline_follow_system.dart:
   - Advances distance along a Spline or Polyline at constant speed.
   - Updates Position component (x, y) and optionally Velocity or rotation angle based on spline tangent.
   - Zero per-frame allocations.
3. Create test/engine/systems/spline_follow_system_test.dart with 100% test coverage.

Verify:
- flutter test passes.
"@
    },
    @{
        Name = "Task 7: Particle Gradient & Lifetime Scaling Curves"
        Role = "Graphics Pipeline Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Graphics Pipeline Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Enhance ParticleEmitter and ParticleSystem with color gradient and scale curves.
1. In lib/engine/components/particle_emitter.dart:
   - Add startColor and endColor (32-bit ARGB integers).
   - Add startScale, midScale, endScale, and midScaleRatio (0.0 to 1.0).
   - Store in the existing flat buffers without adding object allocations.
2. In lib/engine/systems/particle_system.dart:
   - During particle update, interpolate ARGB color components (alpha, red, green, blue) linearly over particle lifetime.
   - Interpolate scale based on the piecewise curve (startScale -> midScale -> endScale).
   - Populate color and transform buffers for drawRawAtlas with zero allocations.
3. Update test/systems/particle_system_test.dart to test color and scale interpolation.

Verify:
- 100% test coverage. Zero allocations per frame.
"@
    },
    @{
        Name = "Task 8: 2D Raycast Query System on NavMesh and Segments"
        Role = "Physics and Math Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Physics and Math Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement 2D Raycast query utility against segments and NavMesh.
1. Create lib/engine/math/raycast2d.dart:
   - Create RaycastHit structure (extension type or reusable scratch object) with fields: hit (bool), pointX, pointY, normalX, normalY, distance, fraction, edgeIndex.
   - raycastSegment(double ox, double oy, double dx, double dy, double maxDist, double x1, double y1, double x2, double y2, RaycastHit outHit): Computes ray-segment intersection.
   - raycastPolyline(double ox, double oy, double dx, double dy, double maxDist, Polyline polyline, RaycastHit outHit): Finds closest intersection along polyline.
   - raycastNavMesh(double ox, double oy, double dx, double dy, double maxDist, NavMesh navMesh, RaycastHit outHit): Raycasts against obstacle boundaries of a NavMesh.
   - Pure math, zero allocations per query.
2. Create test/engine/math/raycast2d_test.dart covering parallel rays, missed rays, direct hits, surface normals, and corner cases.

Verify:
- 100% test coverage. Zero allocations.
"@
    },
    @{
        Name = "Task 9: Isometric Grid Mathematics Library"
        Role = "Math & Engine Systems Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Math & Engine Systems Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement IsometricMath utility for isometric coordinate conversions.
1. Create lib/engine/math/isometric_math.dart:
   - Mathematical conversions for 2D isometric projection (diamond and staggered modes).
   - worldToIsoDiamond(double wx, double wy, double tileWidth, double tileHeight, Float32List outCoord).
   - isoToWorldDiamond(double col, double row, double tileWidth, double tileHeight, Float32List outCoord).
   - worldToIsoStaggered(double wx, double wy, double tileWidth, double tileHeight, Float32List outCoord).
   - isoToWorldStaggered(double col, double row, double tileWidth, double tileHeight, Float32List outCoord).
   - getDepth(double col, double row): Depth sort key for isometric rendering.
   - Zero per-call allocations (output to pre-allocated Float32List or records).
2. Create test/engine/math/isometric_math_test.dart with complete bidirectional mapping tests and edge cases.

Verify:
- 100% test coverage. Zero allocations.
"@
    },
    @{
        Name = "Task 10: Isometric Tilemap Component & Render System"
        Role = "Graphics Pipeline Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Graphics Pipeline Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement IsometricTilemap component and IsometricTilemapRenderSystem.
1. Create lib/engine/components/isometric_tilemap.dart:
   - Backed by Int32List / Float32List.
   - Stores columns, rows, tileWidth, tileHeight, tileData (flat tile ID array), and isoType (diamond vs staggered).
2. Create lib/engine/systems/isometric_tilemap_render_system.dart:
   - Batch renders visible tiles using Canvas.drawRawAtlas.
   - Performs depth sorting and viewport culling in isometric space.
   - Pre-allocated RSTTransforms, rects, and colors buffers (zero allocations per frame).
3. Create test/engine/systems/isometric_tilemap_render_system_test.dart with mock canvas tests.

Verify:
- 100% test coverage. Zero allocations.
"@
    },
    @{
        Name = "Task 11: 2D Normal Map Bump Lighting Material Component"
        Role = "Graphics Pipeline Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Graphics Pipeline Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement NormalMapMaterial component for 2D bump-mapped dynamic lighting.
1. Create lib/engine/components/normal_map_material.dart:
   - Extension type over Float32List or ByteData.
   - Stores normalMapRect (source rect for normal map texture), bumpDepth, specularPower, and specularIntensity.
   - Integrates with LightRenderSystem and ShaderMaterial uniforms.
   - Zero allocations.
2. Create test/engine/components/normal_map_material_test.dart with complete unit tests for getters, setters, and uniform serialization.

Verify:
- 100% test coverage. Zero allocations.
"@
    },
    @{
        Name = "Task 12: Flocking Steering Behaviors (Alignment & Cohesion)"
        Role = "AI & Kinematics Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: AI & Kinematics Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement FlockingAgent component and FlockingSystem.
1. Create lib/engine/components/flocking_agent.dart:
   - Backed by Float32List.
   - Stores neighborRadius, separationWeight, alignmentWeight, cohesionWeight, maxForce.
2. Create lib/engine/systems/flocking_system.dart:
   - Implements Reynolds' classic boids flocking rules:
     * Separation: steer away from nearby agents within separation distance.
     * Alignment: steer in the average direction of local neighbors.
     * Cohesion: steer towards the average center of mass of local neighbors.
   - Uses SpatialHashGrid for local neighbor queries to maintain O(N) performance.
   - Zero allocations during update ticks.
3. Create test/engine/systems/flocking_system_test.dart testing flocking forces, weights, and zero allocation behavior.

Verify:
- 100% test coverage. Zero allocations.
"@
    },
    @{
        Name = "Task 13: Separating Axis Theorem (SAT) Convex Polygon Collision"
        Role = "Physics and Math Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Physics and Math Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement fast Separating Axis Theorem (SAT) convex polygon collision test.
1. Create lib/engine/math/sat_collision.dart:
   - SATCollisionResult structure: intersects (bool), normalX, normalY, depth (minimum translation vector).
   - testPolygonPolygon(Float32List polyA, int countA, Float32List polyB, int countB, SATCollisionResult outResult): Tests intersection between two convex polygons.
   - testPolygonCircle(Float32List poly, int count, double cx, double cy, double radius, SATCollisionResult outResult): Tests polygon vs circle.
   - Zero per-test allocations. Reusable scratch buffers for axis projection.
2. Create test/engine/math/sat_collision_test.dart testing overlapping polygons, separating polygons, contact normals, penetration depth, and corner touches.

Verify:
- 100% test coverage. Zero allocations.
"@
    },
    @{
        Name = "Task 14: Fixed-Point Deterministic Math Library"
        Role = "Math & Engine Systems Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Math & Engine Systems Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Implement Fixed64 fixed-point math library for deterministic simulation.
1. Create lib/engine/math/fixed64.dart:
   - Q32.32 fixed-point numeric representation using Dart 3 extension type over int: extension type const Fixed64(int rawValue) { ... }
   - Conversion: fromDouble, toDouble, fromInt, toInt.
   - Operations: +, -, *, /, abs, clamp, sqrt, sin, cos (using lookup table or Taylor series approximation).
   - FixedVec2 structure for 2D vectors (x: Fixed64, y: Fixed64).
   - Bit-exact deterministic results across all platforms with zero heap allocation overhead.
2. Create test/engine/math/fixed64_test.dart verifying arithmetic correctness, precision, edge cases, and deterministic consistency.

Verify:
- 100% test coverage. Zero allocations.
"@
    },
    @{
        Name = "Task 15: Comprehensive Performance Microbenchmark Suite"
        Role = "Performance and Optimization Engineer"
        Prompt = @"
You are an AI Contributor for the Sting game engine (bare-metal 2D ECS in Dart).
Role: Performance and Optimization Engineer.

Rules:
- Zero Allocations per frame. Pure dart:ui.
- Mandatory TDD: 100% test coverage. Run flutter test.

Task: Create engine subsystem microbenchmarks in benchmark/.
1. Create benchmark/ecs_query_benchmark.dart: Benchmarks Query1, Query2, Query3 iteration over 10,000 entities.
2. Create benchmark/barnes_hut_benchmark.dart: Benchmarks Barnes-Hut quadtree construction and gravitational force calculation on 2,000 bodies.
3. Create benchmark/nav_mesh_benchmark.dart: Benchmarks Funnel algorithm pathfinding queries across 100+ polygon mesh.
4. Create benchmark/rvo_benchmark.dart: Benchmarks RVO/ORCA collision avoidance solver on 500 interacting agents.
5. Create test/benchmark_sanity_test.dart: Sanity test executing each benchmark for a small number of iterations to ensure no exceptions and zero memory leaks.

Verify:
- flutter test passes. Benchmarks run without errors.
"@
    }
)

Write-Host "Starting delegation of $($tasks.Count) tasks to Jules..." -ForegroundColor Cyan

$results = @()

foreach ($t in $tasks) {
    Write-Host "Delegating: $($t.Name) [Role: $($t.Role)]..." -ForegroundColor Yellow
    
    # Run jules remote new
    $output = jules remote new --repo Evgenii-Zinner/Sting --session $t.Prompt
    
    # Extract session ID and URL
    $sessionId = ""
    $sessionUrl = ""
    foreach ($line in $output) {
        if ($line -match "ID:\s*(\d+)") {
            $sessionId = $matches[1]
        }
        if ($line -match "URL:\s*(https?://\S+)") {
            $sessionUrl = $matches[1]
        }
    }
    
    Write-Host " -> Session ID: $sessionId" -ForegroundColor Green
    Write-Host " -> URL: $sessionUrl" -ForegroundColor Cyan
    
    $results += [PSCustomObject]@{
        Name = $t.Name
        Role = $t.Role
        ID = $sessionId
        URL = $sessionUrl
    }
}

Write-Host "`nAll 15 tasks delegated to Jules successfully!" -ForegroundColor Green
$results | Format-Table -AutoSize

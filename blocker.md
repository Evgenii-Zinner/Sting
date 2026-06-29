# Blocker Report: GameplayCollisionSystem Test Failure

## Issue Description
While writing and running tests for the newly created `GameplayCollisionSystem`, a test failure occurs indicating that the projectile is not dealing damage and destroying the enemy (nor being destroyed itself).

### Test Context
File: `showcase/test/systems/gameplay_collision_system_test.dart`
Test: `'Projectile deals damage to enemy and spawns gem on kill'`

The test sets up an enemy at `[200.0, 200.0]` with a `BoundingBox` of `20.0 x 20.0` and a projectile at `[205.0, 205.0]` with a `BoundingBox` of `5.0 x 5.0`. The `SpatialHashGrid` is updated, and the `GameplayCollisionSystem.update()` is called.

Expected Result: The projectile and enemy positions should be `null` (since they should be destroyed via `scene.destroyEntity`).
Actual Result: The projectile's position is still present (`[205.0, 205.0]`).

### Potential Causes
1. **Spatial Hash Query:** The `_grid.queryAABB` might not be returning the enemy entity. The query uses `projectile.x` and `projectile.y` to define the search bounds. If the grid insertion or retrieval misses the cell, the callback won't fire.
2. **Component Lookup:** The projectile iterates over `damageCaste`, checks for `enemyAICaste == null`. The test creates the projectile with `Position`, `BoundingBox`, and `Damage` but NO `EnemyAI`. This should be correct.
3. **Destruction Logic during Iteration:** In the system, I've used `toDestroy` list to avoid modifying the entity list while iterating, but perhaps the iteration is still failing or the `damageCaste` query is incorrect.
4. **Collision Math:** The `_checkAABB` method checks for intersection. AABB overlap logic seems correct, but there could be an off-by-one or edge case.

Please assign this to an agent with ECS debugging skills to investigate and fix the collision resolution in the `GameplayCollisionSystem` or its test setup.

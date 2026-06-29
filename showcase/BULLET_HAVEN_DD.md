# Bullet Haven Design Document

## 1. Overview
This design document outlines the implementation plan for a Bullet Haven (Vampire Survivors-like) MVP using the Sting Engine.
The goal is to render thousands of on-screen entities (enemies, projectiles, experience gems) while maintaining a strict 60 FPS constraint via Sting's zero-allocation Data-Oriented Design (DOD).
This prototype will strictly utilize existing Sting APIs, proving the engine's maturity.

## 2. Core Mechanics

### 2.1 Player Movement
* **Components Used**: `Position`, `Velocity`, `Sprite`, `SpriteAnimation`, `BoundingBox`, `Viewport` (Camera Tracking).
* **Input Handling**: The player utilizes a virtual joystick or simple touch-and-drag mechanics hooked via Sting's zero-allocation `InputSystem`.
* **Action**: Dragging mutates the `Velocity` component. The `MovementSystem` calculates the integration using the frame's `dt`. The `CameraSystem` continuously locks the `Viewport` offset to the player's `Position`.

### 2.2 Massive Enemy Swarms
* **Components Used**: `Position`, `Velocity`, `Sprite`, `BoundingBox`, `EnemyAI` (A new, flat data extension type containing states like target tracking).
* **Spawning**: The `EnemySpawnSystem` runs on a fixed timer (managed via game loop `dt`). It queries `Swarm` for available entity IDs and populates flat arrays using predefined factory constants to spawn rings or swarms of enemies at screen edges.
* **Movement Logic**: A generic `Boid/ChaseSystem` updates enemy `Velocity` components directly towards the Player's coordinate, avoiding costly pathfinding objects.

### 2.3 Auto-Firing Weapons and Projectiles
* **Components Used**: `Position`, `Velocity`, `Sprite`, `BoundingBox`, `WeaponTimer` (to manage cooldowns).
* **Logic**: A `WeaponSystem` queries all active weapons. When the internal cooldown integer threshold is met, it queries the `SpatialHashGrid` to find the nearest enemy coordinates. It then spawns a projectile entity with a calculated `Velocity` vector.
* **Collision Resolution**: The `SpatialHashGrid` limits bounds checking iterations. The narrow-phase collision passes `entityA` (projectile) and `entityB` (enemy) to a resolution callback. Projectiles deal damage, destroy the enemy entity (returning ID to `Swarm`), and recycle themselves.

### 2.4 Experience Gem Pickups
* **Spawning on Death**: When an enemy entity is destroyed, its coordinate is immediately reused to spawn an `ExpGem` entity (a simple Sprite + Position + BoundingBox).
* **Magnet/Pickup Logic**: The player has an `ExpMagnet` component (larger radius). The collision system evaluates intersections between the `ExpMagnet` and `ExpGem` bounding boxes. Gems inside the radius have their `Velocity` altered to track the player. Upon intersection with the player's core bounding box, the gem entity is destroyed, and the player's global XP integer increases.

### 2.5 Level-Up Mechanics & UI
* **Components Used**: `GameState` (Global), `UICaste` (Screen-space bounds), `TextRender`, `ComplexUI` (Panels/Buttons).
* **Trigger**: When the global XP integer crosses a threshold level, the `GameStateSystem` transitions from `Playing` to `Menu/Paused`. This halts `MovementSystem` and `WeaponSystem` execution but keeps rendering systems active.
* **UI Construction**: The `LevelUpUISystem` initializes a set of cached `Path` and `ParagraphBuilder` components mapping to three selectable upgrade buttons (e.g., +Speed, +Damage).
* **Interaction**: The `UISystem` detects touches intersecting the `UICaste` bounds. Selecting an upgrade applies the stat modifier to the player, tears down the UI entities, and transitions the `GameState` back to `Playing`.

## 3. Rendering Strategy

* **Sprite Batching**: All moving entities (Player, Enemies, Projectiles, Gems) are packed into a single giant texture atlas loaded via Dart isolates.
* **Zero-Allocation Passes**: The `SpriteRenderSystem` slices out active entity data using `.sublistView()` on `Float32List` arrays, passing them directly to `Canvas.drawRawAtlas`.
* **Animations**: Simple walk cycles are handled via `SpriteAnimation` components updating the source `Rect` coordinates based on `dt`.
* **Tilemaps**: The background consists of a repeating `Tilemap` rendered via `TilemapRenderSystem`, allowing infinite scrolling without heavy asset costs.

## 4. Audio Implementation
* Background music and sound effects (gem pickup, enemy hit, weapon fire) are handled by enqueueing events into the `AudioSystem`'s flat `Int32List` ring buffer, adjusting volume/pitch modifiers via integer math to prevent mid-game stuttering.

## 5. Development Steps (Phase 8 Execution Plan)
1. **Asset Preparation**: Compile dummy textures (Player, Enemies, Gems, Tiles) into a master atlas.
2. **Core Loop Assembly**: Setup main isolate, `Swarm`, `Caste` pools, and baseline Systems (Render, Movement, Hash).
3. **Player & Camera**: Implement movement and viewport locking.
4. **Enemy & Weapons**: Implement auto-spawning, chasing logic, and auto-firing projectiles.
5. **XP & UI**: Implement gem drops, magnet logic, XP thresholding, and state-pausing upgrade UI.
6. **Polishing**: Wire up audio events and simple particle emitters for projectile impacts.
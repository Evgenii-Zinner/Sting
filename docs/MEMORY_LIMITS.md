# Sting Engine Memory Limits & Architecture Guide

Welcome to the memory limits and architecture guide for the Sting game engine. Sting is designed as a bare-metal, high-performance 2D Entity Component System (ECS) engine for Dart. To achieve a stable 60 or 120 FPS without GC (Garbage Collection) pauses, Sting mandates a strict **zero-allocation-per-frame** policy.

This guide provides deep technical insights, constraints, and concrete usage examples for maintaining these strict memory requirements.

---

## 1. The Static Memory Model (Zero Allocation)

Dart is a garbage-collected language. In many applications, allocating temporary objects is acceptable. However, in high-performance games, creating objects during the 60Hz/120Hz update or render loops triggers unpredictable GC stutters.

To circumvent this, Sting employs a **Static Memory Model**:
- **No `new` inside update/render:** You must never instantiate any standard Dart classes, lists, or Flutter Widgets during the engine's fixed timestep (`update`) or rendering pipeline (`render`).
- **Data-Oriented Design (DoD):** Components in Sting are not standard class objects. They are Dart 3 extension types wrapping flat, pre-allocated typed arrays (like `Float32List`, `Int32List`, `ByteData`).
- **Initialization Phase:** All required memory for your game state (entities, components, spatial grids, render batches, system caches) must be pre-allocated during the `Scene` initialization or application startup.

### Example: The Wrong Way (Causes GC Stutter)

```dart
// BAD: Allocating a new object every frame
class Vector2 { double x, y; Vector2(this.x, this.y); }

class MovementSystem {
  void update(double dt) {
    // Creating a new list AND new objects every frame!
    List<Vector2> positions = getPositions();
    for (var pos in positions) {
      pos.x += 10 * dt;
    }
  }
}
```

### Example: The Sting Way (Zero Allocation)

```dart
// GOOD: Modifying pre-allocated flat arrays
class MovementSystem {
  final Caste _positionCaste;

  MovementSystem(this._positionCaste);

  void update(double dt) {
    // Iterating over a pre-allocated dense array
    for (int i = 0; i < _positionCaste.length; i++) {
       // Component is an extension type struct pointing to the float buffer
       var position = _positionCaste.getComponentAt(i);
       position.x += 10 * dt;
    }
  }
}
```

---

## 2. The Swarm: Maximum Entity Count

The `Swarm` is Sting's core entity manager, responsible for creating, tracking, and destroying entities.

- **Maximum Entities (65,535):** The maximum number of simultaneous entities active in a Sting engine scene is hard-capped at 65,535 (`Swarm.maxEntities`).
- **Why 65,535?** By capping the entity count under 65,536, the engine can utilize `Uint16List` typed arrays internally for mapping Entity IDs. This halves memory consumption and vastly increases CPU cache line locality compared to using 32-bit integers (`Uint32List`).
- **Recycling:** The Swarm automatically recycles entity IDs from destroyed entities using an internal stack (`Int32List`), avoiding continuous incrementation that would rapidly exhaust the available 16-bit ID pool.

### Usage Example: Managing Entities via Scene

You should rarely interact with `Swarm` directly. Instead, use the `Scene` wrapper.

```dart
final scene = Scene();

// Creates an entity. 'entityId' will be an integer between 0 and 65534.
int playerEntityId = scene.createEntity();

if (playerEntityId == -1) {
  print('Failed to spawn: Swarm entity limit reached!');
}

// Destroying the entity recycles its ID for the next spawn
scene.destroyEntity(playerEntityId);
```

---

## 3. Caste: Preallocation Constraints

A `Caste` acts as the storage mechanism for components in Sting. It utilizes an integer-based **Sparse Set** data structure mapping Entity IDs to contiguous dense array indices, ensuring O(1) component lookups and cache-friendly contiguous iteration.

- **Sparse Array Footprint:** The sparse mapping array is always pre-allocated to the global maximum possible entities (`Swarm.maxEntities + 1`), consuming exactly 131,072 bytes (128 KB) per `Caste`.
- **Dense Array Capacity:** The dense array size is explicitly defined by the `capacity` parameter when you initialize the `Caste`. This capacity cannot exceed `Swarm.maxEntities + 1`.
- **No Dynamic Resizing:** A `Caste` cannot grow at runtime. Once you hit the defined `capacity` and attempt to add a component to a new entity, the engine will throw a `StateError`.

### Usage Example: Preallocating Castes

```dart
// Pre-allocate space for exactly 100 on-screen Health components
final healthCaste = ComponentCaste<Health>(100);

// Pre-allocate space for 2000 bullet velocity components
final velocityCaste = ComponentCaste<Velocity>(2000);

// Register them with the Scene during game initialization
scene.registerCaste<Health>('Health', healthCaste);
scene.registerCaste<Velocity>('Velocity', velocityCaste);
```

---

## 4. Memory Reuse Patterns

Sting leverages specific programming patterns to recycle memory on the fly rather than allocating anew during gameplay.

### Component Overwriting (O(1) Removal)
When an entity is removed from a `Caste`, the last active entity in the dense array is swapped into the removed entity's slot to keep the array contiguous. Its underlying component data is simply overwritten by subsequent additions. There is no `nulling` out or garbage collection involved.

### Reusable Frame Collections
If your system requires temporary lists within a frame (e.g., query result sets, arrays of entities to destroy, broad-phase collision pairs), you must define them as class-level `List<int>` or `List<double>` variables.

You can call `.clear()` at the start of your update loop. Dart retains the underlying capacity buffer without freeing memory back to the GC, effectively turning native lists into zero-overhead object pools.

### Usage Example: Reusable Frame Buffers

```dart
class CollisionSystem {
  // Class-level buffer. Dart will grow this once, and never shrink/GC it.
  final List<int> _entitiesToDestroy = [];

  void update() {
    // Clear the list (resets length to 0, but keeps allocated buffer capacity)
    _entitiesToDestroy.clear();

    // Query for collisions and populate the buffer
    _runCollisionChecks(_entitiesToDestroy);

    // Process removals without having allocated a new List this frame
    for (final entity in _entitiesToDestroy) {
      scene.destroyEntity(entity);
    }
  }
}
```

---

## 5. Best Practices for Sizing Component Caches

When starting up a game or scene, allocating precise capacities for your `ComponentCaste` instances is crucial for maintaining CPU cache locality and preventing memory bloat.

1. **Avoid Blind Over-allocating:** Do not lazily set all Castes to `Swarm.maxEntities` (65,535). If you only ever expect 50 NPCs, allocating a 65,535 capacity Caste for `NpcAIState` wastes RAM and pollutes the CPU cache with empty padded data.
2. **Match Simultaneous Gameplay Caps:** Set the capacity to the strict maximum number of simultaneous components your gameplay design actually permits.
   - Example: 100 on-screen enemies + 1 Player = `Health` capacity of 101.
   - Example: 1000 particles max = `ParticleLifetime` capacity of 1000.
   - Example: Local Co-Op = `PlayerInput` capacity of 4.
3. **Use the `Scene` Register Tool:** Leverage `Scene.registerCaste<T>('Name', ComponentCaste<T>(capacity))` to centrally manage and document your memory footprint during initialization.
4. **Stress Testing Constraints:** Use load-testing scripts, mass spawner tools, or internal metrics during QA to confirm you never hit a `StateError('Caste is at full capacity...')` during the most intense gameplay scenarios (e.g., triggering a smart-bomb that spawns 500 explosions).

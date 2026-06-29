# Sting Engine: Comprehensive Guide & Zero-to-Hero Tutorial

Welcome to the Sting Engine, a bare-metal, high-performance 2D game engine built in Dart. Sting bypasses the Flutter UI framework entirely (`runApp`, `Widgets`, `BuildContext`) to achieve maximum performance and zero garbage collection allocations per frame, making it ideal for games with massive entity counts like bullet hells or swarm simulators.

This guide provides a comprehensive overview of the engine's subsystems, how to use its core APIs, and a Zero-to-Hero tutorial to get your first game running.

---

## 1. Engine Philosophy and Architecture

Sting is built strictly around **Data-Oriented Design (DOD)** and an **Entity Component System (ECS)**. The golden rule of Sting is **Zero Allocations per Frame**. This means you must never instantiate new objects inside loops that run every frame.

*   **Entities** are purely integers (`int`).
*   **Components** are flat data structures (often `TypedData` arrays like `Float32List` or `Int32List`).
*   **Systems** are stateless functions that iterate over arrays of components.
*   **Dart 3 Features**: Heavy use of Records, Patterns, and Extension Types to achieve zero-cost abstractions.

---

## 2. Core Subsystems

### 2.1 ECS Core: Swarm, Caste, and Queries

*   **Swarm (Entity Manager)**: Manages the allocation and recycling of integer entity IDs. It tracks up to 65,535 active entities using bit-flags (`Uint32List`) for O(1) liveness checks and zero allocations.
*   **Caste (Component Storage)**: A Sparse Set implementation mapping entity IDs to dense component array indices using the Briggs & Torczon validation technique. This allows O(1) clears and prevents the need for sentinel initialization.
*   **Queries (`Query1`, `Query2`)**: Allow fast iteration over entities that possess specific components. Iteration is done via callbacks to strictly prevent iterator object allocations.

### 2.2 Rendering Subsystem

Sting binds directly to `dart:ui` (`Canvas`, `PlatformDispatcher`).
*   **Sprite Rendering**: Relies on `Canvas.drawRawAtlas`. Data is passed using `.sublistView()` on flat `Float32List` arrays, completely avoiding the instantiation of `Rect` and `RSTransform` objects on every frame.
*   **Tilemaps**: Rendered using a `TilemapRenderSystem` using flat `Int32List` arrays.
*   **Camera/Viewport**: Handled via canvas transformation (save, translate, scale, restore) rather than instantiating camera objects per entity.
*   **Asset Streaming**: Assets are decoded directly from `dart:io` `File` via raw pixel buffers in isolates to prevent main thread blocking, avoiding Flutter's `AssetBundle`.

### 2.3 Physics and Kinematics Subsystem

*   **Broad-phase**: Uses a `SpatialHashGrid` storing entity IDs in cell buckets via flat 1D index mapping.
*   **Narrow-phase**: Math functions (AABB, Circle) strictly accept raw unboxed floats (x, y, w, h, r).
*   **Collision Resolution**: Handled via `SimpleResolutionSystem` providing callbacks for immediate positional separation. Continuous Collision Detection (CCD) is intentionally omitted for performance.
*   **Movement**: Standard Eulerian integration via `MovementSystem` (`Velocity * dt`).

### 2.4 Input Subsystem

*   Hooks directly into `PlatformDispatcher.instance.onPointerDataPacket`.
*   Bypasses Flutter's gesture system, managing flat array slots (`Float32List`, `Int32List`) to track active pointers and their screen coordinates with zero allocations.

### 2.5 Audio Subsystem

*   An event-driven audio dispatcher built around flat queues (`Int32List`).
*   Audio requests (sound ID, volume, pitch) are pushed into ring buffers and processed in bulk.

### 2.6 UI Subsystem

*   Specialized `UICaste` focusing on screen-space AABB collisions synchronized with input pointer slots.
*   Rendering objects (`ParagraphBuilder`, `Path`) are cached on components and rebuilt only on state shifts.

### 2.7 Game State Management

*   A global `GameState` component attached to a singleton entity ID tracks high-level states (Menu, Playing, Paused, GameOver). Logic systems selectively update based on these states.

---

## 3. Endpoints and API Usage

### Managing Entities with `Swarm`
```dart
final swarm = Swarm();
int entityId = swarm.createEntity();
swarm.destroyEntity(entityId);
```

### Storing Data with Components and `Caste`
Components should be simple data holders, ideally wrapping typed data.
```dart
class Position {
  final Float32List data;
  Position(this.data);
  // Extension types are preferred in Sting for zero-cost abstractions
}

final positionCaste = Caste(1000); // Capacity for 1000 entities
final positionData = ComponentCaste<Position>(positionCaste, List.filled(1000, null));

// Add entity to caste
positionCaste.add(entityId);
// Sync data
positionData.set(entityId, Position(Float32List(2)));
```

### Querying with `Query1` and `Query2`
```dart
final query = Query2<Position, Velocity>(positionCaste, velocityCaste);

query.forEach((entity, pos, vel) {
  // Update position based on velocity
  pos.x += vel.x * dt;
  pos.y += vel.y * dt;
});
```

---

## 4. Zero-to-Hero Tutorial: Creating a Working Game

Let's build a minimal "Moving Square" game from an empty project.

### Step 1: Initialize the Engine Loop
Instead of `runApp()`, we hook into `PlatformDispatcher`.

```dart
import 'dart:ui';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/time.dart';

void main() {
  final swarm = Swarm();
  final time = Time();

  PlatformDispatcher.instance.onBeginFrame = (Duration timeStamp) {
    time.update(timeStamp.inMicroseconds);
    double dt = time.dt;

    // 1. Run Systems (Input, Movement, Physics) here

    PlatformDispatcher.instance.scheduleFrame();
  };

  PlatformDispatcher.instance.onDrawFrame = () {
    // 2. Render Systems here
    renderFrame();
  };

  PlatformDispatcher.instance.scheduleFrame();
}
```

### Step 2: Define Components and Castes
We need a `Position` and `Velocity`. We will simulate a simple component setup.

```dart
import 'dart:typed_data';
import 'package:sting/engine/ecs/caste.dart';
import 'package:sting/engine/ecs/component_caste.dart';

// Using Extension Types for zero-allocation
extension type Position(Float32List _data) {
  Position.init(double x, double y) : this(Float32List.fromList([x, y]));
  double get x => _data[0];
  set x(double val) => _data[0] = val;
  double get y => _data[1];
  set y(double val) => _data[1] = val;
}

extension type Velocity(Float32List _data) {
  Velocity.init(double dx, double dy) : this(Float32List.fromList([dx, dy]));
  double get dx => _data[0];
  double get dy => _data[1];
}
```

### Step 3: Setup ECS Data
Initialize the Swarm and Castes in your `main()`.

```dart
final swarm = Swarm();
final maxEntities = 100;

final posCaste = Caste(maxEntities);
final posData = ComponentCaste<Position>(posCaste, List.generate(maxEntities, (_) => Position.init(0, 0)));

final velCaste = Caste(maxEntities);
final velData = ComponentCaste<Velocity>(velCaste, List.generate(maxEntities, (_) => Velocity.init(0, 0)));

// Spawn our hero entity
int player = swarm.createEntity();
posCaste.add(player);
posData.set(player, Position.init(100, 100));

velCaste.add(player);
velData.set(player, Velocity.init(50, 50)); // Move 50 pixels per second
```

### Step 4: Create Systems
Create a `MovementSystem` using `Query2`.

```dart
import 'package:sting/engine/ecs/query.dart';

class MovementSystem {
  final Query2<Position, Velocity> query;

  MovementSystem(this.query);

  void update(double dt) {
    query.forEach((entity, pos, vel) {
      pos.x += vel.dx * dt;
      pos.y += vel.dy * dt;
    });
  }
}
```

### Step 5: Render the Game
Use `dart:ui` directly to draw the frame.

```dart
void renderFrame(ComponentCaste<Position> posData) {
  final dispatcher = PlatformDispatcher.instance;
  final view = dispatcher.views.first;
  final physicalSize = view.physicalSize;

  final recorder = PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & physicalSize);

  // Clear screen
  canvas.drawColor(const Color(0xFF000000), BlendMode.src);

  final paint = Paint()..color = const Color(0xFF00FF00); // Green square

  // Render entities
  final query = Query1<Position>(posData.caste);
  query.forEach((entity, pos) {
    canvas.drawRect(Rect.fromLTWH(pos.x, pos.y, 50, 50), paint);
  });

  final picture = recorder.endRecording();
  final sceneBuilder = SceneBuilder()..addPicture(Offset.zero, picture);
  view.render(sceneBuilder.build());
}
```

### Step 6: Putting it all together
Update your `main()` loop to call the systems.

```dart
void main() {
  // ... initialization from above ...
  final movementSystem = MovementSystem(Query2(posData, velData));

  PlatformDispatcher.instance.onBeginFrame = (Duration timeStamp) {
    time.update(timeStamp.inMicroseconds);
    movementSystem.update(time.dt);
    PlatformDispatcher.instance.scheduleFrame();
  };

  PlatformDispatcher.instance.onDrawFrame = () {
    renderFrame(posData);
  };

  PlatformDispatcher.instance.scheduleFrame();
}
```

Congratulations! You have just built a bare-metal, zero-allocation game engine loop using Sting. The green square will continuously move across the screen!
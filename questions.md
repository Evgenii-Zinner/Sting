# Open Questions

## Task 10.2: Animation System

* **Sprite Rect Update**: The acceptance criteria for `AnimationSystem` specifies transitioning the `Sprite`'s source rect to the next frame. However, there is no frame width or layout configuration (horizontal strip vs grid) available in `Sprite` or `SpriteAnimation` components. How should the `AnimationSystem` compute the new `rectLeft` and `rectRight` for the next frame without making assumptions about the sprite layout?

## Task 11.1: Simple Resolution System

* **Integration with CollisionSystem**: The `SimpleResolutionSystem` provides methods to resolve overlaps (e.g. `resolveAABBAABB(entityA, entityB)`), but it currently needs to be explicitly called. Should the `CollisionSystem` accept these resolution callbacks automatically when iterating pairs, or should there be a higher-level `PhysicsSystem` that queries pairs of overlapping entities using the `CollisionSystem` and applies the `SimpleResolutionSystem` in a single pass?
* **Continuous Collision Detection (CCD)**: The current simple positional separation handles overlaps after they occur. For fast-moving objects, they might pass entirely through each other within a single frame. Should future tasks incorporate swept AABB/Circle math for CCD, and if so, how should we adapt the flat-array approach to store velocity deltas during resolution?

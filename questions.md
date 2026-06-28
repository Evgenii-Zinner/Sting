# SpriteAnimation Component Concerns

As the Animation Engineer for Task 10.1, I have implemented `SpriteAnimation` strictly using a `Float32List` to adhere to zero-allocation and GC pause constraints, storing `currentFrameIndex`, `frameDuration`, `elapsedTime`, and `frameCount`.

**Concerns for Task 10.2 (Animation System):**
Since `SpriteAnimation` only tracks timing and frame counts, how will the `AnimationSystem` know the spatial dimensions of the frames in the spritesheet?
Typically, an animation needs to know `frameWidth`, `frameHeight`, and starting coordinates. Storing these inside `SpriteAnimation` would increase its memory footprint.

Options for Task 10.2:
1. Update `SpriteAnimation` to include `frameWidth` and `frameHeight`.
2. Rely on the `Sprite` component's existing `rect` coordinates to infer frame size, assuming the spritesheet frames are contiguous and uniform. (e.g., `newRectLeft = oldRectLeft + width`).
3. Introduce a separate system or shared resource that maps entity ID or animation type to spatial frame data.

These tradeoffs between memory consumption and flexibility should be carefully considered during Task 10.2 implementation.

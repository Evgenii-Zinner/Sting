# Open Questions

## Task 10.2: Animation System

* **Sprite Rect Update**: The acceptance criteria for `AnimationSystem` specifies transitioning the `Sprite`'s source rect to the next frame. However, there is no frame width or layout configuration (horizontal strip vs grid) available in `Sprite` or `SpriteAnimation` components. How should the `AnimationSystem` compute the new `rectLeft` and `rectRight` for the next frame without making assumptions about the sprite layout?

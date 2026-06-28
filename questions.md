# Questions regarding Audio System Implementation

1. **Audio Event Data Layout:** What exactly should be stored in each audio event within the `Int32List` queue besides `soundId` (playback handle) and `entityId`? Should it include parameters like `volume`, `pitch`, or `loop` status? If so, what precision/representation (e.g. integer encoding for fixed-point math) is expected to stay within `Int32List` bounds?
2. **Audio Package:** Which low-level audio package or FFI bindings will the `AudioSystem` use for playback?

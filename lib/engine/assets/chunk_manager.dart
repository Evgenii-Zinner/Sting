import 'dart:typed_data';

/// A chunk-based memory manager for streaming assets.
/// Maintains a pre-allocated active array of chunks using a flat [Int32List]
/// to enforce zero allocations in the update loop.
class ChunkManager {
  final int maxActiveChunks;
  // Format: [x, y, ... repeated for maxActiveChunks]
  final Int32List _activeChunks;
  // 0 = empty/free slot, 1 = occupied
  final Int8List _chunkStatus;

  /// Callback when a chunk enters the active radius.
  void Function(int x, int y)? onChunkLoad;

  /// Callback when a chunk leaves the active radius.
  void Function(int x, int y)? onChunkUnload;

  ChunkManager({
    this.maxActiveChunks = 64,
    this.onChunkLoad,
    this.onChunkUnload,
  })  : _activeChunks = Int32List(maxActiveChunks * 2),
        _chunkStatus = Int8List(maxActiveChunks);

  /// Updates the chunk loading state based on a spatial position.
  /// No objects are allocated in this method.
  void updatePosition(double x, double y, double chunkSize, int loadRadius) {
    final int centerChunkX = (x / chunkSize).floor();
    final int centerChunkY = (y / chunkSize).floor();

    final int minX = centerChunkX - loadRadius;
    final int maxX = centerChunkX + loadRadius;
    final int minY = centerChunkY - loadRadius;
    final int maxY = centerChunkY + loadRadius;

    // 1. Unload out-of-bounds chunks
    for (int i = 0; i < maxActiveChunks; i++) {
      if (_chunkStatus[i] == 1) {
        final int cx = _activeChunks[i * 2];
        final int cy = _activeChunks[i * 2 + 1];

        if (cx < minX || cx > maxX || cy < minY || cy > maxY) {
          // Unload it
          if (onChunkUnload != null) {
            onChunkUnload!(cx, cy);
          }
          _chunkStatus[i] = 0;
        }
      }
    }

    // 2. Load in-bounds chunks
    for (int cy = minY; cy <= maxY; cy++) {
      for (int cx = minX; cx <= maxX; cx++) {
        bool isLoaded = false;

        // Check if already loaded
        for (int i = 0; i < maxActiveChunks; i++) {
          if (_chunkStatus[i] == 1 &&
              _activeChunks[i * 2] == cx &&
              _activeChunks[i * 2 + 1] == cy) {
            isLoaded = true;
            break;
          }
        }

        if (!isLoaded) {
          for (int i = 0; i < maxActiveChunks; i++) {
            if (_chunkStatus[i] == 0) {
              _chunkStatus[i] = 1;
              _activeChunks[i * 2] = cx;
              _activeChunks[i * 2 + 1] = cy;
              if (onChunkLoad != null) {
                onChunkLoad!(cx, cy);
              }
              break;
            }
          }
          // If no free slot was found, we silently drop the chunk load request to avoid crashing,
          // as per zero-allocation flat array constraints (size is fixed).
        }
      }
    }
  }

  /// Manually clear all active chunks.
  void clear() {
    for (int i = 0; i < maxActiveChunks; i++) {
      if (_chunkStatus[i] == 1) {
        final int cx = _activeChunks[i * 2];
        final int cy = _activeChunks[i * 2 + 1];
        if (onChunkUnload != null) {
          onChunkUnload!(cx, cy);
        }
        _chunkStatus[i] = 0;
      }
    }
  }
}

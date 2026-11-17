import 'dart:typed_data';

/// A chunk-based memory manager for streaming assets.
/// Maintains a pre-allocated active array of chunks using flat typed arrays
/// and an open-addressing hash index to enforce zero allocations and O(1)
/// chunk lookups/slot allocation in the update loop.
class ChunkManager {
  final int maxActiveChunks;
  // Format: [x, y, ... repeated for maxActiveChunks]
  final Int32List _activeChunks;
  // 0 = empty/free slot, 1 = occupied
  final Int8List _chunkStatus;
  // Pre-allocated free-slot stack for O(1) slot allocation.
  final Int32List _freeSlots;
  int _freeTop;

  // Open-addressing hash table mapping (cx, cy) -> slot index.
  // -1 = empty, -2 = tombstone, >= 0 = active slot index.
  final Int32List _hashTable;
  final int _tableMask;
  int _tombstones = 0;

  /// Callback when a chunk enters the active radius.
  void Function(int x, int y)? onChunkLoad;

  /// Callback when a chunk leaves the active radius.
  void Function(int x, int y)? onChunkUnload;

  ChunkManager({
    this.maxActiveChunks = 64,
    this.onChunkLoad,
    this.onChunkUnload,
  })  : _activeChunks = Int32List(maxActiveChunks * 2),
        _chunkStatus = Int8List(maxActiveChunks),
        _freeSlots = Int32List(maxActiveChunks),
        _freeTop = maxActiveChunks,
        _tableMask = _computeTableSize(maxActiveChunks) - 1,
        _hashTable = Int32List(_computeTableSize(maxActiveChunks)) {
    for (int i = 0; i < maxActiveChunks; i++) {
      _freeSlots[i] = maxActiveChunks - 1 - i;
    }
    _hashTable.fillRange(0, _hashTable.length, -1);
  }

  static int _computeTableSize(int maxActive) {
    int size = 8;
    final int target = maxActive * 2;
    while (size < target) {
      size <<= 1;
    }
    return size;
  }

  int _hash(int cx, int cy) {
    return ((cx * 73856093) ^ (cy * 19349663)) & _tableMask;
  }

  bool _containsChunk(int cx, int cy) {
    final int len = _hashTable.length;
    int idx = _hash(cx, cy);
    for (int probe = 0; probe < len; probe++) {
      final int slot = _hashTable[idx];
      if (slot == -1) return false;
      if (slot >= 0 &&
          _activeChunks[slot * 2] == cx &&
          _activeChunks[slot * 2 + 1] == cy) {
        return true;
      }
      idx = (idx + 1) & _tableMask;
    }
    return false;
  }

  void _insertHash(int cx, int cy, int slot) {
    final int len = _hashTable.length;
    int idx = _hash(cx, cy);
    for (int probe = 0; probe < len; probe++) {
      final int existing = _hashTable[idx];
      if (existing < 0) {
        if (existing == -2) _tombstones--;
        _hashTable[idx] = slot;
        return;
      }
      idx = (idx + 1) & _tableMask;
    }
  }

  void _removeHash(int cx, int cy) {
    final int len = _hashTable.length;
    int idx = _hash(cx, cy);
    for (int probe = 0; probe < len; probe++) {
      final int slot = _hashTable[idx];
      if (slot == -1) return;
      if (slot >= 0 &&
          _activeChunks[slot * 2] == cx &&
          _activeChunks[slot * 2 + 1] == cy) {
        _hashTable[idx] = -2;
        _tombstones++;
        return;
      }
      idx = (idx + 1) & _tableMask;
    }
  }

  void _rehashIfNeeded() {
    if (_tombstones <= (maxActiveChunks >> 1)) return;
    _hashTable.fillRange(0, _hashTable.length, -1);
    _tombstones = 0;
    for (int i = 0; i < maxActiveChunks; i++) {
      if (_chunkStatus[i] == 1) {
        _insertHash(_activeChunks[i * 2], _activeChunks[i * 2 + 1], i);
      }
    }
  }

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
          _removeHash(cx, cy);
          _chunkStatus[i] = 0;
          _freeSlots[_freeTop++] = i;
          if (onChunkUnload != null) {
            onChunkUnload!(cx, cy);
          }
        }
      }
    }

    _rehashIfNeeded();

    // 2. Load in-bounds chunks
    for (int cy = minY; cy <= maxY; cy++) {
      for (int cx = minX; cx <= maxX; cx++) {
        if (_freeTop == 0) return;
        if (_containsChunk(cx, cy)) continue;

        final int slot = _freeSlots[--_freeTop];
        _chunkStatus[slot] = 1;
        _activeChunks[slot * 2] = cx;
        _activeChunks[slot * 2 + 1] = cy;
        _insertHash(cx, cy, slot);
        if (onChunkLoad != null) {
          onChunkLoad!(cx, cy);
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
        _freeSlots[_freeTop++] = i;
      }
    }
    _hashTable.fillRange(0, _hashTable.length, -1);
    _tombstones = 0;
  }
}

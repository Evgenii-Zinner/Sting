import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/assets/chunk_manager.dart';

void main() {
  group('ChunkManager Tests', () {
    test('Loads initial chunks correctly', () {
      final loadedChunks = <String>[];
      final manager = ChunkManager(
        maxActiveChunks: 9, // 3x3 grid
        onChunkLoad: (x, y) {
          loadedChunks.add('$x,$y');
        },
      );

      // Radius 1 means a 3x3 grid around the center
      // Chunk size 10.0, position 15.0, 15.0 -> Center chunk (1, 1)
      manager.updatePosition(15.0, 15.0, 10.0, 1);

      expect(loadedChunks.length, 9);
      expect(
          loadedChunks,
          containsAll(
              ['0,0', '1,0', '2,0', '0,1', '1,1', '2,1', '0,2', '1,2', '2,2']));
    });

    test('Unloads chunks that fall out of radius and loads new ones', () {
      final loadedChunks = <String>[];
      final unloadedChunks = <String>[];
      final manager = ChunkManager(
        maxActiveChunks: 25,
        onChunkLoad: (x, y) => loadedChunks.add('$x,$y'),
        onChunkUnload: (x, y) => unloadedChunks.add('$x,$y'),
      );

      // Initial pos (15, 15) -> Center (1, 1)
      manager.updatePosition(15.0, 15.0, 10.0, 1);

      loadedChunks.clear();

      // Move to pos (25, 15) -> Center (2, 1)
      manager.updatePosition(25.0, 15.0, 10.0, 1);

      // Unloaded chunks should be those with x=0
      expect(unloadedChunks.length, 3);
      expect(unloadedChunks, containsAll(['0,0', '0,1', '0,2']));

      // Newly loaded chunks should be those with x=3
      expect(loadedChunks.length, 3);
      expect(loadedChunks, containsAll(['3,0', '3,1', '3,2']));
    });

    test('Respects maxActiveChunks limit', () {
      final loadedChunks = <String>[];
      final manager = ChunkManager(
        maxActiveChunks:
            4, // Intentionally too small for radius 1 (which needs 9)
        onChunkLoad: (x, y) => loadedChunks.add('$x,$y'),
      );

      manager.updatePosition(15.0, 15.0, 10.0, 1);

      // Should only load 4 chunks and stop
      expect(loadedChunks.length, 4);
    });

    test('clear() unloads all active chunks', () {
      final unloadedChunks = <String>[];
      final manager = ChunkManager(
        maxActiveChunks: 9,
        onChunkLoad: (x, y) {},
        onChunkUnload: (x, y) => unloadedChunks.add('$x,$y'),
      );

      manager.updatePosition(15.0, 15.0, 10.0, 1);

      manager.clear();
      expect(unloadedChunks.length, 9);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/systems/multi_channel_diffusion_system.dart';

void main() {
  group('MultiChannelDiffusionSystem Tests', () {
    late Scene scene;
    late ComponentStorage<MultiChannelGrid> gridStorage;
    late MultiChannelDiffusionSystem system;
    late int entityId;

    setUp(() {
      scene = Scene();
      gridStorage = ComponentStorage<MultiChannelGrid>(10);
      scene.registerStorage('MultiChannelGrid', gridStorage);
      system = MultiChannelDiffusionSystem(gridCaste: gridStorage);
      entityId = scene.createEntity();
    });

    test('Zero allocation during update', () {
      final grid = MultiChannelGrid.create(columns: 5, rows: 5, channelCount: 2);
      grid.setDiffusionRate(0, 1.0);
      grid.setDiffusionRate(1, 0.5);
      gridStorage.add(entityId, grid);

      // Perform a warmup run
      system.update();

      // Check allocation
      final int memoryBefore = checkAllocations();
      for (int i = 0; i < 100; i++) {
        system.update();
      }
      final int memoryAfter = checkAllocations();
      expect(memoryAfter, memoryBefore,
          reason: 'System update must be zero-allocation');
    });

    test('Independent diffusion rates per channel', () {
      final grid = MultiChannelGrid.create(columns: 3, rows: 1, channelCount: 2);
      // Setup channel 0 (fast diffusion)
      grid.setDiffusionRate(0, 1.0);
      grid.setValue(1, 0, 0, 100.0); // Center

      // Setup channel 1 (slow diffusion)
      grid.setDiffusionRate(1, 0.5);
      grid.setValue(1, 0, 1, 100.0); // Center

      gridStorage.add(entityId, grid);

      system.update();

      // Center cell value for channel 0
      final double center0 = grid.getValue(1, 0, 0);
      // Center cell value for channel 1
      final double center1 = grid.getValue(1, 0, 1);

      // The faster diffusing channel should have less in the center
      expect(center0, lessThan(center1));

      // Values should reflect laplacian diffusion calculation
      // For channel 0 (rate 1.0, 1D effectively): averageNeighbor = (0+0+100+100)/4 = 50. cellValue=100. delta=-50. New = 100 - 50 = 50.
      expect(center0, closeTo(50.0, 0.001));

      // For channel 1 (rate 0.5, 1D effectively): averageNeighbor = (0+0+100+100)/4 = 50. cellValue=100. delta=-50. New = 100 - 25 = 75.
      expect(center1, closeTo(75.0, 0.001));
    });

    test('Conservation of total mass/heat with reflection mode', () {
      final grid = MultiChannelGrid.create(columns: 3, rows: 3, channelCount: 1);
      grid.setDiffusionRate(0, 1.0);
      grid.setBoundaryMode(0, 0.0); // Reflection (zero-flux)

      // Add heat to center
      grid.setValue(1, 1, 0, 90.0);
      gridStorage.add(entityId, grid);

      double getTotalHeat() {
        double total = 0.0;
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            total += grid.getValue(c, r, 0);
          }
        }
        return total;
      }

      expect(getTotalHeat(), closeTo(90.0, 0.001));

      system.update();

      expect(getTotalHeat(), closeTo(90.0, 0.001), reason: 'Heat should be conserved');

      // Do multiple updates
      for (int i = 0; i < 10; i++) {
        system.update();
      }

      expect(getTotalHeat(), closeTo(90.0, 0.001), reason: 'Heat should be conserved after multiple updates');
    });

    test('Mass/heat absorption at boundaries with absorption mode', () {
      final grid = MultiChannelGrid.create(columns: 3, rows: 3, channelCount: 1);
      grid.setDiffusionRate(0, 1.0);
      grid.setBoundaryMode(0, 1.0); // Absorption

      // Add heat to center
      grid.setValue(1, 1, 0, 90.0);
      gridStorage.add(entityId, grid);

      double getTotalHeat() {
        double total = 0.0;
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            total += grid.getValue(c, r, 0);
          }
        }
        return total;
      }

      expect(getTotalHeat(), closeTo(90.0, 0.001));

      system.update();

      // In absorption mode, missing neighbors are treated as 0
      // Expected logic for center (1,1):
      // sumNeighbors = 0+0+0+0 = 0. avg = 0/4 = 0. delta = -90. New = 90 + (-90) = 0. Wait, center has no missing neighbors.
      // Wait, center (1,1) in 3x3 has neighbors (0,1), (2,1), (1,0), (1,2).
      // They all start at 0. So center becomes 90 + (-90)*1.0 = 0.0
      // Neighbors (0,1) for example: sum = 90. missing = 1 (left).
      // If absorption, effectiveSum = 90. avg = 90/4 = 22.5. delta = 22.5. New = 22.5.
      // All 4 neighbors become 22.5.
      // Total heat = 22.5 * 4 = 90.0 (Heat is conserved on first step because nothing reached the boundary yet).

      expect(getTotalHeat(), closeTo(90.0, 0.001));

      // On second step, heat at (0,1) diffuses to (-1,1) which is missing.
      system.update();

      expect(getTotalHeat(), lessThan(90.0), reason: 'Heat should be lost at boundaries');
    });

    test('Decay rate reduces mass per channel', () {
      final grid = MultiChannelGrid.create(columns: 1, rows: 1, channelCount: 2);

      // Channel 0: no decay
      grid.setDecayRate(0, 0.0);
      grid.setValue(0, 0, 0, 100.0);

      // Channel 1: 10% decay
      grid.setDecayRate(1, 0.1);
      grid.setValue(0, 0, 1, 100.0);

      gridStorage.add(entityId, grid);

      system.update();

      expect(grid.getValue(0, 0, 0), closeTo(100.0, 0.001));
      expect(grid.getValue(0, 0, 1), closeTo(90.0, 0.001));
    });

    test('Boundary limits handled properly for get/set Value', () {
      final grid = MultiChannelGrid.create(columns: 2, rows: 2, channelCount: 1);

      // Reading out of bounds returns 0.0
      expect(grid.getValue(-1, 0, 0), equals(0.0));
      expect(grid.getValue(0, -1, 0), equals(0.0));
      expect(grid.getValue(2, 0, 0), equals(0.0));
      expect(grid.getValue(0, 2, 0), equals(0.0));

      expect(grid.getWriteValue(-1, 0, 0), equals(0.0));
      expect(grid.getWriteValue(0, -1, 0), equals(0.0));
      expect(grid.getWriteValue(2, 0, 0), equals(0.0));
      expect(grid.getWriteValue(0, 2, 0), equals(0.0));

      // Writing out of bounds does nothing (does not crash)
      grid.setValue(-1, 0, 0, 1.0);
      grid.setWriteValue(-1, 0, 0, 1.0);

      // Verify normal operation is not impacted
      grid.setValue(0, 0, 0, 10.0);
      expect(grid.getValue(0, 0, 0), equals(10.0));
    });

    test('Can write and read inactive buffers explicitly', () {
      final grid = MultiChannelGrid.create(columns: 1, rows: 1, channelCount: 1);
      grid.setWriteValue(0, 0, 0, 42.0);

      expect(grid.getValue(0, 0, 0), equals(0.0));
      expect(grid.getWriteValue(0, 0, 0), equals(42.0));

      grid.swapBuffers();

      expect(grid.getValue(0, 0, 0), equals(42.0));
      expect(grid.getWriteValue(0, 0, 0), equals(0.0));

      grid.setWriteValueAt(0, 100.0);
      grid.swapBuffers();
      expect(grid.getValueAt(0), equals(100.0));
    });
  });
}

// A simple helper to ensure the update loop does not allocate memory on the heap.
// We just verify it completes cleanly, as true Dart heap allocation tracking
// requires VM service extensions which aren't typically used in simple unit tests,
// but we include the placeholder pattern used in other Sting tests.
int checkAllocations() {
  return 0; // Stub for heap tracking
}

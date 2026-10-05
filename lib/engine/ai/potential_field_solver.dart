import 'dart:typed_data';
import 'dart:math' as math;

class PotentialFieldSolver {
  final Int32List _queue;
  final int _capacity;

  static const double _infinity = 9999999.0;

  PotentialFieldSolver(int capacity)
    : _capacity = capacity,
      _queue = Int32List(capacity);

  void solveWavefront(
    Float32List potentialGrid,
    Uint8List costOrObstacleGrid,
    int cols,
    int rows,
    Int32List goalCells,
  ) {
    int head = 0;
    int tail = 0;

    int numCells = cols * rows;
    for (int i = 0; i < numCells; i++) {
      potentialGrid[i] = _infinity;
    }

    for (int i = 0; i < goalCells.length; i++) {
      int g = goalCells[i];
      if (g >= 0 && g < numCells) {
        potentialGrid[g] = 0.0;
        _queue[tail] = g;
        tail = (tail + 1) % _capacity;
        assert(tail != head, "Queue capacity exceeded");
      }
    }

    final int dx0 = -1, dy0 = -1;
    final int dx1 =  0, dy1 = -1;
    final int dx2 =  1, dy2 = -1;
    final int dx3 = -1, dy3 =  0;
    final int dx4 =  1, dy4 =  0;
    final int dx5 = -1, dy5 =  1;
    final int dx6 =  0, dy6 =  1;
    final int dx7 =  1, dy7 =  1;

    final double cost0 = 1.41421356;
    final double cost1 = 1.0;
    final double cost2 = 1.41421356;
    final double cost3 = 1.0;
    final double cost4 = 1.0;
    final double cost5 = 1.41421356;
    final double cost6 = 1.0;
    final double cost7 = 1.41421356;

    while (head != tail) {
      int curr = _queue[head];
      head = (head + 1) % _capacity;

      int cx = curr % cols;
      int cy = curr ~/ cols;
      double currPot = potentialGrid[curr];

      // Neighbor 0
      int nx = cx + dx0; int ny = cy + dy0;
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
        int nIdx = ny * cols + nx;
        int cellCost = costOrObstacleGrid[nIdx];
        if (cellCost < 255) {
          double newPot = currPot + cost0 * (cellCost == 0 ? 1.0 : cellCost.toDouble());
          if (newPot < potentialGrid[nIdx]) {
            potentialGrid[nIdx] = newPot;
            _queue[tail] = nIdx;
            tail = (tail + 1) % _capacity;
            assert(tail != head, "Queue capacity exceeded");
          }
        }
      }

      // Neighbor 1
      nx = cx + dx1; ny = cy + dy1;
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
        int nIdx = ny * cols + nx;
        int cellCost = costOrObstacleGrid[nIdx];
        if (cellCost < 255) {
          double newPot = currPot + cost1 * (cellCost == 0 ? 1.0 : cellCost.toDouble());
          if (newPot < potentialGrid[nIdx]) {
            potentialGrid[nIdx] = newPot;
            _queue[tail] = nIdx;
            tail = (tail + 1) % _capacity;
            assert(tail != head, "Queue capacity exceeded");
          }
        }
      }

      // Neighbor 2
      nx = cx + dx2; ny = cy + dy2;
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
        int nIdx = ny * cols + nx;
        int cellCost = costOrObstacleGrid[nIdx];
        if (cellCost < 255) {
          double newPot = currPot + cost2 * (cellCost == 0 ? 1.0 : cellCost.toDouble());
          if (newPot < potentialGrid[nIdx]) {
            potentialGrid[nIdx] = newPot;
            _queue[tail] = nIdx;
            tail = (tail + 1) % _capacity;
            assert(tail != head, "Queue capacity exceeded");
          }
        }
      }

      // Neighbor 3
      nx = cx + dx3; ny = cy + dy3;
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
        int nIdx = ny * cols + nx;
        int cellCost = costOrObstacleGrid[nIdx];
        if (cellCost < 255) {
          double newPot = currPot + cost3 * (cellCost == 0 ? 1.0 : cellCost.toDouble());
          if (newPot < potentialGrid[nIdx]) {
            potentialGrid[nIdx] = newPot;
            _queue[tail] = nIdx;
            tail = (tail + 1) % _capacity;
            assert(tail != head, "Queue capacity exceeded");
          }
        }
      }

      // Neighbor 4
      nx = cx + dx4; ny = cy + dy4;
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
        int nIdx = ny * cols + nx;
        int cellCost = costOrObstacleGrid[nIdx];
        if (cellCost < 255) {
          double newPot = currPot + cost4 * (cellCost == 0 ? 1.0 : cellCost.toDouble());
          if (newPot < potentialGrid[nIdx]) {
            potentialGrid[nIdx] = newPot;
            _queue[tail] = nIdx;
            tail = (tail + 1) % _capacity;
            assert(tail != head, "Queue capacity exceeded");
          }
        }
      }

      // Neighbor 5
      nx = cx + dx5; ny = cy + dy5;
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
        int nIdx = ny * cols + nx;
        int cellCost = costOrObstacleGrid[nIdx];
        if (cellCost < 255) {
          double newPot = currPot + cost5 * (cellCost == 0 ? 1.0 : cellCost.toDouble());
          if (newPot < potentialGrid[nIdx]) {
            potentialGrid[nIdx] = newPot;
            _queue[tail] = nIdx;
            tail = (tail + 1) % _capacity;
            assert(tail != head, "Queue capacity exceeded");
          }
        }
      }

      // Neighbor 6
      nx = cx + dx6; ny = cy + dy6;
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
        int nIdx = ny * cols + nx;
        int cellCost = costOrObstacleGrid[nIdx];
        if (cellCost < 255) {
          double newPot = currPot + cost6 * (cellCost == 0 ? 1.0 : cellCost.toDouble());
          if (newPot < potentialGrid[nIdx]) {
            potentialGrid[nIdx] = newPot;
            _queue[tail] = nIdx;
            tail = (tail + 1) % _capacity;
            assert(tail != head, "Queue capacity exceeded");
          }
        }
      }

      // Neighbor 7
      nx = cx + dx7; ny = cy + dy7;
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
        int nIdx = ny * cols + nx;
        int cellCost = costOrObstacleGrid[nIdx];
        if (cellCost < 255) {
          double newPot = currPot + cost7 * (cellCost == 0 ? 1.0 : cellCost.toDouble());
          if (newPot < potentialGrid[nIdx]) {
            potentialGrid[nIdx] = newPot;
            _queue[tail] = nIdx;
            tail = (tail + 1) % _capacity;
            assert(tail != head, "Queue capacity exceeded");
          }
        }
      }
    }
  }

  void deriveFlowVectors(Float32List potentialGrid, Float32List outVectorGrid, int cols, int rows) {
    int numCells = cols * rows;
    for (int i = 0; i < numCells; i++) {
      int cx = i % cols;
      int cy = i ~/ cols;

      double bestPot = potentialGrid[i];
      int bestNx = cx;
      int bestNy = cy;

      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;

          int nx = cx + dx;
          int ny = cy + dy;
          if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
            int nIdx = ny * cols + nx;
            double nPot = potentialGrid[nIdx];
            if (nPot < bestPot) {
              bestPot = nPot;
              bestNx = nx;
              bestNy = ny;
            }
          }
        }
      }

      double dirX = (bestNx - cx).toDouble();
      double dirY = (bestNy - cy).toDouble();

      if (dirX != 0.0 || dirY != 0.0) {
        double len = math.sqrt(dirX * dirX + dirY * dirY);
        outVectorGrid[i * 2] = dirX / len;
        outVectorGrid[i * 2 + 1] = dirY / len;
      } else {
        outVectorGrid[i * 2] = 0.0;
        outVectorGrid[i * 2 + 1] = 0.0;
      }
    }
  }
}

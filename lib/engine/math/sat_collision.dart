import 'dart:math' as math;
import 'dart:typed_data';

class SATCollisionResult {
  bool intersects = false;
  double normalX = 0.0;
  double normalY = 0.0;
  double depth = 0.0;
}

void testPolygonPolygon(Float32List polyA, int countA, Float32List polyB,
    int countB, SATCollisionResult outResult) {
  double minDepth = double.infinity;
  double bestNormalX = 0.0;
  double bestNormalY = 0.0;

  // Test axes from polyA's edges
  for (int i = 0; i < countA; i++) {
    int next = (i + 1) % countA;
    double p1x = polyA[i * 2];
    double p1y = polyA[i * 2 + 1];
    double p2x = polyA[next * 2];
    double p2y = polyA[next * 2 + 1];

    double edgeX = p2x - p1x;
    double edgeY = p2y - p1y;

    double normalX = -edgeY;
    double normalY = edgeX;

    double len = math.sqrt(normalX * normalX + normalY * normalY);
    if (len > 0) {
      normalX /= len;
      normalY /= len;
    } else {
      continue;
    }

    double minA = double.infinity;
    double maxA = -double.infinity;
    for (int j = 0; j < countA; j++) {
      double proj = polyA[j * 2] * normalX + polyA[j * 2 + 1] * normalY;
      if (proj < minA) minA = proj;
      if (proj > maxA) maxA = proj;
    }

    double minB = double.infinity;
    double maxB = -double.infinity;
    for (int j = 0; j < countB; j++) {
      double proj = polyB[j * 2] * normalX + polyB[j * 2 + 1] * normalY;
      if (proj < minB) minB = proj;
      if (proj > maxB) maxB = proj;
    }

    if (maxA <= minB || maxB <= minA) {
      outResult.intersects = false;
      return;
    }

    double depth = math.min(maxA - minB, maxB - minA);
    if (depth < minDepth) {
      minDepth = depth;
      bestNormalX = normalX;
      bestNormalY = normalY;
    }
  }

  // Test axes from polyB's edges
  for (int i = 0; i < countB; i++) {
    int next = (i + 1) % countB;
    double p1x = polyB[i * 2];
    double p1y = polyB[i * 2 + 1];
    double p2x = polyB[next * 2];
    double p2y = polyB[next * 2 + 1];

    double edgeX = p2x - p1x;
    double edgeY = p2y - p1y;

    double normalX = -edgeY;
    double normalY = edgeX;

    double len = math.sqrt(normalX * normalX + normalY * normalY);
    if (len > 0) {
      normalX /= len;
      normalY /= len;
    } else {
      continue;
    }

    double minA = double.infinity;
    double maxA = -double.infinity;
    for (int j = 0; j < countA; j++) {
      double proj = polyA[j * 2] * normalX + polyA[j * 2 + 1] * normalY;
      if (proj < minA) minA = proj;
      if (proj > maxA) maxA = proj;
    }

    double minB = double.infinity;
    double maxB = -double.infinity;
    for (int j = 0; j < countB; j++) {
      double proj = polyB[j * 2] * normalX + polyB[j * 2 + 1] * normalY;
      if (proj < minB) minB = proj;
      if (proj > maxB) maxB = proj;
    }

    if (maxA <= minB || maxB <= minA) {
      outResult.intersects = false;
      return;
    }

    double depth = math.min(maxA - minB, maxB - minA);
    if (depth < minDepth) {
      minDepth = depth;
      bestNormalX = normalX;
      bestNormalY = normalY;
    }
  }

  // Orient normal to point from A to B
  double cxA = 0.0;
  double cyA = 0.0;
  for (int i = 0; i < countA; i++) {
    cxA += polyA[i * 2];
    cyA += polyA[i * 2 + 1];
  }
  cxA /= countA;
  cyA /= countA;

  double cxB = 0.0;
  double cyB = 0.0;
  for (int i = 0; i < countB; i++) {
    cxB += polyB[i * 2];
    cyB += polyB[i * 2 + 1];
  }
  cxB /= countB;
  cyB /= countB;

  double dirX = cxB - cxA;
  double dirY = cyB - cyA;

  if (dirX * bestNormalX + dirY * bestNormalY < 0) {
    bestNormalX = -bestNormalX;
    bestNormalY = -bestNormalY;
  }

  outResult.intersects = true;
  outResult.depth = minDepth;
  outResult.normalX = bestNormalX;
  outResult.normalY = bestNormalY;
}

void testPolygonCircle(Float32List poly, int count, double cx, double cy,
    double radius, SATCollisionResult outResult) {
  double minDepth = double.infinity;
  double bestNormalX = 0.0;
  double bestNormalY = 0.0;

  // Find closest vertex to circle center
  double closestDistSq = double.infinity;
  int closestIdx = -1;
  for (int i = 0; i < count; i++) {
    double vx = poly[i * 2];
    double vy = poly[i * 2 + 1];
    double dx = cx - vx;
    double dy = cy - vy;
    double distSq = dx * dx + dy * dy;
    if (distSq < closestDistSq) {
      closestDistSq = distSq;
      closestIdx = i;
    }
  }

  // 1. Axes from polygon edges
  for (int i = 0; i < count; i++) {
    int next = (i + 1) % count;
    double p1x = poly[i * 2];
    double p1y = poly[i * 2 + 1];
    double p2x = poly[next * 2];
    double p2y = poly[next * 2 + 1];

    double edgeX = p2x - p1x;
    double edgeY = p2y - p1y;

    double normalX = -edgeY;
    double normalY = edgeX;

    double len = math.sqrt(normalX * normalX + normalY * normalY);
    if (len > 0) {
      normalX /= len;
      normalY /= len;
    } else {
      continue;
    }

    double minA = double.infinity;
    double maxA = -double.infinity;
    for (int j = 0; j < count; j++) {
      double proj = poly[j * 2] * normalX + poly[j * 2 + 1] * normalY;
      if (proj < minA) minA = proj;
      if (proj > maxA) maxA = proj;
    }

    double circleProj = cx * normalX + cy * normalY;
    double minB = circleProj - radius;
    double maxB = circleProj + radius;

    if (maxA <= minB || maxB <= minA) {
      outResult.intersects = false;
      return;
    }

    double depth = math.min(maxA - minB, maxB - minA);
    if (depth < minDepth) {
      minDepth = depth;
      bestNormalX = normalX;
      bestNormalY = normalY;
    }
  }

  // 2. Axis from closest vertex to circle center
  if (closestIdx != -1) {
    double vx = poly[closestIdx * 2];
    double vy = poly[closestIdx * 2 + 1];
    double normalX = cx - vx;
    double normalY = cy - vy;
    double len = math.sqrt(normalX * normalX + normalY * normalY);
    if (len > 0) {
      normalX /= len;
      normalY /= len;
    } else {
      // Circle center is exactly on a vertex. Just pick an arbitrary valid direction, like X axis.
      normalX = 1.0;
      normalY = 0.0;
    }

    double minA = double.infinity;
    double maxA = -double.infinity;
    for (int j = 0; j < count; j++) {
      double proj = poly[j * 2] * normalX + poly[j * 2 + 1] * normalY;
      if (proj < minA) minA = proj;
      if (proj > maxA) maxA = proj;
    }

    double circleProj = cx * normalX + cy * normalY;
    double minB = circleProj - radius;
    double maxB = circleProj + radius;

    if (maxA <= minB || maxB <= minA) {
      outResult.intersects = false;
      return;
    }

    double depth = math.min(maxA - minB, maxB - minA);
    if (depth < minDepth) {
      minDepth = depth;
      bestNormalX = normalX;
      bestNormalY = normalY;
    }
  }

  // Orient normal to point from polygon to circle
  double cxA = 0.0;
  double cyA = 0.0;
  for (int i = 0; i < count; i++) {
    cxA += poly[i * 2];
    cyA += poly[i * 2 + 1];
  }
  cxA /= count;
  cyA /= count;

  double dirX = cx - cxA;
  double dirY = cy - cyA;

  if (dirX * bestNormalX + dirY * bestNormalY < 0) {
    bestNormalX = -bestNormalX;
    bestNormalY = -bestNormalY;
  }

  outResult.intersects = true;
  outResult.depth = minDepth;
  outResult.normalX = bestNormalX;
  outResult.normalY = bestNormalY;
}

void testAABBAABB(double xA, double yA, double wA, double hA, double xB,
    double yB, double wB, double hB, SATCollisionResult outResult) {
  double centerAx = xA + wA / 2;
  double centerAy = yA + hA / 2;
  double centerBx = xB + wB / 2;
  double centerBy = yB + hB / 2;

  double halfAWidth = wA / 2;
  double halfAHeight = hA / 2;
  double halfBWidth = wB / 2;
  double halfBHeight = hB / 2;

  double dx = centerBx - centerAx;
  double dy = centerBy - centerAy;

  double overlapX = halfAWidth + halfBWidth - dx.abs();
  double overlapY = halfAHeight + halfBHeight - dy.abs();

  if (overlapX > 0 && overlapY > 0) {
    outResult.intersects = true;
    if (overlapX < overlapY) {
      outResult.depth = overlapX;
      outResult.normalX = dx < 0 ? -1.0 : 1.0;
      outResult.normalY = 0.0;
    } else {
      outResult.depth = overlapY;
      outResult.normalX = 0.0;
      outResult.normalY = dy < 0 ? -1.0 : 1.0;
    }
  } else {
    outResult.intersects = false;
  }
}

void testCircleCircle(double cxA, double cyA, double radiusA, double cxB,
    double cyB, double radiusB, SATCollisionResult outResult) {
  double dx = cxB - cxA;
  double dy = cyB - cyA;
  double distSq = dx * dx + dy * dy;
  double radiiSum = radiusA + radiusB;

  if (distSq < radiiSum * radiiSum) {
    outResult.intersects = true;
    double dist = math.sqrt(distSq);

    if (dist == 0.0) {
      outResult.depth = radiiSum;
      outResult.normalX = 1.0;
      outResult.normalY = 0.0;
    } else {
      outResult.depth = radiiSum - dist;
      outResult.normalX = dx / dist;
      outResult.normalY = dy / dist;
    }
  } else {
    outResult.intersects = false;
  }
}

void testAABBCircle(double xA, double yA, double wA, double hA, double cxB,
    double cyB, double radiusB, SATCollisionResult outResult) {
  // Find closest point on AABB to circle center
  double closestX = cxB;
  if (closestX < xA) {
    closestX = xA;
  } else if (closestX > xA + wA) {
    closestX = xA + wA;
  }

  double closestY = cyB;
  if (closestY < yA) {
    closestY = yA;
  } else if (closestY > yA + hA) {
    closestY = yA + hA;
  }

  double dx = cxB - closestX;
  double dy = cyB - closestY;
  double distSq = dx * dx + dy * dy;

  if (distSq == 0) {
    // Center is inside AABB
    outResult.intersects = true;

    double distToLeft = cxB - xA;
    double distToRight = (xA + wA) - cxB;
    double distToTop = cyB - yA;
    double distToBottom = (yA + hA) - cyB;

    double minX = math.min(distToLeft, distToRight);
    double minY = math.min(distToTop, distToBottom);

    if (minX < minY) {
      outResult.depth = minX + radiusB;
      outResult.normalX = distToLeft < distToRight ? -1.0 : 1.0;
      outResult.normalY = 0.0;
    } else {
      outResult.depth = minY + radiusB;
      outResult.normalX = 0.0;
      outResult.normalY = distToTop < distToBottom ? -1.0 : 1.0;
    }
  } else if (distSq < radiusB * radiusB) {
    outResult.intersects = true;
    double dist = math.sqrt(distSq);
    outResult.depth = radiusB - dist;
    outResult.normalX = dx / dist;
    outResult.normalY = dy / dist;
  } else {
    outResult.intersects = false;
  }
}

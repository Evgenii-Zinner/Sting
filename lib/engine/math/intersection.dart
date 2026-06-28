/// Checks if two Axis-Aligned Bounding Boxes (AABB) intersect.
///
/// Returns true if the AABB defined by [x1], [y1], [w1], [h1] intersects
/// with the AABB defined by [x2], [y2], [w2], [h2].
bool intersectAABBAABB(
  double x1,
  double y1,
  double w1,
  double h1,
  double x2,
  double y2,
  double w2,
  double h2,
) {
  return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
}

/// Checks if two circles intersect.
///
/// Returns true if the circle centered at [x1], [y1] with radius [r1] intersects
/// with the circle centered at [x2], [y2] with radius [r2].
bool intersectCircleCircle(
  double x1,
  double y1,
  double r1,
  double x2,
  double y2,
  double r2,
) {
  final double dx = x1 - x2;
  final double dy = y1 - y2;
  final double distanceSquared = dx * dx + dy * dy;
  final double radiiSum = r1 + r2;
  return distanceSquared < radiiSum * radiiSum;
}

/// Checks if an Axis-Aligned Bounding Box (AABB) and a circle intersect.
///
/// Returns true if the AABB defined by [rX], [rY], [rW], [rH] intersects
/// with the circle centered at [cX], [cY] with radius [cR].
bool intersectAABBCircle(
  double rX,
  double rY,
  double rW,
  double rH,
  double cX,
  double cY,
  double cR,
) {
  // Find the closest point on the AABB to the circle center.
  double closestX = cX;
  if (closestX < rX) {
    closestX = rX;
  } else if (closestX > rX + rW) {
    closestX = rX + rW;
  }

  double closestY = cY;
  if (closestY < rY) {
    closestY = rY;
  } else if (closestY > rY + rH) {
    closestY = rY + rH;
  }

  // Calculate the distance between the circle center and this closest point.
  final double dx = cX - closestX;
  final double dy = cY - closestY;

  // If the distance is less than the circle's radius, an intersection occurs.
  return (dx * dx + dy * dy) < (cR * cR);
}

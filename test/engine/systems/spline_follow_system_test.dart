import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/spline_follower.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/spline_follow_system.dart';

void main() {
  group('SplineFollower Component', () {
    test('initializes and manages properties correctly', () {
      final follower = SplineFollower.create(
        pointCount: 3,
        currentDistance: 10.0,
        speed: 5.0,
        loopMode: 1, // Loop
        direction: -1.0,
        alignRotation: true,
        type: 1, // QuadraticBezier
      );

      expect(follower.currentDistance, 10.0);
      expect(follower.speed, 5.0);
      expect(follower.loopMode, 1);
      expect(follower.direction, -1.0);
      expect(follower.alignRotation, isTrue);
      expect(follower.type, 1);
      expect(follower.pointCount, 3);
      expect(follower.points.length, 6);

      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 50.0, 50.0);
      follower.setPoint(2, 100.0, 0.0);

      expect(follower.getPointX(1), 50.0);
      expect(follower.getPointY(1), 50.0);

      follower.currentDistance = 20.0;
      expect(follower.currentDistance, 20.0);

      follower.alignRotation = false;
      expect(follower.alignRotation, isFalse);

      follower.loopMode = 2; // Pingpong
      expect(follower.loopMode, 2);
    });

    test('ignores out-of-bounds point settings', () {
      final follower = SplineFollower.create(pointCount: 1);
      follower.setPoint(1, 10.0, 10.0); // Out of bounds
      expect(follower.getPointX(1), 0.0);
      expect(follower.getPointY(1), 0.0);
    });
  });

  group('SplineFollowSystem', () {
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<SplineFollower> followerCaste;
    late ComponentStorage<Velocity> velocityCaste;
    late SplineFollowSystem system;

    setUp(() {
      positionCaste = ComponentStorage<Position>(10);
      followerCaste = ComponentStorage<SplineFollower>(10);
      velocityCaste = ComponentStorage<Velocity>(10);

      system = SplineFollowSystem(
        positionCaste: positionCaste,
        splineFollowerCaste: followerCaste,
        velocityCaste: velocityCaste,
      );
    });

    test('advances along a polyline (once)', () {
      final follower = SplineFollower.create(
        pointCount: 3,
        speed: 10.0,
        loopMode: 0,
        type: 0,
      );
      // Points: (0,0) -> (10,0) -> (10,10). Total length = 20
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 10.0, 0.0);
      follower.setPoint(2, 10.0, 10.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      // dt = 1.0 -> distance = 10.0
      system.update(1.0);

      final pos = positionCaste.get(0)!;
      expect(pos.x, closeTo(10.0, 0.001));
      expect(pos.y, closeTo(0.0, 0.001));

      // dt = 0.5 -> distance = 15.0
      system.update(0.5);
      expect(pos.x, closeTo(10.0, 0.001));
      expect(pos.y, closeTo(5.0, 0.001));

      // dt = 2.0 -> distance = 35.0 (clamps to 20.0)
      system.update(2.0);
      expect(pos.x, closeTo(10.0, 0.001));
      expect(pos.y, closeTo(10.0, 0.001));
      expect(follower.currentDistance, 20.0);
    });

    test('advances along a polyline (loop backwards)', () {
      final follower = SplineFollower.create(
        pointCount: 3,
        speed: 5.0,
        loopMode: 1, // loop
        direction: -1.0, // backwards
        type: 0,
      );
      // Points: (0,0) -> (10,0) -> (10,10). Total length = 20
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 10.0, 0.0);
      follower.setPoint(2, 10.0, 10.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      // dt = 1.0 -> step = -5.0. New distance = 15.0
      system.update(1.0);

      final pos = positionCaste.get(0)!;
      expect(pos.x, closeTo(10.0, 0.001));
      expect(pos.y, closeTo(5.0, 0.001));
    });

    test('advances along a polyline (pingpong)', () {
      final follower = SplineFollower.create(
        pointCount: 3,
        speed: 15.0,
        loopMode: 2, // pingpong
        type: 0,
      );
      // Points: (0,0) -> (10,0) -> (10,10). Total length = 20
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 10.0, 0.0);
      follower.setPoint(2, 10.0, 10.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      // dt = 1.0 -> distance = 15.0
      system.update(1.0);
      expect(positionCaste.get(0)!.y, closeTo(5.0, 0.001));
      expect(follower.direction, 1.0);

      // dt = 1.0 -> distance = 30.0. Pingpongs to 10.0, direction becomes -1.0
      system.update(1.0);
      expect(follower.currentDistance, 10.0);
      expect(follower.direction, -1.0);
      expect(positionCaste.get(0)!.x, closeTo(10.0, 0.001));
      expect(positionCaste.get(0)!.y, closeTo(0.0, 0.001));

      // dt = 1.0 -> distance = -5.0. Pingpongs to 5.0, direction becomes 1.0
      system.update(1.0);
      expect(follower.currentDistance, 5.0);
      expect(follower.direction, 1.0);
      expect(positionCaste.get(0)!.x, closeTo(5.0, 0.001));
    });

    test('aligns velocity to tangent', () {
      final follower = SplineFollower.create(
        pointCount: 2,
        speed: 10.0,
        loopMode: 0,
        alignRotation: true,
        type: 0,
      );
      // Points: (0,0) -> (10,10)
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 10.0, 10.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      velocityCaste.add(0, Velocity.create(0.0, 0.0));
      followerCaste.add(0, follower);

      system.update(1.0); // distance = 10.0

      final vel = velocityCaste.get(0)!;
      // Tangent is (1,1) normalized * speed = (7.07, 7.07)
      expect(vel.dx, closeTo(7.071, 0.001));
      expect(vel.dy, closeTo(7.071, 0.001));
    });

    test('evaluates Quadratic Bezier', () {
      final follower = SplineFollower.create(
        pointCount: 3,
        speed: 0.5, // t advances by 0.5 per second
        type: 1, // Quadratic
      );
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 50.0, 100.0);
      follower.setPoint(2, 100.0, 0.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      system.update(1.0); // t = 0.5
      // Evaluate at t=0.5 -> x = 0.25*0 + 2*0.5*0.5*50 + 0.25*100 = 50
      // y = 0.25*0 + 2*0.5*0.5*100 + 0.25*0 = 50
      final pos = positionCaste.get(0)!;
      expect(pos.x, closeTo(50.0, 0.001));
      expect(pos.y, closeTo(50.0, 0.001));
    });

    test('evaluates Cubic Bezier', () {
      final follower = SplineFollower.create(
        pointCount: 4,
        speed: 1.0, // t advances by 1.0 per second
        type: 2, // Cubic
      );
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 0.0, 0.0);
      follower.setPoint(2, 0.0, 0.0);
      follower.setPoint(3, 100.0, 100.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      system.update(1.0); // t = 1.0
      final pos = positionCaste.get(0)!;
      expect(pos.x, closeTo(100.0, 0.001));
      expect(pos.y, closeTo(100.0, 0.001));
    });

    test('evaluates Hermite', () {
      final follower = SplineFollower.create(
        pointCount: 4,
        speed: 0.5, // t = 0.5
        type: 3, // Hermite
      );
      // p0, t0, p1, t1
      follower.setPoint(0, 0.0, 0.0); // p0
      follower.setPoint(1, 100.0, 0.0); // t0
      follower.setPoint(2, 100.0, 100.0); // p1
      follower.setPoint(3, 0.0, 100.0); // t1

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      system.update(1.0); // t = 0.5
      final pos = positionCaste.get(0)!;
      // Hermite t=0.5 -> h00=0.5, h10=0.125, h01=0.5, h11=-0.125
      // x = 0.5*0 + 0.125*100 + 0.5*100 - 0.125*0 = 62.5
      // y = 0.5*0 + 0.125*0 + 0.5*100 - 0.125*100 = 37.5
      expect(pos.x, closeTo(62.5, 0.001));
      expect(pos.y, closeTo(37.5, 0.001));
    });

    test('handles fallback when not enough points are provided for curve type',
        () {
      final follower = SplineFollower.create(
        pointCount: 2, // only 2 points but type=2 (Cubic needs 4)
        type: 2,
      );
      follower.setPoint(0, 10.0, 10.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      system.update(1.0);
      final pos = positionCaste.get(0)!;
      expect(pos.x, closeTo(10.0, 0.001)); // falls back to point 0
      expect(pos.y, closeTo(10.0, 0.001));
    });

    test('ignores entities with 0 point count', () {
      final follower = SplineFollower.create(pointCount: 0);
      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      system.update(1.0);
      final pos = positionCaste.get(0)!;
      expect(pos.x, 0.0);
      expect(pos.y, 0.0);
      expect(follower.currentDistance, 0.0);
    });

    test('handles polyline loop mode 1 (forward looping)', () {
      final follower = SplineFollower.create(
        pointCount: 3,
        speed: 25.0, // speed > length
        loopMode: 1,
        type: 0,
      );
      // Total length = 20
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 10.0, 0.0);
      follower.setPoint(2, 10.0, 10.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      // dt = 1.0 -> dist = 25.0. 25 % 20 = 5.0
      system.update(1.0);
      expect(follower.currentDistance, closeTo(5.0, 0.001));
    });

    test('handles 0-length polyline safely', () {
      final follower = SplineFollower.create(
        pointCount: 3,
        speed: 10.0,
        type: 0,
      );
      // Total length = 0
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 0.0, 0.0);
      follower.setPoint(2, 0.0, 0.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      followerCaste.add(0, follower);

      system.update(1.0);
      // should return early before calculating loop modes or updating position because maxDistOrT <= 0.0
      expect(follower.currentDistance, 10.0);
      expect(positionCaste.get(0)!.x, 0.0);
    });

    test('zero allocations during update', () {
      final follower = SplineFollower.create(
        pointCount: 3,
        speed: 10.0,
        type: 0,
        alignRotation: true,
      );
      follower.setPoint(0, 0.0, 0.0);
      follower.setPoint(1, 10.0, 0.0);
      follower.setPoint(2, 10.0, 10.0);

      positionCaste.add(0, Position.create(0.0, 0.0));
      velocityCaste.add(0, Velocity.create(0.0, 0.0));
      followerCaste.add(0, follower);

      // Warmup
      system.update(1.0);

      // Should not allocate on steady-state
      expect(() => system.update(0.016), returnsNormally);
    });
  });
}

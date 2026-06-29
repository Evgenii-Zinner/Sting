import 'dart:typed_data';

/// A flat Weapon component using a Dart extension type over a Float32List.
/// Index 0: fireRate (seconds between shots)
/// Index 1: currentCooldown (time until next shot)
/// Index 2: projectileSpeed (speed of spawned projectiles)
/// Index 3: range (max distance to search for targets)
extension type Weapon(Float32List data) {
  /// Creates a new Weapon component.
  Weapon.create(double fireRate, double projectileSpeed, double range)
      : this(Float32List(4)
          ..[0] = fireRate
          ..[1] = 0.0 // Ready to fire initially
          ..[2] = projectileSpeed
          ..[3] = range);

  double get fireRate => data[0];
  set fireRate(double value) => data[0] = value;

  double get currentCooldown => data[1];
  set currentCooldown(double value) => data[1] = value;

  double get projectileSpeed => data[2];
  set projectileSpeed(double value) => data[2] = value;

  double get range => data[3];
  set range(double value) => data[3] = value;
}

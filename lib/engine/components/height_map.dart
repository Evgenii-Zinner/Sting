import 'dart:typed_data';

/// A component that provides a 2D height map for calculating terrain slopes.
class HeightMap {
  final int width;
  final int height;
  final Float32List data;
  final double scaleX;
  final double scaleY;

  HeightMap(this.width, this.height, this.data, {this.scaleX = 1.0, this.scaleY = 1.0});

  double getHeightAt(double x, double y) {
    int ix = (x / scaleX).floor().clamp(0, width - 1);
    int iy = (y / scaleY).floor().clamp(0, height - 1);
    return data[iy * width + ix];
  }

  (double, double) getGradientAt(double x, double y) {
    int ix = (x / scaleX).floor().clamp(0, width - 1);
    int iy = (y / scaleY).floor().clamp(0, height - 1);

    // Central differences for internal pixels, forward/backward for edges
    double hL = ix > 0 ? data[iy * width + (ix - 1)] : data[iy * width + ix];
    double hR = ix < width - 1 ? data[iy * width + (ix + 1)] : data[iy * width + ix];
    double hU = iy > 0 ? data[(iy - 1) * width + ix] : data[iy * width + ix];
    double hD = iy < height - 1 ? data[(iy + 1) * width + ix] : data[iy * width + ix];

    double dx = ix > 0 && ix < width - 1 ? (hR - hL) / (2.0 * scaleX) : (hR - hL) / scaleX;
    double dy = iy > 0 && iy < height - 1 ? (hD - hU) / (2.0 * scaleY) : (hD - hU) / scaleY;

    return (dx, dy);
  }
}

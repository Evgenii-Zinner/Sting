import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/renderer.dart';

void main() {
  test('Renderer.renderFrame does not throw', () {
    final renderer = Renderer();
    // Since PlatformDispatcher.instance.views might be empty in a test environment,
    // this call should simply return without throwing an error.
    expect(() => renderer.renderFrame(), returnsNormally);
  });
}

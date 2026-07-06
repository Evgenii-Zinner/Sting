import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/main.dart';

void main() {
  test('PlatformDispatcher hooks are successfully initialized', () {
    // We cannot use testWidgets because flutter_test expects to own the onBeginFrame and onDrawFrame callbacks.
    // Instead we use a regular test and verify our initEngine function sets the callbacks and they work.

    // We expect the original frame count to be 0
    expect(frameCount, 0);

    initEngine();

    // Check that callbacks are not null
    expect(PlatformDispatcher.instance.onBeginFrame, isNotNull);
    expect(PlatformDispatcher.instance.onDrawFrame, isNotNull);

    // Call the actual hook we set
    PlatformDispatcher.instance.onBeginFrame?.call(Duration.zero);

    // Check that frame count increased
    expect(frameCount, 1);

    // Call the actual hook we set again to verify dt
    PlatformDispatcher.instance.onBeginFrame
        ?.call(const Duration(microseconds: 16666));

    // Check that time correctly calculated dt
    expect(time.dt, closeTo(0.016666, 0.000001));
    expect(frameCount, 2);
  });
}

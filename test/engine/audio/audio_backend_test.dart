import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/audio/audio_backend.dart';

void main() {
  group('NullAudioBackend', () {
    late NullAudioBackend backend;

    setUp(() {
      backend = NullAudioBackend();
    });

    test('init does not throw', () async {
      await expectLater(backend.init(), completes);
    });

    test('loadSound does not throw', () async {
      await expectLater(backend.loadSound(1, 'test.wav'), completes);
    });

    test('unloadSound does not throw', () {
      expect(() => backend.unloadSound(1), returnsNormally);
    });

    test('play returns monotonically increasing handles', () {
      final handle1 = backend.play(1);
      final handle2 = backend.play(2);
      final handle3 = backend.play(3);

      expect(handle1, 1);
      expect(handle2, 2);
      expect(handle3, 3);
    });

    test('stop does not throw', () {
      expect(() => backend.stop(1), returnsNormally);
    });

    test('setVolume does not throw', () {
      expect(() => backend.setVolume(1, 0.5), returnsNormally);
    });

    test('setPan does not throw', () {
      expect(() => backend.setPan(1, 0.5), returnsNormally);
    });

    test('dispose does not throw', () {
      expect(() => backend.dispose(), returnsNormally);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';

void main() {
  group('AudioService', () {
    group('PlaybackState Enum', () {
      test('has all expected values', () {
        expect(PlaybackState.values, hasLength(5));
        expect(PlaybackState.values, contains(PlaybackState.stopped));
        expect(PlaybackState.values, contains(PlaybackState.playing));
        expect(PlaybackState.values, contains(PlaybackState.paused));
        expect(PlaybackState.values, contains(PlaybackState.loading));
        expect(PlaybackState.values, contains(PlaybackState.error));
      });
    });
  });
}

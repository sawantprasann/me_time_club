import 'package:flutter_test/flutter_test.dart';
import 'package:me_time_club/widgets/speech_utterance.dart';

void main() {
  test('finish returns the latest partial once', () {
    final utterance = SpeechUtterance();

    utterance.hear('I am');
    utterance.hear('I am tired of today');

    expect(utterance.finish(), 'I am tired of today');
    expect(utterance.finish(), isNull);
  });

  test('a result after finish does not replace the transcript', () {
    final utterance = SpeechUtterance();

    utterance.hear('school run was heavy');
    utterance.finish();
    utterance.hear('something else');

    expect(utterance.latest, 'school run was heavy');
  });

  test('finish with no words returns null', () {
    expect(SpeechUtterance().finish(), isNull);
  });
}

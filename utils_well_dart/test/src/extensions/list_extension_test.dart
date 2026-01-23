import 'package:test/test.dart';
import 'package:utils_well_dart/src/extensions/list_extension.dart';

void main() {
  group('endsWithRepeatedSequence', () {
    test('must return true', () {
      var list = [1, 1];
      expect(
        list.endsWithRepeatedSequence(),
        [1],
      );

      list = [1, 1, 1];
      expect(
        list.endsWithRepeatedSequence(sequences: 3),
        [1],
      );

      list = [0, 1, 1, 1];
      expect(
        list.endsWithRepeatedSequence(sequences: 2),
        [1],
      );

      list = [0, 2, 1, 2, 1, 2, 1];
      expect(
        list.endsWithRepeatedSequence(sequences: 3),
        [2, 1],
      );

      list = _gen(2, 3, false);
      expect(
        list.endsWithRepeatedSequence(sequences: 2),
        list.sublist(0, 3),
      );
      list = _gen(3, 4, true);
      expect(
        list.endsWithRepeatedSequence(sequences: 3),
        list.sublist(0, 4),
      );

      list = _gen(4, 10, true);
      expect(
        list.endsWithRepeatedSequence(sequences: 3),
        list.sublist(0, 10),
      );
    });

    test('must return false', () {
      expect(
        () => [].endsWithRepeatedSequence(sequences: 1),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => [].endsWithRepeatedSequence(minSequenceRange: 0),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => [].endsWithRepeatedSequence(maxSequenceRange: 0),
        throwsA(isA<AssertionError>()),
      );

      expect(
        [1].endsWithRepeatedSequence(),
        isNull,
      );

      expect(
        [1, 2, 1, 2].endsWithRepeatedSequence(minSequenceRange: 3),
        isNull,
      );

      expect(
        [1, 2, 1, 2].endsWithRepeatedSequence(maxSequenceRange: 1),
        isNull,
      );

      expect(
        [1, 1].endsWithRepeatedSequence(sequences: 3),
        isNull,
      );

      expect(
        [1, 1, 1, 0].endsWithRepeatedSequence(),
        isNull,
      );

      expect(
        [2, 0, 1, 0].endsWithRepeatedSequence(sequences: 2),
        isNull,
      );
    });
  });
}

List<int> _gen(int seq, int range, bool reversed) => [
  for (var i = 0; i < seq; i++) ...[
    if (!reversed) ...[for (var j = 0; j < range; j++) j],
    if (reversed) ...[for (var j = range - 1; j >= 0; j--) j],
  ],
];

extension ListExtension<T> on List<T> {
  void sortInverse([int Function(T, T)? compare]) {
    if (compare == null && firstOrNull is! Comparable) return;
    if (compare != null) return sort((a, b) => compare(b, a));
    return sort((a, b) => (b as Comparable).compareTo(a as Comparable));
  }

  T? indexOrNull(int index) {
    if (length > index) return this[index];
    return null;
  }

  int? indexOfOrNull(bool Function(T e) test) {
    for (var i = 0; i < length; i++) {
      if (test(this[i])) return i;
    }
    return null;
  }

  T? removeFirstWhere(bool Function(T) test) {
    var i = 0;
    int? idx;
    for (final e in this) {
      if (test(e)) {
        idx = i;
        break;
      }
      i++;
    }
    if (idx == null) return null;
    return removeAt(idx);
  }

  /// If [moveIfOutLimit] is true, the element will be moved to
  /// the first or last position if the new index is out of the list limits.
  /// If [moveIfOutLimit] is false, the element will not be moved if the
  /// new index is out of the list limits.
  void move(
    int elementIndex,
    int movePositions, {
    bool moveIfOutLimit = true,
  }) {
    var newIndex = elementIndex + movePositions;
    if (newIndex < 0 || newIndex >= length) {
      if (!moveIfOutLimit) return;
      newIndex = newIndex < 0 ? 0 : length - 1;
    }
    if (elementIndex == newIndex) return;
    final element = removeAt(elementIndex);
    insert(newIndex, element);
  }

  /// Returns a list of the last [sequences] elements that are repeated
  /// with a range of [minSequenceRange] to [maxSequenceRange].
  ///
  /// If [maxSequenceRange] is not provided, it will look for the longest
  /// repeated sequence until the end of the list.
  ///
  /// If the list is too short to contain the repeated sequence,
  /// it will return null.
  List<T>? endsWithRepeatedSequence({
    int sequences = 2,
    int minSequenceRange = 1,
    int? maxSequenceRange,
  }) {
    assert(sequences > 1);
    assert(minSequenceRange > 0);
    assert(maxSequenceRange == null || maxSequenceRange >= minSequenceRange);
    final list = this;
    if (list.length < 2 || sequences <= 1) return null;
    if (list.length < (sequences * minSequenceRange)) return null;

    final found = <T>[];
    for (var range = 1; range > 0; range++) {
      if (maxSequenceRange != null && range >= maxSequenceRange) return null;
      for (var rangeIndex = 1; rangeIndex <= range; rangeIndex++) {
        final baseIndex = list.length - rangeIndex;
        for (var sequence = 1; sequence < sequences; sequence++) {
          final compareIndex = baseIndex - (sequence * range);
          if (compareIndex < 0) return null;
          if (list[baseIndex] != list[compareIndex]) {
            found.clear();
            sequence = sequences;
            rangeIndex = range + 1;
          } else if (sequence == sequences - 1) {
            found.insert(0, list[baseIndex]);
          }
        }
      }
      if (found.isNotEmpty) return found;
    }
    return null;
  }
}

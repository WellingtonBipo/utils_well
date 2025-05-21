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
}

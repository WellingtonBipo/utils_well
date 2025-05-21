extension IterableExtension<T> on Iterable<T> {
  bool isLastIndex(int index) => index == length - 1;

  T? firstWhereOrNull(bool Function(T e) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? lastWhereOrNull(bool Function(T e) test) {
    T? last;
    for (final element in this) {
      if (test(element)) last = element;
    }
    return last;
  }

  bool equalsTo(Iterable<T> other) {
    if (length != other.length) return false;
    final otherRemoved = other.toList();
    for (final e in this) {
      if (otherRemoved.remove(e)) continue;
      return false;
    }
    return true;
  }

  Map<K, V> toMap<K, V>(MapEntry<K, V> Function(T e) mapEntry) {
    final entries = <MapEntry<K, V>>[];
    for (final e in this) {
      entries.add(mapEntry(e));
    }
    return Map.fromEntries(entries);
  }

  Map<K, V> toMapNotNull<K, V>(MapEntry<K, V>? Function(T e) mapEntry) {
    final entries = <MapEntry<K, V>>[];
    for (final e in this) {
      final v = mapEntry(e);
      if (v != null) entries.add(v);
    }
    return Map.fromEntries(entries);
  }

  Map<K, T> toMapWithKey<K>(K Function(T e) mapEntry) {
    final entries = <K, T>{};
    for (final e in this) {
      entries[mapEntry(e)] = e;
    }
    return entries;
  }

  List<A> mapToList<A>(A? Function(T e, int i) toElement) {
    final items = <A>[];
    var i = 0;
    for (final e in this) {
      final item = toElement(e, i);
      if (item != null) items.add(item);
      i++;
    }
    return items;
  }

  List<A> mapNotNull<A>(A? Function(T e) toElement) {
    final items = <A>[];
    for (final e in this) {
      final item = toElement(e);
      if (item != null) items.add(item);
    }
    return items;
  }

  List<N> mapWithBetween<N>({
    required N Function(T e) toElement,
    required N between,
  }) {
    final newList = <N>[];
    var i = 0;
    for (final e in this) {
      newList.add(toElement(e));
      if (i < length - 1) newList.add(between);
      i++;
    }
    return newList;
  }

  List<T> insertBetween(T between) {
    return mapWithBetween(
      toElement: (e) => e,
      between: between,
    );
  }

  Map<K, V> expandMap<K, V>(Map<K, V> Function(T e) toMap) {
    final map = <K, V>{};
    for (final e in this) {
      map.addAll(toMap(e));
    }
    return map;
  }

  (List<T>, List<T>) segregate(bool Function(T e) test) {
    final left = <T>[];
    final right = <T>[];
    for (final e in this) {
      if (test(e)) {
        left.add(e);
      } else {
        right.add(e);
      }
    }
    return (left, right);
  }

  bool unorderedEquals(Iterable devices) {
    if (length != devices.length) return false;
    final devicesList = devices.toList();
    for (final device in this) {
      if (!devicesList.remove(device)) return false;
    }
    return devicesList.isEmpty;
  }
}

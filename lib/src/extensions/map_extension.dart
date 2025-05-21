extension MapExtension<K, V> on Map<K, V> {
  Map<K2, V2> mapNotNull<K2, V2>(MapEntry<K2, V2>? Function(K k, V v) parser) {
    final map = <K2, V2>{};
    for (final entry in entries) {
      final parsed = parser(entry.key, entry.value);
      if (parsed != null) map[parsed.key] = parsed.value;
    }
    return map;
  }

  List<T> mapList<T>(T Function(K k, V v) parser) =>
      mapListNotNull((k, v) => parser(k, v));

  List<T> mapListNotNull<T>(T? Function(K k, V v) parser) {
    final list = <T>[];
    for (final entry in entries) {
      final parsed = parser(entry.key, entry.value);
      if (parsed != null) list.add(parsed);
    }
    return list;
  }

  Map<K, V> where(bool Function(K k, V v) test) {
    final map = <K, V>{};
    for (final entry in entries) {
      if (test(entry.key, entry.value)) map[entry.key] = entry.value;
    }
    return map;
  }

  Map<K2, V2> whereType<K2, V2>() {
    final map = <K2, V2>{};
    for (final entry in entries) {
      if (entry.key is! K2 && entry.value is! V2) continue;
      map[entry.key as K2] = entry.value as V2;
    }
    return map;
  }

  V getOrCreate(K key, V Function() create) {
    if (containsKey(key)) return this[key]!;
    final value = create();
    this[key] = value;
    return value;
  }

  Map<K2, V2> expand<K2, V2>(Map<K2, V2> Function(K k, V v) parser) {
    final map = <K2, V2>{};
    for (final entry in entries) {
      final parsed = parser(entry.key, entry.value);
      map.addAll(parsed);
    }
    return map;
  }

  MapEntry<K, V>? firstWhereOrNull(bool Function(K k, V v) test) {
    for (final entry in entries) {
      final value = test(entry.key, entry.value);
      if (value) return entry;
    }
    return null;
  }

  bool any(bool Function(K k, V v) test) {
    for (final entry in entries) {
      final value = test(entry.key, entry.value);
      if (value) return true;
    }
    return false;
  }

  Map<T, V> mapKeys<T>(T Function(K k) parser) {
    final map = <T, V>{};
    for (final entry in entries) {
      final key = parser(entry.key);
      map[key] = entry.value;
    }
    return map;
  }

  Map<K, T> mapValues<T>(T Function(V v) parser) {
    final map = <K, T>{};
    for (final entry in entries) {
      final value = parser(entry.value);
      map[entry.key] = value;
    }
    return map;
  }

  Map<K2, V2> mergeEntries<K1, V1, K2, V2>({
    required Map<K1, V1> other,
    required MapEntry<K2, V2>? Function(MapEntry<K, V>?, MapEntry<K1, V1>?)
        merge,
  }) {
    final map = <K2, V2>{};
    final keys = {...this.keys, ...other.keys};
    for (final key in keys) {
      MapEntry<K, V>? thisEntry;
      MapEntry<K1, V1>? otherEntry;
      if (containsKey(key)) thisEntry = MapEntry(key as K, this[key] as V);
      if (other.containsKey(key)) {
        otherEntry = MapEntry(key as K1, other[key] as V1);
      }
      final newEntry = merge(thisEntry, otherEntry);
      if (newEntry != null) map[newEntry.key] = newEntry.value;
    }
    return map;
  }

  Map<K, V2> mergeValues<V1, V2>({
    required Map<K, V1> other,
    required V2? Function(K, V?, V1?) merge,
  }) {
    return mergeEntries(
      other: other,
      merge: (thisEntry, otherEntry) {
        final key = thisEntry?.key ?? otherEntry?.key;
        if (key == null) return null;
        final newValue = merge(key, thisEntry?.value, otherEntry?.value);
        if (newValue == null) return null;
        return MapEntry(key, newValue);
      },
    );
  }

  bool unorderedEquals(Map other) {
    if (length != other.length) return false;
    for (final entry in entries) {
      if (entry.value != other[entry.key]) return false;
    }
    return true;
  }

  bool deepUnorderedEquals(Map other) {
    if (length != other.length) return false;
    for (final entry in entries) {
      final value = entry.value;
      final otherValue = other[entry.key];
      if (value is Map && otherValue is Map) {
        if (!value.deepUnorderedEquals(otherValue)) return false;
      } else if (value != otherValue) {
        return false;
      }
    }
    return true;
  }
}

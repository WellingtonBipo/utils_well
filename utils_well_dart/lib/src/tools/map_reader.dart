import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:utils_well_dart/src/extensions/iterable_extension.dart';

/// This helper holds the data [Map] and provides methods to get values from
/// it and handle the result and provider better error messages.
///
/// The rules are:
/// - If the key is not found,
///   - and the type expected can be null, return null.
///   - and the type expected cannot be null, throw an error.
/// - If the value is not the expected type, throw an error.
/// - If the value is a [double] and the expected type is [int], convert it.
/// - If the value is an [int] and the expected type is [double], convert it.
///
/// ### Example:
/// ```dart
/// final data = {
///   'id': '1',
///   'details': {
///     'name': null,
///     'height': 170,
///   },
/// };
///
/// final helper = MapReader(data: data);
/// final infos = helper.getMap('infos'); // throw error
/// final details = helper.getMap('details'); // return new [MapReader]
///
/// UserInfo(
///  id: helper.get('id'),
///  name: details.get('name'), // throw error because is expecting a [String]
///  height: details.get('height'), // convert [int] to [double]
///  phone: details.get('phone'), // throw error not key found
///  age: details.get('age'), // return null even if no key found
/// );
///
/// class UserInfo {
///   UserInfo({
///     required String id,
///     required String name,
///     required double height,
///     required double phone,
///     required int? age,
///   });
///}
/// ```
class MapReader {
  MapReader._(this._data);

  static MapReaderObject parse(dynamic data) => MapReaderObject._(data);

  static MapReader map(Object map) {
    if (map is MapReader) return map;
    if (map is! Map) throw MapReaderErrorWrongType([], Map, map);
    return MapReader._(map);
  }

  static MapReader? mapNull(dynamic map) =>
      map == null ? null : MapReader.map(map);

  static List<MapReader> list(Object list) {
    if (list is List<MapReader>) return list;
    if (list is! List) throw MapReaderErrorWrongType([], List, list);
    final l = <MapReader>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) throw MapReaderErrorWrongType(['[$i]'], Map, item);
      l.add(MapReader._(item).._keys.add('[$i]'));
    }
    return l;
  }

  static List<MapReader>? listNull(dynamic list) =>
      list == null ? null : MapReader.list(list);

  final Map _data;
  List<String> get keys => _data.keys.mapToList((e, i) => e.toString());

  final List<String> _keys = [];

  MapReader getMap(String key) => _getMap<Map>(key)!;

  MapReader? getMapNull(String key, {bool throwIfNotSameType = true}) =>
      _getMap<Map?>(key, throwIfNotSameType);

  MapReader? getMapNullAllowDiffType(String key) => _getMap<Map?>(key, false);

  List<MapReader> getList(String key) => _getList<List>(key)!;

  List<MapReader>? getListNull(String key, {bool throwIfNotSameType = true}) =>
      _getList<List?>(key, throwIfNotSameType);

  List<MapReader>? getListNullAllowDiffType(String key) =>
      _getList<List?>(key, false);

  V getAllowDiffType<V>(String key, {V? defaultValue}) =>
      get<V>(key, defaultValue: defaultValue, throwIfNotSameType: false);

  V get<V>(String key, {V? defaultValue, bool throwIfNotSameType = true}) {
    var value = _data[key];
    if (V == dynamic) return value;
    value ??= defaultValue;
    if (value is V) return value;
    if (value == null) {
      if (V._isMaybeNull()) return value;
      if (!_data.containsKey(key)) {
        throw MapReaderErrorNoKey([..._keys, key]);
      }
    }

    if (value is int && V._isOrNull<double>()) return value.toDouble() as V;

    if (value is double && V._isOrNull<int>()) {
      if (value - value.toInt() == 0) return value.toInt() as V;
    }

    if (V._isOrNull<DateTime>()) {
      var dt = DateTime.tryParse(value.toString());
      dt ??= _fromMilliseconds(value);
      if (dt != null) return dt as V;
    }

    if (value is Iterable) {
      if (V == List<String>) return value.cast<String>().toList() as V;
      if (V == Set<String>) return value.cast<String>().toSet() as V;
    }

    if (value is Iterable?) {
      if (V._isOrNull<List<String>>()) {
        return value?.cast<String>().toList() as V;
      }
      if (V._isOrNull<Set<String>>()) return value?.cast<String>().toSet() as V;
    }

    if (V == MapReader) return (MapReader.map(value).._keys.add(key)) as V;

    if (V._isOrNull<MapReader>()) {
      return (MapReader.mapNull(value)?.._keys.add(key)) as V;
    }

    if (V == List<MapReader>) {
      return (MapReader.list(value)..mapToList((e, i) => e.._keys.add(key)))
          as V;
    }

    if (V._isOrNull<List<MapReader>>()) {
      return (MapReader.listNull(value)
            ?..mapToList((e, i) => e.._keys.add(key)))
          as V;
    }

    if (!throwIfNotSameType && V._isMaybeNull()) return null as V;

    throw MapReaderErrorWrongType([..._keys, key], V, value);
  }

  MapReader? _getMap<T extends Map?>(
    String key, [
    bool throwIfNotSameType = true,
  ]) {
    if (!_data.containsKey(key) && !T.toString().endsWith('?')) {
      throw MapReaderErrorNoKey([..._keys, key]);
    }
    final map = get<T>(key, throwIfNotSameType: throwIfNotSameType);
    if (map == null) return null;
    return MapReader._(map).._keys.addAll([..._keys, key]);
  }

  List<MapReader>? _getList<T extends List?>(
    String key, [
    bool throwIfNotSameType = true,
  ]) {
    if (!_data.containsKey(key) && !T.toString().endsWith('?')) {
      throw MapReaderErrorNoKey([..._keys, key]);
    }
    final listRaw = get<T>(key, throwIfNotSameType: throwIfNotSameType);
    if (listRaw == null) return null;
    final list = <MapReader>[];
    for (var i = 0; i < listRaw.length; i++) {
      final item = listRaw[i];
      if (item is! Map) {
        throw MapReaderErrorWrongType([..._keys, key, '[$i]'], Map, item);
      }
      list.add(MapReader._(item).._keys.addAll([..._keys, key, '[$i]']));
    }
    return list;
  }
}

class MapReaderObject {
  MapReaderObject._(this._data);

  final dynamic _data;

  MapReader foldMap({
    MapReader? Function(List<MapReader>)? onList,
    MapReader? Function(dynamic data)? onOther,
  }) => fold(
    onMap: (e) => e,
    onList: (e) => onList?.call(e) ?? (throw MapReaderErrorParse(List)),
    onOther: (e) =>
        onOther?.call(e) ?? (throw MapReaderErrorParse(e.runtimeType)),
  );

  MapReader? foldMapNull({
    MapReader? Function(List<MapReader>)? onList,
    MapReader? Function(dynamic data)? onOther,
  }) => fold(
    onMap: (e) => e,
    onList: (e) => onList?.call(e) ?? (throw MapReaderErrorParse(List)),
    onOther: (e) => e == null
        ? null
        : onOther?.call(e) ?? (throw MapReaderErrorParse(e.runtimeType)),
  );

  List<MapReader> foldList({
    List<MapReader>? Function(MapReader)? onMap,
    List<MapReader>? Function(dynamic data)? onOther,
  }) => fold(
    onList: (e) => e,
    onMap: (e) => onMap?.call(e) ?? (throw MapReaderErrorParse(List)),
    onOther: (e) =>
        onOther?.call(e) ?? (throw MapReaderErrorParse(e.runtimeType)),
  );

  List<MapReader>? foldListNull({
    List<MapReader>? Function(MapReader)? onMap,
    List<MapReader>? Function(dynamic data)? onOther,
  }) => fold(
    onList: (e) => e,
    onMap: (e) => onMap?.call(e) ?? (throw MapReaderErrorParse(List)),
    onOther: (e) => e == null
        ? null
        : onOther?.call(e) ?? (throw MapReaderErrorParse(e.runtimeType)),
  );

  T foldOther<T>({
    T Function(MapReader)? onMap,
    T Function(List<MapReader>)? onList,
  }) => fold(
    onMap: (e) => onMap?.call(e) ?? (throw MapReaderErrorParse(Map)),
    onList: (e) => onList?.call(e) ?? (throw MapReaderErrorParse(List)),
    onOther: (e) => e is T ? e : (throw MapReaderErrorParse(e.runtimeType)),
  );

  T fold<T>({
    required T Function(MapReader) onMap,
    required T Function(List<MapReader>) onList,
    required T Function(dynamic data) onOther,
  }) {
    var d = _data;
    if (_data is String) {
      try {
        d = jsonDecode(_data);
      } catch (e) {
        return onOther(_data);
      }
    }
    return switch (d) {
      final Map d => onMap(MapReader._(d)),
      final MapReader d => onMap(d),
      final List<MapReader> d => onList(d),
      final List d => onList(MapReader.list(d)),
      final MapReaderObject d => d.fold(
        onMap: onMap,
        onList: onList,
        onOther: onOther,
      ),
      _ => onOther(_data),
    };
  }
}

sealed class MapReaderError extends Error {
  MapReaderError(this.message);

  final String message;

  String get _className;

  @override
  String toString() => '$_className($message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapReaderError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class MapReaderErrorParse extends MapReaderError {
  MapReaderErrorParse(Type t) : super('Found no match for type ($t).');

  @override
  String get _className => 'MapReaderErrorParse';
}

class MapReaderErrorNoKey extends MapReaderError {
  MapReaderErrorNoKey(List<String> keys)
    : super('Key(${keys._path}) not found.');

  @override
  String get _className => 'MapReaderErrorNoKey';
}

class MapReaderErrorWrongType extends MapReaderError {
  MapReaderErrorWrongType(List<String> keys, Type type, value)
    : super(
        'Value for key(${keys._path}) is not "$type",'
        ' but "${value.runtimeType}". Value: "$value"',
      );

  @override
  String get _className => 'MapReaderErrorWrongType';
}

extension on List<String> {
  String get _path => join('/');
}

extension on Type {
  // bool _isOrNull(Type t) => toString().contains(t.toString());

  bool _isMaybeNull() =>
      toString().endsWith('?') || toString() == 'Null' || toString() == 'void';

  bool _is<T>() => this == T;
  bool _isOrNull<T>() => _is<T>() || _is<T?>();
}

DateTime? _fromMilliseconds(dynamic value) {
  var v = value;
  if (v is Int64) v = v.toInt();
  if (v is double) v = v.toInt();
  if (v is String) {
    v = int.tryParse(v);
    v ??= DateTime.tryParse(value);
    if (v is DateTime) return v;
  }
  if (v is! int) return null;
  try {
    return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
  } catch (e) {
    return null;
  }
}

// ignore_for_file: avoid_redundant_argument_values

import 'package:test/test.dart';
import 'package:utils_well_dart/src/tools/map_reader.dart';

void main() {
  test('getMap', () {
    final data = {
      'k': {'k1': 'v1'},
      'l': [
        {'l1': 'v1'},
      ],
    };

    final helper = MapReader.map(data);
    expect(helper.getMap('k').get('k1'), 'v1');
    expect(
      () => helper.getMap('k1').getMap('k1'),
      throwsA(MapReaderErrorNoKey(['k1'])),
    );
    expect(
      () => helper.getMap('k').getMap('k0'),
      throwsA(MapReaderErrorNoKey(['k', 'k0'])),
    );
    expect(
      () => helper.getMap('k').getMap('k1'),
      throwsA(MapReaderErrorWrongType(['k', 'k1'], Map, 'v1')),
    );
    expect(
      () => helper.getMap('l'),
      throwsA(MapReaderErrorWrongType(['l'], Map, data['l'])),
    );
  });

  test('getMapNull', () {
    final data = {
      'k': {'k1': 'v1'},
      'l': [
        {'l1': 'v1'},
      ],
    };
    final helper = MapReader.map(data);
    expect(helper.getMapNull('k')?.get('k1'), 'v1');
    expect(helper.getMapNull('k0')?.get('k1'), isNull);
    expect(
      () => helper.getMapNull('l'),
      throwsA(MapReaderErrorWrongType(['l'], _t<Map?>(), data['l'])),
    );
    expect(helper.getMapNull('l', throwIfNotSameType: false), isNull);
  });

  test('get', () {
    final helper = MapReader.map({'k1': 'v', 'k2': 1, 'k3': 1.0, 'k4': 1.1});
    expect(helper.get('k1'), 'v');
    expect(helper.get<String>('k1'), 'v');
    expect(helper.get<String?>('k1'), 'v');
    //
    expect(helper.get<int>('k2'), 1);
    expect(helper.get<int?>('k2'), 1);
    expect(helper.get<double>('k2'), 1.0);
    expect(helper.get<double?>('k2'), 1.0);
    //
    expect(helper.get<double>('k3'), 1.0);
    expect(helper.get<double?>('k3'), 1.0);
    expect(helper.get<int>('k3'), 1);
    expect(helper.get<int?>('k3'), 1);
    //
    expect(helper.get<double>('k4'), 1.1);
    expect(helper.get<double?>('k4'), 1.1);
    //
    expect(helper.get<String?>('k0'), isNull);
    expect(helper.get<int?>('k0'), isNull);
    expect(helper.get<int?>('k0', defaultValue: null), isNull);
    expect(helper.get<int?>('k0', defaultValue: 1), 1);
    expect(helper.get<int>('k0', defaultValue: 1), 1);
    //
    expect(
      () => helper.get<int>('k0'),
      throwsA(MapReaderErrorNoKey(['k0'])),
    );
    expect(
      () => helper.get<int>('k0', defaultValue: null),
      throwsA(MapReaderErrorNoKey(['k0'])),
    );
    _expect<int>('k1', helper.get, 'v');
    _expect<int?>('k1', helper.get, 'v');
    _expect<int>('k4', helper.get, 1.1);
    _expect<int?>('k4', helper.get, 1.1);
    //
    expect(helper.get<int?>('k1', throwIfNotSameType: false), isNull);
    expect(helper.getAllowDiffType<int?>('k1'), isNull);
    _expect<int>('k1', helper.get, 'v', false);
    _expect<int>('k1', helper.getAllowDiffType, 'v');
  });
}

void _expect<V>(
  String k,
  Function g,
  v, [
  bool? throwIfNotSameType,
]) {
  expect(
    throwIfNotSameType == null
        // ignore: avoid_dynamic_calls
        ? () => g<V>(k)
        // ignore: avoid_dynamic_calls
        : () => g<V>(k, throwIfNotSameType: throwIfNotSameType),
    throwsA(MapReaderErrorWrongType([k], V, v)),
  );
}

Type _t<T>() => T;

import 'dart:collection';

import 'package:flutter/widgets.dart';

class ListNotifier<T> extends ListBase<T> with ChangeNotifier {
  ListNotifier([Iterable<T> initialList = const []]) : _l = [...initialList];

  List<T?> _l;

  @override
  int get length => _l.length;

  @override
  set length(int newLength) {
    _l.length = newLength;
    notifyListeners();
  }

  @override
  T operator [](int index) => _l.elementAt(index)!;

  @override
  void operator []=(int index, T value) {
    final list = _l.toList();
    list[index] = value;
    _l = list;
    notifyListeners();
  }

  void clearAndAddAll(Iterable<T> newList) {
    _l = newList.toList();
    notifyListeners();
  }

  @override
  void addAll(Iterable<T> iterable) {
    _l.addAll(iterable);
    notifyListeners();
  }
}

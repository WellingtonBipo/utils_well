import 'dart:collection';

class ListClass<T> extends ListBase<T> {
  ListClass(this._list);
  final List<T> _list;

  @override
  int get length => _list.length;

  @override
  set length(int newLength) => _list.length = newLength;

  @override
  T operator [](int index) => _list[index];

  @override
  void operator []=(int index, T value) => _list[index] = value;
}

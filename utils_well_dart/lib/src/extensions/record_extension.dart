extension RecordExtT<T> on (T?,)? {
  T? operator >>(T? other) => this == null ? other : this!.$1;
}

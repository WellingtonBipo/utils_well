extension LetExtension<T extends Object> on T? {
  TT? let<TT>(TT Function(T it) block) {
    if (this == null) return null;
    return block(this!);
  }
}

extension LetExtension<T extends Object> on T {
  TT let<TT>(TT Function(T it) block) {
    return block(this);
  }
}

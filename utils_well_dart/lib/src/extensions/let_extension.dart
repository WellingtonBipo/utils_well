extension LetExtension<T extends Object> on T {
  TT let<TT>(TT Function(T it) block) => block(this);

  TT? letType<TT>() => this is TT ? this as TT : null;
}

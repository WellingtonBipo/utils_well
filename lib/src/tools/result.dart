abstract class Result<S, F> {
  const Result._(this.value);

  final dynamic value;

  B fold<B>(B Function(S s) onSuccess, B Function(F f) onFailure) {
    if (isSuccess) return onSuccess(value);
    return onFailure(value);
  }

  B foldNamed<B>({
    required B Function(S s) onSuccess,
    required B Function(F f) onFailure,
  }) =>
      fold(onSuccess, onFailure);

  S? getSuccess<B>({
    S? Function(F f)? onFailure,
  }) =>
      fold((s) => s, onFailure ?? (f) => null);

  F? getFailure<B>({
    F? Function(S s)? onSuccess,
  }) =>
      fold(onSuccess ?? (s) => null, (f) => f);

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failure<S, F>;

  @override
  bool operator ==(Object other) => other is Success && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class Success<S, F> extends Result<S, F> {
  const Success(S super.value) : super._();
}

class Failure<S, F> extends Result<S, F> {
  const Failure(F super.value) : super._();
}

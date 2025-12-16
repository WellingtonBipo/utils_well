abstract class Result<S extends Object, E extends Object> {
  const Result._(this.value);

  final dynamic value;

  B fold<B>(B Function(S s) onSuccess, B Function(E f) onError) {
    if (isSuccess) return onSuccess(value);
    return onError(value);
  }

  B foldNamed<B>({
    required B Function(S s) success,
    required B Function(E f) error,
  }) =>
      fold(success, error);

  E foldSuccess(E Function(S s) success) => value is S ? success(value) : value;

  S foldError(S Function(E e) error) => value is S ? value : error(value);

  S? getSuccess<B>({
    S? Function(E f)? onError,
  }) =>
      fold((s) => s, onError ?? (f) => null);

  E? getError<B>({
    E? Function(S s)? onSuccess,
  }) =>
      fold(onSuccess ?? (s) => null, (f) => f);

  S successOrThrowError() => fold((s) => s, (e) => throw e);

  E errorOrThrowSuccess() => fold((s) => throw s, (e) => e);

  Result<SS, E> mapSuccess<SS extends Object>(SS Function(S value) func) =>
      fold(
        (s) => Success<SS, E>(func(s)),
        Error<SS, E>.new,
      );

  Result<S, EE> mapError<EE extends Object>(EE Function(E value) func) => fold(
        Success<S, EE>.new,
        (e) => Error<S, EE>(func(e)),
      );

  bool get isSuccess => this is Success<S, E>;
  bool get isError => this is Error<S, E>;

  @override
  bool operator ==(Object other) => other is Success && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class Success<S extends Object, E extends Object> extends Result<S, E> {
  const Success(S super.value) : super._();
}

class Error<S extends Object, E extends Object> extends Result<S, E> {
  const Error(E super.value) : super._();
}

import 'dart:async';

abstract class Result<S, E> {
  const Result._(this.value);

  final dynamic value;

  B fold<B>(B Function(S s) onSuccess, B Function(E f) onError) {
    if (isSuccess) return onSuccess(value);
    return onError(value);
  }

  B foldNamed<B>({
    required B Function(S s) success,
    required B Function(E f) error,
  }) => fold(success, error);

  E foldSuccess(E Function(S s) success) => value is S ? success(value) : value;

  S foldError(S Function(E e) error) => value is S ? value : error(value);

  S? getSuccess<B>({
    S? Function(E f)? onError,
  }) => fold((s) => s, onError ?? (f) => null);

  E? getError<B>({
    E? Function(S s)? onSuccess,
  }) => fold(onSuccess ?? (s) => null, (f) => f);

  S successOrThrowError() => fold((s) => s, (e) => throw e as Object);

  E errorOrThrowSuccess() => fold((s) => throw s as Object, (e) => e);

  Result<SS, E> mapSuccess<SS>(SS Function(S value) func) => fold(
    (s) => Success<SS, E>(func(s)),
    Error<SS, E>.new,
  );

  Result<S, EE> mapError<EE>(EE Function(E value) func) => fold(
    Success<S, EE>.new,
    (e) => Error<S, EE>(func(e)),
  );

  bool get isSuccess => this is Success<S, E>;
  bool get isError => this is Error<S, E>;

  @override
  bool operator ==(Object other) => other is Success && other.value == value;

  @override
  int get hashCode => value.hashCode;

  static Result<SS, EE> trySuccess<SS, EE>({
    required SS Function() success,
    Result<SS, EE>? Function(Object e, StackTrace stk)? onError,
  }) {
    try {
      return Success(success());
    } catch (e, stk) {
      final newError = onError?.call(e, stk);
      if (newError == null) rethrow;
      return newError;
    }
  }
}

class Success<S, E> extends Result<S, E> {
  const Success(S super.value) : super._();
}

class Error<S, E> extends Result<S, E> {
  const Error(E super.value) : super._();
}

extension FutureResultExtension<S, E> on Future<Result<S, E>> {
  Future<B> fold<B>(
    B Function(S s) onSuccess,
    B Function(E f) onError,
  ) => then((result) => result.fold(onSuccess, onError));

  Future<B> foldNamed<B>({
    required B Function(S s) success,
    required B Function(E f) error,
  }) => then((result) => result.foldNamed(success: success, error: error));

  Future<E> foldSuccess(E Function(S s) success) =>
      then((result) => result.foldSuccess(success));

  Future<S> foldError(S Function(E e) error) =>
      then((result) => result.foldError(error));

  Future<S?> getSuccess<B>({
    S? Function(E f)? onError,
  }) => then((result) => result.getSuccess(onError: onError));

  Future<E?> getError<B>({
    E? Function(S s)? onSuccess,
  }) => then((result) => result.getError(onSuccess: onSuccess));

  Future<S> successOrThrowError() =>
      then((result) => result.successOrThrowError());

  Future<E> errorOrThrowSuccess() =>
      then((result) => result.errorOrThrowSuccess());

  Future<Result<SS, E>> mapSuccess<SS>(SS Function(S value) func) =>
      then((result) => result.mapSuccess(func));

  Future<Result<S, EE>> mapError<EE>(EE Function(E value) func) =>
      then((result) => result.mapError(func));
}

extension FutureToResultExtension<T> on Future<T> {
  Future<Success<T, E>> toSuccess<E>() async => Success(await this);

  Future<Result<T, E>> trySuccess<E>({
    E? Function(Object e, StackTrace stk)? onError,
  }) async {
    try {
      return Success(await this);
    } catch (e, stk) {
      final newError = onError?.call(e, stk);
      if (newError == null) rethrow;
      return Error(newError);
    }
  }
}

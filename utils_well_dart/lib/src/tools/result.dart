import 'dart:async';

import 'package:utils_well_dart/utils_well_dart.dart';

abstract class Result<S, F> {
  const Result._(this.value);

  final dynamic value;

  B fold<B>(B Function(S s) onSuccess, B Function(F f) onFailure) {
    if (isSuccess) return onSuccess(value);
    return onFailure(value);
  }

  B foldNamed<B>({
    required B Function(S s) success,
    required B Function(F f) failure,
  }) => fold(success, failure);

  F foldSuccess(F Function(S s) success) => value is S ? success(value) : value;

  S foldFailure(S Function(F e) failure) => value is S ? value : failure(value);

  S? getSuccess<B>({
    S? Function(F f)? onFailure,
  }) => fold((s) => s, onFailure ?? (f) => null);

  F? getFailure<B>({
    F? Function(S s)? onSuccess,
  }) => fold(onSuccess ?? (s) => null, (f) => f);

  S successOrThrowFailure() => fold((s) => s, (e) => throw e as Object);

  F failureOrThrowSuccess() => fold((s) => throw s as Object, (e) => e);

  Result<SS, F> mapSuccess<SS>(SS Function(S value) func) => fold(
    (s) => Success<SS, F>(func(s)),
    Failure<SS, F>.new,
  );

  Result<S, FF> mapFailure<FF>(FF Function(F value) func) => fold(
    Success<S, FF>.new,
    (e) => Failure<S, FF>(func(e)),
  );

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failure<S, F>;

  @override
  bool operator ==(Object other) => other is Success && other.value == value;

  @override
  int get hashCode => value.hashCode;

  static FutureOr<Result<SS, FF>> trySuccessOr<SS, FF>({
    required FutureOr<SS> Function() success,
    required FutureOr<FF> Function(Object e, StackTrace stk) onFailure,
  }) async {
    final result = trySuccess(
      success: success,
      onFailure: (e, stk) => Failure((e, stk)),
    );
    if (result.isSuccess) return Success(await success());
    return result.failureOrThrowSuccess().let(
      (e) async => Failure(await onFailure(e.$1, e.$2)),
    );
  }

  static Result<SS, FF> trySuccess<SS, FF>({
    required SS Function() success,
    Result<SS, FF>? Function(Object e, StackTrace stk)? onFailure,
  }) {
    try {
      return Success(success());
    } catch (e, stk) {
      final newFailure = onFailure?.call(e, stk);
      if (newFailure == null) rethrow;
      return newFailure;
    }
  }
}

class Success<S, F> extends Result<S, F> {
  const Success(S super.value) : super._();
}

class Failure<S, F> extends Result<S, F> {
  const Failure(F super.value) : super._();
}

extension FutureResultExtension<S, F> on Future<Result<S, F>> {
  Future<B> fold<B>(
    B Function(S s) onSuccess,
    B Function(F f) onFailure,
  ) => then((result) => result.fold(onSuccess, onFailure));

  Future<B> foldNamed<B>({
    required B Function(S s) success,
    required B Function(F f) failure,
  }) => then((result) => result.foldNamed(success: success, failure: failure));

  Future<F> foldSuccess(F Function(S s) success) =>
      then((result) => result.foldSuccess(success));

  Future<S> foldFailure(S Function(F e) failure) =>
      then((result) => result.foldFailure(failure));

  Future<S?> getSuccess<B>({
    S? Function(F f)? onFailure,
  }) => then((result) => result.getSuccess(onFailure: onFailure));

  Future<F?> getFailure<B>({
    F? Function(S s)? onSuccess,
  }) => then((result) => result.getFailure(onSuccess: onSuccess));

  Future<S> successOrThrowFailure() =>
      then((result) => result.successOrThrowFailure());

  Future<F> failureOrThrowSuccess() =>
      then((result) => result.failureOrThrowSuccess());

  Future<Result<SS, F>> mapSuccess<SS>(SS Function(S value) func) =>
      then((result) => result.mapSuccess(func));

  Future<Result<S, FF>> mapFailure<FF>(FF Function(F value) func) =>
      then((result) => result.mapFailure(func));
}

extension FutureToResultExtension<T> on Future<T> {
  Future<Success<T, F>> toSuccess<F>() async => Success(await this);

  Future<Result<T, F>> trySuccess<F>({
    F? Function(Object e, StackTrace stk)? onFailure,
  }) async {
    try {
      return Success(await this);
    } catch (e, stk) {
      final newFailure = onFailure?.call(e, stk);
      if (newFailure == null) rethrow;
      return Failure(newFailure);
    }
  }

  Future<Result<T, ({E e, StackTrace stk})>>
  tryResult<E extends Object>() async {
    return trySuccess(onFailure: (e, stk) => (e: e as E, stk: stk));
  }
}

import 'api_exception.dart';

/// Tipo resultado que evita try/catch espalhado pela UI.
/// Use [Ok] para sucesso e [Err] para falha tipada.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  ApiException? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final error) => error,
      };

  R fold<R>({
    required R Function(T value) ok,
    required R Function(ApiException error) err,
  }) =>
      switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final error) => err(error),
      };
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final ApiException error;
  const Err(this.error);
}

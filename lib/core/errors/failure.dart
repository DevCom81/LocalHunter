import 'app_exception.dart';

sealed class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

Failure failureFromException(Object error) {
  if (error is AppException) return ServerFailure(error.message);
  return ServerFailure(error.toString());
}

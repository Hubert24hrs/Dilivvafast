/// Core failure types for the application.
/// Used with fpdart Either<Failure, T> pattern.
sealed class Failure {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure($message, code: $code)';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PaymentFailure extends Failure {
  const PaymentFailure(super.message, {super.code});
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

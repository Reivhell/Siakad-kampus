sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Sesi tidak valid.']);
}

final class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Akses ditolak.']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Data tidak ditemukan.']);
}

final class ConflictException extends AppException {
  const ConflictException(super.message);
}

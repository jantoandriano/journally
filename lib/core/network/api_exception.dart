/// Thrown by repositories when journally-api responds with an unexpected
/// status code.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

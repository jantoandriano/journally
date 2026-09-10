/// Thrown by repositories when journally-api responds with an unexpected
/// status code. A real HTTP response was received — this represents a
/// definitive rejection by the server (e.g. 401 invalid credentials, 404,
/// 500), as opposed to [NetworkException] where no response arrived at
/// all.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when a request fails at the network level — no response was
/// received from the server at all (connection error, timeout, DNS
/// failure, offline device, etc.). Callers should treat this as a
/// transient, retriable failure rather than a definitive rejection: unlike
/// [ApiException], it says nothing about whether the request itself was
/// valid.
class NetworkException implements Exception {
  NetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

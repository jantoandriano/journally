import 'auth_user.dart';

class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;
}

class RefreshResult {
  const RefreshResult({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

abstract class AuthRepository {
  Future<AuthResult> signup({required String email, required String password});

  Future<AuthResult> login({required String email, required String password});

  Future<RefreshResult> refresh(String refreshToken);

  Future<void> logout(String refreshToken);
}

import 'auth_user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthLoggedIn extends AuthState {
  const AuthLoggedIn(this.user, this.accessToken);

  final AuthUser user;
  final String accessToken;
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/http_auth_repository.dart';
import '../../data/token_storage.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_state.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) => HttpAuthRepository();

@riverpod
TokenStorage tokenStorage(Ref ref) => TokenStorage();

// Kept alive — this is app-wide session state, not tied to any one
// screen's lifecycle; disposing it on last-unwatch would drop the
// in-memory access token and force a silent-login re-check.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    _trySilentLogin();
    return const AuthLoading();
  }

  Future<void> _trySilentLogin() async {
    final storage = ref.read(tokenStorageProvider);
    final session = await storage.readSession();
    if (session == null) {
      state = const AuthLoggedOut();
      return;
    }
    try {
      final result = await ref.read(authRepositoryProvider).refresh(session.refreshToken);
      await storage.updateRefreshToken(result.refreshToken);
      state = AuthLoggedIn(session.user, result.accessToken);
    } catch (_) {
      await storage.clear();
      state = const AuthLoggedOut();
    }
  }

  Future<void> signup({required String email, required String password}) => _authenticate(
    () => ref.read(authRepositoryProvider).signup(email: email, password: password),
  );

  Future<void> login({required String email, required String password}) => _authenticate(
    () => ref.read(authRepositoryProvider).login(email: email, password: password),
  );

  Future<void> _authenticate(Future<AuthResult> Function() action) async {
    state = const AuthLoading();
    try {
      final result = await action();
      await ref
          .read(tokenStorageProvider)
          .saveSession(refreshToken: result.refreshToken, user: result.user);
      state = AuthLoggedIn(result.user, result.accessToken);
    } catch (e) {
      state = const AuthLoggedOut();
      rethrow;
    }
  }

  /// Called by [AuthInterceptor] on a 401. Rotates the stored refresh
  /// token and returns the new access token, or throws if the refresh
  /// token itself is no longer valid — the interceptor treats that as a
  /// signal to force a logout.
  Future<String> refreshAccessToken() async {
    final storage = ref.read(tokenStorageProvider);
    final session = await storage.readSession();
    if (session == null) {
      throw StateError('No session to refresh');
    }
    final result = await ref.read(authRepositoryProvider).refresh(session.refreshToken);
    await storage.updateRefreshToken(result.refreshToken);
    final current = state;
    final user = current is AuthLoggedIn ? current.user : session.user;
    state = AuthLoggedIn(user, result.accessToken);
    return result.accessToken;
  }

  Future<void> forceLogout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthLoggedOut();
  }

  Future<void> logout() async {
    final storage = ref.read(tokenStorageProvider);
    final session = await storage.readSession();
    if (session != null) {
      await ref.read(authRepositoryProvider).logout(session.refreshToken);
    }
    await storage.clear();
    state = const AuthLoggedOut();
  }
}

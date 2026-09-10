import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../network/api_exception.dart';
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
  // Single-flight guard for `/auth/refresh` calls, shared by every code
  // path that can trigger a refresh (cold-start silent login, and the
  // AuthInterceptor on a 401). Two independent, unguarded call sites
  // hitting `/auth/refresh` concurrently with the same refresh token trip
  // the backend's reuse-detection and revoke the whole session — routing
  // every caller through this one future (mirroring the identical pattern
  // in AuthInterceptor) guarantees at most one `/auth/refresh` request is
  // ever in flight at a time, regardless of who triggered it first.
  Future<String>? _refreshFuture;

  // Bumped by every event that starts a new "session" — logout(),
  // forceLogout(), and _authenticate() (signup/login). A refresh captures
  // the epoch at the moment it starts; if the epoch has moved on by the
  // time it completes, a logout/login happened while it was in flight and
  // its result is stale — see _refresh() below.
  int _authEpoch = 0;

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
      // Routed through the shared, guarded refresh path (not a direct
      // repository call) so this races safely against any concurrent
      // interceptor-triggered refresh instead of firing a second,
      // unguarded `/auth/refresh` request.
      await refreshAccessToken();
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        // A genuine rejection of the refresh token itself
        // (invalid/revoked/reused) — treat as a definitive logout and
        // clear the now-useless stored session.
        await storage.clear();
        state = const AuthLoggedOut();
      } else {
        // Couldn't verify the session because of a network problem, a
        // transient server error (5xx, 429, ...), or anything else that
        // isn't a confirmed 401 rejection. Per spec: don't log out
        // destructively — leave the refresh token in storage so the next
        // attempt (next cold start, or a manual login) can still use it.
        // We still have to leave AuthLoading — the least invasive option
        // given the existing AuthState shape is to surface this as
        // logged-out (so the UI doesn't hang) without clearing storage.
        state = const AuthLoggedOut();
      }
    }
  }

  Future<void> signup({required String email, required String password}) => _authenticate(
    () => ref.read(authRepositoryProvider).signup(email: email, password: password),
  );

  Future<void> login({required String email, required String password}) => _authenticate(
    () => ref.read(authRepositoryProvider).login(email: email, password: password),
  );

  Future<void> _authenticate(Future<AuthResult> Function() action) async {
    // A successful signup/login starts a new session, distinct from
    // whatever session (if any) preceded it — bump the epoch so any
    // refresh still in flight from the old session is recognized as stale
    // when it eventually completes. See _refresh() for how this is used.
    _authEpoch++;
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

  /// Called by [AuthInterceptor] on a 401 (and by cold-start silent
  /// login). Single-flights concurrent callers through [_refreshFuture] so
  /// only one `/auth/refresh` request is ever in flight at a time. Rotates
  /// the stored refresh token and returns the new access token, or throws
  /// if the refresh token itself is no longer valid — the interceptor
  /// treats an [ApiException] with `statusCode == 401` (a genuine
  /// rejection) as a signal to force a logout, but not a
  /// [NetworkException] or an [ApiException] with any other status code
  /// (a transient server problem).
  Future<String> refreshAccessToken() => _refreshFuture ??= _refresh();

  Future<String> _refresh() async {
    // Captured before any await — this is the epoch "as of" the moment
    // this refresh started. Compared against the live _authEpoch both
    // below (to decide whether to persist the result) and in `finally`
    // (to decide whether this refresh still owns `_refreshFuture`).
    final epoch = _authEpoch;
    try {
      return await _doRefresh(epoch);
    } finally {
      // logout()/forceLogout() null `_refreshFuture` directly, and
      // _authenticate() (a fresh login) may already have started its own
      // refresh which owns `_refreshFuture` now. Only clear it here if no
      // such event happened while this refresh was in flight — otherwise
      // this stale refresh would clobber a newer, still-in-flight one's
      // single-flight guard (see _authEpoch's doc comment).
      if (epoch == _authEpoch) {
        _refreshFuture = null;
      }
    }
  }

  Future<String> _doRefresh(int epoch) async {
    final storage = ref.read(tokenStorageProvider);
    final session = await storage.readSession();
    if (session == null) {
      throw StateError('No session to refresh');
    }
    final result = await ref.read(authRepositoryProvider).refresh(session.refreshToken);

    // A logout, or a login as a different user, can complete while this
    // refresh is in flight (they share no mutual exclusion of their own).
    // If that happened, the epoch will have moved on since this refresh
    // started — don't resurrect the old session or clobber the new one:
    // skip persisting the rotated refresh token and skip flipping state.
    // Still return the fresh access token so the interceptor can satisfy
    // the specific request it's retrying — it just won't be remembered
    // anywhere.
    if (epoch != _authEpoch) {
      return result.accessToken;
    }

    await storage.updateRefreshToken(result.refreshToken);
    final current = state;
    final user = current is AuthLoggedIn ? current.user : session.user;
    state = AuthLoggedIn(user, result.accessToken);
    return result.accessToken;
  }

  Future<void> forceLogout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthLoggedOut();
    // Prevent an in-flight (or about-to-start) refresh from writing a
    // fresh refresh token back to storage and flipping state back to
    // logged in after this logout, which would silently resurrect the
    // session and orphan an unrevoked refresh token on the device.
    _refreshFuture = null;
    // This is now a different session than whatever preceded it — see
    // _authEpoch's doc comment. Bumping it (in addition to nulling
    // `_refreshFuture` above) ensures a refresh that was already in
    // flight before this logout, and so isn't covered by the null above,
    // is still recognized as stale when it completes later.
    _authEpoch++;
  }

  Future<void> logout() async {
    final storage = ref.read(tokenStorageProvider);
    final session = await storage.readSession();
    if (session != null) {
      await ref.read(authRepositoryProvider).logout(session.refreshToken);
    }
    await storage.clear();
    state = const AuthLoggedOut();
    // See forceLogout() — guards against a concurrent in-flight refresh
    // undoing this logout, both immediately (nulling `_refreshFuture`) and
    // for one that was already in flight before this call started
    // (bumping `_authEpoch`).
    _refreshFuture = null;
    _authEpoch++;
  }
}

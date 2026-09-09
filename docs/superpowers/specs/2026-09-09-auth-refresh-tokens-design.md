# Auth & Refresh Token Architecture — Design

**Date:** 2026-09-09
**Repos affected:** `journally` (Flutter app), `journally-api` (Express/Prisma/SQLite)
**Scope:** Email/password authentication with JWT access tokens + rotating refresh tokens, multi-user, multi-device. OAuth (Google/Apple) is explicitly out of scope — planned as a separate follow-up spec once this lands.

## Context

`journally` is currently a single-user app with no `User` model and no auth layer. The API (`journally-api`) has no auth middleware — every route is open. This spec introduces real user accounts, scoping all existing data (`JournalEntry`, `Sighting`, and their related models) to a `userId`.

Existing dev/test data in the DB is disposable — no migration/backfill needed, just add the required `userId` columns and reset the dev database.

## Architecture Overview

```
Flutter app                          journally-api
────────────                         ─────────────
login/signup screen  ──POST /auth/login──▶  verify password (argon2id)
                                            issue access JWT (15m) + refresh token (30d)
                      ◀─────────────────────
AuthController (Riverpod)
  - holds access token in memory
  - refresh token → flutter_secure_storage
  - notifies authState (loggedOut/loading/loggedIn)

ApiClient (Dio, replaces raw http.Client in every *_repository.dart)
  - interceptor: attach `Authorization: Bearer <access>` to every request
  - on 401: pause queue, POST /auth/refresh once (single in-flight refresh), replay queued requests
  - refresh itself returns 401 → force logout, clear storage, authState=loggedOut

Every existing repo (http_sighting_repository.dart, http_cafe_repository.dart, ...)
  - public interface unchanged, built on shared ApiClient instead of raw http.Client
```

API side: new `auth` route module (signup/login/refresh/logout/logout-all) + JWT-verify middleware wrapping every existing entries/sightings/feedings/photos/sighting-photos route (adds `req.userId`), all queries scoped by `userId`.

## Data Model (Prisma)

```prisma
model User {
  id             String         @id @default(uuid())
  email          String         @unique
  passwordHash   String
  createdAt      DateTime       @default(now())
  refreshTokens  RefreshToken[]
  journalEntries JournalEntry[]
  sightings      Sighting[]
}

model RefreshToken {
  id          String    @id @default(uuid())
  userId      String
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  tokenHash   String    @unique   // sha256 of the raw token; raw value never stored
  deviceInfo  String?              // e.g. OS string from the client, for a future "sign out everywhere" UI
  expiresAt   DateTime
  revokedAt   DateTime?
  replacedBy  String?              // id of the token this was rotated into, for reuse-detection
  createdAt   DateTime  @default(now())
}
```

Every existing model that stores user data (`JournalEntry`, `Sighting`) gains a required `userId String` field with a relation to `User` (`onDelete: Cascade`).

**Refresh token rotation & reuse detection:** each `/auth/refresh` call looks up the token by hash. If found and unrevoked, it's revoked and a new one issued (`replacedBy` set to the new token's id) — this is the normal rotation path. If the looked-up token is already revoked, that means it was replayed after already being rotated (theft signal): revoke every unrevoked token belonging to that user (or narrower: that `deviceInfo`, if attribution is reliable) and require re-login on that device.

## API Endpoints & Middleware

```
POST /auth/signup      { email, password }         → 201 { user, accessToken, refreshToken }
POST /auth/login       { email, password }         → 200 { user, accessToken, refreshToken }
POST /auth/refresh     { refreshToken }             → 200 { accessToken, refreshToken }  (rotates)
POST /auth/logout      { refreshToken }             → 204  (revokes that one token)
POST /auth/logout-all  (authed, no body)            → 204  (revokes all of the user's tokens)
```

- Passwords hashed with `argon2id`.
- Request bodies validated with Zod, matching the existing validation style used for `Sighting.species`.
- `requireAuth` middleware: reads `Authorization: Bearer <jwt>`, verifies signature + expiry via `jsonwebtoken`, sets `req.userId`; responds 401 on missing/invalid/expired token. Implemented using the existing `asyncHandler` wrapper pattern in `src/middleware/`.
- Existing route files (`entries`, `sightings`, `feedings`, `photos`, `sighting-photos`) get `requireAuth` applied at the router level. Every Prisma query in those routes is scoped with `where: { userId: req.userId }`; update/delete on a resource owned by another user returns 404 (not 403), to avoid confirming the resource exists.

## Flutter Client Architecture

```
lib/core/auth/
  domain/auth_repository.dart        — interface: login, signup, logout, refresh, currentUser stream
  data/http_auth_repository.dart     — implements it, calls /auth/* endpoints
  data/token_storage.dart            — wraps flutter_secure_storage, get/set/clear refresh token
  presentation/providers/auth_providers.dart
        — Riverpod StateNotifier<AuthState>
        — AuthState = loggedOut | loading | loggedIn(User)

lib/core/network/
  api_client.dart          — Dio instance + interceptors; replaces direct baseUrl+http.Client usage
  auth_interceptor.dart    — attaches Bearer token; on 401, triggers a single shared refresh future,
                              queues concurrent requests during refresh, replays them after
```

- All five existing `http_*_repository.dart` files migrate from raw `http.Client` to the shared `ApiClient` (Dio). Public repo interfaces (`SightingsRepository`, etc.) stay identical — only the Riverpod provider wiring changes, injecting `ApiClient` instead of `http.Client`.
- App root listens to `authControllerProvider`: `loggedOut` shows login/signup screens; `loggedIn` shows the current home flow. On cold start, attempt a silent refresh from the stored refresh token before deciding which to show.
- Login/signup requests include a `deviceInfo` string (`Platform.operatingSystem`, or richer via `device_info_plus` if convenient) — stored server-side for future "sign out everywhere" UI; no client UI for it required in v1.

## Error Handling

- **Refresh race:** the interceptor keeps a single `Future<String>? _refreshFuture`. The first 401 triggers a refresh; concurrent 401s from other repos await that same future rather than firing duplicate `/auth/refresh` calls (duplicate concurrent calls would race the rotation and one would be reuse-detected, causing a false logout).
- **Refresh fails due to network error:** don't log out — surface as a generic network error to the caller and keep the stored refresh token for the next attempt. Only a definitive 401 *from* `/auth/refresh` itself (invalid/revoked/reused token) triggers logout.
- **Reuse detected server-side:** `/auth/refresh` returns 401 with a distinct error code (`refresh_token_reused`) so the client can log it distinctly from plain expiry, even though the UI treatment (force re-login) is the same either way.
- `lib/core/network/api_exception.dart` gets a 401 case the interceptor resolves internally (refresh + replay); if truly unauthenticated after that, the exception bubbles to the repo/caller unchanged.
- Signup/login 400s (Zod validation errors) map to per-field form errors on the auth screens, not a generic exception banner.

## Testing

- **API:** new `tests/auth/` covering signup, login, refresh rotation, reuse detection, logout, logout-all. Existing route tests updated to assert 401 without a token and to verify per-user ownership scoping (user A cannot read/edit/delete user B's resources). Unit-level middleware tests use a fake in-memory token store, matching the existing fake-repository test pattern; rotation/reuse-detection logic is tested against real Prisma+sqlite since hash/timing behavior matters.
- **Flutter:** unit tests for `AuthController` state transitions (loggedOut → loading → loggedIn, 401-triggered refresh, forced logout on reuse detection). `ApiClient`/interceptor tests using Dio's mock adapter, verifying a single in-flight refresh under concurrent 401s and correct replay of queued requests with the new token. Existing repo tests need only their mock transport swapped from `http.Client` to a Dio mock adapter — public interfaces are unchanged.
- No widget/golden tests required for login/signup screens in v1 — a functional flow test (enter credentials → land on home screen) is sufficient.

## Out of Scope

- OAuth (Google/Apple) sign-in — separate follow-up spec.
- Password reset / email verification flows.
- "Sign out everywhere" UI (server support exists via `logout-all` and `deviceInfo`, but no client screen).
- Migrating/preserving existing dev DB rows — data is disposable for this change.

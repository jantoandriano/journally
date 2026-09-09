# Auth & Refresh Token Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Multi-user email/password authentication for journally, with short-lived JWT access tokens and rotating, DB-backed refresh tokens, across `journally-api` (Express/Prisma/SQLite) and `journally` (Flutter).

**Architecture:** `journally-api` gains a `User`/`RefreshToken` data model, an `/auth/*` route module, and a `requireAuth` middleware that scopes every existing resource query by `req.userId`. `journally` gains a Dio-based `ApiClient` with an interceptor that attaches the access token and transparently refreshes-and-retries on 401 (single in-flight refresh, so concurrent 401s don't race), a Riverpod `AuthController` holding session state, and login/signup screens gating the existing home flow.

**Tech Stack:** `argon2` (password hashing), `jsonwebtoken` (access tokens), Node `crypto` (refresh token generation/hashing) on the API; `dio` + `flutter_secure_storage` on the client. No new mocking package for API tests (existing supertest+real-sqlite convention is reused); Flutter tests use a small hand-rolled fake `HttpClientAdapter` instead of adding a Dio mocking dependency.

**Spec:** `docs/superpowers/specs/2026-09-09-auth-refresh-tokens-design.md`

## Global Constraints

- Access token lifetime: 15 minutes. Refresh token lifetime: 30 days. (From spec's Architecture Overview.)
- Refresh tokens are rotated on every use; replaying an already-rotated token revokes every live token for that user. (Spec: Data Model.)
- Existing dev DB data is disposable — no backfill migration, `userId` is a required field from the start. (Spec: Context / Out of Scope.)
- Ownership violations on existing resources return 404, not 403. (Spec: API Endpoints & Middleware.)
- `/uploads` stays unauthenticated (existing behavior, not in the spec's endpoint list, so left as-is).
- OAuth, password reset, "sign out everywhere" UI: out of scope for this plan. (Spec: Out of Scope.)

**Note on the spec's testing section:** the spec describes API middleware tests against a "fake in-memory token store." This repo's existing test suite has no mocking convention at all — every test hits the real app + real SQLite test DB via supertest. This plan follows that existing pattern instead (see `superpowers:writing-plans` guidance to follow established codebase conventions) — `requireAuth` is exercised through real protected routes rather than a standalone fake-store harness.

---

## Part 1 — journally-api

### Task 1: Add auth dependencies and JWT secret config

**Files:**
- Modify: `journally-api/package.json`
- Modify: `journally-api/.env`
- Modify: `journally-api/.env.example`

**Interfaces:**
- Produces: `argon2` and `jsonwebtoken` packages available to later tasks; `process.env.JWT_SECRET` available at runtime and in tests.

- [ ] **Step 1: Install dependencies**

Run (from `journally-api/`):
```bash
npm install argon2 jsonwebtoken
npm install -D @types/jsonwebtoken
```

- [ ] **Step 2: Add `JWT_SECRET` to env files**

`.env` and `.env.example` both get a new line appended:
```
JWT_SECRET="dev-only-secret-change-me"
```

- [ ] **Step 3: Commit**

```bash
git add package.json package-lock.json .env.example
git commit -m "chore: add argon2 and jsonwebtoken for auth"
```

(`.env` itself is gitignored — confirm with `git status` that it doesn't appear before committing.)

---

### Task 2: Prisma schema — User, RefreshToken, userId on existing models

**Files:**
- Modify: `journally-api/prisma/schema.prisma`
- Modify: `journally-api/tests/setup.ts`
- Modify: `journally-api/tests/db.test.ts:6-14`

**Interfaces:**
- Produces: `prisma.user`, `prisma.refreshToken` Prisma Client models; `JournalEntry.userId` / `Sighting.userId` required fields.

- [ ] **Step 1: Edit the schema**

Add these two models to `prisma/schema.prisma`:

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
  tokenHash   String    @unique
  deviceInfo  String?
  expiresAt   DateTime
  revokedAt   DateTime?
  replacedBy  String?
  createdAt   DateTime  @default(now())
}
```

Add `userId String` + relation to both `JournalEntry` and `Sighting`:

```prisma
model JournalEntry {
  id           String           @id @default(uuid())
  userId       String
  user         User             @relation(fields: [userId], references: [id], onDelete: Cascade)
  placeName    String
  // ...rest of the existing fields unchanged...
}
```

```prisma
model Sighting {
  id                String              @id @default(uuid())
  userId            String
  user              User                @relation(fields: [userId], references: [id], onDelete: Cascade)
  species           String
  // ...rest of the existing fields unchanged...
}
```

- [ ] **Step 2: Reset the dev DB and generate a migration**

Dev data is disposable (per spec), so delete the existing dev DB rather than writing a backfill:

```bash
rm journally-api/prisma/dev.db
cd journally-api && npm run prisma:migrate -- --name add_auth
```

Confirm a new folder appears under `journally-api/prisma/migrations/`.

- [ ] **Step 3: Update `tests/setup.ts` to clean up the new tables**

`tests/setup.ts` currently deletes rows in dependency order before each test. Add the two new tables at the end of the existing `beforeEach`:

```ts
beforeEach(async () => {
  await prisma.photo.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.entryAttribute.deleteMany();
  await prisma.sightingPhoto.deleteMany();
  await prisma.feedingLogEntry.deleteMany();
  await prisma.sighting.deleteMany();
  await prisma.journalEntry.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.user.deleteMany();
});
```

- [ ] **Step 4: Fix `tests/db.test.ts`, which now violates the required `userId`**

Replace its contents:

```ts
import { describe, it, expect } from 'vitest';
import { prisma } from '../src/db';

describe('prisma client', () => {
  it('creates and fetches a journal entry', async () => {
    const user = await prisma.user.create({
      data: { email: 'db-test@example.com', passwordHash: 'irrelevant-for-this-test' },
    });

    const entry = await prisma.journalEntry.create({
      data: {
        userId: user.id,
        placeName: 'Blue Bottle',
        neighborhood: 'Hayes Valley',
        city: 'San Francisco',
      },
    });

    const found = await prisma.journalEntry.findUniqueOrThrow({
      where: { id: entry.id },
    });

    expect(found.placeName).toBe('Blue Bottle');
  });
});
```

- [ ] **Step 5: Run the full test suite to confirm only the expected failures remain**

Run: `cd journally-api && npm test`
Expected: `db.test.ts`, `app.test.ts`, `errorHandler.test.ts` pass. Every `entries.*`, `sightings.*`, `photos.*`, `sightingPhotos.*`, `feedings.*` test now fails with a Prisma validation error (missing `userId`) — expected, fixed in later tasks.

- [ ] **Step 6: Commit**

```bash
git add prisma/schema.prisma prisma/migrations tests/setup.ts tests/db.test.ts
git commit -m "feat: add User/RefreshToken models and userId ownership columns"
```

---

### Task 3: Password hashing utility

**Files:**
- Create: `journally-api/src/auth/password.ts`
- Test: `journally-api/tests/auth/password.test.ts`

**Interfaces:**
- Produces: `hashPassword(password: string): Promise<string>`, `verifyPassword(hash: string, password: string): Promise<boolean>`

- [ ] **Step 1: Write the failing test**

```ts
import { describe, expect, it } from 'vitest';
import { hashPassword, verifyPassword } from '../../src/auth/password';

describe('password hashing', () => {
  it('verifies a correct password against its hash', async () => {
    const hash = await hashPassword('correct horse battery staple');
    await expect(verifyPassword(hash, 'correct horse battery staple')).resolves.toBe(true);
  });

  it('rejects an incorrect password', async () => {
    const hash = await hashPassword('correct horse battery staple');
    await expect(verifyPassword(hash, 'wrong password')).resolves.toBe(false);
  });

  it('produces a different hash each time (random salt)', async () => {
    const a = await hashPassword('same password');
    const b = await hashPassword('same password');
    expect(a).not.toBe(b);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd journally-api && npx vitest run tests/auth/password.test.ts`
Expected: FAIL — `Cannot find module '../../src/auth/password'`

- [ ] **Step 3: Write the implementation**

```ts
import argon2 from 'argon2';

export async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password);
}

export async function verifyPassword(hash: string, password: string): Promise<boolean> {
  return argon2.verify(hash, password);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd journally-api && npx vitest run tests/auth/password.test.ts`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add src/auth/password.ts tests/auth/password.test.ts
git commit -m "feat: add argon2 password hashing utility"
```

---

### Task 4: Access/refresh token utilities

**Files:**
- Create: `journally-api/src/auth/tokens.ts`
- Test: `journally-api/tests/auth/tokens.test.ts`

**Interfaces:**
- Consumes: `process.env.JWT_SECRET` (Task 1)
- Produces: `signAccessToken({userId}): string`, `verifyAccessToken(token): {userId: string}` (throws on invalid/expired), `generateRefreshToken(): {token, hash, expiresAt}`, `hashRefreshToken(token): string`

- [ ] **Step 1: Write the failing test**

```ts
import { describe, expect, it } from 'vitest';
import {
  generateRefreshToken,
  hashRefreshToken,
  signAccessToken,
  verifyAccessToken,
} from '../../src/auth/tokens';

describe('access tokens', () => {
  it('round-trips the userId through sign and verify', () => {
    const token = signAccessToken({ userId: 'user-123' });
    expect(verifyAccessToken(token)).toEqual({ userId: 'user-123' });
  });

  it('throws for a tampered token', () => {
    const token = signAccessToken({ userId: 'user-123' });
    expect(() => verifyAccessToken(`${token}tampered`)).toThrow();
  });
});

describe('refresh tokens', () => {
  it('generates a token whose hash matches hashRefreshToken', () => {
    const { token, hash } = generateRefreshToken();
    expect(hashRefreshToken(token)).toBe(hash);
  });

  it('generates a future expiresAt', () => {
    const { expiresAt } = generateRefreshToken();
    expect(expiresAt.getTime()).toBeGreaterThan(Date.now());
  });

  it('generates unique tokens on each call', () => {
    const a = generateRefreshToken();
    const b = generateRefreshToken();
    expect(a.token).not.toBe(b.token);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd journally-api && npx vitest run tests/auth/tokens.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Write the implementation**

```ts
import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';

const ACCESS_TOKEN_TTL_SECONDS = 15 * 60;
const REFRESH_TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('JWT_SECRET is not set');
  return secret;
}

export interface AccessTokenPayload {
  userId: string;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, getJwtSecret(), { expiresIn: ACCESS_TOKEN_TTL_SECONDS });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const decoded = jwt.verify(token, getJwtSecret());
  if (typeof decoded === 'string' || typeof decoded.userId !== 'string') {
    throw new Error('Invalid access token payload');
  }
  return { userId: decoded.userId };
}

export function hashRefreshToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function generateRefreshToken(): { token: string; hash: string; expiresAt: Date } {
  const token = crypto.randomBytes(32).toString('hex');
  return {
    token,
    hash: hashRefreshToken(token),
    expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_MS),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd journally-api && npx vitest run tests/auth/tokens.test.ts`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add src/auth/tokens.ts tests/auth/tokens.test.ts
git commit -m "feat: add JWT access token and refresh token utilities"
```

---

### Task 5: Auth Zod schemas

**Files:**
- Create: `journally-api/src/auth/auth.schema.ts`

**Interfaces:**
- Produces: `signupSchema`, `loginSchema`, `refreshSchema`, `logoutSchema` (Zod), and their inferred types `SignupInput`, `LoginInput`, `RefreshInput`, `LogoutInput`.

- [ ] **Step 1: Write the schemas**

```ts
import { z } from 'zod';

export const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  deviceInfo: z.string().optional(),
});
export type SignupInput = z.infer<typeof signupSchema>;

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  deviceInfo: z.string().optional(),
});
export type LoginInput = z.infer<typeof loginSchema>;

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});
export type RefreshInput = z.infer<typeof refreshSchema>;

export const logoutSchema = z.object({
  refreshToken: z.string().min(1),
});
export type LogoutInput = z.infer<typeof logoutSchema>;
```

There's no standalone test for this file — it's exercised through the route tests in Tasks 6-9.

- [ ] **Step 2: Commit**

```bash
git add src/auth/auth.schema.ts
git commit -m "feat: add auth request validation schemas"
```

---

### Task 6: Auth service — signup and login

**Files:**
- Create: `journally-api/src/auth/auth.service.ts`
- Test: `journally-api/tests/auth/signup.test.ts` (via the not-yet-existing route — write this test now, it starts passing once Task 9 mounts the route)

**Interfaces:**
- Consumes: `hashPassword`/`verifyPassword` (Task 3), `signAccessToken`/`generateRefreshToken` (Task 4)
- Produces: `signup(input): Promise<{user, accessToken, refreshToken}>`, `login(input): Promise<{user, accessToken, refreshToken}>`, `AuthError` class with `.code`

This task writes service-layer code with no route yet to hit it through, so there's no runnable test until Task 9. Write the implementation now; Task 9's tests are what actually exercise it.

- [ ] **Step 1: Write `auth.service.ts` (signup/login half)**

```ts
import { prisma } from '../db';
import { hashPassword, verifyPassword } from './password';
import { generateRefreshToken, signAccessToken } from './tokens';
import type { LoginInput, SignupInput } from './auth.schema';

export class AuthError extends Error {
  code: string;

  constructor(message: string, code: string) {
    super(message);
    this.code = code;
  }
}

function shapeUser(user: { id: string; email: string }) {
  return { id: user.id, email: user.email };
}

async function issueTokenPair(userId: string, deviceInfo: string | undefined) {
  const accessToken = signAccessToken({ userId });
  const { token: refreshToken, hash, expiresAt } = generateRefreshToken();

  await prisma.refreshToken.create({
    data: { userId, tokenHash: hash, deviceInfo, expiresAt },
  });

  return { accessToken, refreshToken };
}

export async function signup(input: SignupInput) {
  const existing = await prisma.user.findUnique({ where: { email: input.email } });
  if (existing) throw new AuthError('Email already in use', 'email_taken');

  const user = await prisma.user.create({
    data: { email: input.email, passwordHash: await hashPassword(input.password) },
  });

  const tokens = await issueTokenPair(user.id, input.deviceInfo);
  return { user: shapeUser(user), ...tokens };
}

export async function login(input: LoginInput) {
  const user = await prisma.user.findUnique({ where: { email: input.email } });
  if (!user || !(await verifyPassword(user.passwordHash, input.password))) {
    throw new AuthError('Invalid email or password', 'invalid_credentials');
  }

  const tokens = await issueTokenPair(user.id, input.deviceInfo);
  return { user: shapeUser(user), ...tokens };
}
```

- [ ] **Step 2: Commit**

```bash
git add src/auth/auth.service.ts
git commit -m "feat: add signup/login auth service"
```

(Task 7 appends `refresh`/`logout`/`logoutAll` to this same file.)

---

### Task 7: Auth service — refresh (rotation + reuse detection), logout, logoutAll

**Files:**
- Modify: `journally-api/src/auth/auth.service.ts`

**Interfaces:**
- Consumes: `hashRefreshToken`, `generateRefreshToken`, `signAccessToken` (Task 4)
- Produces: `refresh(rawToken): Promise<{accessToken, refreshToken}>`, `logout(rawToken): Promise<void>`, `logoutAll(userId): Promise<void>`

- [ ] **Step 1: Append to `auth.service.ts`**

Update the import line to add the two new token helpers:

```ts
import { generateRefreshToken, hashRefreshToken, signAccessToken } from './tokens';
```

Append these functions at the end of the file:

```ts
export async function refresh(rawToken: string) {
  const hash = hashRefreshToken(rawToken);
  const existing = await prisma.refreshToken.findUnique({ where: { tokenHash: hash } });

  if (!existing) {
    throw new AuthError('Invalid refresh token', 'refresh_token_invalid');
  }

  if (existing.revokedAt) {
    // Already-rotated token replayed — treat as theft: kill every live
    // session for this user so the legitimate device has to re-login.
    await prisma.refreshToken.updateMany({
      where: { userId: existing.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    throw new AuthError('Refresh token reuse detected', 'refresh_token_reused');
  }

  if (existing.expiresAt < new Date()) {
    throw new AuthError('Refresh token expired', 'refresh_token_expired');
  }

  const accessToken = signAccessToken({ userId: existing.userId });
  const { token: newRefreshToken, hash: newHash, expiresAt } = generateRefreshToken();

  const created = await prisma.refreshToken.create({
    data: {
      userId: existing.userId,
      tokenHash: newHash,
      deviceInfo: existing.deviceInfo,
      expiresAt,
    },
  });

  await prisma.refreshToken.update({
    where: { id: existing.id },
    data: { revokedAt: new Date(), replacedBy: created.id },
  });

  return { accessToken, refreshToken: newRefreshToken };
}

export async function logout(rawToken: string) {
  const hash = hashRefreshToken(rawToken);
  await prisma.refreshToken.updateMany({
    where: { tokenHash: hash, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

export async function logoutAll(userId: string) {
  await prisma.refreshToken.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add src/auth/auth.service.ts
git commit -m "feat: add refresh token rotation, reuse detection, logout"
```

(No standalone test yet — exercised via routes in Task 9.)

---

### Task 8: requireAuth middleware

**Files:**
- Create: `journally-api/src/middleware/requireAuth.ts`

**Interfaces:**
- Consumes: `verifyAccessToken` (Task 4)
- Produces: `requireAuth` Express middleware that sets `req.userId` or responds 401.

- [ ] **Step 1: Write the middleware**

```ts
import type { NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../auth/tokens';

declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing bearer token' });
    return;
  }

  try {
    const { userId } = verifyAccessToken(header.slice('Bearer '.length));
    req.userId = userId;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired access token' });
  }
}
```

There's no route wired to it yet — it's exercised in Task 9 (via `/auth/logout-all`) and Tasks 10-14 (via the existing resource routers).

- [ ] **Step 2: Commit**

```bash
git add src/middleware/requireAuth.ts
git commit -m "feat: add requireAuth middleware"
```

---

### Task 9: Auth routes, mounted in app.ts, plus the test helper and full auth test suite

**Files:**
- Create: `journally-api/src/auth/auth.routes.ts`
- Create: `journally-api/tests/helpers/testAuth.ts`
- Modify: `journally-api/src/app.ts`
- Test: `journally-api/tests/auth/signup.test.ts`
- Test: `journally-api/tests/auth/login.test.ts`
- Test: `journally-api/tests/auth/refresh.test.ts`
- Test: `journally-api/tests/auth/logout.test.ts`

**Interfaces:**
- Consumes: `signup`/`login`/`refresh`/`logout`/`logoutAll`/`AuthError` (Tasks 6-7), `requireAuth` (Task 8), the four schemas (Task 5)
- Produces: `authRouter` mounted at `/auth`; `tests/helpers/testAuth.ts` exports `createTestUser(email?)` and `authedRequest(app)` used by every later scoping task's tests.

- [ ] **Step 1: Write `auth.routes.ts`**

```ts
import { Router } from 'express';
import { asyncHandler } from '../middleware/asyncHandler';
import { requireAuth } from '../middleware/requireAuth';
import { loginSchema, logoutSchema, refreshSchema, signupSchema } from './auth.schema';
import { AuthError, login, logout, logoutAll, refresh, signup } from './auth.service';

export const authRouter = Router();

authRouter.post(
  '/signup',
  asyncHandler(async (req, res) => {
    const parsed = signupSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid signup', details: parsed.error.issues });
      return;
    }
    try {
      const result = await signup(parsed.data);
      res.status(201).json(result);
    } catch (err) {
      if (err instanceof AuthError) {
        res.status(409).json({ error: err.message, code: err.code });
        return;
      }
      throw err;
    }
  })
);

authRouter.post(
  '/login',
  asyncHandler(async (req, res) => {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid login', details: parsed.error.issues });
      return;
    }
    try {
      const result = await login(parsed.data);
      res.json(result);
    } catch (err) {
      if (err instanceof AuthError) {
        res.status(401).json({ error: err.message, code: err.code });
        return;
      }
      throw err;
    }
  })
);

authRouter.post(
  '/refresh',
  asyncHandler(async (req, res) => {
    const parsed = refreshSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid refresh request', details: parsed.error.issues });
      return;
    }
    try {
      const result = await refresh(parsed.data.refreshToken);
      res.json(result);
    } catch (err) {
      if (err instanceof AuthError) {
        res.status(401).json({ error: err.message, code: err.code });
        return;
      }
      throw err;
    }
  })
);

authRouter.post(
  '/logout',
  asyncHandler(async (req, res) => {
    const parsed = logoutSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid logout request', details: parsed.error.issues });
      return;
    }
    await logout(parsed.data.refreshToken);
    res.status(204).send();
  })
);

authRouter.post(
  '/logout-all',
  requireAuth,
  asyncHandler(async (req, res) => {
    await logoutAll(req.userId!);
    res.status(204).send();
  })
);
```

- [ ] **Step 2: Mount it in `app.ts`**

```ts
import cors from 'cors';
import express from 'express';
import { authRouter } from './auth/auth.routes';
import { entriesRouter } from './entries/entries.routes';
import { feedingsRouter } from './feedings/feedings.routes';
import { errorHandler } from './middleware/errorHandler';
import { photosRouter } from './photos/photos.routes';
import { sightingPhotosRouter } from './sighting-photos/sightingPhotos.routes';
import { sightingsRouter } from './sightings/sightings.routes';
import { uploadsDir } from './uploads';

export const app = express();

app.use(cors());
app.use(express.json());

app.use('/auth', authRouter);

app.use('/entries/:entryId/photos', photosRouter);
app.use('/entries', entriesRouter);
app.use('/sightings/:sightingId/photos', sightingPhotosRouter);
app.use('/sightings/:sightingId/feedings', feedingsRouter);
app.use('/sightings', sightingsRouter);
app.use('/uploads', express.static(uploadsDir));

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.use(errorHandler);
```

(Only the `import { authRouter }` line and the `app.use('/auth', authRouter);` line are new — `requireAuth` isn't added to the other routers yet, that happens per-module in Tasks 10-14.)

- [ ] **Step 3: Write the shared test helper**

```ts
import request from 'supertest';
import type { Express } from 'express';
import { prisma } from '../../src/db';
import { hashPassword } from '../../src/auth/password';
import { signAccessToken } from '../../src/auth/tokens';

let currentToken: string | undefined;

export async function createTestUser(email?: string) {
  const user = await prisma.user.create({
    data: {
      email: email ?? `test-${Date.now()}-${Math.random().toString(36).slice(2)}@example.com`,
      passwordHash: await hashPassword('Password123!'),
    },
  });
  const accessToken = signAccessToken({ userId: user.id });
  currentToken = accessToken;
  return { user, accessToken };
}

export function authHeader(token: string = currentToken!) {
  return { Authorization: `Bearer ${token}` };
}

/**
 * Drop-in replacement for supertest's `request(app)` that auto-attaches the
 * most recently created test user's token (see `createTestUser`). Tests
 * that need a specific *other* token, or no token at all, use plain
 * `supertest`'s `request(app)` and `.set()`/omit the header themselves.
 */
export function authedRequest(app: Express) {
  const agent = request(app);
  const withAuth = (test: request.Test) => test.set(authHeader());
  return {
    get: (url: string) => withAuth(agent.get(url)),
    post: (url: string) => withAuth(agent.post(url)),
    patch: (url: string) => withAuth(agent.patch(url)),
    delete: (url: string) => withAuth(agent.delete(url)),
  };
}
```

- [ ] **Step 4: Write `tests/auth/signup.test.ts`**

```ts
import request from 'supertest';
import { describe, it, expect } from 'vitest';
import { app } from '../../src/app';

describe('POST /auth/signup', () => {
  it('creates a user and returns a token pair', async () => {
    const res = await request(app)
      .post('/auth/signup')
      .send({ email: 'new@example.com', password: 'Password123!' });

    expect(res.status).toBe(201);
    expect(res.body.user).toMatchObject({ email: 'new@example.com' });
    expect(res.body.user.id).toEqual(expect.any(String));
    expect(res.body.accessToken).toEqual(expect.any(String));
    expect(res.body.refreshToken).toEqual(expect.any(String));
  });

  it('rejects a duplicate email', async () => {
    await request(app)
      .post('/auth/signup')
      .send({ email: 'dupe@example.com', password: 'Password123!' });

    const res = await request(app)
      .post('/auth/signup')
      .send({ email: 'dupe@example.com', password: 'Password123!' });

    expect(res.status).toBe(409);
    expect(res.body.code).toBe('email_taken');
  });

  it('rejects a short password', async () => {
    const res = await request(app)
      .post('/auth/signup')
      .send({ email: 'short@example.com', password: 'short' });

    expect(res.status).toBe(400);
  });

  it('rejects an invalid email', async () => {
    const res = await request(app)
      .post('/auth/signup')
      .send({ email: 'not-an-email', password: 'Password123!' });

    expect(res.status).toBe(400);
  });
});
```

- [ ] **Step 5: Write `tests/auth/login.test.ts`**

```ts
import request from 'supertest';
import { describe, it, expect } from 'vitest';
import { app } from '../../src/app';

async function signup(email: string, password = 'Password123!') {
  return request(app).post('/auth/signup').send({ email, password });
}

describe('POST /auth/login', () => {
  it('logs in with correct credentials', async () => {
    await signup('login@example.com');

    const res = await request(app)
      .post('/auth/login')
      .send({ email: 'login@example.com', password: 'Password123!' });

    expect(res.status).toBe(200);
    expect(res.body.user.email).toBe('login@example.com');
    expect(res.body.accessToken).toEqual(expect.any(String));
    expect(res.body.refreshToken).toEqual(expect.any(String));
  });

  it('rejects a wrong password', async () => {
    await signup('wrongpw@example.com');

    const res = await request(app)
      .post('/auth/login')
      .send({ email: 'wrongpw@example.com', password: 'WrongPassword1' });

    expect(res.status).toBe(401);
    expect(res.body.code).toBe('invalid_credentials');
  });

  it('rejects an unknown email', async () => {
    const res = await request(app)
      .post('/auth/login')
      .send({ email: 'nobody@example.com', password: 'Password123!' });

    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 6: Write `tests/auth/refresh.test.ts`**

```ts
import request from 'supertest';
import { describe, it, expect } from 'vitest';
import { app } from '../../src/app';

async function signup(email: string) {
  const res = await request(app)
    .post('/auth/signup')
    .send({ email, password: 'Password123!' });
  return res.body as { accessToken: string; refreshToken: string };
}

describe('POST /auth/refresh', () => {
  it('rotates the refresh token and returns a new access token', async () => {
    const { refreshToken } = await signup('refresh@example.com');

    const res = await request(app).post('/auth/refresh').send({ refreshToken });

    expect(res.status).toBe(200);
    expect(res.body.accessToken).toEqual(expect.any(String));
    expect(res.body.refreshToken).toEqual(expect.any(String));
    expect(res.body.refreshToken).not.toBe(refreshToken);
  });

  it('accepts the newly rotated token for a second refresh', async () => {
    const { refreshToken } = await signup('rotate-twice@example.com');
    const first = await request(app).post('/auth/refresh').send({ refreshToken });

    const second = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: first.body.refreshToken });

    expect(second.status).toBe(200);
  });

  it('rejects an unknown refresh token', async () => {
    const res = await request(app).post('/auth/refresh').send({ refreshToken: 'not-a-real-token' });

    expect(res.status).toBe(401);
    expect(res.body.code).toBe('refresh_token_invalid');
  });

  it('detects reuse of an already-rotated token and revokes the session', async () => {
    const { refreshToken } = await signup('reuse@example.com');
    await request(app).post('/auth/refresh').send({ refreshToken });

    // Replaying the original (now-rotated) token is theft-shaped.
    const replay = await request(app).post('/auth/refresh').send({ refreshToken });
    expect(replay.status).toBe(401);
    expect(replay.body.code).toBe('refresh_token_reused');

    // The rotated-in token from the first call is also dead now.
    const firstRefresh = await request(app).post('/auth/refresh').send({ refreshToken });
    expect(firstRefresh.status).toBe(401);
  });
});
```

- [ ] **Step 7: Write `tests/auth/logout.test.ts`**

```ts
import request from 'supertest';
import { describe, it, expect } from 'vitest';
import { app } from '../../src/app';

async function signup(email: string) {
  const res = await request(app)
    .post('/auth/signup')
    .send({ email, password: 'Password123!' });
  return res.body as { accessToken: string; refreshToken: string };
}

describe('POST /auth/logout', () => {
  it('revokes the given refresh token', async () => {
    const { refreshToken } = await signup('logout@example.com');

    const logoutRes = await request(app).post('/auth/logout').send({ refreshToken });
    expect(logoutRes.status).toBe(204);

    const refreshRes = await request(app).post('/auth/refresh').send({ refreshToken });
    expect(refreshRes.status).toBe(401);
  });
});

describe('POST /auth/logout-all', () => {
  it('revokes every refresh token for the user', async () => {
    const { accessToken, refreshToken: firstToken } = await signup('logout-all@example.com');
    const secondLogin = await request(app)
      .post('/auth/login')
      .send({ email: 'logout-all@example.com', password: 'Password123!' });

    const logoutAllRes = await request(app)
      .post('/auth/logout-all')
      .set('Authorization', `Bearer ${accessToken}`);
    expect(logoutAllRes.status).toBe(204);

    const firstRefresh = await request(app).post('/auth/refresh').send({ refreshToken: firstToken });
    expect(firstRefresh.status).toBe(401);

    const secondRefresh = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: secondLogin.body.refreshToken });
    expect(secondRefresh.status).toBe(401);
  });

  it('requires a valid access token', async () => {
    const res = await request(app).post('/auth/logout-all');
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 8: Make `authedRequest` usable by default — auto-create a test user in `tests/setup.ts`**

`authedRequest` reads a module-level `currentToken` that only `createTestUser()` sets. Without a user created before *every* test, `authedRequest` would send `Authorization: Bearer undefined`. Add a second `beforeEach` to `tests/setup.ts`, after the existing cleanup one, so every test starts with a fresh authenticated user by default — tests that need a *second* user (ownership checks) call `createTestUser()` again mid-test to switch the current token:

```ts
import path from 'node:path';
import fs from 'node:fs/promises';
import { beforeEach, afterEach } from 'vitest';
import { prisma } from '../src/db';
import { uploadsDir } from '../src/uploads';
import { createTestUser } from './helpers/testAuth';

beforeEach(async () => {
  await prisma.photo.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.entryAttribute.deleteMany();
  await prisma.sightingPhoto.deleteMany();
  await prisma.feedingLogEntry.deleteMany();
  await prisma.sighting.deleteMany();
  await prisma.journalEntry.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.user.deleteMany();
});

beforeEach(async () => {
  await createTestUser();
});

afterEach(async () => {
  const files = await fs.readdir(uploadsDir).catch(() => [] as string[]);
  await Promise.all(files.map((file) => fs.unlink(path.join(uploadsDir, file))));
});
```

This creates a circular-looking but safe dependency (`setup.ts` imports the helper that itself imports `src/db` and `src/auth/*`, none of which import `setup.ts`) — no actual cycle.

- [ ] **Step 9: Run the new tests**

Run: `cd journally-api && npx vitest run tests/auth`
Expected: PASS (all new auth tests). The pre-existing `entries.*`/`sightings.*`/etc. tests are still red until Tasks 10-14 (they call plain `request(app)` with no auth header at all, against routes that don't require one yet — those still pass as-is; they only start needing `authedRequest` once `requireAuth` is applied to their router in each task below).

- [ ] **Step 10: Commit**

```bash
git add src/auth/auth.routes.ts src/app.ts tests/setup.ts tests/helpers tests/auth
git commit -m "feat: add auth routes (signup/login/refresh/logout/logout-all)"
```

---

### Task 10: Scope entries to the authenticated user

**Files:**
- Modify: `journally-api/src/entries/entries.service.ts`
- Modify: `journally-api/src/entries/entries.routes.ts`
- Modify: `journally-api/src/app.ts:16`
- Modify (rename `request` → `authedRequest`, per Step 3 below): `tests/entries.create.test.ts`, `tests/entries.attributes.test.ts`, `tests/entries.delete.test.ts`, `tests/entries.list-get.test.ts`, `tests/entries.nearby.test.ts`, `tests/entries.update.test.ts`

**Interfaces:**
- Consumes: `requireAuth` (Task 8), `authedRequest`/`createTestUser` (Task 9)
- Produces: every `entries.service.ts` export now takes `userId` as its first argument.

- [ ] **Step 1: Rewrite `entries.service.ts` to take and filter by `userId`**

```ts
import fs from 'node:fs/promises';
import path from 'node:path';
import { prisma } from '../db';
import { boundingBoxDeltas, haversineKm } from '../shared/geo';
import { uploadsDir } from '../uploads';
import type { CreateEntryInput, NearbyEntryQuery, UpdateEntryInput } from './entries.schema';

function shapeEntry(entry: {
  id: string;
  placeName: string;
  neighborhood: string;
  city: string;
  visitedAt: Date;
  createdAt: Date;
  updatedAt: Date;
  lat: number | null;
  lng: number | null;
  placeId: string | null;
  notes: string | null;
  rating: number | null;
  orderItems: { name: string; price: number | null; note: string | null }[];
  photos: { filePath: string }[];
  attributes: { name: string }[];
}) {
  return {
    id: entry.id,
    placeName: entry.placeName,
    neighborhood: entry.neighborhood,
    city: entry.city,
    visitedAt: entry.visitedAt,
    createdAt: entry.createdAt,
    updatedAt: entry.updatedAt,
    lat: entry.lat,
    lng: entry.lng,
    placeId: entry.placeId,
    notes: entry.notes,
    rating: entry.rating,
    orderItems: entry.orderItems.map((item) => ({
      name: item.name,
      price: item.price,
      note: item.note,
    })),
    photoUrls: entry.photos.map((photo) => `/uploads/${photo.filePath}`),
    photoCount: entry.photos.length,
    attributes: entry.attributes.map((attribute) => attribute.name),
  };
}

export async function createEntry(userId: string, input: CreateEntryInput) {
  const entry = await prisma.journalEntry.create({
    data: {
      userId,
      placeName: input.placeName,
      neighborhood: input.neighborhood,
      city: input.city,
      ...(input.visitedAt ? { visitedAt: input.visitedAt } : {}),
      ...(input.lat !== undefined ? { lat: input.lat } : {}),
      ...(input.lng !== undefined ? { lng: input.lng } : {}),
      ...(input.placeId !== undefined ? { placeId: input.placeId } : {}),
      ...(input.notes !== undefined ? { notes: input.notes } : {}),
      ...(input.rating !== undefined ? { rating: input.rating } : {}),
      orderItems: {
        create: input.orderItems.map((item) => ({
          name: item.name,
          price: item.price,
          note: item.note,
        })),
      },
      attributes: {
        create: input.attributes.map((name) => ({ name })),
      },
    },
    include: { orderItems: true, photos: true, attributes: true },
  });

  return shapeEntry(entry);
}

export async function listEntries(userId: string) {
  const entries = await prisma.journalEntry.findMany({
    where: { userId },
    include: { orderItems: true, photos: true, attributes: true },
    orderBy: { visitedAt: 'desc' },
  });
  return entries.map(shapeEntry);
}

export async function getEntryById(userId: string, id: string) {
  const entry = await prisma.journalEntry.findFirst({
    where: { id, userId },
    include: { orderItems: true, photos: true, attributes: true },
  });
  return entry ? shapeEntry(entry) : null;
}

export async function updateEntry(userId: string, id: string, input: UpdateEntryInput) {
  const existing = await prisma.journalEntry.findFirst({ where: { id, userId } });
  if (!existing) return null;

  const entry = await prisma.journalEntry.update({
    where: { id },
    data: {
      ...(input.placeName !== undefined ? { placeName: input.placeName } : {}),
      ...(input.neighborhood !== undefined ? { neighborhood: input.neighborhood } : {}),
      ...(input.city !== undefined ? { city: input.city } : {}),
      ...(input.visitedAt !== undefined ? { visitedAt: input.visitedAt } : {}),
      ...(input.lat !== undefined ? { lat: input.lat } : {}),
      ...(input.lng !== undefined ? { lng: input.lng } : {}),
      ...(input.placeId !== undefined ? { placeId: input.placeId } : {}),
      ...(input.notes !== undefined ? { notes: input.notes } : {}),
      ...(input.rating !== undefined ? { rating: input.rating } : {}),
      ...(input.orderItems !== undefined
        ? {
            orderItems: {
              deleteMany: {},
              create: input.orderItems.map((item) => ({
                name: item.name,
                price: item.price,
                note: item.note,
              })),
            },
          }
        : {}),
      ...(input.attributes !== undefined
        ? {
            attributes: {
              deleteMany: {},
              create: input.attributes.map((name) => ({ name })),
            },
          }
        : {}),
    },
    include: { orderItems: true, photos: true, attributes: true },
  });

  return shapeEntry(entry);
}

export async function listNearbyEntries(userId: string, query: NearbyEntryQuery) {
  const { lat, lng, radiusKm } = query;
  const { latDelta, lngDelta } = boundingBoxDeltas(radiusKm, lat);

  const entries = await prisma.journalEntry.findMany({
    where: {
      userId,
      lat: { gte: lat - latDelta, lte: lat + latDelta },
      lng: { gte: lng - lngDelta, lte: lng + lngDelta },
    },
    include: { orderItems: true, photos: true, attributes: true },
  });

  return entries
    .map((entry) => ({
      ...shapeEntry(entry),
      distanceKm: haversineKm(lat, lng, entry.lat as number, entry.lng as number),
    }))
    .filter((entry) => entry.distanceKm <= radiusKm)
    .sort((a, b) => a.distanceKm - b.distanceKm);
}

export async function deleteEntry(userId: string, id: string) {
  const existing = await prisma.journalEntry.findFirst({
    where: { id, userId },
    include: { photos: true },
  });
  if (!existing) return false;

  await prisma.journalEntry.delete({ where: { id } });

  await Promise.all(
    existing.photos.map(async (photo) => {
      try {
        await fs.unlink(path.join(uploadsDir, photo.filePath));
      } catch (err) {
        console.warn(`Failed to remove photo file ${photo.filePath}`, err);
      }
    })
  );

  return true;
}
```

- [ ] **Step 2: Update `entries.routes.ts` to pass `req.userId!` into every service call**

Same structure as before, each handler's service call gains `req.userId!` as the first argument:

```ts
entriesRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const entries = await listEntries(req.userId!);
    res.json(entries);
  })
);
```
```ts
entriesRouter.get(
  '/nearby',
  asyncHandler(async (req, res) => {
    const parsed = nearbyEntryQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query', details: parsed.error.issues });
      return;
    }

    const entries = await listNearbyEntries(req.userId!, parsed.data);
    res.json(entries);
  })
);
```
```ts
entriesRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const entry = await getEntryById(req.userId!, req.params.id);
    if (!entry) {
      res.status(404).json({ error: 'Entry not found' });
      return;
    }
    res.json(entry);
  })
);
```
```ts
entriesRouter.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const deleted = await deleteEntry(req.userId!, req.params.id);
    if (!deleted) {
      res.status(404).json({ error: 'Entry not found' });
      return;
    }
    res.status(204).send();
  })
);
```
```ts
entriesRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const parsed = createEntrySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid entry', details: parsed.error.issues });
      return;
    }

    const entry = await createEntry(req.userId!, parsed.data);
    res.status(201).json(entry);
  })
);
```
```ts
entriesRouter.patch(
  '/:id',
  asyncHandler(async (req, res) => {
    const parsed = updateEntrySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid entry', details: parsed.error.issues });
      return;
    }

    const entry = await updateEntry(req.userId!, req.params.id, parsed.data);
    if (!entry) {
      res.status(404).json({ error: 'Entry not found' });
      return;
    }
    res.json(entry);
  })
);
```

- [ ] **Step 3: Apply `requireAuth` to the entries router in `app.ts`**

```ts
import { requireAuth } from './middleware/requireAuth';
// ...
app.use('/entries', requireAuth, entriesRouter);
```

(Leave the `/entries/:entryId/photos` line as-is — that's Task 12.)

- [ ] **Step 4: Update the six entries test files**

In each of `tests/entries.create.test.ts`, `tests/entries.attributes.test.ts`, `tests/entries.delete.test.ts`, `tests/entries.list-get.test.ts`, `tests/entries.nearby.test.ts`, `tests/entries.update.test.ts`:

1. Replace `import request from 'supertest';` with `import { authedRequest } from './helpers/testAuth';`
2. Replace every call site `request(app)` with `authedRequest(app)` (mechanical — every occurrence in each file).

`entries.delete.test.ts` and any file also using `prisma` directly keep their `import { prisma } from '../src/db';` line unchanged.

- [ ] **Step 5: Add ownership and auth tests to `entries.list-get.test.ts`**

Append these two `describe` blocks:

```ts
describe('GET /entries — auth', () => {
  it('rejects a request with no token', async () => {
    const res = await request(app).get('/entries');
    expect(res.status).toBe(401);
  });
});

describe('GET /entries/:id — ownership', () => {
  it("returns 404 for another user's entry", async () => {
    // The global beforeEach (tests/setup.ts) already created a user and
    // pointed authedRequest at their token — they're the owner here.
    const created = await authedRequest(app).post('/entries').send({
      placeName: 'Owner Only Cafe',
      neighborhood: 'Hayes Valley',
      city: 'San Francisco',
      orderItems: [],
    });

    await createTestUser(); // switches the module-level "current" token to a second user
    const res = await authedRequest(app).get(`/entries/${created.body.id}`);

    expect(res.status).toBe(404);
  });
});
```

Add the two needed imports at the top of the file:

```ts
import request from 'supertest';
import { app } from '../src/app';
import { authedRequest, createTestUser } from './helpers/testAuth';
```

- [ ] **Step 6: Run the entries tests**

Run: `cd journally-api && npx vitest run tests/entries.create.test.ts tests/entries.attributes.test.ts tests/entries.delete.test.ts tests/entries.list-get.test.ts tests/entries.nearby.test.ts tests/entries.update.test.ts`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/entries src/app.ts tests/entries.*.test.ts
git commit -m "feat: scope entries to the authenticated user"
```

---

### Task 11: Scope sightings to the authenticated user

**Files:**
- Modify: `journally-api/src/sightings/sightings.service.ts`
- Modify: `journally-api/src/sightings/sightings.routes.ts`
- Modify: `journally-api/src/app.ts:19`
- Modify (rename `request` → `authedRequest`): `tests/sightings.create.test.ts`, `tests/sightings.delete.test.ts`, `tests/sightings.list-get.test.ts`, `tests/sightings.nearby.test.ts`, `tests/sightings.update.test.ts`

**Interfaces:**
- Same pattern as Task 10, mirrored onto `Sighting`.

- [ ] **Step 1: Rewrite `sightings.service.ts`**

```ts
import fs from 'node:fs/promises';
import path from 'node:path';
import { prisma } from '../db';
import { boundingBoxDeltas, haversineKm } from '../shared/geo';
import { uploadsDir } from '../uploads';
import type {
  CreateSightingInput,
  NearbySightingQuery,
  UpdateSightingInput,
} from './sightings.schema';

function shapeSighting(sighting: {
  id: string;
  species: string;
  lat: number;
  lng: number;
  notes: string | null;
  fed: boolean;
  fedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  photos: { filePath: string }[];
  attributes: { name: string }[];
}) {
  return {
    id: sighting.id,
    species: sighting.species,
    lat: sighting.lat,
    lng: sighting.lng,
    notes: sighting.notes,
    fed: sighting.fed,
    fedAt: sighting.fedAt,
    createdAt: sighting.createdAt,
    updatedAt: sighting.updatedAt,
    photoUrls: sighting.photos.map((photo) => `/uploads/${photo.filePath}`),
    attributes: sighting.attributes.map((attribute) => attribute.name),
  };
}

export async function createSighting(userId: string, input: CreateSightingInput) {
  const sighting = await prisma.sighting.create({
    data: {
      userId,
      species: input.species,
      lat: input.lat,
      lng: input.lng,
      ...(input.notes !== undefined ? { notes: input.notes } : {}),
      attributes: {
        create: input.attributes.map((name) => ({ name })),
      },
    },
    include: { photos: true, attributes: true },
  });

  return shapeSighting(sighting);
}

export async function listSightings(userId: string) {
  const sightings = await prisma.sighting.findMany({
    where: { userId },
    include: { photos: true, attributes: true },
    orderBy: { createdAt: 'desc' },
  });
  return sightings.map(shapeSighting);
}

export async function getSightingById(userId: string, id: string) {
  const sighting = await prisma.sighting.findFirst({
    where: { id, userId },
    include: { photos: true, attributes: true },
  });
  return sighting ? shapeSighting(sighting) : null;
}

export async function updateSighting(userId: string, id: string, input: UpdateSightingInput) {
  const existing = await prisma.sighting.findFirst({ where: { id, userId } });
  if (!existing) return null;

  const sighting = await prisma.sighting.update({
    where: { id },
    data: {
      ...(input.species !== undefined ? { species: input.species } : {}),
      ...(input.lat !== undefined ? { lat: input.lat } : {}),
      ...(input.lng !== undefined ? { lng: input.lng } : {}),
      ...(input.notes !== undefined ? { notes: input.notes } : {}),
      ...(input.fed !== undefined
        ? { fed: input.fed, fedAt: input.fed ? new Date() : null }
        : {}),
      ...(input.attributes !== undefined
        ? {
            attributes: {
              deleteMany: {},
              create: input.attributes.map((name) => ({ name })),
            },
          }
        : {}),
    },
    include: { photos: true, attributes: true },
  });

  return shapeSighting(sighting);
}

export async function deleteSighting(userId: string, id: string) {
  const existing = await prisma.sighting.findFirst({
    where: { id, userId },
    include: { photos: true },
  });
  if (!existing) return false;

  await prisma.sighting.delete({ where: { id } });

  await Promise.all(
    existing.photos.map(async (photo) => {
      try {
        await fs.unlink(path.join(uploadsDir, photo.filePath));
      } catch (err) {
        console.warn(`Failed to remove photo file ${photo.filePath}`, err);
      }
    })
  );

  return true;
}

export async function listNearbySightings(userId: string, query: NearbySightingQuery) {
  const { lat, lng, radiusKm, species } = query;
  const { latDelta, lngDelta } = boundingBoxDeltas(radiusKm, lat);

  const sightings = await prisma.sighting.findMany({
    where: {
      userId,
      lat: { gte: lat - latDelta, lte: lat + latDelta },
      lng: { gte: lng - lngDelta, lte: lng + lngDelta },
      ...(species !== undefined ? { species } : {}),
    },
    include: { photos: true, attributes: true },
  });

  return sightings
    .map((sighting) => ({
      ...shapeSighting(sighting),
      distanceKm: haversineKm(lat, lng, sighting.lat, sighting.lng),
    }))
    .filter((sighting) => sighting.distanceKm <= radiusKm)
    .sort((a, b) => a.distanceKm - b.distanceKm);
}
```

- [ ] **Step 2: Update `sightings.routes.ts`**

Same mechanical change as Task 10 Step 2 — every handler passes `req.userId!` as the first argument to its service call (`listSightings(req.userId!)`, `listNearbySightings(req.userId!, parsed.data)`, `getSightingById(req.userId!, req.params.id)`, `createSighting(req.userId!, parsed.data)`, `updateSighting(req.userId!, req.params.id, parsed.data)`, `deleteSighting(req.userId!, req.params.id)`), file structure otherwise unchanged.

- [ ] **Step 3: Apply `requireAuth` in `app.ts`**

```ts
app.use('/sightings', requireAuth, sightingsRouter);
```

(Leave the `/sightings/:sightingId/photos` and `/sightings/:sightingId/feedings` lines — Tasks 13 and 14.)

- [ ] **Step 4: Update the five sightings test files**

Same mechanical edit as Task 10 Step 4, applied to `tests/sightings.create.test.ts`, `tests/sightings.delete.test.ts`, `tests/sightings.list-get.test.ts`, `tests/sightings.nearby.test.ts`, `tests/sightings.update.test.ts`.

- [ ] **Step 5: Add ownership and auth tests to `sightings.list-get.test.ts`**

Append, mirroring Task 10 Step 5:

```ts
describe('GET /sightings — auth', () => {
  it('rejects a request with no token', async () => {
    const res = await request(app).get('/sightings');
    expect(res.status).toBe(401);
  });
});

describe('GET /sightings/:id — ownership', () => {
  it("returns 404 for another user's sighting", async () => {
    const created = await authedRequest(app)
      .post('/sightings')
      .send({ species: 'cat', lat: 0, lng: 0 });

    await createTestUser();
    const res = await authedRequest(app).get(`/sightings/${created.body.id}`);

    expect(res.status).toBe(404);
  });
});
```

With imports:

```ts
import request from 'supertest';
import { app } from '../src/app';
import { authedRequest, createTestUser } from './helpers/testAuth';
```

- [ ] **Step 6: Run the sightings tests**

Run: `cd journally-api && npx vitest run tests/sightings.create.test.ts tests/sightings.delete.test.ts tests/sightings.list-get.test.ts tests/sightings.nearby.test.ts tests/sightings.update.test.ts`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/sightings src/app.ts tests/sightings.*.test.ts
git commit -m "feat: scope sightings to the authenticated user"
```

---

### Task 12: Scope photos (nested under entries) to the authenticated user

**Files:**
- Modify: `journally-api/src/photos/photos.service.ts`
- Modify: `journally-api/src/photos/photos.routes.ts`
- Modify: `journally-api/src/app.ts:15`
- Modify (rename `request` → `authedRequest`): `tests/photos.delete.test.ts`, `tests/photos.upload.test.ts`

**Interfaces:**
- Produces: `addPhoto(userId, entryId, filePath)`, `deletePhoto(userId, entryId, photoId)` — ownership proven via the parent `JournalEntry.userId`.

- [ ] **Step 1: Update `photos.service.ts`**

```ts
export async function addPhoto(userId: string, entryId: string, filePath: string) {
  const entry = await prisma.journalEntry.findFirst({ where: { id: entryId, userId } });
  if (!entry) return null;

  const photo = await prisma.photo.create({
    data: { entryId, filePath },
  });

  return { id: photo.id, url: `/uploads/${photo.filePath}` };
}

export async function deletePhoto(userId: string, entryId: string, photoId: string) {
  const photo = await prisma.photo.findFirst({
    where: { id: photoId, entryId, entry: { userId } },
  });
  if (!photo) return false;

  await prisma.photo.delete({ where: { id: photo.id } });

  try {
    await unlink(path.join(uploadsDir, photo.filePath));
  } catch (err) {
    console.warn(`Failed to remove photo file ${photo.filePath}`, err);
  }

  return true;
}
```

(Everything above `addPhoto` — imports, multer setup — is unchanged.)

- [ ] **Step 2: Update `photos.routes.ts`**

Both handlers pass `req.userId!` as the first argument:

```ts
const photo = await addPhoto(req.userId!, req.params.entryId, req.file.filename);
```
```ts
const deleted = await deletePhoto(req.userId!, req.params.entryId, req.params.photoId);
```

- [ ] **Step 3: Apply `requireAuth` in `app.ts`**

```ts
app.use('/entries/:entryId/photos', requireAuth, photosRouter);
```

- [ ] **Step 4: Update the two photos test files**

Same mechanical edit: swap the `supertest` import for `import { authedRequest } from './helpers/testAuth';` and replace `request(app)` → `authedRequest(app)` at every call site in `tests/photos.delete.test.ts` and `tests/photos.upload.test.ts`.

Note: the `.get(photo.url)` calls against `/uploads/...` can stay as `authedRequest(app).get(...)` too — `/uploads` doesn't require auth, an extra header is harmless there.

- [ ] **Step 5: Add an ownership test to `photos.upload.test.ts`**

Append:

```ts
describe('POST /entries/:entryId/photos — ownership', () => {
  it("returns 404 uploading to another user's entry", async () => {
    const entry = await createEntry();
    await createTestUser();

    const res = await authedRequest(app)
      .post(`/entries/${entry.id}/photos`)
      .attach('photo', Buffer.from([0xff, 0xd8, 0xff, 0xd9]), {
        filename: 'cafe.jpg',
        contentType: 'image/jpeg',
      });

    expect(res.status).toBe(404);
  });
});
```

Add `createTestUser` to the existing `import { authedRequest, createTestUser } from './helpers/testAuth';` line, and change the local `createEntry` helper's `request(app)` call to `authedRequest(app)` too (it already will be, from Step 4).

- [ ] **Step 6: Run the photos tests**

Run: `cd journally-api && npx vitest run tests/photos.delete.test.ts tests/photos.upload.test.ts`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/photos src/app.ts tests/photos.*.test.ts
git commit -m "feat: scope photos to the authenticated user via entry ownership"
```

---

### Task 13: Scope sighting-photos (nested under sightings) to the authenticated user

**Files:**
- Modify: `journally-api/src/sighting-photos/sightingPhotos.service.ts`
- Modify: `journally-api/src/sighting-photos/sightingPhotos.routes.ts`
- Modify: `journally-api/src/app.ts:17`
- Modify (rename `request` → `authedRequest`): `tests/sightingPhotos.delete.test.ts`, `tests/sightingPhotos.upload.test.ts`

**Interfaces:**
- Produces: `addSightingPhoto(userId, sightingId, filePath)`, `deleteSightingPhoto(userId, sightingId, photoId)` — ownership via `Sighting.userId`.

- [ ] **Step 1: Update `sightingPhotos.service.ts`**

```ts
import { unlink } from 'node:fs/promises';
import path from 'node:path';
import { prisma } from '../db';
import { uploadsDir } from '../uploads';

export { upload } from '../photos/photos.service';

export async function addSightingPhoto(userId: string, sightingId: string, filePath: string) {
  const sighting = await prisma.sighting.findFirst({ where: { id: sightingId, userId } });
  if (!sighting) return null;

  const photo = await prisma.sightingPhoto.create({
    data: { sightingId, filePath },
  });

  return { id: photo.id, url: `/uploads/${photo.filePath}` };
}

export async function deleteSightingPhoto(userId: string, sightingId: string, photoId: string) {
  const photo = await prisma.sightingPhoto.findFirst({
    where: { id: photoId, sightingId, sighting: { userId } },
  });
  if (!photo) return false;

  await prisma.sightingPhoto.delete({ where: { id: photo.id } });

  try {
    await unlink(path.join(uploadsDir, photo.filePath));
  } catch (err) {
    console.warn(`Failed to remove photo file ${photo.filePath}`, err);
  }

  return true;
}
```

- [ ] **Step 2: Update `sightingPhotos.routes.ts`**

```ts
const photo = await addSightingPhoto(req.userId!, req.params.sightingId, req.file.filename);
```
```ts
const deleted = await deleteSightingPhoto(req.userId!, req.params.sightingId, req.params.photoId);
```

- [ ] **Step 3: Apply `requireAuth` in `app.ts`**

```ts
app.use('/sightings/:sightingId/photos', requireAuth, sightingPhotosRouter);
```

- [ ] **Step 4: Update the two sighting-photos test files**

Same mechanical edit as before, applied to `tests/sightingPhotos.delete.test.ts` and `tests/sightingPhotos.upload.test.ts`.

- [ ] **Step 5: Add an ownership test to `sightingPhotos.upload.test.ts`**

Append:

```ts
describe('POST /sightings/:sightingId/photos — ownership', () => {
  it("returns 404 uploading to another user's sighting", async () => {
    const sighting = await createSighting();
    await createTestUser();

    const res = await authedRequest(app)
      .post(`/sightings/${sighting.id}/photos`)
      .attach('photo', Buffer.from([0xff, 0xd8, 0xff, 0xd9]), {
        filename: 'stray.jpg',
        contentType: 'image/jpeg',
      });

    expect(res.status).toBe(404);
  });
});
```

Add the `import { authedRequest, createTestUser } from './helpers/testAuth';` line (replacing the plain `supertest` import) at the top of the file.

- [ ] **Step 6: Run the sighting-photos tests**

Run: `cd journally-api && npx vitest run tests/sightingPhotos.delete.test.ts tests/sightingPhotos.upload.test.ts`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/sighting-photos src/app.ts tests/sightingPhotos.*.test.ts
git commit -m "feat: scope sighting photos to the authenticated user via sighting ownership"
```

---

### Task 14: Scope feedings (nested under sightings) to the authenticated user

**Files:**
- Modify: `journally-api/src/feedings/feedings.service.ts`
- Modify: `journally-api/src/feedings/feedings.routes.ts`
- Modify: `journally-api/src/app.ts:18`
- Modify (rename `request` → `authedRequest`): `tests/feedings.create.test.ts`, `tests/feedings.list.test.ts`

**Interfaces:**
- Produces: `createFeedingLogEntry(userId, sightingId, input)`, `listFeedingLog(userId, sightingId)` — ownership via `Sighting.userId`.

- [ ] **Step 1: Update `feedings.service.ts`**

```ts
import { prisma } from '../db';
import type { CreateFeedingLogEntryInput } from './feedings.schema';

function shapeFeedingLogEntry(entry: {
  id: string;
  note: string | null;
  sightingId: string;
  createdAt: Date;
}) {
  return {
    id: entry.id,
    note: entry.note,
    sightingId: entry.sightingId,
    createdAt: entry.createdAt,
  };
}

function startOfToday() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

async function purgeStaleEntries(sightingId: string) {
  await prisma.feedingLogEntry.deleteMany({
    where: { sightingId, createdAt: { lt: startOfToday() } },
  });
}

export async function createFeedingLogEntry(
  userId: string,
  sightingId: string,
  input: CreateFeedingLogEntryInput
) {
  const sighting = await prisma.sighting.findFirst({ where: { id: sightingId, userId } });
  if (!sighting) return null;

  await purgeStaleEntries(sightingId);

  const entry = await prisma.feedingLogEntry.create({
    data: {
      sightingId,
      ...(input.note !== undefined ? { note: input.note } : {}),
    },
  });

  return shapeFeedingLogEntry(entry);
}

export async function listFeedingLog(userId: string, sightingId: string) {
  const sighting = await prisma.sighting.findFirst({ where: { id: sightingId, userId } });
  if (!sighting) return null;

  await purgeStaleEntries(sightingId);

  const entries = await prisma.feedingLogEntry.findMany({
    where: { sightingId },
    orderBy: { createdAt: 'desc' },
  });

  return entries.map(shapeFeedingLogEntry);
}
```

- [ ] **Step 2: Update `feedings.routes.ts`**

```ts
const entries = await listFeedingLog(req.userId!, req.params.sightingId);
```
```ts
const entry = await createFeedingLogEntry(req.userId!, req.params.sightingId, parsed.data);
```

- [ ] **Step 3: Apply `requireAuth` in `app.ts`**

```ts
app.use('/sightings/:sightingId/feedings', requireAuth, feedingsRouter);
```

At this point every non-`/auth`, non-`/uploads` line in `app.ts` has `requireAuth` applied — confirm the final file matches:

```ts
app.use('/auth', authRouter);

app.use('/entries/:entryId/photos', requireAuth, photosRouter);
app.use('/entries', requireAuth, entriesRouter);
app.use('/sightings/:sightingId/photos', requireAuth, sightingPhotosRouter);
app.use('/sightings/:sightingId/feedings', requireAuth, feedingsRouter);
app.use('/sightings', requireAuth, sightingsRouter);
app.use('/uploads', express.static(uploadsDir));
```

- [ ] **Step 4: Update the two feedings test files**

Same mechanical edit applied to `tests/feedings.create.test.ts` and `tests/feedings.list.test.ts` (the latter keeps its existing `import { prisma } from '../src/db';` line).

- [ ] **Step 5: Add an ownership test to `feedings.list.test.ts`**

Append:

```ts
describe('GET /sightings/:sightingId/feedings — ownership', () => {
  it("returns 404 for another user's sighting", async () => {
    const sighting = await createSighting();
    await createTestUser();

    const res = await authedRequest(app).get(`/sightings/${sighting.id}/feedings`);

    expect(res.status).toBe(404);
  });
});
```

Add `createTestUser` to the file's `import { authedRequest, createTestUser } from './helpers/testAuth';` line.

- [ ] **Step 6: Run the full test suite**

Run: `cd journally-api && npm test`
Expected: PASS — every test in the suite, including all pre-existing tests.

- [ ] **Step 7: Commit**

```bash
git add src/feedings src/app.ts tests/feedings.*.test.ts
git commit -m "feat: scope feeding log entries to the authenticated user via sighting ownership"
```

This completes Part 1. `journally-api` now requires auth on every resource route and is ready for the Flutter client to integrate against.

---

## Part 2 — journally (Flutter)

### Task 15: Add Dio and flutter_secure_storage dependencies

**Files:**
- Modify: `journally/pubspec.yaml`

**Interfaces:**
- Produces: `dio` and `flutter_secure_storage` packages available; `mocktail` available in tests.

- [ ] **Step 1: Add dependencies**

In `pubspec.yaml`'s `dependencies:` block, alongside the existing `http: ^1.2.2` (keep `http` — `image_picker`/multipart flows aren't being touched by this plan, `Dio`'s `FormData` replaces raw `http.MultipartRequest` usage only inside the three migrated repos):

```yaml
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.2
```

In `dev_dependencies:`:

```yaml
  mocktail: ^1.0.4
```

- [ ] **Step 2: Fetch packages**

Run: `cd journally && flutter pub get`
Expected: resolves cleanly.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add dio, flutter_secure_storage, mocktail"
```

---

### Task 16: Fake Dio HTTP adapter test helper

**Files:**
- Create: `journally/test/helpers/fake_http_client_adapter.dart`

**Interfaces:**
- Produces: `FakeHttpClientAdapter`, used by every Dio-based test in this plan (Tasks 18-23) instead of adding an external Dio-mocking package.

- [ ] **Step 1: Write the fake adapter**

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A minimal, hand-rolled [HttpClientAdapter] for tests — avoids adding an
/// external Dio-mocking package for what's a small, fully-controllable
/// fake. [handler] is called once per request; return the status code and
/// a JSON-encodable body (or `null` for an empty body).
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final FutureOr<({int statusCode, Object? data})> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = await handler(options);
    final bytes = result.data == null
        ? Uint8List(0)
        : Uint8List.fromList(utf8.encode(jsonEncode(result.data)));

    return ResponseBody.fromBytes(
      bytes,
      result.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
```

No standalone test for this file — it's exercised by every test task that follows.

- [ ] **Step 2: Commit**

```bash
git add test/helpers/fake_http_client_adapter.dart
git commit -m "test: add fake Dio HTTP client adapter for auth/repo tests"
```

---

### Task 17: TokenStorage

**Files:**
- Create: `journally/lib/core/auth/domain/auth_user.dart`
- Create: `journally/lib/core/auth/data/token_storage.dart`
- Test: `journally/test/core/auth/token_storage_test.dart`

**Interfaces:**
- Produces: `AuthUser {id, email}`, `StoredSession {refreshToken, user}`, `TokenStorage.saveSession/readSession/updateRefreshToken/clear`

- [ ] **Step 1: Write `auth_user.dart`**

```dart
class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(id: json['id'] as String, email: json['email'] as String);
  }
}
```

- [ ] **Step 2: Write the failing test**

`flutter_secure_storage`'s default backend doesn't work in `flutter test` (no platform channels), so the test injects an in-memory fake implementing `FlutterSecureStorage`'s minimal surface via its constructor's `aOptions`-free API isn't mockable directly — instead, inject a fake through the `TokenStorage({FlutterSecureStorage? storage})` seam using `mocktail`.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: mockStorage);
  });

  test('saveSession writes the refresh token and serialized user', () async {
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await tokenStorage.saveSession(
      refreshToken: 'refresh-abc',
      user: const AuthUser(id: 'u1', email: 'a@b.com'),
    );

    verify(() => mockStorage.write(key: 'refresh_token', value: 'refresh-abc')).called(1);
    verify(
      () => mockStorage.write(
        key: 'auth_user',
        value: '{"id":"u1","email":"a@b.com"}',
      ),
    ).called(1);
  });

  test('readSession returns null when nothing is stored', () async {
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

    expect(await tokenStorage.readSession(), isNull);
  });

  test('readSession reconstructs the stored session', () async {
    when(() => mockStorage.read(key: 'refresh_token')).thenAnswer((_) async => 'refresh-abc');
    when(() => mockStorage.read(key: 'auth_user'))
        .thenAnswer((_) async => '{"id":"u1","email":"a@b.com"}');

    final session = await tokenStorage.readSession();

    expect(session!.refreshToken, 'refresh-abc');
    expect(session.user.id, 'u1');
    expect(session.user.email, 'a@b.com');
  });

  test('clear deletes both keys', () async {
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await tokenStorage.clear();

    verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    verify(() => mockStorage.delete(key: 'auth_user')).called(1);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd journally && flutter test test/core/auth/token_storage_test.dart`
Expected: FAIL — `token_storage.dart` doesn't exist yet.

- [ ] **Step 4: Write `token_storage.dart`**

```dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_user.dart';

class StoredSession {
  const StoredSession({required this.refreshToken, required this.user});

  final String refreshToken;
  final AuthUser user;
}

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String refreshToken,
    required AuthUser user,
  }) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(
      key: _userKey,
      value: jsonEncode({'id': user.id, 'email': user.email}),
    );
  }

  Future<StoredSession?> readSession() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final userJson = await _storage.read(key: _userKey);
    if (refreshToken == null || userJson == null) return null;
    return StoredSession(
      refreshToken: refreshToken,
      user: AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
    );
  }

  Future<void> updateRefreshToken(String refreshToken) =>
      _storage.write(key: _refreshTokenKey, value: refreshToken);

  Future<void> clear() async {
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd journally && flutter test test/core/auth/token_storage_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/core/auth/domain/auth_user.dart lib/core/auth/data/token_storage.dart test/core/auth/token_storage_test.dart
git commit -m "feat: add TokenStorage for the refresh token and cached user"
```

---

### Task 18: Auth domain (state, repository interface) + HttpAuthRepository

**Files:**
- Create: `journally/lib/core/auth/domain/auth_state.dart`
- Create: `journally/lib/core/auth/domain/auth_repository.dart`
- Create: `journally/lib/core/auth/data/http_auth_repository.dart`
- Test: `journally/test/core/auth/http_auth_repository_test.dart`

**Interfaces:**
- Produces: `AuthState` (`AuthLoggedOut`/`AuthLoading`/`AuthLoggedIn`), `AuthResult`, `AuthRepository` interface, `HttpAuthRepository` implementation.

- [ ] **Step 1: Write `auth_state.dart`**

```dart
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
```

- [ ] **Step 2: Write `auth_repository.dart`**

```dart
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
```

- [ ] **Step 3: Write the failing test**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/http_auth_repository.dart';
import 'package:journally/core/network/api_exception.dart';

import '../../helpers/fake_http_client_adapter.dart';

void main() {
  late Dio dio;
  late HttpAuthRepository repository;

  Dio buildDio(FakeHttpClientAdapter adapter) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return dio;
  }

  test('login posts credentials and parses the token pair', () async {
    dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/auth/login');
        expect(options.data, {'email': 'a@b.com', 'password': 'pw'});
        return (
          statusCode: 200,
          data: {
            'user': {'id': 'u1', 'email': 'a@b.com'},
            'accessToken': 'access-1',
            'refreshToken': 'refresh-1',
          },
        );
      }),
    );
    repository = HttpAuthRepository(dio: dio);

    final result = await repository.login(email: 'a@b.com', password: 'pw');

    expect(result.user.id, 'u1');
    expect(result.accessToken, 'access-1');
    expect(result.refreshToken, 'refresh-1');
  });

  test('login throws ApiException on a non-2xx response', () async {
    dio = buildDio(
      FakeHttpClientAdapter(
        (_) => (statusCode: 401, data: {'error': 'Invalid email or password'}),
      ),
    );
    repository = HttpAuthRepository(dio: dio);

    expect(
      () => repository.login(email: 'a@b.com', password: 'wrong'),
      throwsA(isA<ApiException>()),
    );
  });

  test('signup posts to /auth/signup', () async {
    dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/auth/signup');
        return (
          statusCode: 201,
          data: {
            'user': {'id': 'u2', 'email': 'new@b.com'},
            'accessToken': 'access-2',
            'refreshToken': 'refresh-2',
          },
        );
      }),
    );
    repository = HttpAuthRepository(dio: dio);

    final result = await repository.signup(email: 'new@b.com', password: 'pw');

    expect(result.user.email, 'new@b.com');
  });

  test('refresh posts the refresh token and returns a new pair', () async {
    dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/auth/refresh');
        expect(options.data, {'refreshToken': 'old-refresh'});
        return (statusCode: 200, data: {'accessToken': 'access-3', 'refreshToken': 'refresh-3'});
      }),
    );
    repository = HttpAuthRepository(dio: dio);

    final result = await repository.refresh('old-refresh');

    expect(result.accessToken, 'access-3');
    expect(result.refreshToken, 'refresh-3');
  });

  test('logout does not throw even if the server call fails', () async {
    dio = buildDio(FakeHttpClientAdapter((_) => (statusCode: 500, data: null)));
    repository = HttpAuthRepository(dio: dio);

    await expectLater(repository.logout('refresh-1'), completes);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd journally && flutter test test/core/auth/http_auth_repository_test.dart`
Expected: FAIL — `http_auth_repository.dart` doesn't exist yet.

- [ ] **Step 5: Write `http_auth_repository.dart`**

```dart
import 'package:dio/dio.dart';

import '../../api_config.dart';
import '../../network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  final Dio _dio;

  @override
  Future<AuthResult> signup({required String email, required String password}) =>
      _authenticate('/auth/signup', email, password);

  @override
  Future<AuthResult> login({required String email, required String password}) =>
      _authenticate('/auth/login', email, password);

  Future<AuthResult> _authenticate(String path, String email, String password) async {
    try {
      final response = await _dio.post(path, data: {'email': email, 'password': password});
      final data = response.data as Map<String, dynamic>;
      return AuthResult(
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException('POST $path failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<RefreshResult> refresh(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final data = response.data as Map<String, dynamic>;
      return RefreshResult(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException('POST /auth/refresh failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException {
      // Best-effort — the local session is cleared regardless of the
      // server-side result.
    }
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd journally && flutter test test/core/auth/http_auth_repository_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 7: Commit**

```bash
git add lib/core/auth/domain/auth_state.dart lib/core/auth/domain/auth_repository.dart lib/core/auth/data/http_auth_repository.dart test/core/auth/http_auth_repository_test.dart
git commit -m "feat: add auth domain types and HttpAuthRepository"
```

---

### Task 19: ApiClient + AuthInterceptor

**Files:**
- Create: `journally/lib/core/network/auth_interceptor.dart`
- Create: `journally/lib/core/network/api_client.dart`
- Test: `journally/test/core/network/auth_interceptor_test.dart`

**Interfaces:**
- Consumes: nothing app-specific — takes plain callback functions, decoupled from Riverpod so it's independently testable.
- Produces: `AuthInterceptor`, `buildApiClient({getAccessToken, onRefresh, onRefreshFailed})`

- [ ] **Step 1: Write `auth_interceptor.dart`**

```dart
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required this.getAccessToken,
    required this.onRefresh,
    required this.onRefreshFailed,
  }) : _dio = dio;

  final Dio _dio;
  final Future<String?> Function() getAccessToken;
  final Future<String> Function() onRefresh;
  final Future<void> Function() onRefreshFailed;

  Future<String>? _refreshFuture;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isAuthEndpoint = err.requestOptions.path.startsWith('/auth/');
    if (err.response?.statusCode != 401 || isAuthEndpoint) {
      handler.next(err);
      return;
    }

    try {
      final newToken = await (_refreshFuture ??= _refresh());
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken';
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (_) {
      await onRefreshFailed();
      handler.next(err);
    }
  }

  Future<String> _refresh() async {
    try {
      return await onRefresh();
    } finally {
      _refreshFuture = null;
    }
  }
}
```

- [ ] **Step 2: Write `api_client.dart`**

```dart
import 'package:dio/dio.dart';

import '../api_config.dart';
import 'auth_interceptor.dart';

Dio buildApiClient({
  required Future<String?> Function() getAccessToken,
  required Future<String> Function() onRefresh,
  required Future<void> Function() onRefreshFailed,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      getAccessToken: getAccessToken,
      onRefresh: onRefresh,
      onRefreshFailed: onRefreshFailed,
    ),
  );
  return dio;
}
```

- [ ] **Step 3: Write the failing test**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/network/auth_interceptor.dart';

import '../../helpers/fake_http_client_adapter.dart';

void main() {
  test('attaches the current access token to every request', () async {
    final dio = Dio();
    String? currentToken = 'token-1';
    dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.headers['Authorization'], 'Bearer token-1');
      return (statusCode: 200, data: {'ok': true});
    });
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => currentToken,
        onRefresh: () async => throw StateError('should not refresh'),
        onRefreshFailed: () async {},
      ),
    );

    final res = await dio.get('/entries');
    expect(res.statusCode, 200);
  });

  test('on a 401, refreshes once and retries the original request', () async {
    final dio = Dio();
    var callCount = 0;
    var refreshCalls = 0;
    String currentToken = 'expired-token';

    dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      callCount++;
      if (options.headers['Authorization'] == 'Bearer expired-token') {
        return (statusCode: 401, data: {'error': 'expired'});
      }
      expect(options.headers['Authorization'], 'Bearer fresh-token');
      return (statusCode: 200, data: {'ok': true});
    });

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => currentToken,
        onRefresh: () async {
          refreshCalls++;
          currentToken = 'fresh-token';
          return 'fresh-token';
        },
        onRefreshFailed: () async => fail('should not be called'),
      ),
    );

    final res = await dio.get('/entries');

    expect(res.statusCode, 200);
    expect(refreshCalls, 1);
    expect(callCount, 2); // original 401 + retry
  });

  test('concurrent 401s share a single in-flight refresh', () async {
    final dio = Dio();
    var refreshCalls = 0;
    String currentToken = 'expired-token';

    dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      if (options.headers['Authorization'] == 'Bearer expired-token') {
        return (statusCode: 401, data: {'error': 'expired'});
      }
      return (statusCode: 200, data: {'ok': true});
    });

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => currentToken,
        onRefresh: () async {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          currentToken = 'fresh-token';
          return 'fresh-token';
        },
        onRefreshFailed: () async => fail('should not be called'),
      ),
    );

    final results = await Future.wait([dio.get('/entries'), dio.get('/sightings')]);

    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(refreshCalls, 1);
  });

  test('calls onRefreshFailed and rethrows when refresh itself fails', () async {
    final dio = Dio();
    var refreshFailedCalls = 0;

    dio.httpClientAdapter = FakeHttpClientAdapter(
      (_) => (statusCode: 401, data: {'error': 'expired'}),
    );

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => 'expired-token',
        onRefresh: () async => throw StateError('refresh token invalid'),
        onRefreshFailed: () async => refreshFailedCalls++,
      ),
    );

    await expectLater(dio.get('/entries'), throwsA(isA<DioException>()));
    expect(refreshFailedCalls, 1);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd journally && flutter test test/core/network/auth_interceptor_test.dart`
Expected: FAIL — `auth_interceptor.dart` doesn't exist yet (this step is out of order relative to Steps 1-2 above only in the strict TDD sense; since the interceptor's logic is non-trivial, Steps 1-2 wrote it first here — run the test now purely to confirm it exercises real behavior, not a trivial stub).

- [ ] **Step 5: Run test to verify it passes**

Run: `cd journally && flutter test test/core/network/auth_interceptor_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/core/network/auth_interceptor.dart lib/core/network/api_client.dart test/core/network/auth_interceptor_test.dart
git commit -m "feat: add AuthInterceptor with single in-flight refresh and request replay"
```

---

### Task 20: AuthController (Riverpod)

**Files:**
- Create: `journally/lib/core/auth/presentation/providers/auth_providers.dart`
- Test: `journally/test/core/auth/auth_controller_test.dart`

**Interfaces:**
- Consumes: `AuthRepository` (Task 18), `TokenStorage` (Task 17)
- Produces: `authRepositoryProvider`, `tokenStorageProvider`, `authControllerProvider` (`AuthController extends _$AuthController`, state = `AuthState`), with `signup`, `login`, `logout`, `refreshAccessToken`, `forceLogout` methods.

- [ ] **Step 1: Write `auth_providers.dart`**

```dart
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
```

- [ ] **Step 2: Generate the `.g.dart` part file**

Run: `cd journally && dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/core/auth/presentation/providers/auth_providers.g.dart` is generated with no errors.

- [ ] **Step 3: Write the test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_repository.dart';
import 'package:journally/core/auth/domain/auth_state.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRepository mockRepo;
  late MockTokenStorage mockStorage;
  late ProviderContainer container;

  const user = AuthUser(id: 'u1', email: 'a@b.com');

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockTokenStorage();
    when(() => mockStorage.readSession()).thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) => mockRepo),
        tokenStorageProvider.overrideWith((ref) => mockStorage),
      ],
    );
    addTearDown(container.dispose);
  });

  test('starts loggedOut when there is no stored session', () async {
    final controller = container.read(authControllerProvider.notifier);
    // build() kicks off an async silent-login check — wait for it.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
    // ignore: unnecessary_statements
    controller;
  });

  test('login transitions to loggedIn and persists the session', () async {
    when(
      () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer(
      (_) async =>
          const AuthResult(user: user, accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    when(
      () => mockStorage.saveSession(
        refreshToken: any(named: 'refreshToken'),
        user: any(named: 'user'),
      ),
    ).thenAnswer((_) async {});

    await container.read(authControllerProvider.notifier).login(email: 'a@b.com', password: 'pw');

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthLoggedIn>());
    expect((state as AuthLoggedIn).accessToken, 'access-1');
  });

  test('a failed login leaves state loggedOut', () async {
    when(
      () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenThrow(Exception('invalid credentials'));

    await expectLater(
      container.read(authControllerProvider.notifier).login(email: 'a@b.com', password: 'wrong'),
      throwsException,
    );

    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
  });

  test('refreshAccessToken rotates the stored token and updates state', () async {
    when(() => mockStorage.readSession()).thenAnswer(
      (_) async => const StoredSession(refreshToken: 'old-refresh', user: user),
    );
    when(() => mockRepo.refresh('old-refresh')).thenAnswer(
      (_) async => const RefreshResult(accessToken: 'access-2', refreshToken: 'refresh-2'),
    );
    when(() => mockStorage.updateRefreshToken('refresh-2')).thenAnswer((_) async {});

    final token = await container.read(authControllerProvider.notifier).refreshAccessToken();

    expect(token, 'access-2');
    final state = container.read(authControllerProvider);
    expect((state as AuthLoggedIn).accessToken, 'access-2');
  });

  test('forceLogout clears storage and sets loggedOut', () async {
    when(() => mockStorage.clear()).thenAnswer((_) async {});

    await container.read(authControllerProvider.notifier).forceLogout();

    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
    verify(() => mockStorage.clear()).called(1);
  });
}
```

- [ ] **Step 4: Run the test**

Run: `cd journally && flutter test test/core/auth/auth_controller_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/auth/presentation test/core/auth/auth_controller_test.dart
git commit -m "feat: add AuthController (Riverpod session state)"
```

---

### Task 21: Wire ApiClient into Riverpod

**Files:**
- Create: `journally/lib/core/network/api_client_providers.dart`

**Interfaces:**
- Consumes: `authControllerProvider` (Task 20), `buildApiClient` (Task 19)
- Produces: `apiClientProvider` (`Dio`) — the shared, authenticated Dio instance the three repo-migration tasks inject.

- [ ] **Step 1: Write the provider**

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/domain/auth_state.dart';
import '../auth/presentation/providers/auth_providers.dart';
import 'api_client.dart';

part 'api_client_providers.g.dart';

@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  return buildApiClient(
    getAccessToken: () async {
      final state = ref.read(authControllerProvider);
      return state is AuthLoggedIn ? state.accessToken : null;
    },
    onRefresh: () => ref.read(authControllerProvider.notifier).refreshAccessToken(),
    onRefreshFailed: () => ref.read(authControllerProvider.notifier).forceLogout(),
  );
}
```

- [ ] **Step 2: Generate the part file**

Run: `cd journally && dart run build_runner build --delete-conflicting-outputs`
Expected: `api_client_providers.g.dart` generated with no errors.

No standalone test — this is a thin wiring provider, exercised end-to-end by the repo migration tasks that follow.

- [ ] **Step 3: Commit**

```bash
git add lib/core/network/api_client_providers.dart lib/core/network/api_client_providers.g.dart
git commit -m "feat: wire the authenticated Dio ApiClient into Riverpod"
```

---

### Task 22: Migrate HttpCafeRepository to Dio

**Files:**
- Modify: `journally/lib/features/cafes/data/http_cafe_repository.dart`
- Modify: `journally/lib/features/cafes/presentation/providers/cafe_providers.dart:9-11`
- Test: `journally/test/features/cafes/http_cafe_repository_test.dart`

**Interfaces:**
- Consumes: `Dio` (injected)
- Produces: `HttpCafeRepository(dio: Dio)` — same public `CafeRepository` interface as before.

- [ ] **Step 1: Rewrite `http_cafe_repository.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/cafe_entry.dart';
import '../domain/cafe_repository.dart';
import '../../../core/gradient_palette.dart';
import '../../../core/network/api_exception.dart';

class HttpCafeRepository implements CafeRepository {
  HttpCafeRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<CafeEntry>> fetchCafes() async {
    try {
      final response = await _dio.get<List<dynamic>>('/entries');
      return response.data!
          .map((json) => _toCafeEntry(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException('GET /entries failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<CafeEntry> fetchCafeById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/entries/$id');
      return _toCafeEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('GET /entries/$id failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<void> deleteCafe(String id) async {
    try {
      await _dio.delete('/entries/$id');
    } on DioException catch (e) {
      throw ApiException('DELETE /entries/$id failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<CafeEntry> createCafe({
    required String placeName,
    required String neighborhood,
    required String city,
    required List<OrderItem> orderItems,
    required DateTime visitedAt,
    double? rating,
    String notes = '',
    List<String> attributes = const [],
    double? lat,
    double? lng,
    String? placeId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/entries',
        data: {
          'placeName': placeName,
          'neighborhood': neighborhood,
          'city': city,
          'orderItems': orderItems.map((item) => item.toJson()).toList(),
          'visitedAt': visitedAt.toIso8601String(),
          'notes': notes,
          'attributes': attributes,
          'rating': ?rating,
          'lat': ?lat,
          'lng': ?lng,
          'placeId': ?placeId,
        },
      );
      return _toCafeEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('POST /entries failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<CafeEntry> updateCafe(
    String id, {
    String? placeName,
    String? neighborhood,
    String? city,
    List<OrderItem>? orderItems,
    double? lat,
    double? lng,
    String? placeId,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/entries/$id',
        data: {
          'placeName': ?placeName,
          'neighborhood': ?neighborhood,
          'city': ?city,
          if (orderItems != null)
            'orderItems': orderItems.map((item) => item.toJson()).toList(),
          'lat': ?lat,
          'lng': ?lng,
          'placeId': ?placeId,
        },
      );
      return _toCafeEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('PATCH /entries/$id failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<void> uploadPhoto(String entryId, XFile photo) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromBytes(await photo.readAsBytes(), filename: photo.name),
      });
      await _dio.post('/entries/$entryId/photos', data: formData);
    } on DioException catch (e) {
      throw ApiException(
        'POST /entries/$entryId/photos failed with status ${e.response?.statusCode}',
      );
    }
  }

  @override
  Future<List<CafeEntry>> fetchNearbyCafe({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/entries/nearby',
        queryParameters: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm},
      );
      return response.data!
          .map((json) => _toCafeEntry(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException('GET /entries/nearby failed with status ${e.response?.statusCode}');
    }
  }

  CafeEntry _toCafeEntry(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final photoUrls = (json['photoUrls'] as List<dynamic>).cast<String>();
    final palette = pickGradient(id);

    return CafeEntry(
      id: id,
      placeName: json['placeName'] as String,
      neighborhood: json['neighborhood'] as String,
      city: json['city'] as String,
      orderItems: (json['orderItems'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      photoCount: (json['photoCount'] as num?)?.toInt() ?? photoUrls.length,
      photoUrls: photoUrls,
      gradientColors: palette,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      rating: (json['rating'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      attributes: (json['attributes'] as List<dynamic>?)?.cast<String>() ?? const [],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      placeId: json['placeId'] as String?,
    );
  }
}
```

Note: `Dio`'s default `ResponseType.json` auto-decodes the body, so the `dart:convert` `jsonDecode` calls from the `http`-based version are gone — `response.data` is already a `List`/`Map`.

- [ ] **Step 2: Update `cafe_providers.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_providers.dart';
import '../../data/http_cafe_repository.dart';
import '../../domain/cafe_entry.dart';
import '../../domain/cafe_repository.dart';

part 'cafe_providers.g.dart';

@riverpod
CafeRepository cafeRepository(Ref ref) {
  return HttpCafeRepository(dio: ref.watch(apiClientProvider));
}
```

(Rest of the file — `cafeEntries`, `cafeEntry`, `nearbyCafe` — unchanged.)

- [ ] **Step 3: Regenerate part files**

Run: `cd journally && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Write the repository test**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/features/cafes/data/http_cafe_repository.dart';

import '../../helpers/fake_http_client_adapter.dart';

void main() {
  Dio buildDio(FakeHttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  Map<String, dynamic> cafeJson({String id = 'c1'}) => {
    'id': id,
    'placeName': 'Blue Bottle',
    'neighborhood': 'Hayes Valley',
    'city': 'San Francisco',
    'orderItems': <dynamic>[],
    'photoCount': 0,
    'photoUrls': <dynamic>[],
    'visitedAt': '2026-01-01T00:00:00.000Z',
    'rating': null,
    'notes': '',
    'attributes': <dynamic>[],
    'lat': null,
    'lng': null,
    'placeId': null,
  };

  test('fetchCafes GETs /entries and parses the list', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/entries');
        return (statusCode: 200, data: [cafeJson()]);
      }),
    );
    final repo = HttpCafeRepository(dio: dio);

    final cafes = await repo.fetchCafes();

    expect(cafes, hasLength(1));
    expect(cafes.first.placeName, 'Blue Bottle');
  });

  test('fetchCafeById GETs /entries/:id', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/entries/c1');
        return (statusCode: 200, data: cafeJson());
      }),
    );
    final repo = HttpCafeRepository(dio: dio);

    final cafe = await repo.fetchCafeById('c1');

    expect(cafe.id, 'c1');
  });

  test('deleteCafe DELETEs /entries/:id', () async {
    var called = false;
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.method, 'DELETE');
        called = true;
        return (statusCode: 204, data: null);
      }),
    );
    final repo = HttpCafeRepository(dio: dio);

    await repo.deleteCafe('c1');

    expect(called, isTrue);
  });
}
```

- [ ] **Step 5: Run the test**

Run: `cd journally && flutter test test/features/cafes/http_cafe_repository_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafes test/features/cafes/http_cafe_repository_test.dart
git commit -m "feat: migrate HttpCafeRepository to the authenticated Dio ApiClient"
```

---

### Task 23: Migrate HttpSightingRepository to Dio

**Files:**
- Modify: `journally/lib/features/sightings/data/http_sighting_repository.dart`
- Modify: `journally/lib/features/sightings/presentation/providers/sightings_providers.dart:16-20`
- Test: `journally/test/features/sightings/http_sighting_repository_test.dart`

**Interfaces:**
- Same pattern as Task 22, applied to `SightingsRepository`.

- [ ] **Step 1: Rewrite `http_sighting_repository.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:journally/core/gradient_palette.dart';
import 'package:journally/core/network/api_exception.dart';
import 'package:journally/features/place_search/data/nominatim_place_search_repository.dart';
import 'package:journally/features/place_search/domain/place_search_repository.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/domain/sightings_repository.dart';
import 'package:image_picker/image_picker.dart';

class HttpSightingRepository implements SightingsRepository {
  HttpSightingRepository({required Dio dio, PlaceSearchRepository? placeSearch})
    : _dio = dio,
      _placeSearch = placeSearch ?? NominatimPlaceSearchRepository();

  final Dio _dio;
  final PlaceSearchRepository _placeSearch;

  @override
  Future<List<Sighting>> fetchSightings() async {
    try {
      final response = await _dio.get<List<dynamic>>('/sightings');
      return Future.wait(
        response.data!.map((json) => _toSightingEntry(json as Map<String, dynamic>)),
      );
    } on DioException catch (e) {
      throw ApiException('GET /sightings failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<Sighting> fetchSightingById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/sightings/$id');
      return await _toSightingEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('GET /sightings/$id failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<List<Sighting>> fetchNearbySightings({
    required double lat,
    required double lng,
    double radiusKm = 5,
    Species? species,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/sightings/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusKm': radiusKm,
          if (species != null) 'species': species.name,
        },
      );
      return Future.wait(
        response.data!.map((json) => _toSightingEntry(json as Map<String, dynamic>)),
      );
    } on DioException catch (e) {
      throw ApiException('GET /sightings/nearby failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<Sighting> createSighting({
    required Species species,
    required double lat,
    required double lng,
    String? notes,
    List<String> attributes = const [],
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sightings',
        data: {
          'species': species.name,
          'lat': lat,
          'lng': lng,
          'attributes': attributes,
          'notes': ?notes,
        },
      );
      return await _toSightingEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('POST /sightings failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<void> uploadPhoto(String sightingId, XFile photo) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromBytes(await photo.readAsBytes(), filename: photo.name),
      });
      await _dio.post('/sightings/$sightingId/photos', data: formData);
    } on DioException catch (e) {
      throw ApiException(
        'POST /sightings/$sightingId/photos failed with status ${e.response?.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteSightById(String id) async {
    try {
      await _dio.delete('/sightings/$id');
    } on DioException catch (e) {
      throw ApiException('DELETE /sightings/$id failed with status ${e.response?.statusCode}');
    }
  }

  Future<Sighting> _toSightingEntry(Map<String, dynamic> json) async {
    final id = json['id'] as String;
    final photoUrls = (json['photoUrls'] as List<dynamic>?)?.cast<String>();
    final palette = pickGradient(id);
    final photoCount = photoUrls?.length ?? 0;
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    final fedAtJson = json['fedAt'] as String?;
    final createdAtJson = json['createdAt'] as String?;
    final updatedAtJson = json['updatedAt'] as String?;
    final placeName = await _resolvePlaceName(lat, lng);

    return Sighting(
      id: id,
      animal: Species.values.byName(json['species'] as String),
      placeName: placeName,
      lat: lat,
      lng: lng,
      fed: json['fed'] as bool,
      fedAt: fedAtJson != null ? DateTime.parse(fedAtJson) : null,
      notes: (json['notes'] as String?) ?? '',
      photoCount: photoCount,
      gradientColors: palette,
      photoUrls: photoUrls,
      createdAt: createdAtJson != null ? DateTime.parse(createdAtJson) : null,
      updatedAt: updatedAtJson != null ? DateTime.parse(updatedAtJson) : null,
      attributes: (json['attributes'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  Future<String> _resolvePlaceName(double lat, double lng) async {
    try {
      return await _placeSearch.reverseGeocode(lat: lat, lng: lng);
    } catch (_) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }
}
```

- [ ] **Step 2: Update `sightings_providers.dart`**

```dart
import 'package:journally/core/location_provider.dart';
import 'package:journally/core/network/api_client_providers.dart';
import 'package:journally/features/place_search/presentation/providers/place_search_providers.dart';
import 'package:journally/features/sightings/data/http_sighting_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/sighting.dart';
import '../../domain/sightings_repository.dart';

part 'sightings_providers.g.dart';

const nearMeRadiusKm = 5.0;

@riverpod
SightingsRepository sightingsRepository(Ref ref) {
  return HttpSightingRepository(
    dio: ref.watch(apiClientProvider),
    placeSearch: ref.watch(placeSearchRepositoryProvider),
  );
}
```

(Rest of the file unchanged.)

- [ ] **Step 3: Regenerate part files**

Run: `cd journally && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Write the repository test**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/features/place_search/domain/place_search_repository.dart';
import 'package:journally/features/sightings/data/http_sighting_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http_client_adapter.dart';

class FakePlaceSearchRepository extends Fake implements PlaceSearchRepository {
  @override
  Future<String> reverseGeocode({required double lat, required double lng}) async => 'Test Place';
}

void main() {
  Dio buildDio(FakeHttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  Map<String, dynamic> sightingJson({String id = 's1'}) => {
    'id': id,
    'species': 'cat',
    'lat': 0.0,
    'lng': 0.0,
    'notes': null,
    'fed': false,
    'fedAt': null,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    'photoUrls': <dynamic>[],
    'attributes': <dynamic>[],
  };

  test('fetchSightings GETs /sightings and resolves place names', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/sightings');
        return (statusCode: 200, data: [sightingJson()]);
      }),
    );
    final repo = HttpSightingRepository(dio: dio, placeSearch: FakePlaceSearchRepository());

    final sightings = await repo.fetchSightings();

    expect(sightings, hasLength(1));
    expect(sightings.first.placeName, 'Test Place');
  });

  test('createSighting POSTs species/lat/lng to /sightings', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/sightings');
        expect(options.data, {
          'species': 'dog',
          'lat': 1.0,
          'lng': 2.0,
          'attributes': <String>[],
        });
        return (statusCode: 201, data: sightingJson());
      }),
    );
    final repo = HttpSightingRepository(dio: dio, placeSearch: FakePlaceSearchRepository());

    await repo.createSighting(species: Species.dog, lat: 1.0, lng: 2.0);
  });

  test('deleteSightById DELETEs /sightings/:id', () async {
    var called = false;
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.method, 'DELETE');
        called = true;
        return (statusCode: 204, data: null);
      }),
    );
    final repo = HttpSightingRepository(dio: dio, placeSearch: FakePlaceSearchRepository());

    await repo.deleteSightById('s1');

    expect(called, isTrue);
  });
}
```

- [ ] **Step 5: Run the test**

Run: `cd journally && flutter test test/features/sightings/http_sighting_repository_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/features/sightings/data lib/features/sightings/presentation/providers/sightings_providers.dart test/features/sightings/http_sighting_repository_test.dart
git commit -m "feat: migrate HttpSightingRepository to the authenticated Dio ApiClient"
```

---

### Task 24: Migrate HttpFeedingLogsRepository to Dio

**Files:**
- Modify: `journally/lib/features/feeding_logs/data/http_feeding_logs_repository.dart`
- Modify: `journally/lib/features/feeding_logs/presentation/providers/feeding_logs_providers.dart:9-11`
- Test: `journally/test/features/feeding_logs/http_feeding_logs_repository_test.dart`

**Interfaces:**
- Same pattern as Tasks 22-23, applied to `FeedingLogsRepository`.

- [ ] **Step 1: Rewrite `http_feeding_logs_repository.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:journally/core/network/api_exception.dart';
import 'package:journally/features/feeding_logs/domain/feeding_log_entry.dart';
import 'package:journally/features/feeding_logs/domain/feeding_logs_repository.dart';

class HttpFeedingLogsRepository implements FeedingLogsRepository {
  HttpFeedingLogsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<FeedingLogEntry>> fetchFeedingLog(String sightingId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/sightings/$sightingId/feedings');
      return response.data!
          .map((json) => _toFeedingLogEntry(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        'GET /sightings/$sightingId/feedings failed with status ${e.response?.statusCode}',
      );
    }
  }

  @override
  Future<FeedingLogEntry> createFeedingLogEntry(String sightingId, {String? note}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sightings/$sightingId/feedings',
        data: {'note': ?note},
      );
      return _toFeedingLogEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException(
        'POST /sightings/$sightingId/feedings failed with status ${e.response?.statusCode}',
      );
    }
  }

  FeedingLogEntry _toFeedingLogEntry(Map<String, dynamic> json) {
    return FeedingLogEntry(
      id: json['id'] as String,
      sightingId: json['sightingId'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

- [ ] **Step 2: Update `feeding_logs_providers.dart`**

```dart
import 'package:journally/core/network/api_client_providers.dart';
import 'package:journally/features/feeding_logs/data/http_feeding_logs_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/feeding_log_entry.dart';
import '../../domain/feeding_logs_repository.dart';

part 'feeding_logs_providers.g.dart';

@riverpod
FeedingLogsRepository feedingLogsRepository(Ref ref) {
  return HttpFeedingLogsRepository(dio: ref.watch(apiClientProvider));
}
```

(Rest of the file unchanged.)

- [ ] **Step 3: Regenerate part files**

Run: `cd journally && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Write the repository test**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/features/feeding_logs/data/http_feeding_logs_repository.dart';

import '../../helpers/fake_http_client_adapter.dart';

void main() {
  Dio buildDio(FakeHttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  test('fetchFeedingLog GETs /sightings/:id/feedings', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/sightings/s1/feedings');
        return (
          statusCode: 200,
          data: [
            {
              'id': 'f1',
              'sightingId': 's1',
              'note': 'Wet food',
              'createdAt': '2026-01-01T00:00:00.000Z',
            },
          ],
        );
      }),
    );
    final repo = HttpFeedingLogsRepository(dio: dio);

    final entries = await repo.fetchFeedingLog('s1');

    expect(entries, hasLength(1));
    expect(entries.first.note, 'Wet food');
  });

  test('createFeedingLogEntry POSTs the note', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/sightings/s1/feedings');
        expect(options.data, {'note': 'Dry kibble'});
        return (
          statusCode: 201,
          data: {
            'id': 'f2',
            'sightingId': 's1',
            'note': 'Dry kibble',
            'createdAt': '2026-01-01T00:00:00.000Z',
          },
        );
      }),
    );
    final repo = HttpFeedingLogsRepository(dio: dio);

    final entry = await repo.createFeedingLogEntry('s1', note: 'Dry kibble');

    expect(entry.note, 'Dry kibble');
  });
}
```

- [ ] **Step 5: Run the test**

Run: `cd journally && flutter test test/features/feeding_logs/http_feeding_logs_repository_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/features/feeding_logs test/features/feeding_logs/http_feeding_logs_repository_test.dart
git commit -m "feat: migrate HttpFeedingLogsRepository to the authenticated Dio ApiClient"
```

---

### Task 25: Login and signup screens

**Files:**
- Create: `journally/lib/features/auth/presentation/login_screen.dart`
- Create: `journally/lib/features/auth/presentation/signup_screen.dart`
- Test: `journally/test/features/auth/login_screen_test.dart`

**Interfaces:**
- Consumes: `authControllerProvider` (Task 20)
- Produces: `LoginScreen`, `SignupScreen` widgets, each pushing/replacing to the other and (on success) letting the app-root listener (Task 26) take over navigation.

- [ ] **Step 1: Write `login_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/presentation/providers/auth_providers.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: _emailController.text.trim(), password: _passwordController.text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Invalid email or password');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Journally',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('login_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value == null || !value.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your password' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('login_submit_button'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log in'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Need an account? Sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write `signup_screen.dart`**

Same shape as `LoginScreen`, calling `signup` instead of `login` and navigating back to login instead of forward to it:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/presentation/providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signup(email: _emailController.text.trim(), password: _passwordController.text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not create account — try a different email');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('signup_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value == null || !value.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('signup_password_field'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password (min. 8 characters)'),
                    validator: (value) => value == null || value.length < 8
                        ? 'Password must be at least 8 characters'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('signup_submit_button'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write the functional flow test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_repository.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:journally/core/auth/domain/auth_state.dart';
import 'package:journally/features/auth/presentation/login_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  testWidgets('entering valid credentials logs in via AuthController', (tester) async {
    final mockRepo = MockAuthRepository();
    final mockStorage = MockTokenStorage();
    when(() => mockStorage.readSession()).thenAnswer((_) async => null);
    when(() => mockStorage.saveSession(refreshToken: any(named: 'refreshToken'), user: any(named: 'user')))
        .thenAnswer((_) async {});
    when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer(
      (_) async => const AuthResult(
        user: AuthUser(id: 'u1', email: 'a@b.com'),
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) => mockRepo),
        tokenStorageProvider.overrideWith((ref) => mockStorage),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_email_field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider), isA<AuthLoggedIn>());
  });
}
```

- [ ] **Step 4: Run the test**

Run: `cd journally && flutter test test/features/auth/login_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth test/features/auth/login_screen_test.dart
git commit -m "feat: add login and signup screens"
```

---

### Task 26: Wire app root — splash auth gating + logout affordance

**Files:**
- Modify: `journally/lib/features/splash/presentation/splash_screen.dart`
- Modify: `journally/lib/core/widgets/header.dart`
- Modify: `journally/lib/features/home/presentation/home_screen.dart`

**Interfaces:**
- Consumes: `authControllerProvider` (Task 20), `LoginScreen` (Task 25)
- Produces: splash routes to `LoginScreen` when logged out, `HomeScreen` when logged in; a working logout button on the home header.

- [ ] **Step 1: Update `splash_screen.dart`'s warm-up and hand-off**

Add the import:

```dart
import 'package:journally/core/auth/domain/auth_state.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:journally/features/auth/presentation/login_screen.dart';
```

Replace `_warmUp`:

```dart
Future<void> _warmUp() async {
  await _waitForAuthResolved();

  if (ref.read(authControllerProvider) is AuthLoggedIn) {
    await Future.wait([
      _settle(ref.read(cafeEntriesProvider.future)),
      _settle(ref.read(sightingsProvider.future)),
      _settle(ref.read(deviceLocationProvider.future)),
    ]);
  }
}

Future<void> _waitForAuthResolved() async {
  if (ref.read(authControllerProvider) is! AuthLoading) return;

  final completer = Completer<void>();
  late final ProviderSubscription<AuthState> subscription;
  subscription = ref.listenManual(authControllerProvider, (previous, next) {
    if (next is! AuthLoading) {
      subscription.close();
      completer.complete();
    }
  });
  await completer.future;
}
```

Add the `dart:async` import for `Completer`:

```dart
import 'dart:async';
```

Replace `_handOff`:

```dart
void _handOff() {
  if (!mounted) return;
  setState(() => _receding = true);

  final isLoggedIn = ref.read(authControllerProvider) is AuthLoggedIn;
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      transitionDuration: SplashTiming.routeFade,
      pageBuilder: (context, animation, secondaryAnimation) =>
          isLoggedIn ? const HomeScreen() : const LoginScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
```

- [ ] **Step 2: Add an optional trailing widget to `Header`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.subtitle, this.trailing});

  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journally',
          style: GoogleFonts.fraunces(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(fontSize: 13, color: colors.onSurfaceVariant),
        ),
      ],
    );

    if (trailing == null) return titleColumn;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleColumn),
        trailing!,
      ],
    );
  }
}
```

- [ ] **Step 3: Find where `Header` is used in `home_screen.dart` and pass a logout button**

Run: `cd journally && grep -rn "Header(" lib/features/home`

Wherever the existing `Header(subtitle: ...)` call is, add a `trailing`:

```dart
Header(
  subtitle: /* existing subtitle expression, unchanged */,
  trailing: IconButton(
    icon: const Icon(Icons.logout),
    tooltip: 'Log out',
    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
  ),
),
```

Add the import to `home_screen.dart`:

```dart
import '../../../core/auth/presentation/providers/auth_providers.dart';
```

Logging out sets `AuthController`'s state to `AuthLoggedOut`; since nothing in `HomeScreen` currently listens for that transition, also wrap `HomeScreen`'s `build` method's returned `Scaffold` with a `ref.listen`:

At the top of `_HomeScreenState.build`, before `return Scaffold(...)`:

```dart
ref.listen<AuthState>(authControllerProvider, (previous, next) {
  if (next is AuthLoggedOut) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
});
```

Add the matching imports to `home_screen.dart`:

```dart
import '../../../core/auth/domain/auth_state.dart';
import '../../auth/presentation/login_screen.dart';
```

- [ ] **Step 4: Manual verification**

This task's changes span navigation/lifecycle code that's impractical to unit-test meaningfully beyond what Tasks 20 and 25 already cover. Instead, run the app and walk the flow by hand:

Run: `cd journally-api && npm run dev` (in one terminal), then `cd journally && flutter run` (in another).

1. Cold start with no stored session → splash → `LoginScreen`.
2. Tap "Need an account? Sign up" → create an account → should land on `HomeScreen` (via the app-root listener triggering navigation — see note below).
3. Kill and restart the app → splash silently refreshes → lands directly on `HomeScreen` without showing the login screen.
4. Tap the logout icon in the header → returns to `LoginScreen`.
5. Log back in with the same credentials → `HomeScreen` again, previously-created cafe/sighting data (created under that account) still present.

Note: step 2 needs `LoginScreen`/`SignupScreen`'s successful auth to also navigate forward. Since `AuthController`'s state flips to `AuthLoggedIn` on success, add the same `ref.listen` pattern from Step 3 to `LoginScreen` and `SignupScreen` (listening for `AuthLoggedIn` and pushing `HomeScreen`) as part of this step, mirroring `home_screen.dart`'s listener:

In both `_LoginScreenState.build` and `_SignupScreenState.build`, before the `return Scaffold(...)`:

```dart
ref.listen<AuthState>(authControllerProvider, (previous, next) {
  if (next is AuthLoggedIn) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
});
```

With the matching imports (`AuthState` and `HomeScreen`) added to both files.

- [ ] **Step 5: Run the full Flutter test suite**

Run: `cd journally && flutter test`
Expected: PASS — every test in the suite, including the pre-existing widget tests (`cafe_card_test.dart`, `cafe_detail_screen_test.dart`, `date_format_test.dart`, `sighting_detail_feeding_log_test.dart`, `widget_test.dart`), which don't touch auth and should be unaffected.

- [ ] **Step 6: Commit**

```bash
git add lib/features/splash lib/core/widgets/header.dart lib/features/home/presentation/home_screen.dart lib/features/auth
git commit -m "feat: gate app root on auth state, add logout affordance"
```

This completes the plan. `journally` now requires login, holds session state client-side, and transparently refreshes access tokens; `journally-api` rejects unauthenticated requests and scopes every resource to its owner.

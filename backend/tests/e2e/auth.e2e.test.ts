import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createTestDb, type TestDbHandle } from '../helpers/db';
import { createTestApp, type TestAppHandle } from '../helpers/app';
import { authHeaders } from '../helpers/auth';
import { seedUser } from '../helpers/fixtures';

describe('Authentication boundary', () => {
  let dbHandle: TestDbHandle;
  let appHandle: TestAppHandle;

  beforeEach(async () => {
    dbHandle = await createTestDb();
    await seedUser(dbHandle.db, { id: 'alice' });
    appHandle = createTestApp(dbHandle);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    appHandle.cleanup();
    dbHandle.client.close();
  });

  // -----------------------------------------------------------------------
  // 1. Unauthenticated requests to each protected route prefix → 401
  // -----------------------------------------------------------------------

  const protectedRoutes: { method: string; path: string }[] = [
    { method: 'GET',  path: '/api/sessions' },
    { method: 'POST', path: '/api/sessions' },
    { method: 'GET',  path: '/api/transactions' },
    { method: 'GET',  path: '/api/reports' },
    { method: 'GET',  path: '/api/notes' },
    { method: 'GET',  path: '/api/users/me' },
  ];

  for (const { method, path } of protectedRoutes) {
    it(`${method} ${path} without token → 401`, async () => {
      const res = await appHandle.app.fetch(
        new Request(`http://test${path}`, { method }),
        appHandle.env as any
      );
      expect(res.status).toBe(401);
    });
  }

  it('request with wrong Authorization scheme → 401', async () => {
    const res = await appHandle.app.fetch(
      new Request('http://test/api/sessions', {
        headers: { Authorization: 'Basic dXNlcjpwYXNz' },
      }),
      appHandle.env as any
    );
    expect(res.status).toBe(401);
  });

  // -----------------------------------------------------------------------
  // 2. Expired JWT across two route prefixes → 401
  // -----------------------------------------------------------------------

  it('expired JWT on GET /api/sessions → 401', async () => {
    const headers = await authHeaders('alice', { expired: true });
    const res = await appHandle.app.fetch(
      new Request('http://test/api/sessions', { headers }),
      appHandle.env as any
    );
    expect(res.status).toBe(401);
  });

  it('expired JWT on GET /api/transactions → 401', async () => {
    const headers = await authHeaders('alice', { expired: true });
    const res = await appHandle.app.fetch(
      new Request('http://test/api/transactions', { headers }),
      appHandle.env as any
    );
    expect(res.status).toBe(401);
  });

  // -----------------------------------------------------------------------
  // 3. CORS preflight
  //    ALLOWED_ORIGINS in test env = 'http://localhost:5173'
  // -----------------------------------------------------------------------

  it('preflight from allowed origin has Access-Control-Allow-Origin header', async () => {
    const res = await appHandle.app.fetch(
      new Request('http://test/api/sessions', {
        method: 'OPTIONS',
        headers: {
          Origin: 'http://localhost:5173',
          'Access-Control-Request-Method': 'GET',
        },
      }),
      appHandle.env as any
    );
    // Hono cors returns 204 for OPTIONS preflights
    expect([200, 204]).toContain(res.status);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe('http://localhost:5173');
  });

  it('preflight from disallowed origin does not echo the disallowed origin in ACAO header', async () => {
    const disallowed = 'https://evil.example.com';
    const res = await appHandle.app.fetch(
      new Request('http://test/api/sessions', {
        method: 'OPTIONS',
        headers: {
          Origin: disallowed,
          'Access-Control-Request-Method': 'GET',
        },
      }),
      appHandle.env as any
    );
    const acao = res.headers.get('Access-Control-Allow-Origin');
    // The ACAO header must NOT echo back the disallowed origin
    expect(acao).not.toBe(disallowed);
  });
});

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createTestDb, type TestDbHandle } from '../helpers/db';
import { createTestApp, type TestAppHandle } from '../helpers/app';
import { authHeaders } from '../helpers/auth';
import { seedUser, seedSession, seedTransaction } from '../helpers/fixtures';
import { userNotes } from '../../src/db/schema';

/**
 * Cross-user isolation keystone tests.
 *
 * Contract notes per route:
 *
 * - GET /api/sessions/:id    → 404 (resource hidden from non-owner; getSession filters by userId,
 *                                   returning null → "Session not found" 404)
 * - POST /api/sessions/:id/messages → 404 (same getSession guard; no 403 because the session
 *                                          appears non-existent to bob)
 * - GET /api/transactions    → 200 with empty array (route always scopes by JWT userId,
 *                                                    never exposes other users' data)
 * - DELETE /api/transactions/:id → 404 (soft-delete WHERE id AND userId; no match → "Transaction
 *                                        not found" 404)
 * - GET /api/notes/:id       → 404 (userNotesService.getNote filters by (id, userId);
 *                                   not found → "Note not found" 404)
 */

describe('Cross-user isolation keystone', () => {
  let dbHandle: TestDbHandle;
  let appHandle: TestAppHandle;

  let aliceSession: any;
  let aliceTx: any;
  let aliceNote: any;

  beforeEach(async () => {
    dbHandle = await createTestDb();
    await seedUser(dbHandle.db, { id: 'alice' });
    await seedUser(dbHandle.db, { id: 'bob' });
    appHandle = createTestApp(dbHandle);

    // Create alice's resources
    aliceSession = await seedSession(dbHandle.db, { userId: 'alice', title: 'Alice private session' });
    aliceTx = await seedTransaction(dbHandle.db, { userId: 'alice', amount: 50000 });

    // Insert alice's note directly via DB (no route needed)
    const insertedNotes = await dbHandle.db
      .insert(userNotes)
      .values({
        userId: 'alice',
        content: 'Alice private note',
      })
      .returning();
    aliceNote = insertedNotes[0];
  });

  afterEach(() => {
    vi.restoreAllMocks();
    appHandle.cleanup();
    dbHandle.client.close();
  });

  // -----------------------------------------------------------------------
  // Bob cannot GET alice's session by id
  //
  // Contract: 404 — getSession(db, sessionId, userId) returns null when the
  // session belongs to a different user. The route returns "Session not found"
  // with a 404, hiding the resource rather than revealing its existence with 403.
  // -----------------------------------------------------------------------

  it("Bob cannot GET alice's session by id → 404", async () => {
    const bobHeaders = await authHeaders('bob');
    const res = await appHandle.app.fetch(
      new Request(`http://test/api/sessions/${aliceSession.id}`, { headers: bobHeaders }),
      appHandle.env as any
    );
    // 404: session ownership check fails silently — resource is hidden from bob
    expect(res.status).toBe(404);
  });

  // -----------------------------------------------------------------------
  // Bob cannot POST a message to alice's session
  //
  // Contract: 404 — same getSession ownership guard used before message insert.
  // The session simply does not exist for bob.
  // -----------------------------------------------------------------------

  it("Bob cannot POST message to alice's session → 404", async () => {
    const bobHeaders = await authHeaders('bob');
    const res = await appHandle.app.fetch(
      new Request(`http://test/api/sessions/${aliceSession.id}/messages`, {
        method: 'POST',
        headers: { ...bobHeaders, 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: 'hello from bob' }),
      }),
      appHandle.env as any
    );
    // 404: session ownership check in POST /:sessionId/messages returns null → not found
    expect(res.status).toBe(404);
  });

  // -----------------------------------------------------------------------
  // Bob's transaction list does not contain alice's transactions
  //
  // Contract: 200 with an empty array — the route always applies
  // WHERE userId = bob's JWT sub, so alice's rows are never returned.
  // -----------------------------------------------------------------------

  it("Bob's transaction list does not contain alice's transactions → 200 empty", async () => {
    const bobHeaders = await authHeaders('bob');
    const res = await appHandle.app.fetch(
      new Request('http://test/api/transactions', { headers: bobHeaders }),
      appHandle.env as any
    );
    expect(res.status).toBe(200);
    const body = await res.json() as any[];
    // Bob has no transactions; alice's transaction must not appear
    expect(body).toHaveLength(0);
    const aliceTxInList = body.find((t: any) => t.userId === 'alice');
    expect(aliceTxInList).toBeUndefined();
  });

  // -----------------------------------------------------------------------
  // Bob cannot DELETE alice's transaction
  //
  // Contract: 404 — soft-delete WHERE (id = aliceTx.id AND userId = bob).
  // No rows match, so result.length === 0 → "Transaction not found" 404.
  // -----------------------------------------------------------------------

  it("Bob cannot DELETE alice's transaction → 404", async () => {
    const bobHeaders = await authHeaders('bob');
    const res = await appHandle.app.fetch(
      new Request(`http://test/api/transactions/${aliceTx.id}`, {
        method: 'DELETE',
        headers: bobHeaders,
      }),
      appHandle.env as any
    );
    // 404: the UPDATE WHERE (id AND userId=bob) matches nothing
    expect(res.status).toBe(404);
  });

  // -----------------------------------------------------------------------
  // Bob cannot GET alice's user note
  //
  // Contract: 404 — userNotesService.getNote(db, id, userId) filters by
  // (id AND userId). When userId is bob but the note belongs to alice, the
  // service returns null and the route responds with "Note not found" 404.
  // -----------------------------------------------------------------------

  it("Bob cannot GET alice's user note → 404", async () => {
    const bobHeaders = await authHeaders('bob');
    const res = await appHandle.app.fetch(
      new Request(`http://test/api/notes/${aliceNote.id}`, { headers: bobHeaders }),
      appHandle.env as any
    );
    // 404: note ownership check in userNotesService.getNote — resource hidden from bob
    expect(res.status).toBe(404);
  });
});

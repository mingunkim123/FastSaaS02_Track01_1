import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { eq, and, isNull } from 'drizzle-orm';
import { createTestDb, type TestDbHandle } from '../helpers/db';
import { createTestApp, type TestAppHandle } from '../helpers/app';
import { authHeaders } from '../helpers/auth';
import { mockLlmResponse } from '../helpers/llm-mock';
import { seedUser, seedSession } from '../helpers/fixtures';
import { transactions, chatMessages } from '../../src/db/schema';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function createSession(
  appHandle: TestAppHandle,
  headers: Record<string, string>,
  title = 'Test chat'
): Promise<number> {
  const res = await appHandle.app.fetch(
    new Request('http://test/api/sessions', {
      method: 'POST',
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ title }),
    }),
    appHandle.env as any
  );
  expect(res.status).toBe(201);
  const body = await res.json() as any;
  return body.session.id;
}

async function sendMessage(
  appHandle: TestAppHandle,
  headers: Record<string, string>,
  sessionId: number,
  content: string
) {
  return appHandle.app.fetch(
    new Request(`http://test/api/sessions/${sessionId}/messages`, {
      method: 'POST',
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ content }),
    }),
    appHandle.env as any
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('Chat flow — primary user journey', () => {
  let dbHandle: TestDbHandle;
  let appHandle: TestAppHandle;

  beforeEach(async () => {
    dbHandle = await createTestDb();
    await seedUser(dbHandle.db, { id: 'alice' });
    await seedUser(dbHandle.db, { id: 'bob' });
    appHandle = createTestApp(dbHandle);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    appHandle.cleanup();
    dbHandle.client.close();
  });

  // -----------------------------------------------------------------------
  // 1. create flow: session + message → transaction saved, two chat messages
  // -----------------------------------------------------------------------

  it('create action: response has two messages, DB has transaction and chat rows', async () => {
    const aliceHeaders = await authHeaders('alice');
    const sessionId = await createSession(appHandle, aliceHeaders);

    mockLlmResponse({
      type: 'create',
      payload: {
        transactionType: 'expense',
        amount: 12000,
        category: 'food',
        memo: 'lunch',
        date: '2026-04-13',
      },
      confidence: 0.95,
    });

    const res = await sendMessage(appHandle, aliceHeaders, sessionId, '점심 12000원');
    expect(res.status).toBe(200);

    const body = await res.json() as any;
    expect(body.success).toBe(true);
    expect(body.type).toBe('create');
    expect(body.messages).toHaveLength(2);
    expect(body.messages[0].role).toBe('user');
    expect(body.messages[1].role).toBe('assistant');

    // Verify DB: transaction row owned by alice
    const txRows = await dbHandle.db
      .select()
      .from(transactions)
      .where(and(eq(transactions.userId, 'alice'), isNull(transactions.deletedAt)));
    expect(txRows).toHaveLength(1);
    expect(txRows[0].amount).toBe(12000);
    expect(txRows[0].category).toBe('food');

    // Verify DB: two chat_messages rows for alice's session
    const msgRows = await dbHandle.db
      .select()
      .from(chatMessages)
      .where(eq(chatMessages.sessionId, sessionId));
    expect(msgRows).toHaveLength(2);
    expect(msgRows.map((m) => m.role).sort()).toEqual(['assistant', 'user']);
  });

  // -----------------------------------------------------------------------
  // 2. clarify → follow-up create: final transaction has correct userId
  // -----------------------------------------------------------------------

  it('clarify → create flow: final transaction created with alice userId', async () => {
    const aliceHeaders = await authHeaders('alice');
    const sessionId = await createSession(appHandle, aliceHeaders);

    // First message → AI asks for clarification
    mockLlmResponse({
      type: 'clarify',
      payload: {
        message: '얼마를 쓰셨나요?',
        missingFields: ['amount'],
        partialData: { transactionType: 'expense', category: 'food', memo: '커피' },
        confidence: 0.55,
      },
      confidence: 0.55,
    });

    const clarifyRes = await sendMessage(appHandle, aliceHeaders, sessionId, '커피 마셨어');
    expect(clarifyRes.status).toBe(200);
    const clarifyBody = await clarifyRes.json() as any;
    expect(clarifyBody.type).toBe('clarify');

    // Second message → AI creates the transaction
    mockLlmResponse({
      type: 'create',
      payload: {
        transactionType: 'expense',
        amount: 5000,
        category: 'food',
        memo: '커피',
        date: '2026-04-13',
      },
      confidence: 0.95,
    });

    const createRes = await sendMessage(appHandle, aliceHeaders, sessionId, '5000원이요');
    expect(createRes.status).toBe(200);
    const createBody = await createRes.json() as any;
    expect(createBody.success).toBe(true);

    // Verify the created transaction belongs to alice
    const txRows = await dbHandle.db
      .select()
      .from(transactions)
      .where(and(eq(transactions.userId, 'alice'), isNull(transactions.deletedAt)));
    expect(txRows.length).toBeGreaterThanOrEqual(1);
    const created = txRows.find((t) => t.amount === 5000);
    expect(created).toBeDefined();
    expect(created!.userId).toBe('alice');
  });

  // -----------------------------------------------------------------------
  // 3. report action: response has report data, NO transaction created
  // -----------------------------------------------------------------------

  it('report action: response contains report data and no transaction is created', async () => {
    const aliceHeaders = await authHeaders('alice');
    const sessionId = await createSession(appHandle, aliceHeaders);

    mockLlmResponse({
      type: 'report',
      payload: {
        reportType: 'monthly_summary',
        params: { month: '2026-04' },
      },
      confidence: 0.92,
    });

    const res = await sendMessage(appHandle, aliceHeaders, sessionId, '이번달 분석해줘');
    expect(res.status).toBe(200);

    const body = await res.json() as any;
    expect(body.success).toBe(true);
    expect(body.type).toBe('report');
    // AI message metadata should carry actionType: 'report'
    const aiMsg = body.messages.find((m: any) => m.role === 'assistant');
    expect(aiMsg).toBeDefined();
    expect(aiMsg.metadata?.actionType).toBe('report');

    // No transaction should have been created
    const txRows = await dbHandle.db
      .select()
      .from(transactions)
      .where(eq(transactions.userId, 'alice'));
    expect(txRows).toHaveLength(0);
  });

  // -----------------------------------------------------------------------
  // 4. read action: response contains alice's transactions only
  // -----------------------------------------------------------------------

  it('read action: response contains only alice\'s transactions', async () => {
    const aliceHeaders = await authHeaders('alice');
    const sessionId = await createSession(appHandle, aliceHeaders);

    mockLlmResponse({
      type: 'read',
      payload: {
        month: '2026-04',
      },
      confidence: 0.9,
    });

    const res = await sendMessage(appHandle, aliceHeaders, sessionId, '이번달 지출 보여줘');
    expect(res.status).toBe(200);

    const body = await res.json() as any;
    expect(body.success).toBe(true);
    expect(body.type).toBe('read');
    expect(body.messages).toHaveLength(2);

    const aiMsg = body.messages.find((m: any) => m.role === 'assistant');
    expect(aiMsg).toBeDefined();
    // The metadata actionType should be 'read'
    expect(aiMsg.metadata?.actionType).toBe('read');
  });
});

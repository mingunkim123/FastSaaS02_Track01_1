// backend/src/routes/waitlist.ts
//
// [공개] 출시 알림 이메일 수집 엔드포인트
// - `POST /waitlist` (주의: /api 프리픽스 미사용 — 인증 미들웨어 회피)
// - 스팸 방지를 위해 IP 기반 레이트 리밋 (1분에 5회)
// - Zod로 이메일 검증
// - 중복 이메일은 에러 대신 { alreadyRegistered: true }로 친절하게 응답

import { Hono } from 'hono';
import { z } from 'zod';
import { eq } from 'drizzle-orm';
import { getDb, type Env } from '../db/index';
import { waitlist } from '../db/schema';

const router = new Hono<{ Bindings: Env }>();

// IP별 레이트 리밋 (인메모리, isolate별)
// authMiddleware의 userId 기반 리미터를 쓸 수 없어 별도 구현
const ipStore = new Map<string, { count: number; windowStart: number }>();
const MAX_REQ = 5;
const WINDOW_MS = 60_000;

function getClientIp(c: { req: { header: (name: string) => string | undefined } }): string {
  return (
    c.req.header('CF-Connecting-IP') ||
    c.req.header('x-forwarded-for')?.split(',')[0]?.trim() ||
    'unknown'
  );
}

function checkRateLimit(ip: string): { limited: boolean; retryAfterSec: number } {
  const now = Date.now();
  const entry = ipStore.get(ip);

  if (!entry || now - entry.windowStart >= WINDOW_MS) {
    ipStore.set(ip, { count: 1, windowStart: now });
    // 메모리 누수 방지: 만료된 엔트리 정리
    for (const [k, v] of ipStore.entries()) {
      if (now - v.windowStart >= WINDOW_MS) ipStore.delete(k);
    }
    ipStore.set(ip, { count: 1, windowStart: now });
    return { limited: false, retryAfterSec: 0 };
  }

  if (entry.count >= MAX_REQ) {
    const retryAfterSec = Math.ceil((WINDOW_MS - (now - entry.windowStart)) / 1000);
    return { limited: true, retryAfterSec };
  }

  entry.count += 1;
  return { limited: false, retryAfterSec: 0 };
}

const bodySchema = z.object({
  email: z.string().trim().toLowerCase().email().max(320),
});

router.post('/', async (c) => {
  const ip = getClientIp(c);
  const rl = checkRateLimit(ip);
  if (rl.limited) {
    return c.json(
      { error: 'Too many requests' },
      429,
      { 'Retry-After': String(rl.retryAfterSec) }
    );
  }

  const raw = await c.req.json().catch(() => null);
  const parsed = bodySchema.safeParse(raw);
  if (!parsed.success) {
    return c.json({ error: 'Invalid email' }, 400);
  }
  const { email } = parsed.data;

  const db = getDb(c.env);

  const existing = await db
    .select({ id: waitlist.id })
    .from(waitlist)
    .where(eq(waitlist.email, email))
    .limit(1);

  if (existing.length > 0) {
    return c.json({ alreadyRegistered: true });
  }

  await db.insert(waitlist).values({
    id: crypto.randomUUID(),
    email,
  });

  return c.json({ success: true });
});

export default router;

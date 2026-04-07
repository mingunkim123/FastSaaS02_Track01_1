# Backend Architecture — 프론트/백엔드 데이터 교환 명세

## 개요

- **백엔드**: Cloudflare Workers + Hono 프레임워크, Turso(LibSQL) DB, Drizzle ORM
- **프론트엔드**: React + Vite, Supabase Auth
- **인증**: Supabase JWT (ES256 or HS256) → `Authorization: Bearer <token>`
- **모든 `/api/*` 경로**는 authMiddleware를 통과해야 함 (401 반환 시 제외)

---

## 공통 규칙

### 요청 헤더 (인증 필요 엔드포인트)
```
Authorization: Bearer <Supabase JWT>
Content-Type: application/json   ← POST/PUT 요청에만 포함
```

### 에러 응답 형식
| HTTP 상태 | 상황 | 응답 body |
|-----------|------|-----------|
| 400 | 입력값 검증 실패 (Zod) | `{ "error": "Validation failed", "details": [...] }` |
| 400 | 클라이언트 오류 (잘못된 값) | `{ "success": false, "error": "메시지" }` |
| 401 | 토큰 없거나 만료 | `{ "error": "Unauthorized" }` |
| 404 | 리소스 없음 | `{ "success": false, "error": "Transaction not found" }` |
| 500 | 서버 내부 오류 | `{ "error": "메시지" }` |
| 502 | AI 서비스 오류 | `{ "success": false, "error": "메시지" }` |

---

## 1. 사용자 (Users)

### `POST /api/users/sync`
OAuth 로그인 직후 사용자 정보를 백엔드 DB에 동기화 (upsert).

**요청 body:**
```json
{
  "email": "user@example.com",   // 선택
  "name": "홍길동",               // 선택
  "avatar_url": "https://...",   // 선택
  "provider": "google"           // 필수: OAuth 제공자
}
```

**응답 (200):**
```json
{ "success": true }
```

---

### `GET /api/users/me`
현재 로그인한 사용자 정보 조회.

**요청:** body 없음

**응답 (200):**
```json
{
  "id": "uuid-...",
  "email": "user@example.com",
  "name": "홍길동",
  "avatar_url": "https://...",
  "provider": "google",
  "created_at": "2024-01-01 12:00:00"
}
```

---

## 2. 거래 기록 (Transactions)

### `GET /api/transactions`
본인의 거래 기록 조회 (소프트 삭제된 항목 제외).

**쿼리 파라미터:**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `date` | string | 선택 | `YYYY-MM` 형식, 해당 월만 조회 |

**요청 예시:**
```
GET /api/transactions?date=2024-03
```

**응답 (200) — Transaction 배열:**
```json
[
  {
    "id": 1,
    "user_id": "uuid-...",
    "type": "expense",
    "amount": 12000,
    "category": "food",
    "memo": "점심",
    "date": "2024-03-15",
    "created_at": "2024-03-15 12:30:00",
    "deleted_at": null
  }
]
```

> 프론트 `api.ts`의 `Transaction` 타입과 매핑:
> - DB 컬럼 `user_id` → 프론트 타입 `user_id` (snake_case 그대로)
> - `deleted_at`는 프론트에 전달되나 UI에서 사용 안 함

---

### `POST /api/transactions`
새 거래 기록 저장.

**요청 body:**
```json
{
  "transactionType": "expense",   // 필수: "income" | "expense"
  "amount": 12000,                // 필수: 양의 정수, 최대 1,000,000,000
  "category": "food",             // 필수: 1~50자
  "memo": "점심",                 // 선택: 최대 500자
  "date": "2024-03-15"           // 필수: YYYY-MM-DD
}
```

> 프론트의 `api.addTransaction()`은 `{ type, ... }` 형태를 받아서 `transactionType`으로 변환해서 전송함.

**응답 (201):**
```json
{ "id": 42 }
```

**검증 규칙 (Zod — CreatePayloadSchema):**
- `transactionType`: `"income"` 또는 `"expense"` 중 하나 (type 필드로 와도 허용)
- `amount`: 양수, 최대 1,000,000,000
- `category`: 비어있지 않음, 최대 50자
- `memo`: 최대 500자 (선택)
- `date`: `YYYY-MM-DD` 정규식, 30일 초과 미래 날짜 불가

---

### `DELETE /api/transactions/:id`
거래 기록 소프트 삭제 (본인 소유만 가능).

**요청:** body 없음, URL에 id 포함

**응답 (200):**
```json
{ "success": true }
```

**응답 (404):**
```json
{ "success": false, "error": "Transaction not found" }
```

---

### `POST /api/transactions/:id/undo`
소프트 삭제된 거래 복원.

**요청:** body 없음

**응답 (200):**
```json
{
  "success": true,
  "message": "지출 ₩12,000 점심 (2024-03-15) 복원되었습니다",
  "result": {
    "id": 42,
    "user_id": "uuid-...",
    "type": "expense",
    "amount": 12000,
    "category": "food",
    "memo": "점심",
    "date": "2024-03-15",
    "created_at": "...",
    "deleted_at": null
  }
}
```

---

### `GET /api/transactions/summary`
월별 카테고리별 합계 조회 (통계 페이지용).

**쿼리 파라미터:**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `month` | string | 선택 | `YYYY-MM` 형식, 기본값: 현재 월 |

**응답 (200) — SummaryRow 배열:**
```json
[
  { "type": "expense", "category": "food",      "total": 150000 },
  { "type": "expense", "category": "transport", "total": 45000  },
  { "type": "income",  "category": "work",      "total": 3000000 }
]
```

> 같은 `(type, category)` 조합은 하나의 row로 집계됨.

---

## 3. AI 채팅 (AI)

### `POST /api/ai/action`
자연어 입력을 받아 의도를 파싱하고 해당 액션을 실행한 뒤 결과를 반환. 채팅 히스토리에도 자동 저장됨.

**요청 body:**
```json
{ "text": "오늘 점심 12000원 식비로 기록해줘" }
```

**처리 흐름:**
```
1. 사용자 메시지 → chat_messages 저장
2. 최근 거래 10건 + 사용자 카테고리 목록 조회
3. LLM 호출 → JSON 의도 파싱
4. Zod 검증 → DB 액션 실행
5. 어시스턴트 메시지 → chat_messages 저장
6. 응답 반환
```

**응답 공통 구조 (200):**
```json
{
  "success": true,
  "type": "create | update | read | delete | report",
  "result": { ... },        // 액션 결과 (타입마다 다름, 아래 참조)
  "message": "한국어 안내 메시지",
  "content": "한국어 안내 메시지",  // message와 동일 (호환성)
  "metadata": {
    "actionType": "create",
    "action": { ... }       // 액션 상세 (report는 report 필드 사용)
  }
}
```

#### type별 result 상세

**create:**
```json
{
  "result": {
    "id": 42, "user_id": "uuid-...", "type": "expense",
    "amount": 12000, "category": "food", "memo": "점심",
    "date": "2024-03-15", "created_at": "...", "deleted_at": null
  },
  "metadata": {
    "actionType": "create",
    "action": { "id": 42, "date": "2024-03-15", "category": "food", "amount": 12000, "type": "expense" }
  }
}
```

**update:**
```json
{
  "result": { /* 수정된 Transaction 전체 */ },
  "metadata": {
    "actionType": "update",
    "action": { "id": 42, "date": "...", "category": "...", "amount": 15000, "type": "expense" }
  }
}
```

**read:**
```json
{
  "result": [ /* Transaction 배열 */ ],
  "metadata": {
    "actionType": "read",
    "action": { "month": "2024-03", "category": null, "type": null, "count": 5 }
  }
}
```

**delete:**
```json
{
  "result": { "id": 42 },
  "metadata": {
    "actionType": "delete",
    "action": { "id": 42, "date": "...", "category": "...", "amount": 12000, "type": "expense" }
  }
}
```

**report:**
```json
{
  "message": "📊 Monthly Summary for 2024-03\n\nI've analyzed...",
  "content": "위와 동일",
  "metadata": {
    "actionType": "report",
    "report": {
      "reportType": "monthly_summary",
      "title": "Monthly Summary",
      "subtitle": "for 2024-03",
      "generatedAt": "2024-03-15T12:00:00.000Z",
      "sections": [
        {
          "type": "card | pie | bar | line | alert | suggestion",
          "title": "섹션 제목",
          "subtitle": "선택적 부제목",
          "metric": "₩150,000",
          "trend": "up | down | stable",
          "data": { /* 차트 데이터 */ }
        }
      ],
      "params": { "month": "2024-03" }
    }
  }
}
```

**LLM이 파싱하는 액션 JSON 내부 구조 (참고용):**
```json
{
  "type": "create | update | read | delete | report",
  "payload": { ... },
  "confidence": 0.95
}
```

---

### `GET /api/ai/chat/history`
채팅 히스토리 조회 (최신순, 페이지네이션 지원).

**쿼리 파라미터:**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `limit` | number | 선택 | 가져올 메시지 수 (기본값: 50) |
| `before` | number | 선택 | 이 ID보다 작은 메시지만 반환 (cursor 기반 페이지네이션) |

**응답 (200):**
```json
{
  "success": true,
  "messages": [
    {
      "id": 10,
      "role": "assistant",
      "content": "지출 ₩12,000 점심으로 2024-03-15에 저장되었습니다",
      "metadata": {
        "actionType": "create",
        "action": { "id": 42, "date": "2024-03-15", "category": "food", "amount": 12000, "type": "expense" }
      },
      "createdAt": "2024-03-15T12:30:00"
    },
    {
      "id": 9,
      "role": "user",
      "content": "오늘 점심 12000원 식비로 기록해줘",
      "metadata": null,
      "createdAt": "2024-03-15T12:29:50"
    }
  ]
}
```

> 최신 메시지가 먼저 오므로, 프론트에서 역순 정렬 필요.

---

### `DELETE /api/ai/chat/history`
현재 사용자의 채팅 히스토리 전체 삭제.

**요청:** body 없음

**응답 (200):**
```json
{ "success": true, "deletedCount": 42 }
```

---

## 4. DB 스키마 요약

### `users`
| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text PK | Supabase 사용자 UUID |
| `email` | text | 이메일 (nullable) |
| `name` | text | 이름 (nullable) |
| `avatar_url` | text | 프로필 이미지 (nullable) |
| `provider` | text NOT NULL | OAuth 제공자 (google 등) |
| `created_at` | text | 자동 생성 |

### `transactions`
| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | integer PK autoincrement | |
| `user_id` | text FK → users.id | |
| `type` | `"income"\|"expense"` | |
| `amount` | integer | 원(₩) 단위 |
| `category` | text | food, transport, work 등 |
| `memo` | text | nullable |
| `date` | text | YYYY-MM-DD |
| `created_at` | text | 자동 생성 |
| `deleted_at` | text | nullable, 소프트 삭제 타임스탬프 |

### `chat_messages`
| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | integer PK autoincrement | |
| `user_id` | text FK → users.id | |
| `role` | `"user"\|"assistant"` | |
| `content` | text | 메시지 내용 |
| `metadata` | text | JSON 문자열 (nullable), report 데이터 등 저장 |
| `created_at` | text | 자동 생성 |

---

## 5. 인증 흐름

```
프론트(Supabase 로그인) → JWT 발급
  → 모든 API 요청: Authorization: Bearer <JWT>
  → authMiddleware: JWT 서명 검증 (ES256 우선, HS256 폴백)
  → 검증 성공: payload.sub → userId로 Hono context에 저장
  → 이후 모든 라우트에서 c.get('userId') 사용
```

JWKS는 `https://<supabase-project>.supabase.co/auth/v1/.well-known/jwks.json`에서 가져오며 1시간 인메모리 캐싱.

---

## 6. CORS 허용 Origin

| Origin | 용도 |
|--------|------|
| `http://localhost:5173` | 개발 환경 |
| `capacitor://localhost` | 모바일 앱 (Capacitor) |
| `https://fastsaas02-track01-1.pages.dev` | Cloudflare Pages 프로덕션 |
| `https://fastsaas2.fastsaas2.workers.dev` | Workers 도메인 |

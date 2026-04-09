# RAG 완성 구현 계획 (2026-04-09)

**상태:** 설계 승인됨  
**목표:** VectorizeService, AI Service 통합, User Notes API, 지식 베이스 시드 데이터, 포괄적 테스트 완성  
**예상 기간:** 3-4 영업일 (단계별 순차 진행)

---

## 1. VectorizeService 완성 (Phase 1)

### 개요
Cloudflare Vectorize API를 활용한 벡터 임베딩 및 검색 기능 완성.

### 세부 단계

#### 1.1 벡터 검색 구현 (searchVectors 메서드)
**파일:** `/backend/src/services/vectorize.ts`

**작업:**
- `searchVectors()` 메서드 구현 (현재 placeholder)
  - 입력: embedding (number[]), table (string), limit (number), userId (선택)
  - 출력: { id, content, score }[] 배열
  - 구현 방식: 
    - Cloudflare Vectorize API `/search` 엔드포인트 호출
    - 코사인 유사도 기반 순위 정렬
    - userId가 제공되면 사용자별 필터링
  - 에러 처리: API 실패 시 빈 배열 반환 (graceful fallback)

**테스트:**
```bash
npm test -- vectorize.test.ts
```

#### 1.2 재시도 로직 추가
**파일:** `/backend/src/services/vectorize.ts`

**작업:**
- 3회 재시도 로직 (exponential backoff)
  - 첫 시도: 즉시
  - 1회 실패 후: 100ms 대기
  - 2회 실패 후: 300ms 대기
  - 3회 실패 후: 실패 로그 및 empty 반환
- 타임아웃: 2초

**수정 위치:**
- `embedText()` 메서드
- `searchVectors()` 메서드

#### 1.3 타입 정의 완성
**파일:** `/backend/src/types/rag.ts`

**확인 사항:**
- VectorResult, VectorSearchRequest, ContextItem, ContextData, RetrievalStrategy 정의 ✓ (이미 완성)
- EmbeddingResponse 정의 ✓ (이미 완성)

### 파일 수정 목록
- `/backend/src/services/vectorize.ts` - searchVectors 구현 및 재시도 로직

### 검증 방법
1. 단위 테스트: `npm test -- vectorize.test.ts` (신규 생성)
2. Cloudflare 환경에서 통합 테스트
3. Mock Vectorize API로 오프라인 테스트

---

## 2. AI Service 통합 (Phase 2)

### 개요
ContextService를 AIService에 통합하고 `/api/sessions/:sessionId/messages` 엔드포인트에서 context 주입.

### 세부 단계

#### 2.1 AIService.parseUserInput() 수정
**파일:** `/backend/src/services/ai.ts`

**현재 상태:**
```typescript
async parseUserInput(
  userText: string,
  recentTransactions: Transaction[],
  userCategories: string[],
  userId?: string,
  contextService?: any,
  db?: any
): Promise<TransactionAction>
```

**필수 수정:**
- `contextService` 파라미터 required로 변경 (선택사항 → 필수)
- `db` 파라미터 required로 변경
- 메서드 내 context 구성 로직:
  1. actionType 결정 후
  2. `contextService.getContextForAction(db, userId, actionType, userText)` 호출
  3. 반환된 `contextData.formatted` 문자열을 system message로 추가
  4. LLM 호출 시 context 포함 messages array 전달

**코드 위치:**
- 행 104-196: parseUserInput 메서드

**변경 상세:**
```typescript
// 기존
const messages: any[] = [
  { role: 'system', content: systemPrompt },
];

messages.push({
  role: 'user',
  content: baseContextMessage,
});

// 변경 후
const messages: any[] = [
  { role: 'system', content: systemPrompt },
];

// NEW: 컨텍스트 추가
if (contextData?.formatted) {
  messages.push({
    role: 'system',
    content: contextData.formatted,
  });
}

messages.push({
  role: 'user',
  content: baseContextMessage,
});
```

#### 2.2 /api/sessions/:sessionId/messages 엔드포인트 수정
**파일:** `/backend/src/routes/sessions.ts`

**현재 상태:**
- 행 314-359: POST /:sessionId/messages 라우트
- `contextService` 생성: `const contextService = new ContextService(c.env.VECTORIZE);` (행 358)

**필수 수정:**
1. ContextService 초기화 시 VectorizeService 주입:
   ```typescript
   const vectorizeService = new VectorizeService(
     c.env.CLOUDFLARE_ACCOUNT_ID,
     c.env.CLOUDFLARE_API_TOKEN
   );
   const contextService = new ContextService(vectorizeService);
   ```

2. AIService.parseUserInput 호출 시 모든 파라미터 전달 (행 438-445):
   ```typescript
   const action = await aiService.parseUserInput(
     content,
     transactions_,
     userCategories,
     userId,
     contextService,
     db
   );
   ```

**환경 변수 확인:**
- `CLOUDFLARE_ACCOUNT_ID` (wrangler.toml)
- `CLOUDFLARE_API_TOKEN` (wrangler.toml)

### 파일 수정 목록
- `/backend/src/services/ai.ts` - context 통합 로직
- `/backend/src/routes/sessions.ts` - VectorizeService 주입 및 파라미터 전달

### 검증 방법
1. 단위 테스트: `npm test -- ai.test.ts`
2. 통합 테스트: `npm test -- chat-workflow.integration.test.ts`
3. E2E 테스트: `/api/sessions/:sessionId/messages` POST 요청으로 context 주입 확인

---

## 3. User Notes API 구현 (Phase 3)

### 개요
User Notes의 CRUD 엔드포인트 완성 및 벡터화 통합.

### 현재 상태 검토
**파일들:**
- `/backend/src/services/user-notes.ts` - 서비스 레이어 ✓ (완성)
- `/backend/src/routes/user-notes.ts` - 라우트 ✓ (완성)
- `/backend/src/db/schema.ts` - user_notes 테이블 정의 ✓ (완성)

### 세부 단계

#### 3.1 VectorizeService 주입 확인
**파일:** `/backend/src/routes/user-notes.ts`

**확인 사항:**
- `createUserNotesRoutes()` 함수가 `userNotesService`를 받고 있는지 확인
- userNotesService 내부에 VectorizeService가 주입되어 있는지 확인

**필수 수정 (백엔드 진입점):**
**파일:** `/backend/src/index.ts`

현재 상태: user-notes 라우트가 마운트되지 않음 (행 39 없음)

**추가 필요:**
```typescript
import { userNotesRoutes } from './routes/user-notes';
import { userNotesService } from './services/user-notes';
import { VectorizeService } from './services/vectorize';

// 라우트 마운트 섹션에 추가 (행 39 이후)
const vectorizeService = new VectorizeService(
  env.CLOUDFLARE_ACCOUNT_ID,
  env.CLOUDFLARE_API_TOKEN
);
const notesService = userNotesService(vectorizeService);
app.route('/api/notes', userNotesRoutes(notesService));
```

#### 3.2 API 엔드포인트 검증
**완성된 엔드포인트:**

| 메서드 | 경로 | 상태 | 설명 |
|--------|------|------|------|
| POST | /api/notes | ✓ | 노트 생성 + 벡터화 |
| GET | /api/notes | ✓ | 사용자의 모든 노트 조회 |
| GET | /api/notes/:id | ✓ | 단일 노트 조회 |
| PATCH | /api/notes/:id | ✓ | 노트 수정 + 재벡터화 |
| DELETE | /api/notes/:id | ✓ | 노트 삭제 |

#### 3.3 요청/응답 형식 확정

**POST /api/notes (생성)**
```json
{
  "content": "I prefer to save 30% of income monthly"
}
```

응답 (201):
```json
{
  "id": 1,
  "userId": "user123",
  "content": "I prefer to save 30% of income monthly",
  "embeddingId": "note-1712704800000",
  "createdAt": "2026-04-09T10:00:00Z",
  "updatedAt": "2026-04-09T10:00:00Z"
}
```

**PATCH /api/notes/:id (수정)**
```json
{
  "content": "Updated: I prefer to save 40% of income monthly"
}
```

응답 (200): 위와 동일한 형식 + updatedAt 갱신

**GET /api/notes (조회)**
응답 (200):
```json
[
  {
    "id": 1,
    "userId": "user123",
    "content": "My note",
    "embeddingId": "note-1712704800000",
    "createdAt": "2026-04-09T10:00:00Z",
    "updatedAt": "2026-04-09T10:00:00Z"
  }
]
```

**DELETE /api/notes/:id**
응답 (200):
```json
{
  "success": true
}
```

### 파일 수정 목록
- `/backend/src/index.ts` - user-notes 라우트 마운트 및 서비스 주입

### 검증 방법
1. 단위 테스트: `npm test -- user-notes.test.ts` (이미 존재)
2. 라우트 테스트: CRUD 엔드포인트 호출 확인
3. 벡터화 확인: embeddingId가 생성/수정 시 갱신되는지 확인

---

## 4. 지식 베이스 시드 데이터 (Phase 4)

### 개요
개발/테스트용 20-30개 지식 베이스 항목 생성.

### 현재 상태
**파일:** `/backend/src/db/seeds/knowledge-base.ts`
- 현재: 14개 항목 (budgeting, savings, investment, debt, credit, tax, general)

### 세부 단계

#### 4.1 시드 데이터 확장
**파일:** `/backend/src/db/seeds/knowledge-base.ts`

**추가 카테고리 및 항목:**

**추가 항목 (16개):**
1. **budgeting (추가 2개)**
   - "Zero-based budgeting: allocate every dollar you earn to specific categories"
   - "50/30/20 rule alternative: use 70/20/10 (70% needs, 20% wants, 10% goals)"

2. **spending_analysis (신규 3개)**
   - "Track your top spending categories monthly to identify patterns and opportunities to save"
   - "Anomaly detection: spending 2x or more above your average in a category signals unusual behavior"
   - "Weekly spending reviews: spend 15 minutes each Sunday reviewing the past week's expenses"

3. **transaction_tips (신규 3개)**
   - "Always categorize transactions immediately to maintain accurate financial records"
   - "Use descriptive memos for large or unclear transactions to understand spending habits"
   - "Round amounts up slightly when budgeting to account for unexpected costs"

4. **goal_setting (신규 3개)**
   - "SMART goals: make your financial goals Specific, Measurable, Achievable, Relevant, Time-bound"
   - "Break large financial goals into monthly or weekly targets for better progress tracking"
   - "Review financial goals quarterly and adjust based on income changes or life events"

5. **income_management (신규 2개)**
   - "Income stability: if self-employed, average income over 3 months for more realistic budgeting"
   - "Bonus handling: allocate 50% to savings, 30% to debt payoff, 20% to discretionary spending"

6. **seasonal_planning (신규 2개)**
   - "Plan for seasonal expenses in advance: holidays, insurance renewals, vacation"
   - "Create a sinking fund by setting aside small amounts monthly for annual or irregular expenses"

**총 항목:** 14 + 16 = 30개

#### 4.2 시드 실행
**명령어:**
```bash
cd backend
npm run seed
```

**예상 로그:**
```
Successfully seeded 30 knowledge base items
```

### 파일 수정 목록
- `/backend/src/db/seeds/knowledge-base.ts` - KNOWLEDGE_ITEMS 배열 확장

### 검증 방법
1. 시드 실행: `npm run seed`
2. DB 확인: knowledge_base 테이블에 30개 행 존재 확인
3. 카테고리 분포: 각 카테고리별 항목 수 확인
4. 벡터화 검증: embeddingId 필드 채워지는지 확인 (embedding 호출 성공 시)

---

## 5. 포괄적 테스트 (Phase 5)

### 개요
6-7개 테스트 파일로 RAG 기능 전체 검증.

### 신규 생성 테스트 파일

#### 5.1 VectorizeService 테스트
**파일:** `/backend/tests/services/vectorize.test.ts`

**테스트 케이스:**
```typescript
describe('VectorizeService', () => {
  // embedText() 테스트
  - embedText with valid text
  - embedText with empty text
  - embedText handles API errors gracefully
  - embedText retries on failure (3 times)
  
  // searchVectors() 테스트
  - searchVectors returns results with scores
  - searchVectors filters by userId
  - searchVectors respects limit parameter
  - searchVectors returns empty array on error
  - searchVectors applies cosine similarity scoring
})
```

**Mock:** Cloudflare Vectorize API

#### 5.2 ContextService 테스트
**파일:** `/backend/tests/services/context.test.ts`

**테스트 케이스:**
```typescript
describe('ContextService', () => {
  // getContextForAction() 테스트
  - getContextForAction for CREATE action (3 items)
  - getContextForAction for READ action (15 items)
  - getContextForAction for REPORT action (15 items)
  - getContextForAction for CLARIFY action (5 items)
  - getContextForAction for plain_text action (0 items)
  - getContextForAction retrieves from all three sources
  - getContextForAction formats message correctly
  
  // 검색 전략 테스트
  - Retrieval strategy per action type
  - Knowledge base items retrieved
  - Transaction context retrieved with user filter
  - User notes retrieved with user filter
})
```

**Mock:** VectorizeService, Database

#### 5.3 UserNotesService 테스트
**파일:** `/backend/tests/services/user-notes.test.ts` (기존 확장)

**추가 테스트 케이스:**
```typescript
describe('UserNotesService - Extended', () => {
  - vectorization on create note
  - vectorization on update note
  - embeddingId generated and stored
  - embeddingId updated on content change
  - list notes ordered by updatedAt
  - ownership verification on update/delete
})
```

#### 5.4 AI Service 통합 테스트
**파일:** `/backend/tests/services/ai-integration.test.ts` (신규)

**테스트 케이스:**
```typescript
describe('AIService with ContextService', () => {
  - parseUserInput includes context in LLM messages
  - context formatted as system message
  - context injection for CREATE action (minimal)
  - context injection for READ action (rich)
  - context injection for REPORT action (rich)
  - context injection for CLARIFY action (moderate)
  - graceful fallback when context service fails
  - no context for plain_text action
})
```

**Mock:** LLM API, ContextService

#### 5.5 User Notes Routes 테스트
**파일:** `/backend/tests/routes/user-notes.test.ts` (기존 확장)

**추가 테스트 케이스:**
```typescript
describe('User Notes Routes - Extended', () => {
  - create note returns 201
  - create note with vectorization
  - update note updates embeddingId
  - delete note removes from DB
  - list notes returns array
  - get note by id with ownership check
  - 400 error on missing content
  - 404 error on unauthorized access
  - 500 error handling
})
```

#### 5.6 Sessions Route with Context 테스트
**파일:** `/backend/tests/routes/sessions-context.test.ts` (신규)

**테스트 케이스:**
```typescript
describe('Sessions Route - Context Integration', () => {
  - POST /:sessionId/messages with context
  - context injected into AI response generation
  - context from knowledge base included
  - context from user transactions included
  - context from user notes included
  - context formatting in AI system prompt
  - graceful degradation without context
  - user message saved correctly
  - AI message saved with correct metadata
})
```

**Mock:** LLM API, ContextService, VectorizeService

#### 5.7 Knowledge Base Seed 테스트
**파일:** `/backend/tests/seeds/knowledge-base.test.ts` (확장)

**테스트 케이스:**
```typescript
describe('Knowledge Base Seed', () => {
  - seed inserts correct number of items (30)
  - seed respects idempotency (no duplicate on re-run)
  - all items have content
  - categories are valid (budgeting, savings, etc.)
  - items are retrievable from DB
  - seed creates proper indexes
})
```

### 테스트 실행 명령어

```bash
# 전체 테스트
npm test

# 개별 테스트
npm test -- vectorize.test.ts
npm test -- context.test.ts
npm test -- user-notes.test.ts
npm test -- ai-integration.test.ts
npm test -- sessions-context.test.ts
npm test -- knowledge-base.test.ts

# 특정 테스트 케이스
npm test -- vectorize.test.ts -t "embedText"
npm test -- context.test.ts -t "getContextForAction"

# 커버리지 리포트
npm test -- --coverage
```

### 테스트 파일 생성 체크리스트

| 파일 | 상태 | 케이스 수 |
|------|------|---------|
| vectorize.test.ts | 신규 | 8 |
| context.test.ts | 신규 | 12 |
| user-notes.test.ts | 확장 | +6 |
| ai-integration.test.ts | 신규 | 8 |
| sessions-context.test.ts | 신규 | 10 |
| knowledge-base.test.ts | 확장 | +5 |
| **합계** | - | **49+** |

### 파일 수정/생성 목록
- `/backend/tests/services/vectorize.test.ts` - 신규 생성
- `/backend/tests/services/context.test.ts` - 신규 생성
- `/backend/tests/services/ai-integration.test.ts` - 신규 생성
- `/backend/tests/services/user-notes.test.ts` - 확장
- `/backend/tests/routes/sessions-context.test.ts` - 신규 생성
- `/backend/tests/seeds/knowledge-base.test.ts` - 확장

### 테스트 커버리지 목표
- 서비스 레이어: 90%+
- 라우트 레이어: 85%+
- 전체: 85%+

### 검증 방법
1. 모든 테스트 통과: `npm test` (exit code 0)
2. 커버리지 확인: `npm test -- --coverage`
3. 특정 기능별 테스트: 각 단계별 수동 검증

---

## 구현 순서 및 의존성

```
Phase 1: VectorizeService
  ├─ searchVectors 구현
  ├─ 재시도 로직
  └─ vectorize.test.ts

    ↓ (VectorizeService 완성 후)

Phase 2: AI Service 통합
  ├─ AIService.parseUserInput 수정
  ├─ /api/sessions/:sessionId/messages 수정
  ├─ ai-integration.test.ts
  └─ sessions-context.test.ts

    ↓ (AI 통합 완성 후)

Phase 3: User Notes API
  ├─ /backend/src/index.ts에 라우트 마운트
  ├─ user-notes.test.ts 확장
  └─ 엔드포인트 검증

    ↓ (API 완성 후)

Phase 4: 지식 베이스 시드
  ├─ knowledge-base.ts 확장 (30개 항목)
  ├─ knowledge-base.test.ts 확장
  └─ npm run seed 실행

    ↓ (시드 데이터 준비 후)

Phase 5: 포괄적 테스트
  ├─ context.test.ts
  └─ 모든 테스트 통과 확인
```

---

## 환경 변수 및 설정

### 필수 환경 변수 (wrangler.toml)
```toml
[env.development]
vars = {
  CLOUDFLARE_ACCOUNT_ID = "your-account-id",
  CLOUDFLARE_API_TOKEN = "your-api-token",
  # ... 기존 변수들
}
```

### 데이터베이스 마이그레이션
```bash
# user_notes 테이블이 없으면 생성
npx drizzle-kit generate
npx drizzle-kit migrate
```

---

## 테스트 체크리스트

### Phase 1: VectorizeService 완성
- [ ] searchVectors 메서드 구현
- [ ] 재시도 로직 추가
- [ ] 에러 처리 확인
- [ ] vectorize.test.ts 모두 통과
- [ ] Cloudflare 환경에서 통합 테스트

### Phase 2: AI Service 통합
- [ ] AIService.parseUserInput() 수정
- [ ] /api/sessions/:sessionId/messages 수정
- [ ] context 주입 확인 (로그 확인)
- [ ] ai-integration.test.ts 모두 통과
- [ ] sessions-context.test.ts 모두 통과
- [ ] 수동 테스트: /api/sessions/1/messages POST로 context 확인

### Phase 3: User Notes API
- [ ] /backend/src/index.ts에 라우트 마운트
- [ ] POST /api/notes 엔드포인트 테스트
- [ ] GET /api/notes 엔드포인트 테스트
- [ ] GET /api/notes/:id 엔드포인트 테스트
- [ ] PATCH /api/notes/:id 엔드포인트 테스트
- [ ] DELETE /api/notes/:id 엔드포인트 테스트
- [ ] user-notes.test.ts 모두 통과

### Phase 4: 지식 베이스 시드
- [ ] KNOWLEDGE_ITEMS 배열 30개 항목으로 확장
- [ ] npm run seed 실행
- [ ] DB에 30개 행 확인
- [ ] knowledge-base.test.ts 모두 통과

### Phase 5: 포괄적 테스트
- [ ] context.test.ts 모두 통과
- [ ] vectorize.test.ts 모두 통과
- [ ] ai-integration.test.ts 모두 통과
- [ ] sessions-context.test.ts 모두 통과
- [ ] user-notes.test.ts (확장) 모두 통과
- [ ] knowledge-base.test.ts (확장) 모두 통과
- [ ] npm test 전체 통과 (49+ 테스트)
- [ ] 커버리지 85%+ 달성

---

## 주요 파일 수정 요약

| 파일 | 수정 내용 | 라인 | 우선순위 |
|------|---------|------|---------|
| `/backend/src/services/vectorize.ts` | searchVectors 구현 | 46-60 | 1순위 |
| `/backend/src/services/ai.ts` | context 통합 | 145-175 | 2순위 |
| `/backend/src/routes/sessions.ts` | VectorizeService 주입 | 357-359 | 2순위 |
| `/backend/src/index.ts` | user-notes 라우트 마운트 | 39+ | 3순위 |
| `/backend/src/db/seeds/knowledge-base.ts` | 30개 항목 확장 | 5-62 | 4순위 |
| `/backend/tests/services/vectorize.test.ts` | 신규 생성 | - | 5순위 |
| `/backend/tests/services/context.test.ts` | 신규 생성 | - | 5순위 |
| `/backend/tests/services/ai-integration.test.ts` | 신규 생성 | - | 5순위 |
| `/backend/tests/routes/sessions-context.test.ts` | 신규 생성 | - | 5순위 |

---

## Critical Files for Implementation

- `/backend/src/services/vectorize.ts`
- `/backend/src/services/ai.ts`
- `/backend/src/routes/sessions.ts`
- `/backend/src/index.ts`
- `/backend/src/db/seeds/knowledge-base.ts`

---

이 계획은 설계 사양(2026-04-08-rag-context-enhancement-design.md)을 기반으로 작성되었으며, 단계별 순차 진행으로 의존성을 최소화하고 검증 가능성을 최대화합니다.

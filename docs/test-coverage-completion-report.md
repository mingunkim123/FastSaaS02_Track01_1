# 테스트 커버리지 확장 완료 보고서

**날짜:** 2026-04-13  
**작업 범위:** 백엔드 (`backend/src/`) 전체 — 유닛, 통합, E2E, LLM 스모크  
**작업 결과:** 베이스라인 372개 → **627개** 통과 (+255개 신규 테스트)

---

## 1. 작업 요약

보안 위험도 우선순위에 따라 4개 계층으로 테스트를 확장했습니다. 모든 인증 라우트가 실제 HS256 JWT와 실제 인메모리 SQLite DB를 사용해 사용자별 데이터 격리를 검증합니다.

### 핵심 원칙
- **실제 DB**: `@libsql/client :memory:` + 마이그레이션 적용 (모의 체인 아님)
- **실제 JWT**: 테스트 전용 HS256 서명 → 프로덕션 `verifyJWT` 통과 확인
- **LLM 경계 모킹**: `callLLM` spy로 결정론적 테스트, 별도 LLM 스모크 스위트 분리
- **보안 계약**: 모든 인증 라우트에 `expectAuthContract()` 적용 의무화

---

## 2. 신규 파일 목록

### 테스트 헬퍼 (5개 공유 인프라)

| 파일 | 역할 |
|------|------|
| `tests/helpers/db.ts` | `createTestDb()` — 인메모리 libsql + 마이그레이션 적용 |
| `tests/helpers/auth.ts` | `signTestJwt()`, `authHeaders()` — HS256 테스트 JWT 생성 |
| `tests/helpers/llm-mock.ts` | `mockLlmResponse()` — `callLLM` spy |
| `tests/helpers/fixtures.ts` | `seedUser()`, `seedSession()`, `seedTransaction()` |
| `tests/helpers/app.ts` | `createTestApp()` — Hono 앱을 인메모리 DB에 연결 |
| `tests/helpers/auth-contract.ts` | `expectAuthContract()` — 3가지 공통 인증 실패 시나리오 |
| `tests/helpers/init.sql` | 테스트 전용 기본 스키마 (프로덕션 마이그레이션 디렉토리 외부) |

### Tier 1 — 보안 핵심 (65개 테스트)

| 파일 | 커버 시나리오 |
|------|--------------|
| `tests/unit/routes/sessions.test.ts` | 인증 계약, create/clarify/report/plain_text 흐름, 속도 제한, 교차 사용자 격리 |
| `tests/unit/middleware/rateLimit.test.ts` | 창(window), 사용자별 격리, 시간 리셋 |
| `tests/unit/services/clarifications.test.ts` | userId 격리, 상태 머신, 병합 보호 |
| `tests/unit/routes/ai.test.ts` | 세션 소유권 확인, 액션 타입, 교차 사용자 403/404 |
| `tests/unit/routes/reports.test.ts` | userId 필터링, 속도 제한, 빈 결과 |

### Tier 2 — 정확성 핵심 (55개 테스트)

| 파일 | 커버 시나리오 |
|------|--------------|
| `tests/unit/services/ai.test.ts` | `parseUserInput` — JSON 파싱, 오류 폴백, 신뢰도 분기 |
| `tests/unit/services/sessions.test.ts` | CRUD + 소유권 (실제 DB) |
| `tests/unit/services/reports.test.ts` | 집계 수학, 날짜 필터, 소프트 삭제 제외 |
| `tests/unit/services/context.test.ts` | userId 필터링 (실제 DB) |
| `tests/unit/services/ai-report.test.ts` | 모킹된 LLM으로 보고서 구조 검증 |

### Tier 3 — 기능 완성도 (63개 테스트)

| 파일 | 커버 시나리오 |
|------|--------------|
| `tests/unit/services/user-notes.test.ts` | CRUD 격리, 벡터화 모킹, 벡터 실패 시 노트 보존 |
| `tests/unit/services/vectorize.test.ts` | userId별 검색 격리, API 오류 처리 |
| `tests/unit/routes/users.test.ts` | `/me` 엔드포인트, 다른 사용자 프로필 차단 |
| `tests/unit/routes/user-notes.test.ts` | JWT의 userId 사용, 교차 사용자 404, 목록 격리 |
| `tests/unit/middleware/logging.test.ts` | Authorization 헤더 마스킹, PII 미노출, 로깅 실패 시 요청 지속 |

### Tier 4 — E2E (24개 테스트)

| 파일 | 커버 시나리오 |
|------|--------------|
| `tests/e2e/auth.e2e.test.ts` | 모든 보호 라우트 401, 만료 JWT, CORS |
| `tests/e2e/chat-flow.e2e.test.ts` | 생성→검증, 명확화→병합→생성, 보고서, 읽기 |
| `tests/e2e/reports.e2e.test.ts` | 사용자별 보고서 격리, 빈 결과, 유효성 검사 |
| `tests/e2e/isolation.e2e.test.ts` | **보안 키스톤** — 교차 사용자 공격 5개 시나리오 (각각 독립 테스트) |

### LLM 스모크 (11개 테스트, `RUN_LLM_TESTS=1`로 게이팅)

| 파일 | 설명 |
|------|------|
| `tests/llm-smoke/ai-parse.llm.test.ts` | create/report/clarify 액션 구조 검증 |
| `tests/llm-smoke/clarifications.llm.test.ts` | 명확화 병합 로직 |

---

## 3. 인프라 변경사항

| 파일 | 변경 내용 |
|------|----------|
| `backend/src/db/index.ts` | `createDb(client)` 추가 — 테스트 주입 심(seam) |
| `backend/vitest.config.ts` | unit/integration/e2e 프로젝트 분리 |
| `backend/vitest.llm.config.ts` | LLM 스모크 스위트 전용 설정 |
| `backend/tests/setup-env.ts` | 결정론적 테스트 환경 변수 (JWT secret, ENVIRONMENT=test 등) |
| `backend/package.json` | `test:unit`, `test:integration`, `test:e2e`, `test:llm`, `test:coverage` 스크립트 추가 |
| `docs/testing.md` | 테스트 가이드 (헬퍼 참조, 새 라우트 추가 템플릿, 알려진 이슈) |
| `CLAUDE.md` | Critical Security Invariants에 `expectAuthContract` 사용 의무 추가 |

---

## 4. 테스트 결과

```
베이스라인:  372개 통과 / 64개 실패 / 436개 합계
최종:       627개 통과 / 64개 실패 / 691개 합계
신규 추가:  +255개 통과
소요 시간:  ~9.5초 (60초 목표 대비 충분)
```

**64개 기존 실패 (이 작업 전부터 존재, 변경 없음):**
- `tests/routes/ai.test.ts` — `.get()` 미구현 모의 체인 (기존 코드 문제)
- `tests/services/ai-report.test.ts` — Workers AI 바인딩 없이 실제 LLM 호출
- `tests/integration/chat-workflow.integration.test.ts` — Workers AI 바인딩 누락
- `tests/integration/ai-report-workflow.integration.test.ts` — Workers AI 바인딩 누락

---

## 5. 테스트 중 발견된 이슈

### 버그: `ReportService.getReports` 이중 `.where()` 체인

**위치:** `backend/src/services/reports.ts`  
**증상:** `month` 파라미터 제공 시 Drizzle `.where()` 두 번 체인 → SQL 구문 오류 (`near ')': syntax error`)  
**재현:** `tests/e2e/reports.e2e.test.ts` 라인 132 (TODO 주석 포함)  
**수정 방법:** 두 `where` 조건을 `and(condition1, condition2)`로 병합

### 발견된 보안 계약

**교차 사용자 접근 → 404 (403 아님)**  
모든 라우트가 `getSession(db, id, userId)` / 서비스 레이어 쿼리로 `(id AND userId)` 필터링 후 null 반환 시 404. "리소스 숨김(resource hidden)" 패턴 — 의도적인 설계. `isolation.e2e.test.ts` 각 테스트에 계약 주석 포함.

---

## 6. LLM 스모크 제한사항

`@cloudflare/vitest-pool-workers`는 Vitest ≤ 2.x를 요구하지만 현재 프로젝트는 Vitest 4.x 사용. 현재 스모크 테스트는 `mockLlmResponse`를 사용해 구조적 어설션을 문서화함. 실제 Workers AI 바인딩 테스트를 원한다면:
- Vitest를 `^2.x`로 다운그레이드 후 `vitest.llm.config.ts`에서 `defineWorkersConfig` 사용
- 또는 `wrangler dev` + HTTP 클라이언트로 외부 테스트 실행

---

## 7. 테스트 실행 방법

```bash
cd backend

# 전체 스위트
npm run test

# 계층별 실행
npm run test:unit
npm run test:integration
npm run test:e2e

# LLM 스모크 (게이팅됨)
npm run test:llm

# 커버리지 리포트
npm run test:coverage
```

---

## 8. Git 태그

| 태그 | 의미 |
|------|------|
| `phase-1-foundation` | 테스트 인프라 완성 |
| `tier-1-complete` | 보안 핵심 테스트 완성 |
| `tier-2-complete` | 정확성 핵심 테스트 완성 |
| `tier-3-complete` | 기능 완성도 테스트 완성 |
| `tier-4-complete` | E2E 테스트 완성 |
| `test-coverage-expansion-complete` | 전체 작업 완성 |

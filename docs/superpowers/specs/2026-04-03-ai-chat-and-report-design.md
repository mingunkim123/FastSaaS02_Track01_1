# AI 채팅 프론트엔드 + 인라인 리포트 설계

## 개요

기존 백엔드 AI(`POST /api/ai/action`)에 ChatGPT 스타일 프론트엔드를 연결하고, 리포트 기능을 채팅 안에서 인라인으로 제공한다. 대화 히스토리는 DB에 영구 저장한다.

## 결정 사항

- **접근 방식**: 단일 엔드포인트 확장 (기존 `/api/ai/action`에 REPORT 타입 추가)
- **대화 저장**: DB 영구 저장 (`chat_messages` 테이블)
- **채팅 범위**: CRUD + 리포트까지 채팅에서 처리
- **네비게이션**: CREATE/UPDATE/DELETE → 캘린더(해당 날짜), READ/REPORT → 통계 페이지
- **차트 수준**: 섹션별로 다르게 (간단한 카드 ~ Recharts 풍부한 차트)
- **탭 위치**: 맨 오른쪽 (기록 / 달력 / 통계 / AI)

---

## 1. 데이터 모델

### 새 테이블: `chat_messages`

| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | integer (PK, auto-increment) | |
| userId | text (FK → users.id) | |
| role | text | 'user' \| 'assistant' |
| content | text | 사용자 입력 또는 AI 텍스트 응답 |
| metadata | text (nullable) | JSON — AI 액션 결과, 차트 데이터, 네비게이션 정보 |
| createdAt | text | datetime('now') |

### metadata JSON 구조

**CRUD 액션 결과:**

```json
{
  "actionType": "CREATE",
  "transaction": { "id": 42, "amount": 8000, "category": "식비", "date": "2026-04-03" },
  "navigation": { "page": "/calendar", "params": { "date": "2026-04-03" } }
}
```

**리포트 결과:**

```json
{
  "actionType": "REPORT",
  "reportType": "monthly_summary",
  "sections": [ ... ]
}
```

기존 `transactions` 테이블은 변경 없음.

---

## 2. 백엔드 API 변경

### 기존 `POST /api/ai/action` 확장

AI 파싱 타입에 `REPORT` 추가: `CREATE | READ | UPDATE | DELETE | REPORT`

REPORT payload:

```json
{
  "reportType": "monthly_summary" | "category_detail" | "spending_pattern" | "anomaly" | "suggestion",
  "params": { "month": "2026-04", "category": "식비" }
}
```

REPORT 처리 흐름:
1. AI가 사용자 입력 파싱 → `type: "REPORT"`, reportType/params 결정
2. 백엔드가 해당 월 트랜잭션 데이터를 DB에서 조회
3. 조회된 데이터를 AI에게 다시 전달 → AI가 분석 텍스트 + 차트용 구조화 데이터 생성
4. 응답: `{ message: "...", chartData: {...}, sections: [...] }`

### 새 엔드포인트: 채팅 히스토리

- `GET /api/ai/chat/history?limit=50&before={messageId}` — 사용자의 대화 기록 조회 (cursor 기반 페이지네이션, 최신순)
- `DELETE /api/ai/chat/history` — 대화 기록 전체 삭제

### 채팅 메시지 저장 흐름

`POST /api/ai/action` 호출 시:
1. 사용자 메시지를 `chat_messages`에 저장 (role: 'user')
2. AI 처리 수행
3. AI 응답을 `chat_messages`에 저장 (role: 'assistant', metadata에 액션 결과)
4. 응답 반환

기존 CRUD 로직은 변경 없음. 채팅 메시지 저장만 추가.

---

## 3. 프론트엔드 구조

### BottomNav 변경

4번째 탭 추가: 기록 / 달력 / 통계 / **AI**
- 아이콘: `MessageCircle` (Lucide React)
- 경로: `/ai`

### 컴포넌트 구조

```
pages/AIPage.tsx              — 메인 채팅 페이지 (컨테이너)
components/ai/
  ChatMessageList.tsx         — 메시지 목록 (스크롤 영역)
  ChatBubble.tsx              — 개별 메시지 버블 (user/assistant 스타일 분기)
  ChatInput.tsx               — 하단 입력창 + 전송 버튼
  ActionButton.tsx            — 네비게이션 버튼 ("캘린더로 이동" 등)
  ReportCard.tsx              — 리포트 요약 카드 (총지출, 증감 등)
  ReportChart.tsx             — 인라인 차트 렌더링 (Recharts)
```

### 채팅 화면 레이아웃

```
┌─────────────────────┐
│     AI 어시스턴트     │  ← 헤더 (대화 초기화 버튼)
├─────────────────────┤
│                     │
│   메시지 목록 영역    │  ← ChatMessageList (스크롤)
│                     │
│   ChatBubble들...    │
│     + ActionButton  │
│     + ReportCard    │
│     + ReportChart   │
│                     │
├─────────────────────┤
│ [메시지 입력...]  [➤] │  ← ChatInput
├─────────────────────┤
│ 기록  달력  통계  AI  │  ← BottomNav
└─────────────────────┘
```

### 메시지 렌더링 로직

`ChatBubble`이 `metadata`를 확인하여 추가 UI 렌더링:
- `metadata.actionType`이 CRUD → `ActionButton` (캘린더/통계 이동)
- `metadata.actionType`이 REPORT → `ReportCard` + `ReportChart`
- `metadata`가 null → 텍스트만 표시

### 상태 관리

- `useState`로 메시지 배열 관리
- 초기 로드 시 `GET /api/ai/chat/history`로 히스토리 fetch
- 전송 시 optimistic UI: 사용자 메시지 즉시 표시 → API 응답 후 assistant 메시지 추가
- 로딩 중 typing indicator (점 3개 애니메이션)

### API 클라이언트 추가 (`api.ts`)

```typescript
sendAIMessage(text: string)        // POST /api/ai/action
getChatHistory(page?: number)      // GET /api/ai/chat/history
clearChatHistory()                 // DELETE /api/ai/chat/history
```

---

## 4. 리포트 차트 렌더링 전략

### 간단한 카드 (ReportCard) — Recharts 불필요

| 항목 | 표현 |
|------|------|
| 총지출 / 총수입 / 순저축 | 숫자 카드 |
| 지난달 대비 증감 | 숫자 + 빨강/초록 화살표 |
| 예산 위험도 | 프로그레스 바 + 퍼센트 |
| 이상 지출 알림 | 경고 카드 (노란 배경) |
| 행동 제안 | 체크리스트 스타일 카드 |

### 풍부한 차트 (ReportChart via Recharts)

| 항목 | 차트 타입 |
|------|-----------|
| 카테고리별 지출 비율 | 도넛차트 (PieChart) |
| 지난달 vs 이번 달 비교 | 막대그래프 (BarChart) |
| 주차별/일별 지출 추이 | 라인차트 (LineChart) |
| 증가 기여도 | 수평 막대 (BarChart horizontal) |

### AI 응답의 sections 구조

```json
{
  "sections": [
    {
      "type": "card",
      "title": "이번 달 한눈에 보기",
      "items": [
        { "label": "총지출", "value": 820000, "format": "currency" },
        { "label": "전월 대비", "value": 14, "format": "percent", "trend": "up" }
      ]
    },
    {
      "type": "pie",
      "title": "카테고리별 지출",
      "data": [
        { "name": "식비", "value": 230000, "color": "#FF6B6B" },
        { "name": "교통", "value": 150000, "color": "#4ECDC4" }
      ]
    },
    {
      "type": "bar",
      "title": "지난달 vs 이번달",
      "data": [
        { "category": "식비", "lastMonth": 175000, "thisMonth": 230000 }
      ]
    },
    {
      "type": "line",
      "title": "주차별 지출 추이",
      "data": [
        { "week": "1주", "amount": 180000 },
        { "week": "2주", "amount": 220000 }
      ]
    },
    {
      "type": "alert",
      "title": "이상 지출",
      "items": [
        { "text": "3/18 커피 14,000원 — 평소 평균의 2.5배", "severity": "warning" }
      ]
    },
    {
      "type": "suggestion",
      "title": "다음 행동 제안",
      "items": [
        { "text": "배달앱 결제 빈도를 주 2회 이하로 관리" }
      ]
    }
  ]
}
```

ReportChart 컴포넌트가 `sections` 배열을 순회하며 `type`에 따라 렌더링.

---

## 5. AI 리포트 백엔드 처리 흐름

### 2단계 AI 호출

```
사용자 입력
  → [1단계] AI 파싱 (의도 분류: REPORT, reportType, params)
  → [2단계] DB 조회 (해당 월/카테고리 트랜잭션)
  → [3단계] AI 분석 (트랜잭션 데이터 → sections JSON 생성)
  → [4단계] 응답 조립 + chat_messages 저장
  → [5단계] 클라이언트 반환
```

### reportType별 데이터 조회 범위

| reportType | DB 조회 | AI에게 전달하는 데이터 |
|---|---|---|
| `monthly_summary` | 이번 달 + 지난달 전체 | 양쪽 트랜잭션 + 카테고리별 합계 |
| `category_detail` | 이번 달 + 지난달 해당 카테고리만 | 필터링된 트랜잭션 + 사용처별 그룹 |
| `spending_pattern` | 최근 3개월 | 일별/요일별 집계 |
| `anomaly` | 최근 3개월 | 카테고리별 평균/표준편차 + 이번 달 개별 건 |
| `suggestion` | 이번 달 + 지난 3개월 | 카테고리별 추이 |

### 서비스 레이어 구조

```
services/
  ai.ts              — 기존 CRUD 파싱 (변경 최소화)
  ai-report.ts       — 리포트 분석 전용 서비스 (NEW)
  messages.ts        — 기존 메시지 생성 (리포트용 추가)
  validation.ts      — 기존 Zod 검증 (REPORT 스키마 추가)
  chat.ts            — 채팅 히스토리 CRUD (NEW)
```

### 성능 고려

- 리포트는 CRUD보다 응답이 느림 (2번 AI 호출 + DB 조회)
- 프론트에서 로딩 상태 명확히 표시
- 첫 번째 응답(텍스트)을 먼저 보여주고, chartData는 파싱 후 렌더링

---

## 6. 네비게이션 & UX

### 액션별 네비게이션 버튼 매핑

| 액션 타입 | 버튼 텍스트 | 이동 경로 | 파라미터 |
|---|---|---|---|
| CREATE | "캘린더에서 확인" | `/calendar` | `?date=2026-04-03` |
| UPDATE | "수정 내역 확인" | `/calendar` | `?date=2026-04-03` |
| DELETE | "캘린더에서 확인" | `/calendar` | `?date=2026-04-03` |
| READ | "통계에서 보기" | `/stats` | `?month=2026-04` |
| REPORT | "통계에서 보기" | `/stats` | `?month=2026-04` |

기존 CalendarPage/StatsPage에서 URL 쿼리 파라미터를 읽어 해당 날짜/월로 자동 이동하도록 소폭 수정 필요.

### 초기 진입 시 UX

- 히스토리가 있으면 → 이전 대화 로드 (최근 50개)
- 히스토리가 없으면 → 웰컴 메시지:
  > "안녕하세요! 가계부 AI 어시스턴트입니다. 지출 기록, 수정, 삭제는 물론 소비 분석까지 도와드려요."

### 에러 처리

- AI 응답 실패 → "죄송합니다. 잠시 후 다시 시도해주세요." assistant 버블
- 네트워크 오류 → 재시도 버튼 포함 에러 메시지
- 빈 입력 → 전송 버튼 비활성화

### 대화 초기화

헤더 초기화 버튼 → 확인 다이얼로그 → `DELETE /api/ai/chat/history` → 웰컴 메시지로 리셋

# API 명세서

**Base URL**: `https://<worker>.workers.dev`  
**인증**: 모든 `/api/*` 엔드포인트는 `Authorization: Bearer <JWT>` 헤더 필요 (`/waitlist` 제외)  
**Content-Type**: `application/json`

---

## 목차

- [Users](#users)
- [Transactions](#transactions)
- [Sessions](#sessions)
- [AI (Legacy)](#ai-legacy)
- [Reports](#reports)
- [Notes](#notes)
- [Waitlist](#waitlist)

---

## Users

### `POST /api/users/sync`

OAuth 로그인 직후 사용자 정보를 DB에 동기화. 처음 로그인이면 INSERT, 이미 존재하면 UPDATE.

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `provider` | `string` | ✅ | OAuth 제공자 (`google`, `kakao` 등) |
| `email` | `string` | | 이메일 |
| `name` | `string` | | 사용자 이름 |
| `avatar_url` | `string` | | 프로필 이미지 URL |

**Response `200`**

```json
{ "success": true }
```

---

### `GET /api/users/me`

현재 로그인한 사용자 정보 조회.

**Response `200`**

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "홍길동",
  "avatarUrl": "https://...",
  "provider": "google",
  "createdAt": "2026-04-01T00:00:00"
}
```

**Response `404`** — 사용자 없음

```json
{ "error": "User not found" }
```

---

## Transactions

### `GET /api/transactions`

본인의 거래 목록 조회. soft delete된 거래는 제외.

**Query Parameters**

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `date` | `YYYY-MM` | 월별 필터. 없으면 전체 조회 |

**Response `200`**

```json
[
  {
    "id": 42,
    "userId": "uuid",
    "type": "expense",
    "amount": 5000,
    "category": "food",
    "memo": "커피",
    "date": "2026-04-21",
    "createdAt": "2026-04-21T10:00:00",
    "deletedAt": null,
    "previousState": null
  }
]
```

---

### `POST /api/transactions`

새 거래 기록 저장.

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `transactionType` | `"income" \| "expense"` | ✅ | 수입 또는 지출 |
| `amount` | `number` | ✅ | 금액 (양수, 최대 ₩1,000,000,000) |
| `category` | `string` | ✅ | 카테고리 (1~50자) |
| `date` | `YYYY-MM-DD` | ✅ | 거래 날짜 |
| `memo` | `string` | | 메모 (최대 500자) |

**Response `201`**

```json
{ "id": 42 }
```

**Response `400`** — 입력값 검증 실패

---

### `DELETE /api/transactions/:id`

거래 soft delete. 본인 거래만 삭제 가능.

**Path Parameters**: `id` — 거래 ID (integer)

**Response `200`**

```json
{ "success": true }
```

**Response `404`** — 거래 없음 또는 권한 없음

```json
{ "success": false, "error": "Transaction not found" }
```

---

### `GET /api/transactions/summary`

월별 카테고리 합계 통계 조회.

**Query Parameters**

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `month` | `YYYY-MM` | 조회 월. 없으면 현재 월 |

**Response `200`**

```json
[
  { "type": "expense", "category": "food", "total": 35000 },
  { "type": "income",  "category": "work", "total": 2000000 }
]
```

---

### `POST /api/transactions/:id/undo`

soft delete된 거래 복원.

**Path Parameters**: `id` — 거래 ID (integer)

**Response `200`**

```json
{
  "success": true,
  "message": "지출 ₩5,000 커피 (2026-04-21) 복원되었습니다",
  "result": { /* Transaction 객체 */ }
}
```

**Response `404`** — 거래 없음 또는 권한 없음

---

## Sessions

### `POST /api/sessions`

새 채팅 세션 생성.

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | `string` | ✅ | 세션 제목 |

**Response `201`**

```json
{
  "success": true,
  "session": {
    "id": 1,
    "title": "4월 가계부",
    "createdAt": "2026-04-21T10:00:00"
  }
}
```

---

### `GET /api/sessions`

본인의 채팅 세션 목록 조회.

**Query Parameters**

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `limit` | `number` | 최대 개수 (기본 50, 최대 100) |

**Response `200`**

```json
{
  "success": true,
  "sessions": [
    {
      "id": 1,
      "title": "4월 가계부",
      "createdAt": "2026-04-21T10:00:00",
      "updatedAt": "2026-04-21T10:00:00"
    }
  ]
}
```

---

### `GET /api/sessions/:id`

세션 단건 조회.

**Path Parameters**: `id` — 세션 ID (integer)

**Response `200`**

```json
{
  "success": true,
  "session": {
    "id": 1,
    "title": "4월 가계부",
    "createdAt": "2026-04-21T10:00:00",
    "updatedAt": "2026-04-21T10:00:00"
  }
}
```

**Response `404`** — 세션 없음 또는 권한 없음

---

### `PATCH /api/sessions/:id`

세션 이름 변경.

**Path Parameters**: `id` — 세션 ID (integer)

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | `string` | ✅ | 새 제목 |

**Response `200`**

```json
{
  "success": true,
  "session": {
    "id": 1,
    "title": "새 제목",
    "updatedAt": "2026-04-21T11:00:00"
  }
}
```

---

### `DELETE /api/sessions/:id`

세션 삭제. 세션에 속한 메시지도 함께 삭제(cascade).

**Path Parameters**: `id` — 세션 ID (integer)

**Response `200`**

```json
{ "success": true, "message": "Session deleted" }
```

**Response `404`** — 세션 없음 또는 권한 없음

---

### `GET /api/sessions/:sessionId/messages`

세션의 메시지 목록 조회 (시간 오름차순).

**Path Parameters**: `sessionId` — 세션 ID (integer)

**Response `200`**

```json
{
  "success": true,
  "messages": [
    {
      "id": 10,
      "sessionId": 1,
      "userId": "uuid",
      "role": "user",
      "content": "커피 5000원 지출",
      "metadata": null,
      "createdAt": "2026-04-21T10:00:00"
    },
    {
      "id": 11,
      "sessionId": 1,
      "userId": "uuid",
      "role": "assistant",
      "content": "지출 ₩5,000 커피로 2026-04-21에 저장되었습니다",
      "metadata": {
        "actionType": "create",
        "action": { "count": 1, "ids": [42], "totalAmount": 5000 }
      },
      "createdAt": "2026-04-21T10:00:01"
    }
  ]
}
```

---

### `POST /api/sessions/:sessionId/messages` ⭐

메시지 전송 + AI 처리. 이 서비스의 핵심 엔드포인트.

**Rate Limit**: 20 req/min

**Path Parameters**: `sessionId` — 세션 ID (integer)

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `content` | `string` | ✅ | 사용자 입력 텍스트 |

**AI 액션 타입별 동작**

| type | 동작 |
|------|------|
| `create` | 거래 생성 후 확인 메시지 반환 |
| `update` | 거래 수정 후 확인 메시지 반환 |
| `read` | 거래 조회 결과 요약 반환 |
| `delete` | 거래 soft delete 후 확인 메시지 반환 |
| `report` | AI 리포트 생성 후 저장 및 반환 |
| `clarify` | 모호한 입력 — 추가 정보 요청 질문 반환 |
| `undo` | 직전 create/update/delete 되돌리기 |
| `plain_text` | 비재무 메시지 — 자연어 응답 반환 |

**Response `200`**

```json
{
  "success": true,
  "type": "create",
  "messages": [
    {
      "id": 10,
      "sessionId": 1,
      "userId": "uuid",
      "role": "user",
      "content": "커피 5000원 지출",
      "metadata": null,
      "createdAt": "2026-04-21T10:00:00"
    },
    {
      "id": 11,
      "sessionId": 1,
      "userId": "uuid",
      "role": "assistant",
      "content": "지출 ₩5,000 커피로 2026-04-21에 저장되었습니다",
      "metadata": {
        "actionType": "create",
        "action": { "count": 1, "ids": [42], "totalAmount": 5000 }
      },
      "createdAt": "2026-04-21T10:00:01"
    }
  ]
}
```

**Response `404`** — 세션 없음 또는 권한 없음  
**Response `429`** — Rate limit 초과  
**Response `503`** — LLM 서비스 일시 불가

---

## AI (Legacy)

> ⚠️ 레거시 엔드포인트. 신규 개발은 `POST /api/sessions/:sessionId/messages` 사용 권장.

### `POST /api/ai/action`

AI에게 텍스트를 보내고 액션 실행.

**Rate Limit**: 20 req/min

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `text` | `string` | ✅ | 사용자 입력 텍스트 |
| `sessionId` | `number` | ✅ | 대화 세션 ID |

**Response `200`**

```json
{
  "success": true,
  "type": "create",
  "result": { /* Transaction 객체 */ },
  "message": "지출 ₩5,000 커피로 2026-04-21에 저장되었습니다",
  "content": "지출 ₩5,000 커피로 2026-04-21에 저장되었습니다",
  "metadata": {
    "actionType": "create",
    "action": { "count": 1, "ids": [42], "totalAmount": 5000 }
  }
}
```

---

### `GET /api/ai/chat/history`

채팅 기록 조회 (페이지네이션).

**Query Parameters**

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `limit` | `number` | 최대 개수 (기본 50, 최대 200) |
| `before` | `number` | 해당 메시지 ID 이전 것만 조회 (커서 페이지네이션) |

**Response `200`**

```json
{ "success": true, "messages": [ /* ChatMessage[] */ ] }
```

---

### `DELETE /api/ai/chat/history`

전체 채팅 기록 삭제.

**Response `200`**

```json
{ "success": true, "deletedCount": 15 }
```

---

## Reports

### `POST /api/reports`

리포트 저장.

**Rate Limit**: 10 req/min

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `reportType` | `string` | ✅ | `monthly_summary` \| `category_detail` \| `spending_pattern` \| `anomaly` \| `suggestion` |
| `title` | `string` | ✅ | 제목 (1~200자) |
| `subtitle` | `string` | | 부제목 (최대 100자) |
| `reportData` | `object[]` | ✅ | 리포트 섹션 배열 |
| `params` | `object` | ✅ | 리포트 생성 파라미터 (예: `{ month: "2026-04" }`) |

**Response `201`**

```json
{ "success": true, "id": 7, "createdAt": "2026-04-21T10:00:00" }
```

---

### `GET /api/reports`

리포트 목록 조회.

**Query Parameters**

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `month` | `YYYY-MM` | 월별 필터 |
| `limit` | `number` | 최대 개수 (기본 50, 최대 100) |

**Response `200`**

```json
{
  "success": true,
  "reports": [
    {
      "id": 7,
      "reportType": "monthly_summary",
      "title": "4월 소비 분석",
      "subtitle": "총 지출 ₩320,000",
      "createdAt": "2026-04-21T10:00:00"
    }
  ]
}
```

---

### `GET /api/reports/:id`

리포트 상세 조회.

**Path Parameters**: `id` — 리포트 ID (integer)

**Response `200`**

```json
{
  "success": true,
  "report": {
    "id": 7,
    "reportType": "monthly_summary",
    "title": "4월 소비 분석",
    "subtitle": "총 지출 ₩320,000",
    "reportData": [ /* 섹션 배열 */ ],
    "params": { "month": "2026-04" },
    "createdAt": "2026-04-21T10:00:00"
  }
}
```

**Response `404`** — 리포트 없음 또는 권한 없음

---

### `DELETE /api/reports/:id`

리포트 삭제.

**Path Parameters**: `id` — 리포트 ID (integer)

**Response `200`**

```json
{ "success": true, "message": "Report deleted" }
```

---

### `PATCH /api/reports/:id`

리포트 제목 수정.

**Path Parameters**: `id` — 리포트 ID (integer)

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | `string` | ✅ | 새 제목 |

**Response `200`**

```json
{ "success": true, "report": { /* Report 객체 */ } }
```

---

## Notes

### `POST /api/notes`

노트 생성. 생성 시 벡터 임베딩도 함께 저장 (AI 컨텍스트에 활용).

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `content` | `string` | ✅ | 노트 내용 |

**Response `201`**

```json
{
  "id": 3,
  "userId": "uuid",
  "content": "스타벅스는 항상 food로 분류",
  "embeddingId": "note-1713693600000",
  "createdAt": "2026-04-21T10:00:00",
  "updatedAt": "2026-04-21T10:00:00"
}
```

---

### `GET /api/notes`

본인의 노트 목록 조회.

**Response `200`**

```json
[
  {
    "id": 3,
    "userId": "uuid",
    "content": "스타벅스는 항상 food로 분류",
    "embeddingId": "note-1713693600000",
    "createdAt": "2026-04-21T10:00:00",
    "updatedAt": "2026-04-21T10:00:00"
  }
]
```

---

### `GET /api/notes/:id`

노트 단건 조회.

**Path Parameters**: `id` — 노트 ID (integer)

**Response `200`** — 노트 객체  
**Response `404`** — 노트 없음 또는 권한 없음

---

### `PATCH /api/notes/:id`

노트 수정. 수정 시 벡터 임베딩 재생성.

**Path Parameters**: `id` — 노트 ID (integer)

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `content` | `string` | ✅ | 새 내용 |

**Response `200`** — 수정된 노트 객체  
**Response `404`** — 노트 없음 또는 권한 없음

---

### `DELETE /api/notes/:id`

노트 삭제.

**Path Parameters**: `id` — 노트 ID (integer)

**Response `200`**

```json
{ "success": true }
```

**Response `404`** — 노트 없음 또는 권한 없음

---

## Waitlist

> 인증 불필요. IP 기반 Rate Limit: 5 req/min.

### `POST /waitlist`

출시 알림 이메일 등록.

**Request Body**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `email` | `string` | ✅ | 이메일 주소 (최대 320자) |

**Response `200`** — 신규 등록 성공

```json
{ "success": true }
```

**Response `200`** — 이미 등록된 이메일

```json
{ "alreadyRegistered": true }
```

**Response `400`** — 이메일 형식 오류

```json
{ "error": "Invalid email" }
```

**Response `429`** — Rate limit 초과

```json
{ "error": "Too many requests" }
```

---

## 공통 에러 응답

| 상태 코드 | 의미 | 예시 상황 |
|-----------|------|-----------|
| `400` | 잘못된 요청 | 필수 필드 누락, 유효하지 않은 값 |
| `401` | 인증 실패 | JWT 없음 또는 만료 |
| `403` | 권한 없음 | 다른 사용자의 리소스 접근 시도 |
| `404` | 리소스 없음 | 존재하지 않는 ID, 소유권 없는 리소스 |
| `429` | Rate limit 초과 | AI 엔드포인트 분당 20회 초과 |
| `500` | 서버 오류 | DB 오류, 예상치 못한 에러 |
| `503` | 서비스 불가 | LLM API 타임아웃 또는 장애 |

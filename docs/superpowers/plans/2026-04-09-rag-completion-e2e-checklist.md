# RAG 완성 E2E 체크리스트 (2026-04-09)

**목표:** RAG 구현 완료 후 엔드-투-엔드 기능 검증

---

## 🎯 핵심 E2E 체크리스트

### **1️⃣ 벡터 임베딩 & 검색 흐름**

**목표:** Cloudflare Vectorize가 정상 작동하는가?

- [ ] **임베딩 생성**
  ```
  테스트: POST /api/notes with content "I prefer to save 30% of income"
  검증: embeddingId가 생성되었는가?
  ```

- [ ] **벡터 검색**
  ```
  테스트: 유사한 노트 검색 (ContextService.retrieveNotes)
  검증: 관련성 높은 노트가 반환되는가?
  점수: score > 0.7인 결과가 있는가?
  ```

- [ ] **재시도 로직**
  ```
  테스트: VectorizeService API 실패 시뮬레이션
  검증: 3회 재시도 후 graceful fallback하는가?
  ```

### **2️⃣ 컨텍스트 수집 & 포맷팅**

**목표:** 각 액션별로 올바른 컨텍스트가 수집되는가?

- [ ] **CREATE 액션 (3 items)**
  ```
  테스트: POST /api/sessions/:sessionId/messages with "커피 5000"
  검증:
    - 지식 베이스 3개
    - 거래 0개 (CREATE는 거래 없음)
    - 노트 0개 (CREATE는 노트 없음)
  ```

- [ ] **READ 액션 (15 items)**
  ```
  테스트: POST /api/sessions/:sessionId/messages with "분석해줘"
  검증:
    - 지식 베이스 2개
    - 거래 10개
    - 노트 2개
    - 포맷: "Consider this context:" 메시지에 포함됨
  ```

- [ ] **REPORT 액션 (15 items)**
  ```
  테스트: POST /api/sessions/:sessionId/messages with "리포트 생성"
  검증:
    - 지식 베이스 4개
    - 거래 12개
    - 노트 4개 (추가 생성되어야 함)
  ```

- [ ] **CLARIFY 액션 (5 items)**
  ```
  테스트: 모호한 입력 (예: "5000" - 금액만)
  검증:
    - 지식 베이스 1개
    - 거래 3개
    - 노트 1개
  ```

- [ ] **PLAIN_TEXT 액션 (0 items)**
  ```
  테스트: POST /api/sessions/:sessionId/messages with "안녕하세요"
  검증: context가 주입되지 않음 (일반 채팅)
  ```

### **3️⃣ AI 응답 & 컨텍스트 주입**

**목표:** LLM이 컨텍스트를 받고 활용하는가?

- [ ] **컨텍스트가 LLM 메시지에 포함됨**
  ```
  테스트: POST /api/sessions/:sessionId/messages
  검증:
    - LLM 호출 로그에서 messages array 확인
    - system role에 "Consider this context:" 포함
  ```

- [ ] **AI 응답이 컨텍스트를 활용함**
  ```
  테스트: "분석해줘" 메시지 → AI 응답
  검증: 
    - 응답에 사용자 거래 금액 언급
    - 응답에 사용자 노트 목표 언급
    - 응답에 금융 팁 언급
  ```

- [ ] **컨텍스트 없이도 작동 (graceful fallback)**
  ```
  테스트: Vectorize API 실패 상황 시뮬레이션
  검증: 빈 컨텍스트로도 AI가 응답함 (에러 안 남)
  ```

### **4️⃣ User Notes API**

**목표:** 노트 CRUD가 벡터화와 함께 작동하는가?

- [ ] **POST /api/notes — 노트 생성**
  ```
  요청: { "content": "I want to save 40% monthly" }
  검증:
    - 201 상태 반환
    - embeddingId 생성됨
    - userId 자동 할당됨
    - DB에 저장됨
  ```

- [ ] **GET /api/notes — 노트 조회**
  ```
  검증:
    - 생성된 노트가 목록에 나타남
    - 사용자별 필터링 (다른 사용자 노트 안 보임)
    - 최신순 정렬
  ```

- [ ] **PATCH /api/notes/:id — 노트 수정**
  ```
  요청: { "content": "Updated: I want to save 50% monthly" }
  검증:
    - 200 상태 반환
    - embeddingId 재생성됨 (새로운 벡터)
    - updatedAt 갱신됨
  ```

- [ ] **DELETE /api/notes/:id — 노트 삭제**
  ```
  검증:
    - 200 상태 반환
    - 목록에서 제거됨
  ```

### **5️⃣ 지식 베이스 시드**

**목표:** 30개 항목이 제대로 로드되었는가?

- [ ] **시드 데이터 존재**
  ```
  테스트: npm run seed
  검증:
    - "Successfully seeded 30 items" 메시지
    - DB의 knowledge_base 테이블에 30개 행
  ```

- [ ] **카테고리별 분포**
  ```
  검증:
    - budgeting: 4개
    - savings: 3개
    - spending_analysis: 3개
    - transaction_tips: 3개
    - goal_setting: 3개
    - income_management: 2개
    - seasonal_planning: 2개
    - investment: 2개
    - general: 3개
  ```

- [ ] **컨텍스트에 포함됨**
  ```
  테스트: READ 액션으로 컨텍스트 수집
  검증: 지식 베이스 항목이 "Financial Knowledge:" 섹션에 나타남
  ```

### **6️⃣ 엔드-투-엔드 사용자 흐름**

**목표:** 실제 사용자 시나리오가 작동하는가?

#### **시나리오 A: 새 사용자 첫 채팅**
```
1. 사용자: "커피 5000원 지출했어"
   ✓ CREATE 액션 감지
   ✓ 지식 베이스 3개 컨텍스트
   ✓ 거래 생성됨
   ✓ AI 응답: "커피 5000원 지출이 저장되었습니다"

2. 사용자: "지금까지 얼마나 썼어?"
   ✓ READ 액션 감지
   ✓ 거래 10개 + 지식 10개 컨텍스트
   ✓ AI 응답: "커피로 5000원 지출했습니다 (전체 지출)"

3. 사용자: "내 저축 목표는 30%야"
   ✓ 노트 생성 (embedding 포함)
   ✓ embeddingId 저장됨

4. 사용자: "분석해줘"
   ✓ REPORT 액션 감지
   ✓ 거래 12개 + 노트 4개 포함 (방금 추가한 목표 포함)
   ✓ AI 응답: "저축 목표 30% 대비 현황 분석..."
```

#### **시나리오 B: 모호한 입력 → 선택**
```
1. 사용자: "5000"
   ✓ CLARIFY 액션 감지
   ✓ 컨텍스트 5개 (거래 패턴 활용)
   ✓ AI 응답: "5000원 음식 비용인가요? (최근 커피) 아니면 다른 카테고리?"

2. 사용자: "커피"
   ✓ 이전 clarification 상태 병합
   ✓ 거래 생성: 커피 5000원
```

#### **시나리오 C: 노트 수정 후 AI 응답 변화**
```
1. 노트 생성: "매달 500만원 저축하고 싶어"
   ✓ 벡터화 완료
   
2. 노트 수정: "이제 600만원 목표로 올렸어"
   ✓ embeddingId 재생성 (새로운 벡터)
   
3. READ 액션: "분석해줘"
   ✓ 업데이트된 노트 (600만원) 포함
   ✓ AI가 새로운 목표 인식하고 분석
```

---

## 📋 검증 포인트별 체크

### **데이터 흐름**
- [ ] 사용자 입력 → 액션 감지 ✓
- [ ] 액션 감지 → 컨텍스트 수집 ✓
- [ ] 컨텍스트 수집 → LLM 포맷팅 ✓
- [ ] LLM 포맷팅 → AI 응답 ✓
- [ ] AI 응답 → 메시지 저장 ✓

### **에러 처리**
- [ ] Vectorize API 실패 → graceful fallback ✓
- [ ] DB 쿼리 실패 → 빈 컨텍스트 ✓
- [ ] 타임아웃 (2초) → 재시도 ✓
- [ ] 사용자 권한 없음 → 403 반환 ✓

### **성능**
- [ ] 벡터 검색 < 500ms ✓
- [ ] 컨텍스트 포맷팅 < 100ms ✓
- [ ] 전체 context 수집 < 2초 ✓
- [ ] AI 응답 시간 < 10초 ✓

### **데이터 무결성**
- [ ] userId 필터링 (다른 사용자 데이터 안 보임) ✓
- [ ] embeddingId 자동 생성 ✓
- [ ] 벡터 유사도 스코어 0-1 범위 ✓
- [ ] 시드 데이터 30개 정확함 ✓

---

## 🧪 테스트 명령어 모음

```bash
# 전체 테스트
npm test

# 개별 테스트 스위트
npm test -- vectorize.test.ts
npm test -- context.test.ts
npm test -- user-notes.test.ts
npm test -- ai-integration.test.ts
npm test -- sessions-context.test.ts
npm test -- knowledge-base.test.ts

# 커버리지 리포트
npm test -- --coverage

# E2E 수동 테스트 (로컬 dev 서버)
curl -X POST http://localhost:8787/api/sessions/1/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "분석해줘"}'
```

---

## ✅ 최종 검증

모든 E2E 체크리스트 항목이 ✓ 표시되었으면:

```bash
✅ Phase 1: VectorizeService 완성
✅ Phase 2: AI Service 통합
✅ Phase 3: User Notes API
✅ Phase 4: 지식 베이스 시드
✅ Phase 5: 포괄적 테스트
✅ E2E: 엔드-투-엔드 흐름 검증

🎉 RAG 구현 완료!
```

---

## 문제 해결 가이드

| 증상 | 원인 | 해결 |
|------|------|------|
| embeddingId가 null | Vectorize API 실패 | `.env` 확인, API 토큰 갱신 |
| 컨텍스트가 안 보임 | userId 필터링 오류 | 로그에서 userId 확인 |
| 성능 느림 | 벡터 검색 타임아웃 | 2초 제한 확인 |
| 테스트 실패 | Mock 데이터 오류 | test.ts 파일의 mock 데이터 확인 |
| 노트 목록이 비어있음 | 시드 데이터 미실행 | `npm run seed` 실행 |

---

이 체크리스트를 사용하여 RAG 구현이 완료되었음을 검증하세요! 🚀

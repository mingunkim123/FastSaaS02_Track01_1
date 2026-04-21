# FastSaaS 전체 시스템 아키텍처

> AI 기반 개인 금융 챗봇 — Flutter + Hono + Cloudflare Workers + Turso + Supabase

---

## 1. 전체 시스템 개요

```mermaid
graph TB
    subgraph Clients["클라이언트 레이어"]
        Flutter["📱 Flutter App<br/>(Android / iOS)<br/>Riverpod · Dio · go_router"]
        Web["🌐 Landing Page<br/>(Astro + React)<br/>Tailwind · DaisyUI"]
    end

    subgraph CF["☁️ Cloudflare Edge"]
        Workers["Cloudflare Workers<br/>Hono 4.12 · TypeScript<br/>fastsaas2.workers.dev"]
        CFAI["Workers AI<br/>(LLM Binding)"]
        Vectorize["Vectorize<br/>(Vector DB)"]
    end

    subgraph Auth["🔐 Supabase"]
        SupaAuth["Supabase Auth<br/>Google OAuth · Kakao OAuth"]
        JWKS["JWKS Endpoint<br/>(ES256 Public Keys)"]
    end

    subgraph DB["🗄️ Turso (Serverless SQLite)"]
        TursoDB["libSQL Database<br/>Drizzle ORM<br/>9개 테이블"]
    end

    subgraph LLM["🤖 LLM Providers (선택적)"]
        Gemini["Google Gemini API"]
        OpenAI["OpenAI API"]
    end

    Flutter -- "JWT Bearer" --> Workers
    Web -- "HTTP" --> Workers
    Flutter -- "OAuth Login" --> SupaAuth
    SupaAuth -- "JWT ES256 발급" --> Flutter
    Workers -- "JWKS 검증" --> JWKS
    Workers -- "SQL 쿼리" --> TursoDB
    Workers -- "AI 추론" --> CFAI
    Workers -- "벡터 검색" --> Vectorize
    Workers -.->|"AI_PROVIDER=gemini"| Gemini
    Workers -.->|"AI_PROVIDER=openai"| OpenAI
```

---

## 2. 인증 흐름 (Auth Flow)

```mermaid
sequenceDiagram
    actor User
    participant Flutter
    participant Supabase
    participant Workers as Cloudflare Workers
    participant JWKS as Supabase JWKS

    User->>Flutter: 로그인 버튼 클릭
    Flutter->>Supabase: OAuth 요청 (Google/Kakao)
    Supabase-->>Flutter: JWT (ES256) + Refresh Token
    Flutter->>Flutter: SharedPreferences에 JWT 저장

    Flutter->>Workers: API 요청 (Authorization: Bearer JWT)
    Workers->>JWKS: Public Key 조회 (1시간 캐시)
    JWKS-->>Workers: ES256 Public Key
    Workers->>Workers: JWT 서명 검증<br/>payload.sub → userId 추출
    Workers-->>Flutter: 응답 (userId 기반 데이터)

    Note over Flutter,Workers: JWT 만료 시 Dio AuthInterceptor가<br/>자동으로 토큰 갱신 후 재시도
```

---

## 3. AI 트랜잭션 처리 흐름

```mermaid
sequenceDiagram
    actor User
    participant Flutter
    participant Workers as Cloudflare Workers
    participant LLM as Workers AI / Gemini / OpenAI
    participant Turso

    User->>Flutter: "오늘 점심 8천원 먹었어"
    Flutter->>Workers: POST /api/sessions/:id/messages
    Workers->>Workers: JWT 검증 → userId 추출
    Workers->>Workers: Rate Limit 확인 (20 req/min)

    Workers->>Turso: 최근 트랜잭션 컨텍스트 조회
    Turso-->>Workers: 최근 거래 내역

    Workers->>LLM: parseUserInput()<br/>{ action, payload, confidence }
    LLM-->>Workers: { type: "create", amount: 8000,<br/>category: "food", confidence: 0.92 }

    alt confidence >= 0.7
        Workers->>Turso: INSERT INTO transactions
        Workers->>Turso: INSERT INTO chatMessages (user + AI)
        Workers-->>Flutter: { messages: [userMsg, aiMsg] }
        Flutter-->>User: "점심 8,000원 기록했어요 ✅"
    else confidence < 0.7
        Workers->>Turso: 클래리피케이션 상태 저장
        Workers-->>Flutter: { messages: [aiMsg(clarify)] }
        Flutter-->>User: "카테고리를 알려주세요 🤔"
    end
```

---

## 4. 백엔드 내부 구조 (Cloudflare Workers)

```mermaid
graph TB
    subgraph Entry["src/index.ts — Hono App"]
        CORS["CORS Middleware<br/>(env-based origins)"]
        Log["Logging Middleware"]
        Public["Public Routes<br/>POST /waitlist"]
        AuthMW["Auth Middleware<br/>JWT ES256 → userId"]
    end

    subgraph Routes["src/routes/"]
        Sessions["sessions.ts<br/>/api/sessions/**"]
        Tx["transactions.ts<br/>/api/transactions/**"]
        Reports["reports.ts<br/>/api/reports/**"]
        Notes["notes.ts<br/>/api/notes/**"]
        Users["users.ts<br/>/api/users/**"]
        AI["ai.ts<br/>/api/ai/** (legacy)"]
    end

    subgraph Services["src/services/"]
        AISvc["ai.ts<br/>parseUserInput()"]
        LLMSvc["llm.ts<br/>multi-provider"]
        ChatSvc["chat.ts<br/>getChatHistoryBySession()"]
        SessionSvc["sessions.ts<br/>CRUD + 제목 생성"]
        ContextSvc["context.ts<br/>대화 컨텍스트 조립"]
        ReportSvc["ai-report.ts<br/>리포트 생성"]
        VectorSvc["vectorize.ts<br/>임베딩 API"]
        NotesSvc["user-notes.ts<br/>노트 CRUD"]
    end

    subgraph DB["src/db/"]
        Schema["schema.ts<br/>Drizzle 스키마"]
        Migrations["migrations/<br/>007개 마이그레이션"]
    end

    CORS --> Log --> Public
    Log --> AuthMW
    AuthMW --> Sessions & Tx & Reports & Notes & Users & AI
    Sessions --> AISvc & ChatSvc & SessionSvc & ContextSvc
    AISvc --> LLMSvc
    Reports --> ReportSvc
    Notes --> NotesSvc & VectorSvc
    Sessions & Tx & Reports & Notes & Users --> Schema
    Schema --> Migrations
```

---

## 5. 데이터베이스 스키마 (Turso / libSQL)

```mermaid
erDiagram
    users {
        text id PK
        text email
        text name
        text avatarUrl
        text provider
        integer createdAt
    }

    transactions {
        text id PK
        text userId FK
        text type
        integer amount
        text category
        text memo
        text date
        integer deletedAt
        text previousState
        integer createdAt
    }

    sessions {
        text id PK
        text userId FK
        text title
        integer createdAt
        integer updatedAt
    }

    chatMessages {
        text id PK
        text userId FK
        text sessionId FK
        text role
        text content
        text metadata
        integer createdAt
    }

    clarificationSessions {
        text id PK
        text userId FK
        text chatSessionId FK
        text state
        integer createdAt
    }

    reports {
        text id PK
        text userId FK
        text reportType
        text title
        text subtitle
        text reportData
        text params
        integer createdAt
    }

    userNotes {
        text id PK
        text userId FK
        text content
        text embeddingId
        integer createdAt
        integer updatedAt
    }

    knowledgeBase {
        text id PK
        text content
        text category
        text embeddingId
        integer createdAt
    }

    waitlist {
        text id PK
        text email
        integer createdAt
    }

    users ||--o{ transactions : "소유"
    users ||--o{ sessions : "소유"
    users ||--o{ chatMessages : "작성"
    users ||--o{ reports : "소유"
    users ||--o{ userNotes : "소유"
    sessions ||--o{ chatMessages : "포함"
    sessions ||--o{ clarificationSessions : "연결"
```

---

## 6. Flutter 앱 아키텍처

```mermaid
graph TB
    subgraph UI["UI Layer (lib/features/)"]
        Auth["auth/<br/>로그인 · 회원가입"]
        Home["home/<br/>대시보드 · 거래 목록"]
        Chat["ai_chat/ + chat/<br/>AI 채팅 인터페이스"]
        Record["record/<br/>수동 입력"]
        Stats["stats/<br/>월별 통계"]
        Calendar["calendar/<br/>캘린더 뷰"]
        Reports["reports/<br/>재무 리포트"]
        Settings["settings/<br/>설정"]
    end

    subgraph State["State Layer (Riverpod)"]
        Providers["Providers<br/>authProvider · transactionProvider<br/>sessionProvider · reportProvider"]
    end

    subgraph Core["Core Layer (lib/core/)"]
        ApiClient["api/api_client.dart<br/>REST API 통신"]
        AuthService["auth/supabase_auth.dart<br/>OAuth · JWT 관리"]
        DioConfig["Dio + AuthInterceptor<br/>자동 토큰 갱신"]
        NativeBridge["storage/native_shared_prefs.dart<br/>Android JNI 브릿지"]
        AdService["ads/ad_service.dart<br/>Google Mobile Ads"]
    end

    UI --> Providers
    Providers --> ApiClient
    ApiClient --> DioConfig
    DioConfig --> AuthService
    AuthService --> NativeBridge
```

---

## 7. 배포 구성

```mermaid
graph LR
    subgraph Dev["개발 환경"]
        LocalBack["localhost:8787<br/>wrangler dev"]
        LocalFront["localhost:5173<br/>Vite dev server"]
        LocalFlutter["Flutter hot reload<br/>Android Emulator"]
    end

    subgraph Prod["프로덕션"]
        CFWorkers["Cloudflare Workers<br/>fastsaas2.fastsaas2.workers.dev"]
        CFPages["Cloudflare Pages<br/>Landing Page"]
        TursoProd["Turso DB<br/>libsql://...turso.io"]
        SupaProd["Supabase<br/>Auth + JWKS"]
        AppStore["Google Play Store<br/>Flutter APK"]
    end

    LocalBack -->|"npm run deploy"| CFWorkers
    LocalFront -->|"astro build + pages deploy"| CFPages
    LocalFlutter -->|"flutter build apk"| AppStore
    CFWorkers --- TursoProd
    CFWorkers --- SupaProd
```

---

## 8. LLM 멀티 프로바이더 구조

```mermaid
graph TD
    Req["사용자 메시지"]
    LLMSvc["llm.ts<br/>getLLMProvider()"]

    Req --> LLMSvc

    LLMSvc -->|"AI_PROVIDER=workers-ai"| WorkersAI["☁️ Cloudflare Workers AI<br/>무료 · 내장 바인딩"]
    LLMSvc -->|"AI_PROVIDER=gemini"| GeminiAPI["🤖 Google Gemini API<br/>GEMINI_API_KEY 필요"]
    LLMSvc -->|"AI_PROVIDER=openai"| OpenAIAPI["🤖 OpenAI API<br/>OPENAI_API_KEY 필요"]

    WorkersAI --> Parse["parseUserInput()<br/>{ type, payload, confidence }"]
    GeminiAPI --> Parse
    OpenAIAPI --> Parse
```

---

## 9. 보안 레이어

| 계층 | 보안 조치 |
|------|----------|
| **인증** | Supabase JWT ES256 서명 검증, JWKS 1시간 캐시 |
| **인가** | 모든 DB 쿼리에 `userId` 필터 강제 (`WHERE userId = ?`) |
| **세션** | 쓰기 전 세션 소유권 확인 (`getSession(db, sessionId, userId)`) |
| **Rate Limit** | AI 엔드포인트 20 req/min, 리포트 10 req/min (per-user) |
| **입력 검증** | Zod 스키마로 모든 API 요청 검증 |
| **CORS** | 환경변수 기반 허용 오리진 화이트리스트 |
| **Semgrep** | 하드코딩 시크릿·SQL 인젝션·eval 사용 정적 분석 |

---

## 10. 기술 스택 요약

| 영역 | 기술 |
|------|------|
| **Mobile** | Flutter 3.11.4, Dart, Riverpod, Dio, go_router |
| **Backend** | Hono 4.12, TypeScript, Cloudflare Workers |
| **Database** | Turso (libSQL / SQLite), Drizzle ORM |
| **Auth** | Supabase Auth, OAuth 2.0, JWT ES256 |
| **AI/LLM** | Workers AI (기본), Gemini, OpenAI (선택) |
| **Vector DB** | Cloudflare Vectorize |
| **Frontend** | Astro 6.1, React 19, Tailwind, DaisyUI |
| **Test** | Vitest, Playwright E2E |
| **CI/Deploy** | Cloudflare Workers CLI (wrangler) |

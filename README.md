# FastSaaS02_Track01_1

AI 기반 가계부 챗봇 애플리케이션입니다. 자연어로 가계부를 관리하고, AI가 재무 분석 리포트를 생성해줍니다.

## 기술 스택

| 구분 | 기술 |
| --- | --- |
| Frontend | React + Vite + TypeScript |
| Backend | Hono (Cloudflare Workers) |
| Database | Turso (Serverless SQLite) + Drizzle ORM |
| Auth | Supabase (OAuth + JWT) |
| AI | Google Gemini API |
| Mobile | Capacitor |

## 개발 서버 실행 방법

### 1. 백엔드

```bash
cd backend
npm install      # 최초 1회
npm run dev      # wrangler dev 실행
```

실행되면 아래 주소에서 API 서버가 동작합니다:

```
http://localhost:8787
```

> 환경 변수(`TURSO_DB_URL`, `TURSO_AUTH_TOKEN`, `SUPABASE_JWT_SECRET`, `GEMINI_API_KEY`, `GEMINI_MODEL_NAME`)는 `wrangler.jsonc`에 설정되어 있습니다.

### 2. 프론트엔드

```bash
cd frontend
npm install      # 최초 1회
npm run dev      # vite 실행
```

실행되면 아래 주소에서 웹 앱에 접속할 수 있습니다:

```
http://localhost:5173
```

> 포트가 이미 사용 중이면 자동으로 5174, 5175 등으로 올라갑니다. 터미널 출력에 표시된 주소를 확인하세요.

### 3. 동시 실행

백엔드와 프론트엔드를 **각각 별도의 터미널**에서 실행해야 합니다:

```bash
# 터미널 1: 백엔드
cd backend && npm run dev

# 터미널 2: 프론트엔드
cd frontend && npm run dev
```

두 서버가 모두 떠야 앱이 정상 동작합니다.

## 기타 명령어

| 명령어 | 위치 | 설명 |
| --- | --- | --- |
| `npm run build` | frontend | 프로덕션 빌드 |
| `npm run deploy` | backend | Cloudflare Workers 배포 |
| `npm run test` | backend | Vitest 테스트 실행 |
| `npm run type-check` | backend | TypeScript 타입 체크 |

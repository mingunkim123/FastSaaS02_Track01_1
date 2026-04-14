# Semgrep 도입 제안서

## 프로젝트 개요

- **백엔드**: TypeScript + Cloudflare Workers (Hono 프레임워크)
- **프론트엔드**: Flutter (Dart)
- **개발 규모**: 솔로 개발자
- **목표**: 빠른 실행, 낮은 오탐률(false positive), 높은 신호 대비 노이즈 비율

---

## 설치 방법

```bash
# pip로 설치 (Python 환경)
pip install semgrep

# 또는 Homebrew로 설치 (macOS/Linux)
brew install semgrep

# 버전 확인
semgrep --version
```

---

## 실행 명령어

```bash
# 백엔드 전체 스캔
semgrep --config .semgrep.yml backend/src/

# 특정 파일만 스캔
semgrep --config .semgrep.yml backend/src/middleware/auth.ts

# JSON 출력 (CI/CD 파이프라인용)
semgrep --config .semgrep.yml backend/src/ --json > semgrep-results.json

# 오탐 무시 주석 허용 모드
semgrep --config .semgrep.yml backend/src/ --disable-nosem=false
```

---

## 전체 `.semgrep.yml` 설정

```yaml
rules:

  # ============================================================
  # 카테고리 1: 보안 (Security) — 최우선 적용
  # ============================================================

  - id: hardcoded-api-key
    patterns:
      - pattern-regex: '(?i)(api_key|apikey|api-key|secret_key|auth_token|access_token)\s*[:=]\s*["\x27][A-Za-z0-9_\-\.]{16,}["\x27]'
    message: |
      하드코딩된 API 키 또는 시크릿이 감지되었습니다.
      환경 변수(c.env.VARIABLE_NAME)를 통해 주입받으세요.
      위반 위치: $FILE:$LINE
    languages: [typescript, javascript]
    severity: ERROR
    metadata:
      category: security
      cwe: CWE-798
      owasp: A02:2021

  - id: hardcoded-jwt-secret
    pattern-regex: '(?i)(jwt_secret|supabase_jwt|signing_secret)\s*[:=]\s*["\x27][A-Za-z0-9+/=_\-]{20,}["\x27]'
    message: |
      하드코딩된 JWT 시크릿이 감지되었습니다.
      Cloudflare Workers secrets 또는 .dev.vars를 사용하세요.
    languages: [typescript, javascript]
    severity: ERROR
    metadata:
      category: security
      cwe: CWE-321

  - id: sql-injection-string-concat
    patterns:
      - pattern: |
          $DB.run($QUERY + $INPUT)
      - pattern: |
          $DB.run(`...${$INPUT}...`)
      - pattern: |
          $DB.execute($QUERY + $INPUT)
    message: |
      문자열 연결을 통한 SQL 쿼리 구성이 감지되었습니다.
      Drizzle ORM의 파라미터 바인딩(eq(), and() 등)을 사용하세요.
      예: db.select().from(table).where(eq(table.col, value))
    languages: [typescript, javascript]
    severity: ERROR
    metadata:
      category: security
      cwe: CWE-89
      owasp: A03:2021

  - id: eval-usage
    pattern: eval(...)
    message: |
      eval() 사용이 감지되었습니다. 코드 인젝션 취약점으로 이어질 수 있습니다.
      동적 코드 실행이 필요한 경우 안전한 대안을 검토하세요.
    languages: [typescript, javascript]
    severity: ERROR
    metadata:
      category: security
      cwe: CWE-95
      owasp: A03:2021

  - id: console-log-sensitive-data
    patterns:
      - pattern: console.log(..., $VAR, ...) where:
          - metavariable-regex:
              metavariable: $VAR
              regex: '(?i)(userId|user_id|token|password|passwd|secret|apikey|api_key|auth)'
      - pattern: console.log($MSG) where:
          - metavariable-regex:
              metavariable: $MSG
              regex: '(?i)(userId|token|password|secret)'
    message: |
      민감한 변수(userId, token, password 등)를 console.log로 출력하고 있습니다.
      프로덕션 로그에 민감 정보가 노출될 수 있습니다.
      디버그 로그는 개발 환경에서만 조건부로 출력하거나 제거하세요.
    languages: [typescript, javascript]
    severity: WARNING
    metadata:
      category: security
      cwe: CWE-532
      owasp: A09:2021

  - id: missing-await-async
    patterns:
      - pattern: |
          const $VAR = $ASYNC_FN(...);
        where:
          - metavariable-regex:
              metavariable: $VAR
              regex: '(?i)(user|auth|token|session|transaction|result|data|response)'
          - metavariable-pattern:
              metavariable: $ASYNC_FN
              pattern-regex: '(getUser|verifyToken|fetchSession|getTransaction|parseUserInput|db\.\w+)'
    message: |
      비동기 함수 결과에 await가 누락되었을 수 있습니다.
      인증/인가 관련 함수에서 await 누락 시 보안 로직이 건너뛰어질 수 있습니다.
      확인 후 필요시 await를 추가하세요.
    languages: [typescript, javascript]
    severity: WARNING
    metadata:
      category: security
      cwe: CWE-362

  # ============================================================
  # 카테고리 2: TypeScript/JS 코드 품질
  # ============================================================

  - id: parseint-without-radix
    pattern: parseInt($STR)
    message: |
      parseInt()에 radix(기수) 인자가 없습니다.
      의도치 않은 8진수 파싱을 방지하려면 parseInt($STR, 10)을 사용하세요.
    languages: [typescript, javascript]
    severity: WARNING
    metadata:
      category: correctness
      cwe: CWE-704

  - id: loose-equality-comparison
    patterns:
      - pattern: $A == $B
      - pattern: $A != $B
    message: |
      느슨한 동등 비교(==, !=)가 사용되었습니다.
      타입 강제 변환으로 인한 예기치 않은 동작을 방지하려면 === 또는 !==을 사용하세요.
    languages: [typescript, javascript]
    severity: INFO
    metadata:
      category: correctness

  - id: any-type-in-security-files
    patterns:
      - pattern: ": any"
      - pattern: "as any"
    message: |
      'any' 타입 사용이 감지되었습니다.
      보안 관련 파일(auth, middleware, validation)에서 any 타입은 타입 안전성을 우회합니다.
      구체적인 타입 또는 unknown을 사용하세요.
    languages: [typescript]
    severity: WARNING
    paths:
      include:
        - "backend/src/middleware/**"
        - "backend/src/services/validation.ts"
        - "backend/src/routes/**"
    metadata:
      category: type-safety

  # ============================================================
  # 카테고리 3: Hono/Cloudflare Workers 특화 규칙
  # ============================================================

  - id: userid-from-request-body
    patterns:
      - pattern: |
          const { userId, ... } = await $C.req.json()
      - pattern: |
          const $BODY = await $C.req.json();
          ...
          $BODY.userId
      - pattern: |
          $REQ.userId
        where:
          - metavariable-regex:
              metavariable: $REQ
              regex: '^body|json|data|payload$'
    message: |
      요청 바디(body)에서 userId를 읽고 있습니다. 보안 취약점입니다.
      userId는 반드시 JWT 검증 미들웨어에서 추출한 값을 사용하세요:
        const userId = c.get('userId');  // auth 미들웨어에서 검증된 값
      요청 바디의 userId는 클라이언트가 임의로 조작할 수 있습니다.
    languages: [typescript, javascript]
    severity: ERROR
    paths:
      include:
        - "backend/src/routes/**"
        - "backend/src/services/**"
    metadata:
      category: security
      cwe: CWE-639
      owasp: A01:2021

  - id: direct-req-json-for-userid
    pattern: |
      const { $A, userId: $UID, $B } = await c.req.json()
    message: |
      c.req.json()에서 직접 userId를 구조분해 할당하고 있습니다.
      이 패턴은 사용자가 임의의 userId로 타인의 데이터에 접근할 수 있게 합니다.
      반드시 c.get('userId')를 사용하세요.
    languages: [typescript, javascript]
    severity: ERROR
    paths:
      include:
        - "backend/src/routes/**"
    metadata:
      category: security
      cwe: CWE-639

  - id: missing-auth-middleware-on-route
    patterns:
      - pattern: |
          $APP.get($PATH, async ($C) => { ... })
        where:
          - pattern-not: |
              $APP.use($PATH, authMiddleware)
          - metavariable-regex:
              metavariable: $PATH
              regex: '^.*/api/.*$'
    message: |
      /api/ 경로에 authMiddleware가 적용되지 않았을 수 있습니다.
      민감한 엔드포인트에는 반드시 인증 미들웨어를 적용하세요.
      확인 후 필요시 app.use('/api/...', authMiddleware)를 추가하세요.
    languages: [typescript, javascript]
    severity: WARNING
    paths:
      include:
        - "backend/src/index.ts"
        - "backend/src/routes/**"
    metadata:
      category: security
      owasp: A01:2021
```

---

## 오탐률 추정

| 규칙 카테고리 | 규칙 ID | 예상 오탐률 | 비고 |
|---|---|---|---|
| 보안 | `hardcoded-api-key` | 낮음 (5%) | 테스트 더미 값 제외 필요 |
| 보안 | `hardcoded-jwt-secret` | 매우 낮음 (2%) | 패턴이 매우 구체적 |
| 보안 | `sql-injection-string-concat` | 낮음 (8%) | Drizzle ORM 사용 시 해당 패턴 드묾 |
| 보안 | `eval-usage` | 매우 낮음 (1%) | 정상적 eval 사용 케이스 거의 없음 |
| 보안 | `console-log-sensitive-data` | 중간 (15%) | 변수명 기반 추론이므로 오탐 가능 |
| 보안 | `missing-await-async` | 중간 (20%) | 복잡한 패턴 매칭, 수동 검토 필요 |
| JS 품질 | `parseint-without-radix` | 낮음 (5%) | 명확한 패턴 |
| JS 품질 | `loose-equality-comparison` | 높음 (30%) | 레거시 코드 많을수록 증가 |
| JS 품질 | `any-type-in-security-files` | 중간 (10%) | 경로 필터 적용으로 감소 |
| Hono 특화 | `userid-from-request-body` | 낮음 (3%) | 프로젝트 고유 패턴 |
| Hono 특화 | `direct-req-json-for-userid` | 매우 낮음 (2%) | 매우 구체적 패턴 |
| Hono 특화 | `missing-auth-middleware-on-route` | 중간 (15%) | 미들웨어 적용 방식 다양 |

---

## 솔로 개발자를 위한 우선순위 적용 순서

솔로 개발자는 한 번에 모든 규칙을 활성화하면 노이즈가 많아져 피로감이 생깁니다.
아래 단계별로 점진적으로 도입하는 것을 권장합니다.

### 1단계: 즉시 적용 (Critical Security)

오탐률이 낮고 실제 보안 사고 예방 효과가 높은 규칙입니다.

```bash
semgrep --config .semgrep.yml backend/src/ \
  --include-rule hardcoded-api-key \
  --include-rule hardcoded-jwt-secret \
  --include-rule userid-from-request-body \
  --include-rule direct-req-json-for-userid \
  --include-rule eval-usage \
  --include-rule sql-injection-string-concat
```

적용 규칙:
- `hardcoded-api-key`
- `hardcoded-jwt-secret`
- `userid-from-request-body`
- `direct-req-json-for-userid`
- `eval-usage`
- `sql-injection-string-concat`

### 2단계: 1~2주 후 추가 (High Signal Quality)

코드 정확성 관련 규칙입니다.

```bash
semgrep --config .semgrep.yml backend/src/
# (전체 config 파일 사용, 단 loose-equality 제외 권장)
```

추가 규칙:
- `parseint-without-radix`
- `any-type-in-security-files`
- `console-log-sensitive-data`

### 3단계: 안정화 후 적용 (Lower Priority)

오탐률이 상대적으로 높아 수동 검토 비용이 필요합니다.

추가 규칙:
- `loose-equality-comparison` (기존 코드베이스에 광범위하게 적용될 수 있음)
- `missing-await-async` (패턴 정확도 한계로 수동 검토 필요)
- `missing-auth-middleware-on-route` (미들웨어 구조에 따라 오탐 가능)

---

## 오탐 억제 방법

특정 라인에서 규칙을 무시하려면 주석을 추가하세요:

```typescript
// nosemgrep: console-log-sensitive-data
console.log('Debug userId:', userId);  // 개발 환경 전용

// nosemgrep: loose-equality-comparison
if (value == null) { ... }  // null/undefined 동시 체크 의도적 사용
```

---

## CI/CD 통합 (선택사항)

GitHub Actions에 통합하려면 `.github/workflows/semgrep.yml`을 생성하세요:

```yaml
name: Semgrep Security Scan
on: [push, pull_request]
jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Semgrep
        run: |
          pip install semgrep
          semgrep --config .semgrep.yml backend/src/ --error
```

`--error` 플래그는 ERROR 심각도 발견 시 빌드를 실패시킵니다.

---

## 참고 자료

- [Semgrep 공식 문서](https://semgrep.dev/docs/)
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [Hono 보안 가이드](https://hono.dev/guides/middleware)
- [Cloudflare Workers 보안 모범 사례](https://developers.cloudflare.com/workers/platform/security/)

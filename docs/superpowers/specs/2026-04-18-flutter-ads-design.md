# Flutter 광고 통합 설계 (Freemium: Free 유저에게 AdMob 노출)

**작성일:** 2026-04-18
**범위:** Flutter 앱 (`flutter_app/`) 전용. 백엔드 변경 없음.
**목표:** Free 플랜 유저에게 Google AdMob 배너 + 전면광고를 노출하여 수익화. Paid 유저는 광고 미노출. 백엔드 권한을 아직 얻지 못한 상태이므로 플랜 판별은 Flutter 측 추상화로 처리하고, 추후 백엔드 API 연동 시 최소 수정으로 교체 가능하게 설계.

---

## 1. 확정된 결정 사항

| 항목 | 결정 |
|------|------|
| 플랜 판별 방식 | `PlanProvider` Riverpod 추상화. 현재는 항상 `PlanStatus.free` 반환. 백엔드 권한 확보 후 이 provider 내부만 교체. |
| 광고 포맷 | 배너(Banner) + 전면광고(Interstitial) |
| 배너 노출 화면 | 세션 목록(`chat`/`ai_chat` 세션 리스트), 캘린더, 통계, 리포트 |
| 배너 미노출 화면 | 로그인/회원가입(`auth`), 대화 화면(`ai_chat`/`chat` 메시지 뷰), 입력 화면(`record`) |
| 전면광고 트리거 | 리포트 생성 완료 시. **빈도 제한 없음** (유저 결정). |
| 플랫폼 범위 | Android 우선. iOS는 추후 별도 작업 (ATT 동의 + Info.plist 설정 필요). |
| 광고 ID 전략 | Google 공식 테스트 ID로 개발. `--dart-define=ADMOB_MODE=prod` 빌드 시 실 ID로 전환. |
| 에러 정책 | 광고 로드/표시 실패는 조용히 무시. 본 기능에 영향 없음. |

---

## 2. 아키텍처

```
flutter_app/lib/
├── core/
│   └── ads/
│       ├── ad_service.dart          # AdMob SDK 초기화
│       ├── ad_ids.dart              # 테스트/실 광고 ID 관리 (dart-define)
│       └── plan_provider.dart       # PlanStatus enum + Riverpod provider (현재 Free 하드코딩)
└── shared/widgets/
    ├── ad_banner.dart               # 재사용 가능한 배너 위젯 (plan 체크 내장)
    └── ad_interstitial_trigger.dart # 전면광고 preload/show 헬퍼
```

**의존성 추가:**
- `pubspec.yaml`: `google_mobile_ads: ^5.1.0`
- `android/app/build.gradle`: `minSdkVersion 23` 이상 확인
- `android/app/src/main/AndroidManifest.xml`: AdMob App ID meta-data, `<uses-permission android:name="android.permission.INTERNET" />` 확인

**핵심 설계 원칙:**
1. **PlanProvider는 광고 로직을 모른다** — 플랜 상태만 반환. 광고 표시 결정은 호출부(위젯/헬퍼)에서.
2. **AdBanner는 plan을 자체 체크** — 호출 화면은 plan 신경 안 써도 됨. `AdBanner()`만 붙이면 끝.
3. **광고 ID는 빌드 타임 주입** — 런타임 분기 대신 `String.fromEnvironment('ADMOB_MODE')`로 컴파일 시 결정. 실수로 테스트 ID가 프로덕션에 올라갈 위험 감소.

---

## 3. 컴포넌트 상세

### 3.1 `plan_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlanStatus { free, paid }

final planProvider = Provider<PlanStatus>((ref) {
  // 백엔드 권한 확보 전: 전원 Free 취급.
  // 추후 이 함수를 API 호출 또는 Supabase user_metadata 조회로 교체.
  return PlanStatus.free;
});
```

**교체 시점 전환 예시 (향후 참고용):**
```dart
final planProvider = FutureProvider<PlanStatus>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  final plan = user?.userMetadata?['plan'] as String?;
  return plan == 'paid' ? PlanStatus.paid : PlanStatus.free;
});
```

### 3.2 `ad_service.dart`

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}
```

`main()`에서 `runApp` 직전 1회 호출:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.initialize();
  runApp(const ProviderScope(child: App()));
}
```

### 3.3 `ad_ids.dart`

```dart
class AdIds {
  static const _mode = String.fromEnvironment('ADMOB_MODE', defaultValue: 'test');

  // Google 공식 테스트 광고 ID (Android)
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  // AdMob 계정 생성 후 교체 예정
  static const _prodBanner = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  static String get banner => _mode == 'prod' ? _prodBanner : _testBanner;
  static String get interstitial => _mode == 'prod' ? _prodInterstitial : _testInterstitial;
}
```

### 3.4 `ad_banner.dart`

```dart
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final plan = ref.read(planProvider);
    if (plan == PlanStatus.free) {
      _loadAd();
    }
  }

  void _loadAd() {
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(), // 재시도 없음
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
```

### 3.5 `ad_interstitial_trigger.dart`

```dart
class AdInterstitialTrigger {
  static InterstitialAd? _cached;
  static bool _loading = false;

  static void preload() {
    if (_cached != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _cached = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }

  static Future<void> showIfFree(WidgetRef ref) async {
    final plan = ref.read(planProvider);
    if (plan != PlanStatus.free) return;
    final ad = _cached;
    if (ad == null) return; // 아직 로드 안 됨 → 스킵
    _cached = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload(); // 다음 용도 준비
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        preload();
      },
    );
    await ad.show();
  }
}
```

---

## 4. 데이터 플로우

### 4.1 배너 광고
```
화면 build()
  → AdBanner 위젯 마운트
  → initState에서 ref.read(planProvider)
      ├─ Free: BannerAd.load()
      │   ├─ onAdLoaded: setState → AdWidget 렌더
      │   └─ onAdFailedToLoad: 위젯 숨김 (재시도 없음)
      └─ Paid: 아무것도 안 함, SizedBox.shrink 반환
  → dispose에서 BannerAd.dispose()
```

**재시도 없음 이유:** 재시도 루프는 대역폭/배터리 낭비. 다음 화면 진입 시 새 인스턴스가 자연히 재로드됨.

### 4.2 전면광고 (리포트 생성 플로우)
```
유저가 "리포트 생성" 버튼 탭
  → 리포트 API 호출 시작
  → 동시에 AdInterstitialTrigger.preload() 호출 (병렬)
  → API 응답 도착
      → UI에 리포트 렌더 (blocking X)
      → AdInterstitialTrigger.showIfFree(ref) 호출
          ├─ Free + 광고 로드됨: show() → 닫힘 후 다음 전면 preload()
          ├─ Free + 아직 로드중: skip
          ├─ Paid: skip
          └─ 로드 실패: skip, 다음 리포트 때 재시도
```

**핵심 결정:** 전면광고 로드를 **대기하지 않는다**. 리포트는 즉시 렌더, 광고는 "준비됐으면 띄움". UX 우선. 로드 실패가 자연스러운 빈도 완화 역할도 수행.

---

## 5. 에러 처리 원칙

| 상황 | 동작 |
|------|------|
| 네트워크 없음 | 광고 로드 실패 → 위젯 숨김, 에러 UI 미표시 |
| AdMob SDK 초기화 실패 | 앱 정상 동작, 광고만 미노출 (`AdService.initialize()`를 try/catch로 격리) |
| 광고 로드 중 화면 이탈 | `dispose()`에서 안전하게 해제 |
| 광고 표시 중 앱 백그라운드 전환 | AdMob SDK 자체 처리 |
| 전면광고 로드 실패 | 로그만 남기고 스킵 |

**원칙:** 광고는 앱의 **부가 기능**. 광고 오류가 본 기능(AI 채팅, 거래 기록, 리포트 생성 등)을 절대 막지 않는다. 모든 광고 관련 초기화/호출부는 try/catch로 격리.

---

## 6. 테스트 전략

### 6.1 유닛 테스트 (`flutter_app/test/`)

**`plan_provider_test.dart`:**
- 기본 상태에서 `PlanStatus.free` 반환 검증
- `overrideWithValue(PlanStatus.paid)`로 교체 시 `paid` 반환 검증

**`ad_banner_test.dart`:**
- Free plan → 위젯이 마운트되고 BannerAd 로드 시도 (mock)
- Paid plan override → `find.byType(SizedBox)` 확인, BannerAd 인스턴스 미생성

**`ad_ids_test.dart`:**
- 기본값(`ADMOB_MODE` 미설정) → 테스트 ID 반환
- prod 분기는 실 ID 교체 전까지 플레이스홀더 확인만

**AdMob SDK는 모두 mock.** 유닛 테스트에서 실제 네트워크 호출 금지.

### 6.2 수동 검증 체크리스트 (실기기/에뮬레이터)

| 항목 | 기대 결과 |
|------|----------|
| Android 앱 최초 실행 | 크래시 없음, AdMob SDK 초기화 로그 확인 |
| 세션 목록 하단 | "Test Ad" 라벨의 테스트 배너 노출 |
| 캘린더 / 통계 / 리포트 화면 | 각각 배너 노출 |
| `ai_chat` / `chat` / `record` / `auth` | 배너 미노출 확인 |
| 리포트 생성 완료 | 테스트 전면광고 팝업 (Close 버튼 동작) |
| 기내 모드 (네트워크 차단) | 앱 정상 동작, 배너 자리 빈 공간, 앱 크래시 없음 |
| Paid override 빌드 | `planProvider` 오버라이드로 광고 전부 미노출 확인 |

### 6.3 자동화 범위 한계
실제 AdMob 광고는 네트워크/외부 시스템 의존이라 완전 자동화는 불가. `integration_test/`에서는 plan 상태에 따른 `AdBanner` 가시성만 검증.

---

## 7. 출시 전 최종 체크리스트

1. AdMob 계정 생성 및 앱 등록
2. 배너/전면 Ad Unit 생성 → Ad Unit ID 획득
3. `ad_ids.dart`의 `_prodBanner`, `_prodInterstitial` 상수 교체
4. `AndroidManifest.xml`의 AdMob App ID meta-data 업데이트
5. `flutter build apk --release --dart-define=ADMOB_MODE=prod` 빌드 검증
6. Google Play 내부 테스트 트랙 배포 → 실 유저 피드백 수집
7. AdMob 대시보드에서 노출/클릭 이벤트 정상 기록 확인

---

## 8. 향후 작업 (이번 스펙 범위 외)

- **iOS 대응:** ATT 동의 팝업, Info.plist `SKAdNetworkItems`, `NSUserTrackingUsageDescription` 추가
- **백엔드 플랜 연동:** 백엔드 권한 확보 후 `planProvider` 내부를 API/Supabase metadata 조회로 교체
- **리워드 광고:** "광고 보고 AI 분석 1회 추가" 같은 가치 교환형. 유저 행동 데이터 수집 후 도입 검토
- **AdMob 미디에이션:** DAU 1만+ 도달 시 AppLovin MAX 도입 검토 (eCPM 20~40% 개선 기대)
- **빈도 조절:** 현재 전면광고 무제한. 유저 이탈률 데이터 기반으로 향후 일일/시간당 cap 도입 판단

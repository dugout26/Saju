# Android 포팅 전략 — CodeRabbit 검토 요청

> iOS 하루결 앱의 Android 포팅을 시작하기 전 tradeoff를 명시하고 합의 도출. iOS 코드와 동일 monorepo 안에 위치해 CR이 양 플랫폼 컨텍스트로 검토 가능.

## 배경

- **iOS 하루결** (이 repo의 `Unse/`): SwiftUI, SwiftData, StoreKit 2, Apple Sign-In, Kakao, FCM, AdMob, Supabase, Firebase
- v1.0.0 App Store 심사 제출 직전 (2-3일 대기)
- 심사 대기 동안 Android 포팅 시작

## Session 1 현재 상태 (`android/` 폴더)

- ✅ Gradle Android 프로젝트 (Kotlin 2.0 + Compose + JDK 17 + targetSdk 35)
- ✅ `manse` 패키지 — pure Kotlin 도메인 (Swift `Unse/Core/Saju/Manse.swift` 1:1 포팅)
- ✅ 단위 테스트 15건 PASS — iOS `UnseTests/ManseTests.swift`와 동일 fixture
- ✅ APK 빌드 SUCCESS

이미 결정한 부분:
- **Native Android (Kotlin + Jetpack Compose)** — KMP 안 씀
- **Monorepo** (`android/` 서브폴더) — CR이 iOS 비교 검토 가능
- **manse 패키지** Android 의존성 0 — 향후 KMP 모듈로 추출 가능한 구조

---

## CodeRabbit에 검토 요청하는 6가지

### Q1. 아키텍처 — Native Android Compose가 정답인가?

| 전략 | iOS 코드 공유 | UI 작업 | 학습 곡선 | 1.0 ETA |
|---|---|---|---|---|
| **Native Android (선택)** | 0% (도메인만 수동 포팅 완료) | Compose 풀 구현 | Kotlin + Compose만 | 4-6주 |
| Kotlin Multiplatform (KMP) | ~30% | Compose + SwiftUI 각각 | KMP Gradle, iOS framework export, Swift bridge | 6-8주 |
| Compose Multiplatform (CMP) | ~60% | Compose for both | iOS Compose 안정성 검증 X | 8-12주 (iOS 재작성) |
| Flutter 전체 재작성 | 0% | Dart + Flutter | iOS 매몰비용 + Flutter 학습 | 12+ 주 |

**Native Android 선택 근거**:
1. iOS는 출시 직전 — 코드 손대지 말아야 함 (Karpathy Surgical 원칙)
2. 도메인은 이미 deterministic 포팅 완료 (15 tests 검증, [Manse.kt](../android/app/src/main/kotlin/run/mound/unse/manse/Manse.kt) vs [Manse.swift](../Unse/Core/Saju/Manse.swift))
3. UI는 어차피 플랫폼별 네이티브 UX 필요 (Material 3 vs SwiftUI Apple HIG)
4. 1인 개발자 학습 부담 최소화

**우려점 (CR 의견 요청)**:
- 도메인 추후 변경 시 양쪽 동기화 비용 — 알고리즘 fix가 발생하면 양쪽 다 수정
- 향후 v2+ 에서 KMP 마이그레이션 가치

### Q2. 인증 — Kakao + Google? 또는 Kakao + Apple?

iOS는 Kakao + Apple Sign-In. Android에선 Apple Sign-In은 web view 방식이라 UX 어색.

옵션:
- **A. Kakao + Sign in with Google** — Android 네이티브 UX. iOS와 별도 계정 가능
- **B. Kakao + Sign in with Apple** — iOS 계정과 통합 가능. Android UX 떨어짐
- **C. Kakao만** — 단순. Google 계정 사용자 매출 손실

**잠정 결정**: **A 채택** — Android UX 우선. 서버 측 Supabase Auth에 Google Provider 추가 (Dashboard 설정).

### Q3. 결제 — Google Play Billing 구조

iOS: StoreKit 2 + `verify-receipt` Edge Function + `asn-v2-webhook` (구독 자동 동기화).

Android Play Billing 동등 흐름:
- Play Billing Library 7+ → 구매 토큰 발급
- 서버 검증: Google Play Developer API
- Real-time Developer Notifications (RTDN) — ASN v2 동등 (Pub/Sub)

**서버 측 추가 필요**:
- `verify-play-receipt` Edge Function — Google Play 구매 토큰 검증
- `play-rtdn-webhook` — Pub/Sub → Supabase 구독 상태 갱신

**CR 의견 요청**:
1. Play Billing v7 vs v8 (마이그레이션 진행 중) 안정성
2. RTDN: Pub/Sub 직접 vs Cloud Function → Supabase 분리

### Q4. SwiftData 동등 — Room? Realm? DataStore?

iOS는 SwiftData(`@Model`): UserProfile + SajuProfile + DailyFortune + SajuReading.

옵션:
- **Room** (Google 권장, SQLite wrapper)
- Realm (multiplatform, 빠른 ORM)
- DataStore (Preferences only — 우리 도메인엔 부족)

**잠정 결정**: **Room** — Google 표준, 학습 자료 풍부, KMP 시 SQLDelight 전환 가능.

### Q5. Push 알림 — FCM 단일 인프라

iOS는 APNs → Supabase `send-push` → FCM Service Account. Android는 FCM 직접 토큰.

**서버 변경 필요?**

현재 `users.push_token`은 iOS APNs token 1개 컬럼.

**제안 (CR 의견 요청)**: 단일 사용자가 양 디바이스 운영하는 경우 처리 방식
- **A.** `users.push_token` 공통 + `users.platform` 컬럼 추가 (마지막 디바이스 토큰만 저장)
- **B.** 별도 `device_tokens` 테이블 (1:N, user_id별 여러 디바이스)

**B가 더 견고하지만 마이그레이션 비용**. A는 단순하지만 multi-device 한계.

### Q6. AdMob — Android unit ID 분리

iOS [`AdsManager.swift`](../Unse/Core/Ads/AdsManager.swift)는 Debug=테스트 ID / Release=production ID 분기.

Android는 AdMob 콘솔에서 별도 앱 등록 + 별도 Banner/Rewarded unit 생성 필요. 코드 패턴 동일 (`BuildConfig.DEBUG` 분기).

**액션**: 사용자가 AdMob 콘솔 "하루결 Android" 앱 등록 + unit 발급.

---

## CodeRabbit에게 묻고 싶은 핵심 4가지

1. **Q1 아키텍처** — Native Android가 최선인가? KMP를 지금 도입할 가치가 있는가? 도메인 동기화 비용 관리 방안?
2. **Q3 결제** — Play Billing v7 vs v8, RTDN 처리 방식 추천
3. **Q4 DB** — Room이 합리적인가? SwiftData → Room 데이터 모델 매핑 시 주의점?
4. **Q5 Push 토큰 스키마** — A vs B + 마이그레이션 전략

추가로 빠뜨린 부분:
- Crashlytics / Firebase Performance / Analytics Android SDK 통합 (iOS는 이미 함)
- Android Network Security Config + Play Integrity API (App Attestation 대응)
- App Widget — iOS는 `UnseWidget/` 있음, Android Glance API로 동등 구현 가능

---

## Session 2 이후 로드맵 (검토 통과 후)

1. ~~Session 1: Bootstrap + 도메인 포팅 + 테스트~~ ✅ 완료
2. **Session 2**: Compose 골격 + Theme + Onboarding 4 슬라이드
3. **Session 3**: 인증 (Kakao + Google) + Supabase Kotlin SDK
4. **Session 4**: BirthInfoView + AnalyzingView + SajuResultView
5. **Session 5**: DailyFortuneView + AI 챗봇 SSE
6. **Session 6**: TimelineView 대운 차트 + Settings + 약관
7. **Session 7**: Room DB + 캐시
8. **Session 8**: Play Billing + RTDN webhook
9. **Session 9**: FCM + AdMob + Release 빌드
10. **Session 10**: Play Console 등록 + 내부 테스트

대략 **4-6주** 추정 (iOS와 동등 v1 기능).

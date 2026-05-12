# Android 포팅 전략 — CodeRabbit 검토 요청

> iOS 하루결의 Android 포팅 시작 전 tradeoff 명시 + 합의 도출. monorepo 구조라 CR이 iOS 코드(`ios/`)와 함께 검토 가능.

## 배경

- iOS 하루결 ([`ios/`](../ios/)) — SwiftUI, SwiftData, StoreKit 2, Apple Sign-In, Kakao, FCM, AdMob, Supabase, Firebase
- v1.0.0 App Store 심사 제출 직전 (2-3일 대기)
- 심사 대기 동안 Android 포팅 시작

## Session 1 현재 상태 ([`android/`](../android/))

- ✅ Gradle Android 프로젝트 (Kotlin 2.0 + Compose + JDK 17 + targetSdk 35)
- ✅ `manse` 패키지 — pure Kotlin 도메인 (Swift [`Manse.swift`](../ios/Unse/Core/Saju/Manse.swift) 1:1 포팅)
- ✅ 단위 테스트 15건 PASS — iOS [`ManseTests.swift`](../ios/UnseTests/ManseTests.swift)와 동일 fixture
- ✅ APK 빌드 SUCCESS

이미 결정한 부분:
- **Native Android (Kotlin + Jetpack Compose)** — KMP 안 씀
- **Monorepo** — `ios/` + `android/` 대칭 구조 (Pattern A)
- **manse 패키지** Android 의존성 0 — 향후 KMP 모듈로 추출 가능한 구조

---

## CodeRabbit에 검토 요청하는 6가지

### Q1. 아키텍처 — Native Android Compose가 정답인가?

| 전략 | iOS 코드 공유 | UI 작업 | 학습 곡선 | 1.0 ETA |
|---|---|---|---|---|
| **Native Android (선택)** | 0% (도메인만 수동 포팅 완료) | Compose 풀 구현 | Kotlin + Compose만 | 4-6주 |
| Kotlin Multiplatform (KMP) | ~30% | Compose + SwiftUI 각각 | KMP Gradle, iOS framework export, Swift bridge | 6-8주 |
| Compose Multiplatform (CMP) | ~60% | Compose for both | iOS Compose 안정성 X | 8-12주 (iOS 재작성) |
| Flutter 전체 재작성 | 0% | Dart + Flutter | iOS 매몰비용 + Flutter 학습 | 12+ 주 |

**Native Android 선택 근거**:
1. iOS는 출시 직전 — 코드 손대지 말아야 함 (Karpathy Surgical)
2. 도메인은 deterministic 포팅 완료 + 15 tests 검증
3. UI는 어차피 플랫폼별 네이티브 UX 필요 (Material 3 vs SwiftUI HIG)
4. 1인 개발자 학습 부담 최소화

**우려점 (CR 의견 요청)**:
- 도메인 추후 변경 시 양쪽 동기화 비용
- 향후 v2+ KMP 마이그레이션 가치

### Q2. 인증 — Kakao + Google? 또는 Kakao + Apple?

iOS는 Kakao + Apple. Android에선 Apple Sign-In web view라 UX 어색.

- **A. Kakao + Sign in with Google** — Android UX 자연스러움
- **B. Kakao + Sign in with Apple** — iOS 계정 통합 가능, UX 떨어짐
- **C. Kakao만** — 단순, Google 사용자 손실

**잠정 결정**: **A** — Android UX 우선. Supabase Auth에 Google Provider 추가.

### Q3. 결제 — Google Play Billing 구조

iOS: StoreKit 2 + [`verify-receipt`](../supabase/functions/verify-receipt/) Edge + [`asn-v2-webhook`](../supabase/functions/asn-v2-webhook/).

Android 동등:
- Play Billing Library 7+
- 서버 검증: Google Play Developer API
- RTDN (Real-time Developer Notifications) — Pub/Sub

**추가 필요**:
- `verify-play-receipt` Edge Function
- `play-rtdn-webhook` 또는 Pub/Sub → 직접 Supabase

**CR 의견 요청**: Play Billing v7 vs v8 안정성, RTDN 처리 패턴

### Q4. SwiftData 동등 — Room? Realm? DataStore?

iOS [`SajuProfile`, `UserProfile`, `DailyFortune`, `SajuReading`](../ios/Unse/Core/Storage/) → Android Room.

**잠정 결정**: **Room** — Google 표준, SQLDelight 마이그레이션 가능.

### Q5. Push 알림 — FCM 단일 인프라

iOS APNs → [`send-push`](../supabase/functions/send-push/) → FCM. Android는 FCM 직접.

`users.push_token` 현재 1 컬럼. 사용자 multi-device 처리:
- **A.** `users.platform` 컬럼 추가 (마지막 디바이스만 저장)
- **B.** `device_tokens` 테이블 (1:N)

**B가 견고하지만 마이그레이션 비용**. CR 의견 요청.

### Q6. AdMob — Android unit ID 분리

iOS [`AdsManager.swift`](../ios/Unse/Core/Ads/AdsManager.swift)는 Debug=테스트 / Release=production 분기. Android 동일 패턴 + AdMob 콘솔에서 별도 앱 등록.

---

## CodeRabbit에게 묻고 싶은 핵심 4가지

1. **Q1** Native Android가 최선인가? KMP 도입 가치?
2. **Q3** Play Billing v7 vs v8, RTDN 처리 방식
3. **Q4** Room이 합리적인가? SwiftData → Room 매핑 주의점?
4. **Q5** Push 토큰 스키마 A vs B + 마이그레이션 전략

추가로 빠뜨린 부분:
- Crashlytics / Firebase Performance / Analytics Android SDK
- Network Security Config + Play Integrity API
- Android Widget (iOS [`UnseWidget/`](../ios/UnseWidget/) → Glance API)

---

## Session 2 이후 로드맵

1. ~~Session 1: Bootstrap + 도메인~~ ✅
2. Session 2: Compose 골격 + Theme + Onboarding 4 슬라이드
3. Session 3: 인증 (Kakao + Google) + Supabase Kotlin SDK
4. Session 4: BirthInfoView + AnalyzingView + SajuResultView
5. Session 5: DailyFortuneView + AI 챗봇 SSE
6. Session 6: TimelineView 대운 차트 + Settings + 약관
7. Session 7: Room DB + 캐시
8. Session 8: Play Billing + RTDN webhook
9. Session 9: FCM + AdMob + Release 빌드
10. Session 10: Play Console 등록 + 내부 테스트

**4-6주 추정** (iOS와 동등 v1 기능).

# 하루결 Android

[하루결 iOS](https://github.com/dugout26/Saju)의 Android 포팅. Kotlin 2.0 + Jetpack Compose.

## 현재 상태 — Bootstrap (Session 1)

- [x] Gradle Android 프로젝트 셋업 (Kotlin 2.0, Compose, JDK 17, targetSdk 35)
- [x] 만세력 (`Manse`) 코어 알고리즘 포팅 (Swift → Kotlin) — pure value type
- [x] 모델: `Stem` / `Branch` / `Element` / `Pillar` / `SajuComputed` / `DaeWoon` / `BirthInput`
- [x] 단위 테스트 15건 — iOS `ManseTests.swift`와 동일 fixture 결과 확인
- [ ] Compose UI (Onboarding / Login / SajuResult / Daily / Timeline / Chat / Settings) — Session 2+
- [ ] Supabase Kotlin SDK 통합
- [ ] Sign in with Google + Kakao SDK
- [ ] StoreKit 대신 Google Play Billing
- [ ] FCM 푸시 + AdMob
- [ ] Play Store 출시

## Build

```bash
./gradlew test            # 15 unit tests
./gradlew assembleDebug   # debug APK
```

요구사항: JDK 17, Android SDK 35.

## 아키텍처

- **MV(VM)** 패턴 — iOS와 동일. 비즈니스 로직 ViewModel, UI Compose, Service layer로 분리.
- **manse 패키지** — pure Kotlin, Android 의존성 없음. 향후 KMP 공유 모듈로 추출 가능.

## iOS와의 관계

- 도메인 로직(만세력 계산)은 deterministic이라 Swift/Kotlin 결과 1:1 일치 검증됨.
- Supabase 백엔드, Edge Functions, DB 스키마는 iOS와 100% 공유.
- 사용자 데이터(SajuProfile, 구독 상태 등)는 Supabase에 있으므로 플랫폼 간 동기화 자동.

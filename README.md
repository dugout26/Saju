# 하루결 (Unse)

> 자평명리(子平命理) 기반 매일 운세 + AI 풀이 모바일 앱 (iOS + Android)

iOS: SwiftUI · iOS 17+ · Swift 6 · SwiftData
Android: Jetpack Compose · Kotlin 2.0 · Material 3
공통: Supabase · OpenAI

---

## 주요 기능

- **만세력 계산**: 율리우스 데이트 + 60갑자로 사주 8자 + 대운 도출 (서버 의존 없음)
- **매일 운세**: 일진 ↔ 사주 십신 관계 + 충/형/합/회 작용으로 매일 다른 결과
  - 한 줄 운세 + 행운의 색·방향·시간·숫자 + 피해야 할 것
- **AI 사주 풀이**: 단계별 깊이 있는 해석 (OpenAI GPT-4o-mini)
- **AI 챗봇**: 사주 기반 자유 질문 (스트리밍 응답)
- **매일 푸시 알림**: 사용자 지정 시각에 personalized 한 줄 운세
- **다크모드 + Dynamic Type** 완전 지원

## 기술 스택

| 영역 | 선택 |
|---|---|
| iOS | SwiftUI · iOS 17+ · Swift 6 (strict concurrency) |
| Android | Jetpack Compose · Kotlin 2.0 · Material 3 · minSdk 26 (Android 8.0+) |
| 로컬 저장 | iOS: SwiftData (VersionedSchema) / Android: 향후 Room |
| 백엔드 | Supabase (Postgres + Edge Functions + Auth) |
| AI | OpenAI GPT-4o-mini |
| 결제 | iOS: StoreKit 2 + ASC JWT(ES256) / Android: 향후 Play Billing |
| 푸시 | FCM (iOS는 APNs 경유) + pg_cron broadcast |
| 분석 | Firebase Crashlytics + Analytics + Performance |
| 광고 | Google AdMob |
| 인증 | Apple Sign-In + Kakao SDK → Supabase Auth |

## 아키텍처

MV(VM) 패턴:

```
View (SwiftUI)
  ↓ binds
ViewModel (@Observable @MainActor)
  ↓ calls
APIClient (actor) / Repository
  ↓
Supabase Edge / SwiftData
```

- `Features/<Name>/`: View + ViewModel
- `Core/Saju/`: 만세력 도메인 (순수 value type)
- `Core/Network/`: actor APIClient + DTOs
- `Core/Storage/`: SwiftData @Model
- `supabase/functions/`: Deno + TypeScript Edge Functions

자세한 가이드: [CLAUDE.md](CLAUDE.md)

## 개발 시작하기

### 사전 요구사항

```bash
brew install xcodegen swiftlint
gem install bundler:2.5.22   # fastlane 사용 시
```

### 셋업

```bash
git clone https://github.com/dugout26/Saju.git
cd Saju
cp Config.example.xcconfig Config.local.xcconfig
# Config.local.xcconfig를 열어 KAKAO_APP_KEY 입력
cd ios && xcodegen generate
open Unse.xcodeproj
```

### 필요한 secrets (gitignored, 사용자 환경별)

- `Unse/GoogleService-Info.plist` — Firebase Console에서 다운로드
- `Config.local.xcconfig` — KAKAO_APP_KEY 입력
- Supabase Dashboard → Edge Functions secrets: `OPENAI_API_KEY`, `ASC_PRIVATE_KEY`, `ASC_KEY_ID`, `ASC_ISSUER_ID`

### 빌드

```bash
# 시뮬레이터 빌드
xcodebuild -project Unse.xcodeproj -scheme Unse \
  -destination 'generic/platform=iOS Simulator' build

# 테스트 (54 tests)
xcodebuild test -project Unse.xcodeproj -scheme Unse \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Lint
swiftlint --strict
```

### TestFlight / App Store 배포

```bash
bundle install
bundle exec fastlane beta      # TestFlight 업로드
bundle exec fastlane release   # App Store 제출
bundle exec fastlane bump type:patch  # version bump
```

자세한 사전 작업: [HANDOFF.md](HANDOFF.md)

## Android

> 현재: Compose UI + 만세력 도메인 포팅 완료. Auth/Network/Storage/Push/Billing/Ads는 SDK 정책 결정 후 통합 예정.
> 진행 상태 + 사용자 환경 작업: [HANDOFF.md §9](HANDOFF.md)

### 사전 요구사항

- Android Studio (Ladybug 이상)
- JDK 17 (`brew install --cask temurin`)
- Android SDK (compileSdk 35, minSdk 26)

### 빌드

```bash
cd android
./gradlew :app:assembleDebug        # debug APK
./gradlew :app:assembleRelease      # release APK (R8 + ProGuard)
./gradlew :app:testDebugUnitTest    # 29 unit tests (만세력 도메인)
./gradlew :app:detekt               # 린트 (baseline 적용)
```

### 만세력 동등성

`android/app/src/main/kotlin/run/mound/unse/manse/` 는 iOS `Unse/Core/Saju/` 의 1:1 Kotlin 포트.
fixture 케이스 (1990-03-15, 2000-01-01, 1985-08-25, 입춘 경계, 시주 등)가 iOS Swift 결과와 동일하게 통과해야 함 — `ManseTest.kt` 29개 검증.

### 산출물

- `android/app/build/outputs/apk/debug/app-debug.apk` — 에뮬레이터/실기기 sideload
- `android/app/build/outputs/apk/release/app-release.apk` — R8 minify + adaptive icon + splash

## 문서

- [CLAUDE.md](CLAUDE.md) — Claude Code 세션용 프로젝트 컨텍스트 + Karpathy 4원칙
- [HANDOFF.md](HANDOFF.md) — 환경 셋업 + Phase 4 사용자 작업 체크리스트
- [CHANGELOG.md](CHANGELOG.md) — 버전 이력
- [legal/](legal/) — 약관·개인정보처리방침·면책

## 라이선스

비공개 (1인 운영, Mound).

## 문의

- 회사: **Mound**
- 이메일: support@mound.kr (placeholder — 실제 출시 시 갱신)

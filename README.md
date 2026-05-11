# 하루결 (Unse)

> 자평명리(子平命理) 기반 매일 운세 + AI 풀이 iOS 앱

SwiftUI · iOS 17+ · Swift 6 · SwiftData · Supabase · OpenAI

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
| 로컬 저장 | SwiftData (VersionedSchema) |
| 백엔드 | Supabase (Postgres + Edge Functions + Auth) |
| AI | OpenAI GPT-4o-mini |
| 결제 | StoreKit 2 + App Store Server API JWT(ES256) 영수증 검증 |
| 푸시 | FCM (APNs 경유) + pg_cron broadcast |
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
xcodegen generate
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

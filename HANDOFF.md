# HANDOFF — 2026-05-12

> 회사컴 → 집컴 인계 문서. 다음 세션은 이 파일을 먼저 읽고 시작.

---

## 1. 최근 작업 타임라인

### 2026-05-08 (Phase 3 마무리, #19~#23 머지)
Firebase Performance/Analytics, 다크모드/Dynamic Type, APIClientProtocol DI, fastlane lanes, ASN v2 webhook.

### 2026-05-11 (MVVM 분리 + 테스트 보강, #53~#58 머지)
- `SettingsService`/`OnboardingService.saveLocalProfile` 테스트 8건
- Deno test 인프라 + `dayPillar`/`deriveAction` 6건
- `EditSajuView`/`SettingsView`/`TimelineView` → 각각 ViewModel 분리 (MVVM)

### 2026-05-11~12 (실기기 검증 + 출시 직전 블로커, #60~#63)

| PR | 상태 | 내용 |
|---|---|---|
| [#60](https://github.com/dugout26/Saju/pull/60) | ✅ merged | `fix(push)`: 알림 시간 서버 동기화 누락 — Supabase `users.push_time`이 default '07:30:00'에 고정되던 버그 |
| [#61](https://github.com/dugout26/Saju/pull/61) | ✅ merged | `fix(login)`: Apple 버튼 maxWidth 누락 — Kakao 대비 가로폭 차이 |
| [#62](https://github.com/dugout26/Saju/pull/62) | ⏳ 대기 | `fix`: 로그인 버튼 폰트 통일(SignInWithAppleButton → 커스텀 Apple HIG 버튼 + Pretendard) + 로그아웃 stale `refreshedUser` |
| [#63](https://github.com/dugout26/Saju/pull/63) | ⏳ 대기 | `fix(auth)`: 재로그인 시 서버 `saju_profiles` 자동 fetch → 로컬 복원. Manse deterministic으로 pillar 직렬화 우회 |

---

## 2. 출시 전 체크리스트

### 2-1. 코드 작업 (대부분 완료)
- [x] Phase 1 출시 블로커 (PrivacyInfo / Crashlytics / ATT / StoreKit + ASN v2)
- [x] Phase 2 안정성 (CI, retry/backoff)
- [x] Phase 3 인프라 (Firebase Performance, 다크모드, DI, fastlane)
- [x] MVVM 분리 (#53~#58)
- [x] **AdMob production unit ID** — 이미 코드에 반영. Debug=Google 테스트 ID, Release=production ID([AdsManager.swift:13](Unse/Core/Ads/AdsManager.swift:13))
- [x] 약관/개인정보처리방침/면책 v1 문구 ([LegalDocumentView.swift](Unse/Features/Legal/LegalDocumentView.swift))
- [x] App Store 메타데이터 초안 ([docs/app-store-metadata.md](docs/app-store-metadata.md), 305줄)
- [x] PrivacyInfo.xcprivacy ([Unse/PrivacyInfo.xcprivacy](Unse/PrivacyInfo.xcprivacy))
- [ ] PR #62 + #63 머지 (CR + 사용자 시각 확인 후)

### 2-2. 사용자 환경 작업

| 항목 | 상태 | 비고 |
|---|---|---|
| `Unse/GoogleService-Info.plist` | (집/회사 별도) | Firebase Console |
| App Store Connect API key `.p8` | (집컴) | StoreKit verify + fastlane |
| Supabase secrets (`ASC_PRIVATE_KEY/KEY_ID/ISSUER_ID`) | ✅ 등록됨 | 사용자 보고 |
| Edge Functions 배포 | ⚠️ verify 필요 | `supabase functions deploy chat daily-fortune daily-detail kakao-auth saju-reading send-push verify-receipt asn-v2-webhook` |
| pg_cron + Vault + 0007 migration | ⚠️ verify 필요 | Dashboard → Extensions 활성, SQL editor에서 vault secret 등록 후 `supabase db push` |
| App Store Connect ASN v2 URL | ⚠️ | `https://<project>.functions.supabase.co/asn-v2-webhook` |
| fastlane ENV (`FASTLANE_APPLE_ID`, `ASC_PRIVATE_KEY_PATH` 등) | ⚠️ | `bundle exec fastlane beta` 실행 전 |
| AdMob console — production unit 활성 확인 | ⚠️ | 코드는 이미 production ID 사용 |

### 2-3. App Store Connect 작업
- [x] 메타데이터 초안 ([docs/app-store-metadata.md](docs/app-store-metadata.md))
- [ ] 스크린샷 자동 2장 캡처됨 ([docs/screenshots/](docs/screenshots/)) — 나머지 5-6장 수동 캡처 필요
- [ ] App Store Connect에서 앱 정보 입력 (이름·부제·키워드·설명)
- [ ] 연령 등급 (12+, 점복 카테고리)
- [ ] 카테고리: Entertainment / Reference
- [ ] In-App Purchase product 등록 (`unse.monthly`, `unse.yearly`)
- [ ] TestFlight 베타 50명 인비테이션

---

## 3. CD 전략 (옵션 A — 수동)

매번 `bundle exec fastlane beta` 로컬 실행. 사용 빈도 보고 GitHub Action으로 승급 검토.

```bash
# TestFlight 업로드 (build number 자동 증가 + archive + pilot upload)
bundle exec fastlane beta

# App Store 제출
bundle exec fastlane release

# MARKETING_VERSION만 bump
bundle exec fastlane bump version:1.0.1
```

**필수 환경변수**:
- `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_PATH` — App Store Connect API key
- `FASTLANE_APPLE_ID`, `FASTLANE_ITC_TEAM_ID` — Appfile에서 참조

---

## 4. 실기기 검증 시나리오 (CLAUDE.md §6 + 5/12 fix 검증)

PR #62 + #63 머지 전 마지막으로 cleanwater iPhone 15 Pro에서 확인:

1. **로그인 화면** — Kakao/Apple 버튼 폰트 + 가로폭 시각적 일치 (#62)
2. **설정 → 로그아웃** → OnboardingView 즉시 전환 (#62 stale `refreshedUser` fix)
3. **로그아웃 → 재로그인** → MainTabView 즉시 진입, 출생정보 재입력 X (#63 restore)
4. **설정 → 알림 시간 변경** → 다음 알림이 변경된 시각에 도착 (#60)
5. **CLAUDE.md §6 4 시나리오** — 편집/scenePhase/콜드 스타트/장시간

---

## 5. 디바이스 설치 명령

```bash
# cleanwater iPhone 15 Pro (와이파이 페어링)
xcodebuild -project Unse.xcodeproj -scheme Unse \
  -destination 'id=00008130-000A4D8136F8001C' \
  -configuration Debug -allowProvisioningUpdates build

xcrun devicectl device install app --device 9FE5BF11-2185-5B72-92A9-19AEF11C7BD7 \
  ~/Library/Developer/Xcode/DerivedData/Unse-acjvzkfyayeomzfvusdqfukkmywi/Build/Products/Debug-iphoneos/Unse.app
```

---

## 6. gh CLI 멀티계정 주의

- `2cr-Andy` (회사컴 기본) + `dugout26` (이 repo 권한자) 두 계정 등록.
- 머지·푸시 전 `gh auth switch -u dugout26` 필요.
- git push 시 osxkeychain이 2cr-Andy로 캐시되어 있어 토큰 명시 push 패턴 사용:
  ```bash
  git push "https://x-access-token:$(gh auth token)@github.com/dugout26/Saju.git" <branch>
  ```

---

## 7. 활성 메모리 (`~/.claude/projects/-Users-jeongsoobaek-Saju/memory/`)

- 1인 framing 금지
- CodeRabbit 자율 처리 (60-90s wakeup)
- silent fallback 금지
- PR push 후 보고 댓글 필수
- 작업 중 CI 대기 wakeup 금지
- 머지 후 브랜치 무조건 삭제
- 새 로직은 테스트 동시 작성

---

## 8. 참고 명령어

```bash
# 빌드 검증
xcodebuild -project Unse.xcodeproj -scheme Unse \
  -destination 'generic/platform=iOS Simulator' build

# 전체 테스트
xcodebuild test -project Unse.xcodeproj -scheme Unse \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Edge Functions Deno 테스트
deno test --no-check supabase/functions/

# Lint
swiftlint --strict

# Edge Function 개별 배포
supabase functions deploy asn-v2-webhook
```

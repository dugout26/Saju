# HANDOFF — 2026-05-11

> 회사컴 → 집컴 인계 문서. 다음 Claude Code 세션은 이 파일을 먼저 읽고 시작.
> 작성 시점: 2026-05-11 회사 작업 종료.

---

## 1. 오늘 완료 작업 (MVVM 분리 + 테스트 보강, 6개 PR)

| PR | 제목 | 변경 요약 |
|---|---|---|
| [#53](https://github.com/dugout26/Saju/pull/53) | test(settings): SettingsService SwiftData mutation 4건 | `updatePushEnabled/Time`, `deleteAccount`, `logout` 단위 테스트 |
| [#54](https://github.com/dugout26/Saju/pull/54) | test(onboarding): `saveLocalProfile` helper 추출 + 테스트 4건 | `completeSignup`에서 순수 SwiftData 저장 부분 분리해 testable |
| [#55](https://github.com/dugout26/Saju/pull/55) | test(edge): Deno test 인프라 + dayPillar/deriveAction 6건 | CI에 `denoland/setup-deno@v2` 추가, edge function 단위 테스트 첫 도입 |
| [#56](https://github.com/dugout26/Saju/pull/56) | refactor(edit-saju): EditSajuView → EditSajuViewModel | `@Observable @MainActor` ViewModel + 9 tests. round-1.1에서 `finishRecompute()` MVVM 위반 P1 수정 |
| [#57](https://github.com/dugout26/Saju/pull/57) | refactor(settings): SettingsView → SettingsViewModel | 7개 `@State` → ViewModel. `Crashlytics` import 제거. 5 tests |
| [#58](https://github.com/dugout26/Saju/pull/58) | refactor(timeline): TimelineView → TimelineViewModel | `daeWoonJSON` decode를 `nonisolated static`으로 분리, 4 tests |

master HEAD: `c898cf6`. 전 PR squash merge + 브랜치 정리 완료.

---

## 2. 집에서 가장 먼저 할 일

### 2-1. master 동기화
```bash
cd ~/Saju
git checkout master && git pull && git fetch --prune
xcodegen generate   # project.yml 변경분 반영 (UnseTests 새 파일 4개 포함)
```

### 2-2. 사용자(=직접) 작업 필요 — production 배포 전 필수 (2026-05-08부터 유지)

| 항목 | 회사컴 | 집컴 | 우선순위 | 비고 |
|---|---|---|---|---|
| `Unse/GoogleService-Info.plist` | ✅ | (집컴 별도) | 🔴 P0 | Firebase Console 다운로드 (gitignored) |
| App Store Connect API key (`.p8`) | ❌ | (집컴) | 🔴 P0 | StoreKit verify-receipt + ASN v2 + fastlane 동일 key |
| Supabase secrets 설정 | (Dashboard) | (Dashboard) | 🔴 P0 | `ASC_PRIVATE_KEY` (PEM), `ASC_KEY_ID`, `ASC_ISSUER_ID` |
| Edge Functions 배포 | (선택) | ✅ | 🔴 P0 | `supabase functions deploy verify-receipt asn-v2-webhook chat daily-fortune kakao-auth saju-reading send-push daily-detail` |
| pg_cron 활성화 + Vault secret + 0007 migration | — | ✅ | 🟡 P1 | Dashboard → Extensions에서 `pg_cron`, `pg_net` 활성. SQL editor: `select vault.create_secret('<service_role_jwt>', 'service_role_key');` + `vault.create_secret('https://<ref>.supabase.co', 'project_url');` → `supabase db push` |
| App Store Connect → ASN v2 URL 등록 | — | ✅ | 🟡 P1 | URL: `https://<project>.functions.supabase.co/asn-v2-webhook`, Version 2 |
| fastlane ENV 설정 | (선택) | ✅ | 🟡 P1 | `FASTLANE_APPLE_ID`, `FASTLANE_ITC_TEAM_ID`, `ASC_PRIVATE_KEY_PATH` |
| 실기기 + Release 빌드 검증 | (선택) | ✅ | 🔴 P0 | CLAUDE.md §6 4개 시나리오 (편집/scenePhase/콜드 스타트/장시간) |

---

## 3. 다음 작업 — 추천 순위

### 옵션 A (추천) — P2 backlog 일괄 정리 (1~2 PR로 묶음)

오늘 머지한 6개 PR의 CodeRabbit P2 nitpick들 — non-critical이라 모두 머지했으나 quality 개선 가치 있음:

| 항목 | 파일 | 작업 |
|---|---|---|
| #57-1 dangerSection guard | `Unse/Features/Settings/SettingsView.swift:307` | `vm.user == nil`일 때 logout/delete 버튼 hide |
| #57-2 dual source of truth | `Unse/Features/Settings/SettingsView.swift:6` | View의 `user` 프로퍼티 제거, `vm.user`만 사용 |
| #57-3 optimistic update rollback | `Unse/Features/Settings/SettingsViewModel.swift:36-57` | `setPushEnabled/Time` 실패 시 oldValue rollback + 성공 시 `pushSaveError = nil` |
| #58-1 magic 30 | `Unse/Features/Timeline/TimelineViewModel.swift:35-38` | `currentAge` fallback 30 → 명시 상수 or `Int?` |
| #58-2 user duplicate | `Unse/Features/Timeline/TimelineView.swift:5` | View의 `user` 프로퍼티 제거 |
| #56-1 no-op save shortcut | `Unse/Features/Settings/EditSajuViewModel.swift:69` | 닉네임/출생 모두 unchanged → 즉시 dismiss, 네트워크 호출 skip |
| #55-1 boundary test | `supabase/functions/asn-v2-webhook/deriveAction.test.ts:39` | `expiresDate === Date.now()` 정확히 검증 (지금은 `now - 1`이라 `<` 만 커버) |
| #53-1 persist-and-verify | `UnseTests/SettingsServiceTests.swift:24-33` | 새 ModelContext fetch로 persist 검증 |
| #54-1 authProvider 검증 | `Unse/Core/Services/OnboardingService.swift:44` | `apple`/`kakao` enum or 입구 validation |

권장: PR 2개로 묶기 — (a) MVVM polish (#57-1/2/3, #58-1/2, #56-1), (b) 테스트 quality (#55-1, #53-1, #54-1).

### 옵션 B — ShareCardView MVVM 분리 (가치 낮음)
사주 결과 공유 카드. 도메인 로직(snapshot 이미지 export) 분리. user-facing 가치 작음.

### 옵션 C — Phase 4 출시 작업 (사용자 환경 의존, 위 §2-2 참조)

### 옵션 D — 실기기 + Release 빌드 4 시나리오 검증 (CLAUDE.md §6)

---

## 4. 작업 흐름 / 환경

### 회사컴 / 집컴 동기화
- 모든 변경은 PR 거쳐 master 머지. master pull로 동기화.
- 집컴 첫 작업 전: `git pull && git fetch --prune && xcodegen generate`
- secrets는 안 가져옴 — 집컴에 .p8 / GoogleService-Info.plist / Supabase secrets 별도 보유

### gh CLI 주의 (오늘 작업 중 발견)
- `gh auth`에 `2cr-Andy` (회사컴 기본)와 `dugout26` (이 repo 권한자) 두 계정 등록.
- 머지·푸시 직전 `gh auth switch -u dugout26` 필요. 매 머지 후 active account가 회사 기본으로 reset되는 경우 있음.
- git push는 `git push "https://x-access-token:$(gh auth token)@github.com/dugout26/Saju.git" <branch>` 패턴 사용 (osxkeychain이 2cr-Andy로 캐시되어 있음).

### CodeRabbit 자율 운영 (memory 참고)
- 푸시 후 ScheduleWakeup으로 자율 polling·수정·재푸시
- PR 댓글에서 명시적 이슈 등록 요청 (standalone `@coderabbitai create issue` 금지)
- 수정 사이클 중 CI 대기 wakeup X — 사용자 보고 직전에만 일괄 검증

### 활성 메모리 (`~/.claude/projects/-Users-jeongsoobaek-Saju/memory/`)
- 1인 framing 금지
- CodeRabbit 자율 처리 (60-90s wakeup)
- silent fallback 금지
- PR push 후 보고 댓글 필수
- 작업 중 CI 대기 wakeup 금지
- 머지 후 브랜치 무조건 삭제
- 새 로직은 테스트 동시 작성

(집컴은 별도 memory 디렉토리. 같은 user면 sync 필요.)

---

## 5. 참고 명령어

```bash
# 현재 master 상태
git log --oneline -10

# 빌드 검증
xcodebuild -project Unse.xcodeproj -scheme Unse \
  -destination 'generic/platform=iOS Simulator' build

# 전체 테스트 (오늘 추가 — EditSaju/Settings/Timeline ViewModel + SettingsService + OnboardingService)
xcodebuild test -project Unse.xcodeproj -scheme Unse \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# 특정 ViewModel만 (예시)
xcodebuild test -project Unse.xcodeproj -scheme Unse \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:UnseTests/EditSajuViewModelTests

# Edge Functions Deno 테스트 (#55에서 도입)
deno test --no-check supabase/functions/

# Lint
swiftlint --strict

# Edge Function 배포 (개별)
supabase functions deploy asn-v2-webhook
```

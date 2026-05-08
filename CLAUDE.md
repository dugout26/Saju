# CLAUDE.md — Unse iOS

> 사주 기반 매일 운세 + AI 풀이 iOS 앱. 1인 SaaS (Mound).
> 기획서 원본: `~/Downloads/SAJU_APP_PLAN.md` (repo 외부, 개인 자료)

이 문서는 매 Claude Code 세션 시작 시 자동 로드됩니다.
**모든 코드 변경에 아래 원칙을 적용**합니다. 어기면 사용자가 reject합니다.

---

## 0. 절대 원칙 (Karpathy Guidelines) — 매 변경에 필수

> 출처: <https://x.com/karpathy/status/2015883857489522876>
> 트레이드오프: 속도보다 신중함. trivial한 작업은 판단으로.

### 1) Think Before Coding — 가정 명시, 혼란 숨기지 말 것
- 가정은 명시. 불확실하면 **묻기**.
- 해석이 여러 개면 **모두 제시**, 임의로 고르지 말 것.
- 더 단순한 방법이 있으면 그렇게 말하기. 필요하면 사용자 의견 push back.
- 무언가 불분명하면 멈추고 명명하고 묻기.

### 2) Simplicity First — 문제 푸는 최소 코드. 추측 금지
- 요청 외 기능 추가 금지.
- 단발성 코드에 추상화 금지.
- 요청 안 한 "유연성"·"설정 가능성" 금지.
- 일어날 수 없는 시나리오의 에러 핸들링 금지.
- 200줄 짠 게 50줄로 가능하면 다시 쓰기.
- "시니어가 이거 과하다고 할까?" → 그렇다면 단순화.

### 3) Surgical Changes — 손대야 할 것만. 내가 만든 쓰레기만 치우기
- 인접 코드/주석/포맷 "개선" 금지.
- 안 깨진 것 리팩토링 금지.
- 기존 스타일 따라가기. 내가 다르게 할 거여도 맞추기.
- 무관한 dead code 발견하면 **언급만**, 삭제 금지.
- 내 변경으로 고아가 된 import/var/func만 제거.
- 검증: 변경된 모든 줄이 사용자 요청에 직접 연결되는가?

### 4) Goal-Driven Execution — 성공 기준 정의, 검증될 때까지 루프
- "검증 X 추가" → "유효하지 않은 입력에 대한 테스트 작성, 통과시키기"
- "버그 수정" → "버그를 재현하는 테스트 작성, 통과시키기"
- "X 리팩토링" → "전후 테스트 통과 확인"
- 다단계 작업은 다음 형식으로 계획:
  ```
  1. [Step] → verify: [check]
  2. [Step] → verify: [check]
  ```

---

## 1. 기술 스택 (확정)

| 영역 | 선택 | 비고 |
|------|------|------|
| iOS | **SwiftUI**, iOS 17+ | NavigationStack, @Observable 사용 |
| 언어 | **Swift 6** | strict concurrency 활성. `SWIFT_VERSION: "6.0"` |
| 로컬 저장 | **SwiftData** (`@Model`) | Core Data 신규 사용 X |
| 백엔드 | **Supabase** (Postgres + Edge Functions + Auth) | Phase B에서 셋업 |
| AI | **OpenAI GPT-4o-mini** (단계별로 4o로 승급) | Claude 사용 X (비용 이슈) |
| 결제 | **StoreKit 2** + 서버 영수증 검증 | |
| 푸시 | **APNs** (직접) | Supabase scheduled function이 큐 |
| 인증 | 카카오 + 애플 → Supabase Auth | Phase B |
| 프로젝트 생성 | **xcodegen** (`project.yml`) | `.xcodeproj` 직접 편집 X |
| 린트 | **SwiftLint** (`.swiftlint.yml`) | prebuild script |
| 테스트 | **swift-testing** (`import Testing`) | XCTest 신규 사용 X. 별도 테스트 타겟에서만 |

---

## 2. 아키텍처 — MV(VM) 패턴 (1인 프로젝트 스코프)

복잡한 패턴 (TCA, Redux, Coordinator) 금지. 1인 운영에 부담.

```
View (SwiftUI)
  ↓ binds
ViewModel (@Observable @MainActor)
  ↓ calls
APIClient (actor) / Repository
  ↓
Network (Supabase Edge) / SwiftData
```

### 레이어 경계
- `Features/<Name>/`: View + ViewModel. UI 전용. 도메인 로직 금지.
- `Core/Network/`: `APIClient` (actor), Endpoints, **DTO struct (Sendable)**
- `Core/Storage/`: SwiftData `@Model` 클래스, Repository
- `Core/Saju/`: 만세력 도메인. **순수 value type, I/O 없음**
- `Core/DesignSystem/`: 색상·타이포·컴포넌트
- `Auth/`, `Push/`, `Subscription/`: 시스템 통합 wrapper

### 데이터 흐름
- **단방향**: View → ViewModel → APIClient/Repository → Network/SwiftData
- ViewModel은 View에서만 소유. 글로벌 싱글턴 ViewModel 금지.
- APIClient는 actor 싱글턴 OK (네트워크는 본질적으로 외부 격리).

### DTO ≠ Model — 분리 필수
- 서버 응답 DTO(struct, Sendable)와 SwiftData `@Model`(class, **non-Sendable**)을 절대 섞지 않음.
- actor 경계 넘기는 데이터는 **DTO만**. SwiftData 모델을 actor로 넘기면 data race.

---

## 3. Swift 6 Concurrency 규칙

- 새 코드는 항상 strict concurrency 가정.
- UI 상태: `@MainActor` + `@Observable`.
- I/O 상태: `actor`.
- 직렬화 데이터: `struct`, `Sendable` 명시.
- `Task {}`는 surrounding isolation을 inherit (Swift 6 변경).
- SwiftData `@Model`은 Sendable 아님 → DTO로 변환 후 actor 호출.
- `nonisolated` 남용 금지 — 진짜로 격리 불필요한 함수에만.

---

## 4. 보안 원칙 (필수, 양보 없음)

### 시크릿 관리
- **API 키 절대 클라이언트 X**: OpenAI/Anthropic 키는 **반드시** Supabase Edge Function 경유.
- 카카오 App Key, Supabase anon key는 Info.plist 변수화 (`KAKAO_APP_KEY` 패턴).
- `.gitignore`에 다음 추가 필수: `*.env`, `Secrets.plist`, `Config.local.xcconfig`, `GoogleService-Info.plist`, `*.p8` (APNs 키)
- 회사컴 작업 중 절대 git에 키 커밋 금지. 커밋 전 `git diff --staged | grep -iE "key|token|secret|password"` 체크.

### 인증·세션
- 사용자 토큰은 **Keychain** 저장. UserDefaults 금지.
- Supabase JWT는 access/refresh 분리. refresh는 Keychain.
- 모든 Supabase 테이블에 **RLS (Row Level Security)** 적용. user_id 기반.

### 데이터 보호
- 생년월일·시각은 **민감정보**. 서버 전송은 HTTPS only (ATS 강제, exception 금지).
- 로그·분석 이벤트에 PII (닉네임, 생년) 노출 금지. user_id 해시만.
- 결제 화면·사주 상세 화면은 `UIScreen.capturedDidChangeNotification` 처리 고려 (스크린샷 워터마크).

### 입력 검증
- 출생일자: 1900~현재 범위, 음력은 변환 가능 범위 체크.
- 챗봇 입력: 길이 제한 (예: 500자), 서버 측 키워드 필터 (의료·종목·확정표현).
- API 응답: JSON 디코딩 실패 시 안전한 기본값 + 사용자에게 부드러운 에러 메시지.

### LLM 콘텐츠 가드
- 시스템 프롬프트는 서버에 (클라이언트에 노출 금지).
- 출력 후필터: "절대", "100%", "반드시" 같은 단정 표현 차단.
- 의료·종목·자해 키워드는 입력·출력 양쪽 차단.

### iOS-specific
- **App Transport Security**: 모든 통신 HTTPS. exception 추가 금지.
- **Keychain access group**: 위젯과 메인 앱 공유 시에만 설정.
- **Privacy manifest** (`PrivacyInfo.xcprivacy`): iOS 17+ 필수. 사용 API와 데이터 수집 명시.

---

## 5. 디자인 시스템 규칙

- 색상은 항상 `Color.ink1`, `Color.lavender` 같은 **토큰**으로. `Color(hex: 0x...)` 직접 사용 금지 (단, `Colors.swift` 내부 정의 외).
- `extension ShapeStyle where Self == Color`로 promote되어 있어 `.foregroundStyle(.ink1)` shorthand 가능.
- 폰트는 `.pretendard(size, weight)` / `.serifKR(size, weight)` 헬퍼만.
- 간격은 `Spacing.sm/md/lg/xl/xxl/xxxl` 토큰만. 매직 넘버 금지.
- 새 컴포넌트는 `Core/DesignSystem/Components/` 하위에 작은 단위로.
- 톤: 화이트 베이스 + 라벤더/피치/민트/크림 파스텔 (기획서 1.페르소나).

---

## 6. 빌드 / 검증 명령

```bash
# 프로젝트 재생성 (project.yml 변경 후 필수)
xcodegen generate

# 시뮬레이터 빌드 (코드 변경 후 항상 검증)
xcodebuild -project Unse.xcodeproj -scheme Unse \
  -destination 'generic/platform=iOS Simulator' build

# 만세력 테스트 (Phase A Step 1 이후)
xcodebuild test -project Unse.xcodeproj -scheme Unse \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**가이드 4번 (Goal-Driven)**: 코드 변경 후 빌드 검증 통과 전엔 다음 작업으로 안 넘어감.

### TestFlight / App Store 제출 전 필수 — Device + Release 테스트
시뮬레이터 + Debug 빌드만 검증하면 SwiftData iOS 18 production 버그 (Release 빌드의 `BackingData.set` assertion 크래시 등)가 노출되지 않음.
다음 시나리오를 실기기 + Release scheme에서 반드시 한 번 돌려볼 것:

1. **출생 정보 편집 → 사주 재계산 흐름** (`SajuEditService.recomputeAndSaveLocally` + `invalidateReadings`)
2. **백그라운드 → 포그라운드 전환 후 사주 탭 진입** (FutureBackingData 우회 검증 — RootView scenePhase mitigation 동작 확인)
3. **앱 강제 종료 → 재실행 → 모든 탭 진입** (ModelContainer 복원, VersionedSchema 정상 로드)
4. **장시간 사용 (30분+) → 챗봇 streaming → 사주 풀이 연속 호출** (메모리 누수, Task cancellation)

---

## 6.5 Git 워크플로 — Trunk-Based + Release Branches (2026 모바일 표준)

> 모든 코드/문서 변경은 아래 흐름을 따른다. master(trunk) direct push 금지.
> 채택 근거: 2026 elite teams (Google/Amazon/Netflix, growing mobile teams) 기본.
> 풀 Git Flow의 `develop` 브랜치는 "main이 항상 deployable" 원칙과 충돌해 제외.

### 브랜치 정책

| 브랜치 | 역할 | 수명 | 비고 |
|---|---|---|---|
| `master` | **trunk** — 항상 release-ready, App Store 빌드 base | 영구 | direct push 금지. 보호됨 |
| `feat/<kebab>` | 신규 기능 | **1일 이내** (가능하면) | 미완성은 feature flag로 hide 후 머지 |
| `fix/<kebab>` | 버그 / 회귀 수정 | 단명 | 예: `fix/chat-stream-leak` |
| `chore/<kebab>` | 빌드·CI·린트·deps | 단명 | 예: `chore/swift-6-migration` |
| `docs/<kebab>` | README, CLAUDE.md, 가이드 | 단명 | 예: `docs/gitflow-policy` |
| `refactor/<kebab>` | 동작 무변경 코드 정리 | 단명 | audit 후속 PR 등 |
| `release/v<x.y.z>` | **App Store 제출 freeze**. master에서 cut, 안정화 fix만 적용 | 심사 통과까지 | tag 후 master back-merge |
| `hotfix/v<x.y.z>` | production 긴급 수정 | 매우 단명 | master 직접 분기 → master + 활성 release 양쪽 머지 |

브랜치명 = `<type>/<kebab-case-slug>`. 슬러그 50자 이내, 영문 소문자.

### 핵심 원칙 (2026 trunk-based)

1. **master는 절대 깨지지 않는다** — 매 commit이 release-ready
2. **PR은 작고 짧게** — 큰 작업은 feature flag로 점진 머지
3. **release branch는 freeze 용** — 새 기능 추가 금지, 안정화 fix만
4. **hotfix는 양방향 머지** — master + 모든 활성 release 브랜치에

### Commit 규약 — Conventional Commits

```
<type>(<scope?>): <한국어 요약 한 줄>

<본문 — why 중심, 줄당 100자 이내>

Co-Authored-By: ...
```

`type`: `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style` / `perf` / `build` / `ci`

scope는 선택 (예: `feat(chat): streaming 재시도 추가`). round 후속 fix는 `fix(round-N.M): ...` 패턴.

### PR 규약

- **1 PR = 1 논리 변경**. 여러 블로커 묶어 올리지 말 것.
- PR 제목 = commit summary와 일치 (squash 시 자동 사용)
- PR description: "왜" 중심 + 검증 방법 (build / lint / 실기기 시나리오)
- CodeRabbit auto-review 대기 후 P1/P2 응답
- **머지 전략 = squash + delete branch** (`gh pr merge <n> --squash --delete-branch`)
- 머지 후 로컬 브랜치 삭제 (`git branch -D` + `git fetch --prune`)

### Issue 규약 (심각도 큰 항목 고정화)

| Label | 사용 시점 |
|---|---|
| `blocker` | App Store 제출 거부 / production 데이터 손실 위험 |
| `security` | 인증·결제·secrets·PII 관련 |
| `monitoring` | crash·perf·analytics·alerting |
| `compliance` | privacy manifest, ATT, 약관, 법적 |
| `enhancement` | 신규 기능 / 개선 |
| `bug` | 재현 가능 결함 |
| `tech-debt` | refactor 대상 (audit 결과 등) |

CodeRabbit 코멘트로 발견된 P1/P2가 **다음 PR로 이월되거나 별도 작업으로 분리되어야 하면** Issue로 등록 (`@coderabbitai create issue` 또는 `gh issue create`). PR 코멘트만으로는 PR 머지 후 backlog가 휘발되므로.

### 브랜치 보호 / Required Checks

- `master`: direct push 금지 (정책상 + 가능하면 GitHub branch protection rule 적용)
- PR 머지 전 통과 필수: `iOS build · lint · test` (CI), CodeRabbit "P1/P2 미수정 없음" 명시 답변

### Feature Flag 정책 (점진 머지 핵심)

미완성 기능을 master에 머지할 때는 **꺼진 상태**로 들어가야 함. 패턴:

```swift
// Core/Storage/AppConfig.swift 또는 SwiftData 기반 설정
if AppConfig.isFeatureEnabled(.newWidget) {
    NewWidgetView()
}
```

원천: Supabase `app_config` 테이블 + 로컬 캐시. 출시 후 원격으로 점진 enable.

**Flag Debt 방지 — 모든 flag는 만료 계획을 가져야 함** (Martin Fowler, trunk-based 핵심).
flag 추가 시 아래 표에 등록, 전체 롤아웃 후 즉시 제거.

| Flag | 도입 PR | 활성화 조건 | 제거 목표 버전 | Owner |
|---|---|---|---|---|
| (예시) `.newWidget` | #99 | TestFlight 베타 검증 후 | v1.3 | @owner |

flag enum 자체에도 `// 제거 예정: v1.3` 주석 강제.

### App Store 배포 흐름

1. master HEAD 안정 확인 (CI 그린 + 실기기 sanity)
2. master에서 `release/v<x.y.z>` 분기
3. version bump commit (project.yml `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`)
4. git tag `v<x.y.z>` + push
5. archive → TestFlight 업로드 (fastlane 권장, 수동도 OK)
6. 베타 검증 — 발견된 버그는 release 브랜치에 fix 머지 (cherry-pick from master 또는 직접)
7. App Store 심사 제출
8. 심사 통과 → release 브랜치 master back-merge (release 동안 적용된 fix가 master에 반영되도록)
9. release 브랜치 삭제 (tag만 남김)

**release 동안 master 작업은 계속됨** (다음 버전 feature). 핵심: release 브랜치가 freeze 역할.

### Hotfix 흐름

1. master에서 `hotfix/v<x.y.z>` 분기 (이전 release tag 기준 버전 bump)
2. fix commit + tag
3. archive → TestFlight expedited review 요청 가능
4. 머지: hotfix → master + 모든 활성 release 브랜치 (있다면)

---

## 7. 폴더 구조 (확정)

```
Unse/
  Auth/           — Apple/Kakao login wrappers
  Core/
    DesignSystem/ — Colors, Typography, Spacing, Components/
    Network/      — APIClient(actor), Endpoints, DTOs
    Saju/         — Manse 엔진, 순수 value types
    Storage/      — SwiftData @Model, Repository
  Features/
    <Name>/       — View + ViewModel
  Push/
  Subscription/
UnseWidget/
UnseTests/        — Phase A Step 1에서 분리 예정
```

새 기능은 `Features/<Name>/` 하위에. View 안에 도메인 로직 들어가지 않게 — ViewModel로 빼기.

---

## 8. 진행 단계 (현재 위치 추적)

### Phase A — 회사컴 (백엔드 의존 0) ✅ **완료**
1. ✅ 만세력 테스트 타겟 분리 + 부록 B 케이스 통과 (11 tests PASS)
2. ✅ `SajuProfile → SajuComputed/DaeWoon` reconstruction (round-trip 검증)
3. ⏸ 온보딩→만세력→SwiftData→사주탭 end-to-end (사용자 직접 시뮬 검증 보류)
4. ✅ 매일 운세 규칙기반 계산 (8 engine tests + UI 동적 렌더링)
5. ✅ AI 호출 인터페이스 정의 + DEBUG mock (`APIClient.fetchSajuReading`)

총 19 tests PASS. iOS 앱 단독으로 작동.

### Phase B — 개인컴 이전 후 ← **다음 위치**

**시작 전 체크리스트** (개인컴에서):
- [ ] git pull (회사컴 마지막 commit 확인)
- [ ] xcodegen 설치 확인 (`brew install xcodegen`)
- [ ] swiftlint 설치 확인 (`brew install swiftlint`)
- [ ] `xcodebuild test -scheme Unse -destination 'platform=iOS Simulator,name=iPhone 17'` 통과 확인
- [ ] OpenAI API key 발급 (서버용)
- [ ] Supabase 계정 + 프로젝트 생성

**Phase B 작업 순서**:
6. Supabase 프로젝트 + DB schema (기획서 6장 그대로)
7. Edge Function: OpenAI proxy (사주 풀이 1·2단계, 매일 운세 한 줄, 챗봇 SSE)
8. [Endpoints.swift:4](Unse/Core/Network/Endpoints.swift:4)의 `base` URL → 실제 Supabase URL로 교체 → `APIClient`의 mock 자동 비활성
9. 카카오/애플 로그인 → Supabase auth 연동
10. 매일 운세 cron (Supabase scheduled function) + APNs 발송 큐
11. SajuResultView/DailyFortuneView의 `TODO(Phase B):` 주석 자리에서 mock → 실제 호출 전환

### Phase C — 출시 직전
12. StoreKit 실제 product + 영수증 서버 검증
13. AdMob + 카카오 애드핏
14. 약관·개인정보처리방침·면책
15. TestFlight 베타 50명

---

## 9. AI(=Claude/me)에게 — 매 응답 전 자가 점검

- [ ] Karpathy 4원칙 적용했는가? (특히 Surgical, Simplicity)
- [ ] 코드 변경했으면 `xcodebuild` 검증했는가?
- [ ] 백엔드 의존 작업을 Phase B 전에 시도하지 않았는가?
- [ ] 새 의존성 추가 전 사용자에게 물었는가?
- [ ] 시크릿(키·토큰) 코드에 박지 않았는가?
- [ ] 디자인 토큰 우회해서 hex 직접 박지 않았는가?
- [ ] DTO와 SwiftData `@Model` 섞지 않았는가?
- [ ] SwiftLint 룰 위반 추가하지 않았는가?
- [ ] 요청 외 기능·추상화·"개선" 추가하지 않았는가?

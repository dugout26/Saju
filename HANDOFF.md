# HANDOFF — 2026-05-08

> 회사컴 → 집컴 인계 문서. 다음 Claude Code 세션은 이 파일을 먼저 읽고 시작.
> 작성 시점: 2026-05-08 회사 작업 종료.

---

## 1. 오늘 완료 작업 (Phase 3, 5개 PR)

| PR | 제목 | 상태 | 변경 요약 |
|---|---|---|---|
| [#19](https://github.com/dugout26/Saju/pull/19) | Firebase Performance + Analytics 통합 (Phase 3-1) | ✅ merged | Performance/Analytics 의존성 추가, 로그인·구매 이벤트 로깅. CodeRabbit fix: GA4 `items` 배열, 불필요 `appInstanceID()` 제거 |
| [#20](https://github.com/dugout26/Saju/pull/20) | 다크모드 + Dynamic Type 지원 (Phase 3-2) | ✅ merged | `Color(light:dark:)` 동적 컬러, Typography에 `relativeTo: .body` |
| [#21](https://github.com/dugout26/Saju/pull/21) | APIClientProtocol + ViewModel DI + 6 async tests (Phase 3-3) | ✅ merged | actor APIClient → protocol DI 패턴. MockAPIClient + DailyFortune/SajuResult 테스트 (총 36건) |
| [#22](https://github.com/dugout26/Saju/pull/22) | fastlane TestFlight + App Store lanes (Phase 3-4) | ✅ merged | beta/release/bump 3-lane 자동화. CodeRabbit fix: `release` lane build_app, `bump` 직접 액션 호출, private_lane 추출 |
| [#23](https://github.com/dugout26/Saju/pull/23) | ASN v2 webhook (Phase 3-5) | ✅ merged | Apple Server Notifications V2 webhook. trusted-state-driven action (notificationType 미신뢰), 4xx/5xx 분리, environment 교차검증, started_at 보존 |

CodeRabbit 평가: 전 PR "구현 승인 가능합니다 🎉" / 잔존 known trade-off 1건만 — webhook spam (x5c chain 미검증 — 후속 PR 분리).

---

## 2. 집에서 가장 먼저 할 일

### 2-1. master 동기화
```bash
cd ~/Saju  # 집컴 path
git checkout master && git pull && git fetch --prune
xcodegen generate  # project.yml 변경분 반영
```

회사컴 작업분(5/5 PR)이 master에 모두 들어가 있음. 추가 머지 작업 없음.

### 2-2. 사용자(=직접) 작업 필요 — production 배포 전 필수
다음은 코드 외 사용자가 직접 해야 하는 작업. 모두 deferred 상태:

| 항목 | 회사컴 | 집컴 | 우선순위 | 비고 |
|---|---|---|---|---|
| `Unse/GoogleService-Info.plist` | ✅ 보유 | (집컴 별도 보유) | 🔴 P0 | 새 환경 셋업 시 Firebase Console에서 다운로드 (gitignored) |
| App Store Connect API key (`.p8`) | ❌ | (집컴 보유 시 OK) | 🔴 P0 | StoreKit verify-receipt + ASN v2 webhook + fastlane 모두 동일 key. 회사컴에선 배포 안 하면 불필요 |
| Supabase secrets 설정 | (Dashboard) | (Dashboard) | 🔴 P0 | `ASC_PRIVATE_KEY` (PEM 전체), `ASC_KEY_ID`, `ASC_ISSUER_ID`. Supabase Dashboard → Project Settings → Edge Functions → Secrets |
| Edge Functions 배포 | (선택) | ✅ 추천 | 🔴 P0 | `supabase functions deploy verify-receipt asn-v2-webhook chat daily-fortune kakao-auth saju-reading send-push daily-detail` |
| App Store Connect → ASN v2 URL 등록 | — | ✅ | 🟡 P1 | Production/Sandbox 동일 URL: `https://<project>.functions.supabase.co/asn-v2-webhook`, Version 2 |
| fastlane ENV 설정 | (선택) | ✅ 추천 | 🟡 P1 | `FASTLANE_APPLE_ID`, `FASTLANE_ITC_TEAM_ID`, `ASC_PRIVATE_KEY_PATH` (.p8 파일 경로) |
| 실기기 + Release 빌드 검증 | (선택) | ✅ 추천 | 🔴 P0 | CLAUDE.md §6 "TestFlight / App Store 제출 전 필수" 4개 시나리오 (편집/포그라운드/재실행/장시간) |

> 이미 회사컴/집컴에 셋업된 secrets는 별도 작업 불필요. 새 컴퓨터에서 시작할 때만 위 표 참조.

---

## 3. 다음 작업 (Phase 4 + 후속)

### 3-1. Phase 3 follow-up issues (CodeRabbit가 등록한 GitHub Issues)
- [#7](https://github.com/dugout26/Saju/issues/7) ~ [#10](https://github.com/dugout26/Saju/issues/10): 이전 라운드 critical 처리 후 잔존. 집에서 한 번 점검 필요 — 이미 해결된 것은 close.
- ASN v2 webhook x5c chain 검증 (webhook spam mitigation): 별도 PR로 분리. trusted state 모델은 견고하므로 우선순위 낮음.

### 3-2. Phase 4 — 출시 직전 (CLAUDE.md §8.12-15)
1. **StoreKit production product 등록** — App Store Connect에서 unse.monthly / unse.yearly 가격·소개 작성, 검토 제출
2. **AdMob production unit ID 교체** — 현재 테스트 단위 ID 사용 중인지 확인 (`AdsManager.swift`)
3. **카카오 애드핏** — 백업/대체 광고 네트워크 (선택)
4. **법적 문서** — 약관, 개인정보처리방침, 면책. 사주 앱은 종교/점복 카테고리라 면책 표현 필수
5. **TestFlight 베타 50명** — fastlane beta로 업로드, 베타 그룹 초대
6. **App Store 메타데이터** — 스크린샷 (6.7"/6.1"/5.5"), 키워드, 설명, 개인정보 보호 답변

### 3-3. Phase B 미완 (CLAUDE.md §8.10-11)
- 매일 운세 cron (Supabase scheduled function) + APNs 발송 큐 — 코드는 `send-push/` 있으나 cron 트리거 미구성
- SajuResultView/DailyFortuneView mock → 실제 호출 전환은 [Endpoints.swift:4](Unse/Core/Network/Endpoints.swift:4) URL만 교체하면 자동 전환

### 3-4. 알려진 이슈 / 기술 부채
- **SwiftData iOS 18 FutureBackingData 우회** (RootView scenePhase mitigation) — Apple 측 fix 후 제거 가능. 현재 `UnseApp.swift:131-134, 154-158` 적용
- **Test 호스트 앱 SIGABRT 가드** (`isRunningTests` flag) — Firebase init skip. 향후 더 깔끔한 host app 분리 가능
- **fastlane Gemfile 미도입** — CI 파이프라인 구축 시 함께 도입 (Phase 4)

---

## 4. 작업 흐름 / 환경

### 회사컴 / 집컴 동기화
- 모든 변경은 PR 거쳐 master 머지. master pull로 동기화.
- 집컴 첫 작업 전: `git pull && git fetch --prune && xcodegen generate`
- 회사컴 secrets는 안 가져옴 — 집컴에 .p8 / GoogleService-Info.plist / Supabase secrets 별도 보유

### CodeRabbit 자율 운영 (memory 참고)
- 푸시 후 ScheduleWakeup으로 자율 polling·수정·재푸시
- PR 댓글에서 명시적 이슈 등록 요청 (standalone `@coderabbitai create issue` 금지)
- 수정 사이클 중 CI 대기 wakeup X — 사용자 보고 직전에만 일괄 검증

### 활성 메모리 (`~/.claude/projects/-Users-jeongsoobaek-Saju/memory/`)
- 1인 framing 금지
- CodeRabbit 자율 처리
- silent fallback 금지
- PR push 후 보고 댓글 필수
- 작업 중 CI 대기 wakeup 금지

(집컴은 별도 memory 디렉토리. 같은 user면 sync 필요.)

---

## 5. 참고 명령어

```bash
# 현재 master 상태
git log --oneline -10

# 빌드 검증
xcodebuild -project Unse.xcodeproj -scheme Unse \
  -destination 'generic/platform=iOS Simulator' build

# 테스트 (총 36건)
xcodebuild test -project Unse.xcodeproj -scheme Unse \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Lint
swiftlint --strict

# Edge Function 배포 (개별)
supabase functions deploy asn-v2-webhook
```

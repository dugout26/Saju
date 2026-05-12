# App Store Screenshots — 6.9" iPhone 17 Pro Max

> 1320×2868 px. Apple은 6.9"만 업로드해도 6.5"/5.5"에 자동 다운스케일.

## 캡처된 5장 — App Store 업로드 ready

| 파일 | 화면 | 용도 |
|---|---|---|
| `01-onboarding-color.png` | Onboarding 슬라이드 1 — "오늘의 행운 색" 카드 스택 | 브랜드 첫인상 |
| `02-saju-result.png` | SajuResultView — 사주 8글자 + 오행 균형 | 핵심 가치 |
| `login.png` | LoginView — Kakao + Apple 통일 폰트 (`Pretendard 20 .bold`) | 진입 |
| `paywall.png` | PaywallView — PRO 구독 옵션 + 혜택 4건 | 매출 |
| `timeline.png` | TimelineView — 평생 흐름 대운 + PRO lock card | PRO 차별화 |

## 재캡처 방법

UnseApp.swift의 DEBUG-only launch arguments 활용. iPhone 17 Pro Max 시뮬레이터 + 디버그 빌드 필요.

### 1. 시뮬레이터 부팅 + 앱 설치
```bash
xcrun simctl boot 64A959A5-ABCA-42B3-95D1-ABF486E4F54E
xcodebuild -project Unse.xcodeproj -scheme Unse \
  -destination 'platform=iOS Simulator,id=64A959A5-ABCA-42B3-95D1-ABF486E4F54E' \
  -configuration Debug build
xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/Unse-*/Build/Products/Debug-iphonesimulator/Unse.app
```

### 2. 각 launch argument로 개별 캡처
```bash
# (no arg) — Onboarding 슬라이드 1
xcrun simctl launch booted kr.mound.unse
sleep 3
xcrun simctl io booted screenshot --type=png docs/screenshots/01-onboarding-color.png

# -preview-saju — SajuResultView
xcrun simctl terminate booted kr.mound.unse
xcrun simctl launch booted kr.mound.unse -preview-saju
sleep 3
xcrun simctl io booted screenshot --type=png docs/screenshots/02-saju-result.png

# -preview-login — LoginView 직접 표시 (Onboarding 우회)
# -preview-paywall — PaywallView 직접 표시
# -preview-timeline — TimelineView + PRO lock card (mock user)
# -preview-daily — DailyFortuneView (서버 호출 필요, error 500 표시 — 비추천)
```

## App Store Connect 업로드 절차

1. App Store Connect → My Apps → 하루결 → App Store → iOS App version 1.0.0
2. "iPhone Screenshots" 섹션 → "6.9-inch Display" 선택
3. 위 5장을 드래그앤드롭. 순서는 업로드 후 재정렬 가능.
4. 첫 3장이 검색 결과에 미리보기로 노출됨 — 가장 강한 컷 앞쪽 권장.

## 추가 권장 컷 (선택)

서버 의존 화면은 launch arg로 렌더링하기 어려움. 필요하면 실기기에서 실제 사용 중 캡처 후 추가:
- DailyFortuneView (오늘의 운세 + 행운 색)
- ChatView (AI 챗봇 대화)
- SettingsView (프로필 + 사주 요약)

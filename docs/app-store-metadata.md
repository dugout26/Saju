# App Store Connect 메타데이터 초안

> v1.0.0 출시용. App Store Connect → My Apps → 하루결 → App Information / App Store / Version Information에 입력.
> placeholder (`{{...}}`)는 사용자가 출시 직전 채움.

---

## 1. App Information

### 이름 (App Name) — 30자 제한
```
하루결
```
**대안 (검색 노출 강화 시):**
```
하루결: 사주 운세
```

### 부제 (Subtitle) — 30자 제한
```
자평명리 사주 + AI 매일 운세
```
**대안:**
```
사주 만세력 + AI 풀이
오늘의 운세 + 사주 풀이
```

### Bundle ID
```
kr.mound.unse
```

### Primary Category
```
Lifestyle (라이프스타일)
```
**대안**: Entertainment (점복 카테고리 명시 시 — Apple 정책상 명확히 Entertainment 권장)

### Secondary Category (선택)
```
Reference (참조)
```

### Content Rights
- Does this app contain third-party content?: **No**

### Age Rating (4.10 — 광고+점복)
- **17+ 권장 등급** (사주 풀이 + 챗봇 + 자유 텍스트 응답)
- 평가 항목:
  - Unrestricted Web Access: No
  - Gambling and Contests: No
  - Mature/Suggestive Themes: **None** (단, 운명/예측 콘텐츠 → Apple은 보통 12+)
  - Horror/Fear Themes: None
  - Frequent/Intense Mature Themes: None
  - **Fortune Telling: Yes** (한국 앱스토어 등록 시)
- 최종: **12+** 또는 **17+** (점복 카테고리 명시 시)

---

## 2. Version Information

### Promotional Text (홍보 텍스트) — 170자, 심사 없이 수시 변경 가능
```
매일 아침, 오늘의 한 줄 운세와 행운의 색을 만나보세요. 자평명리 정통 방식으로 계산된 사주 8자에 AI 풀이가 더해집니다.
```

### Description (앱 설명) — 4000자 제한
```
하루결은 자평명리(子平命理) 정통 방식으로 사주를 계산하고 AI가 풀이하는 매일 운세 앱입니다.

▶ 정확한 만세력 계산
60갑자 + 율리우스 데이트 + 24절기 기반으로 사주 8자(연주·월주·일주·시주)와 대운을 정확히 계산합니다.

▶ 매일 다른 운세
오늘의 일진(日辰)과 사주 십신 관계, 충/형/합/회 작용으로 매일 다른 운세를 생성합니다.
한 줄 운세, 행운의 색, 방향, 시간대, 숫자, 피해야 할 것까지 한눈에.

▶ AI 사주 풀이
GPT-4 기반의 깊이 있는 사주 해석. 일간 강약, 격국, 용신, 십신 관계를 친근한 한국어로 풀어냅니다.

▶ AI 챗봇
사주에 대한 자유로운 질문에 답합니다. "이번 달 금전운은?", "잘 맞는 사람의 일간은?" 같은 궁금증을 즉시 해소.

▶ 매일 푸시 알림
원하는 시각에 오늘의 운세가 도착합니다. 라벤더, 코랄, 민트, 크림 — 매일 다른 행운의 색과 함께.

▶ PRO 구독
- 광고 제거
- 무제한 AI 풀이 (무료는 광고 시청 후 1회)
- 자세한 풀이 확장
- 내일 운세 미리보기

▶ 개인정보 보호
- 출생 정보는 본인 디바이스와 암호화된 서버에만 저장
- Apple ID 또는 카카오 로그인 (생체 인증 가능)
- 언제든지 계정 삭제 시 모든 데이터 즉시 파기

▶ 면책
본 앱은 오락 및 정보 제공 목적이며, 의료/법률/금융 등 전문 분야의 조언을 대체하지 않습니다. 중요한 결정은 자격을 갖춘 전문가와 상담하시기 바랍니다.

문의: support@mound.kr
```

### Keywords (키워드) — 100자, 쉼표로 구분, 띄어쓰기 안 함
```
사주,운세,사주풀이,만세력,오늘운세,일진,대운,궁합,자평명리,점성술,오행,십신,사주팔자,띠별운세
```

### Support URL (지원 URL)
```
https://mound.kr/support
```
*(또는 GitHub Issues 또는 별도 지원 페이지)*

### Marketing URL (선택)
```
https://mound.kr/harukyeol
```

### Privacy Policy URL — 필수
```
https://mound.kr/privacy
```
*(또는 GitHub repo의 [legal/privacy-policy.md](../legal/privacy-policy.md) 호스팅 페이지)*

### What's New in This Version — 4000자, 버전마다 갱신
```
하루결 1.0 첫 출시!

✦ 정확한 사주 8자 + 대운 계산
✦ 매일 일진 기반 운세 + 행운의 색
✦ AI 사주 풀이 + 챗봇
✦ 매일 푸시 알림
✦ PRO 구독 (광고 제거 + 확장 기능)
✦ 다크모드 + 큰 글자 지원

여러분의 하루를 응원합니다 ❤️
```

---

## 3. App Privacy

### Data Used to Track You (ATT 동의 필요)
| Type | Purpose | Linked |
|---|---|---|
| Advertising Data (IDFA) | Third-Party Advertising | Yes |

### Data Linked to You
| Type | Subtype | Purpose |
|---|---|---|
| Contact Info | Name (닉네임) | App Functionality |
| User Content | Other User Content (사주 입력, 챗봇 대화) | App Functionality |
| Identifiers | User ID (Apple/Kakao ID) | App Functionality |
| Identifiers | Device ID (FCM 토큰) | App Functionality |
| Purchases | Purchase History | App Functionality |
| Diagnostics | Crash Data | App Functionality, Analytics |

### Data Not Linked to You
| Type | Subtype | Purpose |
|---|---|---|
| Usage Data | Product Interaction (login_method, purchase 이벤트) | Analytics |
| Diagnostics | Performance Data (Firebase Performance) | App Functionality, Analytics |

*(PrivacyInfo.xcprivacy와 일치 확인 필요)*

---

## 4. Pricing & In-App Purchases

### Base App
- 무료 (Free)

### In-App Purchases

| 식별자 | 가격 (KR) | 가격 (US) | 자동 갱신 |
|---|---|---|---|
| `unse.monthly` | ₩6,900 / 월 | $4.99 / month | 매월 |
| `unse.yearly` | ₩59,900 / 년 | $39.99 / year | 매년 (28% 할인) |

*가격은 사용자 결정. 위 값은 placeholder.*

### Subscription Group Display Name
```
하루결 PRO
```

### Subscription Display Name
```
하루결 PRO (월간)
하루결 PRO (연간)
```

### Subscription Description (App Store Connect)
```
광고 없이 무제한 AI 사주 풀이를 받아보세요. 매일 운세는 물론, 자세한 풀이와 내일 미리보기까지 PRO 사용자만의 혜택입니다.
```

### Review Notes (앱 심사 노트) — 4000자
```
하루결은 자평명리 사주 계산 + AI 풀이 앱입니다.

[테스트 계정]
- 카카오 로그인 또는 Apple Sign-In 사용
- 심사용 별도 계정 불필요 (게스트 흐름 없음)

[StoreKit 검증]
- Apple App Store Server API를 사용해 영수증을 서버에서 검증합니다.
- Sandbox 테스트 가능: 1) 가입 → 2) 사주 입력 → 3) Settings 탭 → 4) PRO 구독 → 5) 광고 제거 확인

[AI 콘텐츠 가드]
- 시스템 프롬프트에 의료/법률/금융 조언 차단, 자해 키워드 차단 명시
- 챗봇 응답에 "절대"·"100%"·"반드시" 단정 표현 제외
- 정서적 위기 상담 핫라인 (1393, 1577-0199) 면책 페이지에 게시

[데이터 수집]
- 출생 정보, 닉네임은 본인 디바이스 + 암호화된 Supabase 서버에 RLS 보호로 저장
- 결제 정보는 Apple App Store에서만 처리 (서버에 카드 정보 X)

[심사 거부 위험 사전 대응]
- 4.10 (Religion/Fortune Telling): 면책 명시, 의료/법률/금융 조언 X, 위기 상담 핫라인 표시
- 5.1.1 (Privacy): 명시적 ATT 프롬프트, 출생 정보는 본인만 접근 가능

문의: support@mound.kr
```

---

## 5. App Store Connect 체크리스트

- [ ] App Information 입력 (이름, 부제, 카테고리, 권한 등급)
- [ ] Version Information 입력 (홍보, 설명, 키워드, URL 3종)
- [ ] App Privacy 답변 (위 표 기준)
- [ ] In-App Purchases 등록 (`unse.monthly`, `unse.yearly`)
- [ ] Subscription Group 생성 + Display Name 입력
- [ ] Review Notes 작성 (위 텍스트 기반)
- [ ] Test User 등록 또는 자체 가입 흐름 보장
- [ ] Screenshots 업로드 (6.7" / 6.1" / 5.5" 각 5장)
- [ ] App Preview Video (선택, 30초 이내)
- [ ] Build 업로드 + 선택 (fastlane beta 후)
- [ ] Privacy Policy URL 호스팅 (mound.kr/privacy 또는 GitHub Pages)
- [ ] Support URL 호스팅
- [ ] 4.10 점복 카테고리 표기 + 면책 명시

---

## 6. Screenshots 디렉션 (별도 작업)

각 사이즈별 5장 추천 (출시 첫 3장이 검색 결과에 노출됨):

1. **온보딩 + 사주 입력** — "정확한 만세력 8자 계산"
2. **매일 운세 카드** — "오늘의 행운의 색과 시간"
3. **사주 풀이 화면** — "AI가 풀어주는 깊이 있는 해석"
4. **챗봇 대화** — "궁금한 점을 자유롭게 질문하세요"
5. **PRO 구독 / 다크모드** — "광고 없이, 무제한으로"

캡션은 8단어 이내 한국어. iOS Simulator에서 캡처 후 Figma 등으로 텍스트 오버레이.

---

## 7. 출시 후 갱신

- Promotional Text: 심사 없이 수시 갱신 (이벤트, 시즌 메시지)
- What's New: 버전마다 갱신
- Keywords: 검색 트렌드 분석 후 조정
- Screenshots: 큰 UI 변경 시 갱신

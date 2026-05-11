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
Entertainment (엔터테인먼트)
```
*점복(Fortune Telling) 콘텐츠는 4.10 맥락에서 Entertainment 분류가 표준. Lifestyle은 심사관 혼선 유발.*

### Secondary Category (선택)
```
Reference (참조)
```

### Content Rights
- Does this app contain third-party content?: **No**

### Age Rating (2025-07 신규 시스템 기준)
Apple은 2025년 7월부터 4+, 9+, 13+, 16+, 18+ 5단계 시스템 사용. 기존 12+, 17+ 등급 폐지.

- **권장 등급: 16+** (점복 + AI 챗봇 + 자유 텍스트 응답 — 미성년자 노출 부담)
  *AI 챗봇이 예측 불가능한 자유 텍스트를 생성하므로 18+로 상향 검토 가능*
- 평가 항목:
  - Unrestricted Web Access: No
  - Gambling and Contests: No
  - Mature/Suggestive Themes: None
  - Horror/Fear Themes: None
  - Frequent/Intense Mature Themes: None
  - **Fortune Telling: Yes**
  - **AI Chatbot / Generated Content: Yes** (Apple AI 가이드 추가 검토 요소)

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
AI 기반의 깊이 있는 사주 해석. 일간 강약, 격국, 용신, 십신 관계를 친근한 한국어로 풀어냅니다.

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
사주,운세,사주풀이,만세력,오늘운세,일진,대운,궁합,자평명리,명리학,역학,오행,십신,사주팔자,띠별운세
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

[테스트 계정 — App Review Guideline 2.1 준수]
다음 테스트 계정으로 즉시 로그인 가능합니다.

- 방식: Apple Sign-In (테스트 Apple ID로 가입된 계정)
- 이메일: {{심사용 Apple ID 이메일}}   ← 사용자 출시 직전 입력
- 비밀번호: {{심사용 Apple ID 비밀번호}}
- 또는: 카카오 계정 — 이메일: {{심사용 카카오 이메일}}, 비밀번호: {{심사용 카카오 비밀번호}}

테스트 계정에는 이미 사주 입력 + PRO 구독(Sandbox)이 완료된 상태로 모든 화면을 즉시 확인 가능합니다.

[차별성 — 4.10 Fortune Telling 카테고리 차별화 요구]
하루결은 시중 사주 앱과 다음 점에서 기술적으로 차별화됩니다.

1. 정확한 만세력 알고리즘
- 율리우스 데이트 + 24절기 (lichun 등) 기반 사주 8자 계산
- 부록 B의 11개 고전 검증 케이스 (예: 입춘 경계, 30분 단위 시지 분기) 통과
- 서버 의존 없이 클라이언트가 직접 계산 (offline 가능)

2. 자평명리 정통 분석
- 일간 강약 평가 (월령·통근·투출·합화 종합)
- 격국·용신 자동 추론
- 십신 관계 (비겁/식상/재성/관성/인성) 매일 일진과의 작용 분석
- 충(沖)/형(刑)/합(合)/회(會) 작용 명시적 처리

3. 매일 다른 결과 보장
- 일진(day pillar)이 매일 60갑자 순환에 따라 변하므로 같은 사주라도 매일 다른 운세
- 행운의 색·방향·시간·숫자가 오행 분포에 따라 동적 결정

4. AI 풀이의 안전 가드
- 시스템 프롬프트에서 의료/법률/금융 조언 차단
- "절대"·"100%"·"반드시" 단정 표현 명시 차단
- 자해/극단적 키워드 입출력 양방향 차단
- 정서적 위기 상담 핫라인 (1393, 1577-0199, 129) 면책 페이지에 항시 게시

[StoreKit 영수증 서버 검증]
- Apple App Store Server API를 ES256 JWT 인증으로 서버 측 영수증 검증
- 클라이언트가 위조한 transaction은 PRO 활성 실패
- ASN v2 webhook으로 환불/취소 실시간 처리

[Sandbox 테스트 시나리오]
1. 가입 (Apple 또는 카카오 로그인)
2. 사주 입력 (생년월일/시각/성별/닉네임)
3. 메인 화면 — 오늘의 운세 카드 + 행운의 색
4. 사주 탭 — AI 사주 풀이 (스트리밍 응답)
5. 챗봇 탭 — 자유 질문 (광고 시청 또는 PRO)
6. Settings → PRO 구독 (Sandbox 결제) → 광고 제거 확인

[데이터 수집]
- 출생 정보, 닉네임은 본인 디바이스 + 암호화된 Supabase 서버에 RLS 보호로 저장
- 결제 정보는 Apple App Store에서만 처리 (서버에 카드 정보 X)

[심사 거부 위험 사전 대응]
- 4.10 (Religion/Fortune Telling): 면책 페이지 명시, 의료/법률/금융 조언 X, 위기 상담 핫라인 게시, 차별성 위 4개 항목으로 입증
- 5.1.1 (Privacy): 명시적 ATT 프롬프트, 출생 정보는 본인만 접근 가능 (RLS)
- 2.1 (Demo Account): 위 테스트 계정 제공

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

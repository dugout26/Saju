# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 매일 운세 personalization: cache miss user에 daily-fortune pregenerate (#44)
- AnalyzingViewModel testability (OnboardingService DI) (#42)
- RewardedAdPresenting protocol + 광고 게이팅 단위 테스트 8건 (#43)
- pg_cron + Vault 기반 매일 푸시 broadcast 인프라 (#40)
- ASN v2 webhook — Apple Server Notifications 처리 (#23)
- daily-detail feature — 자세한 풀이 카드
- 다크모드 + Dynamic Type 지원
- Firebase Performance + Analytics 통합
- fastlane TestFlight + App Store lanes + Gemfile
- KAKAO_APP_KEY xcconfig 외부화 (보안)
- SPM 의존성 CI 캐싱
- 단위 테스트 36 → 54건 (Phase 3 완료 시점)

### Changed
- APIClient → actor + protocol DI 패턴
- StoreKit 영수증 검증: 클라이언트 단독 → App Store Server API JWT(ES256)

### Fixed
- send-push 23:30 윈도우 버그 (자정 wrap 시 user 미발송)
- N+1 쿼리 → 배치 SELECT/INSERT
- service_role JWT 위조 가능성 → 토큰 직접 비교
- Crashlytics setUserID 시 PrivacyInfo Linked=true 정확화

## [1.0.0] - TBD

첫 App Store 출시 예정.

### 출시 전 사용자 작업
- StoreKit production product 등록
- AdMob production unit ID 발급
- 약관 / 개인정보처리방침 / 면책 변호사 검토
- App Store 메타데이터 (스크린샷, 키워드, 설명)
- 실기기 Release 빌드 검증 (CLAUDE.md §6 4개 시나리오)
- Supabase secrets + pg_cron Vault 등록

import SwiftUI

/// 약관·개인정보처리방침·면책 고지 in-app 화면 (App Store 심사 표준).
/// v1 출시용 — 사주 카테고리 표준 문구. 향후 변호사 검토로 정교화.
struct LegalDocumentView: View {
    enum Kind {
        case terms, privacy, disclaimer

        var title: String {
            switch self {
            case .terms:      "이용약관"
            case .privacy:    "개인정보처리방침"
            case .disclaimer: "면책 고지"
            }
        }
    }

    let kind: Kind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(kind.title)
                    .font(.serifKR(24, .semibold))
                    .foregroundStyle(.ink1)

                Text(Self.body(for: kind))
                    .font(.pretendard(14))
                    .foregroundStyle(.ink2)
                    .lineSpacing(6)

                Text("시행일: 2026년 5월 1일")
                    .font(.pretendard(11))
                    .foregroundStyle(.ink3)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func body(for kind: Kind) -> String {
        switch kind {
        case .terms:
            return """
            제1조 (목적)
            본 약관은 하루결(이하 "회사")가 제공하는 사주·운세 서비스(이하 "서비스") 이용과 관련하여 회사와 이용자 간의 권리·의무 및 책임 사항을 규정함을 목적으로 합니다.

            제2조 (용어의 정의)
            ① "서비스"란 사주 8글자 풀이, 매일 운세, AI 챗봇 등 회사가 제공하는 운세 콘텐츠 전반을 말합니다.
            ② "이용자"란 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.

            제3조 (서비스의 성격)
            본 서비스는 전통 명리학에 기반한 참고·오락 목적의 콘텐츠를 제공하며, 어떠한 결정의 근거나 보장을 의미하지 않습니다.

            제4조 (유료 서비스 및 환불)
            ① 유료 구독은 Apple App Store 정책에 따릅니다.
            ② 청약철회는 결제일로부터 7일 이내, 미사용 상태에서 가능합니다.

            제5조 (책임의 한계)
            회사는 본 서비스 콘텐츠를 근거로 한 의료·재정·법적 결정에 책임지지 않습니다.
            """

        case .privacy:
            return """
            1. 수집하는 개인정보
            • 필수: 닉네임, 생년월일·시각(사주 계산용)
            • 선택: 이메일(애플 로그인 시 자동), 푸시 토큰
            • 자동 수집: 기기 식별자, OS 버전, 앱 버전

            2. 수집 목적
            • 사주 계산 및 운세 콘텐츠 제공
            • 매일 알림 전송 (사용자가 동의한 경우)
            • 서비스 개선 및 통계 분석

            3. 보유 기간
            • 회원 탈퇴 시 즉시 삭제
            • 단, 전자상거래법 등 관련 법령에서 정한 기간은 예외

            4. 제3자 제공
            • OpenAI: 사주 풀이 AI 응답 생성을 위해 사주 정보(개인 식별 정보 제외) 전송
            • Apple: In-App Purchase 결제 처리
            • 그 외 제3자에게 개인정보를 판매하거나 공유하지 않습니다.

            5. 이용자 권리
            • 언제든지 회원 탈퇴를 통해 모든 정보 삭제 가능
            • 개인정보 열람·정정·삭제 요청: support@unse.kr

            6. 인공지능(AI) 콘텐츠 고지
            본 서비스의 풀이 텍스트는 AI(OpenAI GPT 모델)가 사주 정보를 기반으로 생성한 결과입니다.
            """

        case .disclaimer:
            return """
            본 앱은 전통 명리학에 기반한 참고·오락 목적의 운세 콘텐츠를 제공합니다.

            • 본 앱의 콘텐츠는 의료, 법적, 재정적 조언이 아닙니다.
            • 사주 풀이, 매일 운세, 챗봇 응답은 모두 참고용이며 어떠한 결정의 보장이 아닙니다.
            • 중요한 결정은 전문가(의사, 변호사, 재무 상담사 등)와 상의하시기 바랍니다.
            • AI가 생성한 풀이 텍스트는 부정확할 수 있으며, 회사는 그 정확성을 보장하지 않습니다.
            """
        }
    }
}

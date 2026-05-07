import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var sub
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID = "unse.yearly"
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var yearlyProduct: Product? { sub.products.first { $0.id == "unse.yearly" } }
    private var monthlyProduct: Product? { sub.products.first { $0.id == "unse.monthly" } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                        .padding(.bottom, 32)

                    featureList
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                    planPicker
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    ctaSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)

                    footerLinks
                        .padding(.bottom, 40)
                }
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.ink3)
                            .frame(width: 28, height: 28)
                            .background(Color.surface)
                            .clipShape(Circle())
                    }
                }
            }
            .task { await sub.loadProducts() }
        }
    }

    // MARK: - Sub-views

    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color.lavenderSoft, Color.bg],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 260)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.lavender.opacity(0.3))
                        .frame(width: 80, height: 80)
                    Text("戊")
                        .font(.serifKR(36, .semibold))
                        .foregroundStyle(Color.lavenderDeep)
                }

                VStack(spacing: 6) {
                    Text("하루결 PRO")
                        .font(.serifKR(28, .semibold))
                        .foregroundStyle(.ink1)
                    Text("자세한 5단계 풀이와\n무제한 AI 챗봇")
                        .font(.pretendard(14))
                        .foregroundStyle(.ink2)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("🎉 오픈 특가 — 평생 ₩4,900 lock-in")
                        .font(.pretendard(11, .semibold))
                        .foregroundStyle(Color.lavenderDeep)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.lavenderSoft)
                        .clipShape(Capsule())
                        .padding(.top, 6)
                }
            }
            .padding(.top, 24)
        }
    }

    private var featureList: some View {
        VStack(spacing: 12) {
            featureRow(
                icon: "sparkles",
                title: "무제한 AI 챗봇",
                description: "사주에 대한 모든 궁금증을 AI와 함께"
            )
            featureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "평생운 + 5단계 풀이",
                description: "10년 대운 흐름과 평생 종합 분석"
            )
            featureRow(
                icon: "rectangle.stack.badge.person.crop",
                title: "영역별 자세한 풀이",
                description: "직업·금전·연애·건강 4영역 분석"
            )
            featureRow(
                icon: "bell.badge",
                title: "매일 운세 자세히",
                description: "오늘 시간대별 행운 + 광고 없음"
            )
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.lavenderSoft)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.lavenderDeep)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pretendard(14, .semibold))
                    .foregroundStyle(.ink1)
                Text(description)
                    .font(.pretendard(12))
                    .foregroundStyle(.ink3)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.lavenderDeep)
        }
    }

    private var planPicker: some View {
        VStack(spacing: 10) {
            if let yearly = yearlyProduct {
                planCard(
                    product: yearly,
                    badge: "가장 인기",
                    isSelected: selectedProductID == yearly.id,
                    monthlyEquivalent: monthlyEquivalent(for: yearly)
                )
                .onTapGesture { selectedProductID = yearly.id }
            }

            if let monthly = monthlyProduct {
                planCard(
                    product: monthly,
                    badge: nil,
                    isSelected: selectedProductID == monthly.id,
                    monthlyEquivalent: nil
                )
                .onTapGesture { selectedProductID = monthly.id }
            }

            if sub.products.isEmpty {
                skeletonPlanCard
                skeletonPlanCard
            }
        }
    }

    private func planCard(
        product: Product,
        badge: String?,
        isSelected: Bool,
        monthlyEquivalent: String?
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? Color.lavenderDeep : Color.line, lineWidth: 2)
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle()
                        .fill(Color.lavenderDeep)
                        .frame(width: 12, height: 12)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(product.displayName)
                        .font(.pretendard(15, .semibold))
                        .foregroundStyle(.ink1)
                    if let badge {
                        Text(badge)
                            .font(.pretendard(10, .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.lavenderDeep)
                            .clipShape(Capsule())
                    }
                }
                if let equiv = monthlyEquivalent {
                    Text(equiv)
                        .font(.pretendard(12))
                        .foregroundStyle(.ink3)
                }
            }

            Spacer()

            Text(product.displayPrice)
                .font(.pretendard(16, .semibold))
                .foregroundStyle(.ink1)
        }
        .padding(16)
        .background(isSelected ? Color.lavenderSoft : Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Color.lavenderDeep : Color.line, lineWidth: isSelected ? 1.5 : 1)
        )
    }

    private var skeletonPlanCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.surface)
            .frame(height: 72)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.line, lineWidth: 1)
            )
    }

    private var ctaSection: some View {
        VStack(spacing: 10) {
            if let error = errorMessage {
                Text(error)
                    .font(.pretendard(12))
                    .foregroundStyle(Color(hex: 0xC97070))
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                title: isPurchasing ? "처리 중..." : "시작하기",
                color: Color.lavenderDeep
            ) {
                Task { await purchase() }
            }
            .disabled(isPurchasing || sub.products.isEmpty)

            Button {
                Task { try? await sub.restorePurchases() }
            } label: {
                Text("이미 구독 중이에요")
                    .font(.pretendard(13))
                    .foregroundStyle(.ink3)
                    .underline()
            }
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Link("이용약관", destination: URL(string: "https://unse.kr/terms")!)
            Text("·").foregroundStyle(.ink4)
            Link("개인정보처리방침", destination: URL(string: "https://unse.kr/privacy")!)
        }
        .font(.pretendard(11))
        .foregroundStyle(.ink3)
    }

    // MARK: - Actions

    private func purchase() async {
        guard let product = sub.products.first(where: { $0.id == selectedProductID }) else { return }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            try await sub.purchase(product)
            dismiss()
        } catch {
            errorMessage = "결제 중 오류가 발생했어요. 다시 시도해주세요."
        }
    }

    private func monthlyEquivalent(for product: Product) -> String? {
        guard product.id == "unse.yearly",
              let monthly = monthlyProduct else { return nil }

        let yearlyMonthly = (product.price / 12).formatted(.number.precision(.fractionLength(0)))
        return "월 \(yearlyMonthly)원 · \(monthly.displayPrice)보다 저렴"
    }
}

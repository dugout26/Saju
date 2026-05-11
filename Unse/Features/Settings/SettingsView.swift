import SwiftUI
import SwiftData

struct SettingsView: View {
    var user: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var sub
    @State private var vm: SettingsViewModel

    init(user: UserProfile? = nil) {
        self.user = user
        _vm = State(initialValue: SettingsViewModel(user: user))
    }

    private var nickname: String { user?.nickname ?? "사용자" }

    var body: some View {
        NavigationStack {
            List {
                profileSection
                sajuSection
                subscriptionSection
                notificationSection
                supportSection
                dangerSection
                #if DEBUG
                debugSection
                #endif
            }
            .listStyle(.insetGrouped)
            .background(Color.bg.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $vm.showPaywall) {
                PaywallView()
                    .environment(sub)
            }
            .alert("계정 삭제", isPresented: $vm.showDeleteAlert) {
                Button("삭제", role: .destructive) {
                    vm.deleteAccount(modelContext: modelContext)
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("모든 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
            .alert("로그아웃", isPresented: $vm.showLogoutAlert) {
                Button("로그아웃", role: .destructive) {
                    Task { await vm.logout(modelContext: modelContext) }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("로그아웃하면 시작 화면으로 돌아갑니다.")
            }
            .alert("로그아웃 실패", isPresented: Binding(
                get: { vm.logoutError != nil },
                set: { if !$0 { vm.logoutError = nil } }
            )) {
                Button("확인") { vm.logoutError = nil }
            } message: {
                Text(vm.logoutError ?? "")
            }
            .alert("저장 실패", isPresented: Binding(
                get: { vm.pushSaveError != nil },
                set: { if !$0 { vm.pushSaveError = nil } }
            )) {
                Button("확인") { vm.pushSaveError = nil }
            } message: {
                Text(vm.pushSaveError ?? "")
            }
            .alert("삭제 실패", isPresented: Binding(
                get: { vm.deleteError != nil },
                set: { if !$0 { vm.deleteError = nil } }
            )) {
                Button("확인") { vm.deleteError = nil }
            } message: {
                Text(vm.deleteError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.lavenderSoft)
                        .frame(width: 52, height: 52)
                    Text(nickname.prefix(1))
                        .font(.serifKR(22, .semibold))
                        .foregroundStyle(Color.lavenderDeep)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(nickname)
                        .font(.pretendard(16, .semibold))
                        .foregroundStyle(.ink1)
                    Text(user?.authProvider ?? "게스트")
                        .font(.pretendard(12))
                        .foregroundStyle(.ink3)
                }
            }
            .padding(.vertical, 6)

            // 사주 정보 요약 — 사주 프로필이 있을 때만 표시.
            if let saju = user?.sajuProfile {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    profileRow(label: "생년월일", value: Self.birthDateLabel(saju))
                    profileRow(label: "성별", value: saju.gender)
                    profileRow(label: "사주", value: Self.eightCharsLabel(saju))
                }
                .padding(.vertical, Spacing.xs)
            }
        }
    }

    /// "1996년 3월 15일 (양력) 14:00" 형식. 시각 미입력 시 "시간 미상".
    private static func birthDateLabel(_ saju: SajuProfile) -> String {
        let calendarSuffix = saju.birthCalendar == "lunar" ? "음력" : "양력"
        let dateStr = "\(saju.birthYear)년 \(saju.birthMonth)월 \(saju.birthDay)일 (\(calendarSuffix))"
        if let h = saju.birthHour {
            let m = saju.birthMinute ?? 0
            return dateStr + " \(String(format: "%02d:%02d", h, m))"
        }
        return dateStr + " · 시간 미상"
    }

    /// "丙子 庚寅 戊午 己未" — 사주 8자.
    private static func eightCharsLabel(_ saju: SajuProfile) -> String {
        var parts = [
            "\(saju.yearStem)\(saju.yearBranch)",
            "\(saju.monthStem)\(saju.monthBranch)",
            "\(saju.dayStem)\(saju.dayBranch)"
        ]
        if let hs = saju.hourStem, let hb = saju.hourBranch {
            parts.append("\(hs)\(hb)")
        }
        return parts.joined(separator: " ")
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.pretendard(13))
                .foregroundStyle(.ink3)
            Spacer()
            Text(value)
                .font(.pretendard(13, .medium))
                .foregroundStyle(.ink2)
        }
    }

    @ViewBuilder
    private var sajuSection: some View {
        if let user {
            Section(header: Text("사주")) {
                NavigationLink {
                    EditSajuView(user: user)
                } label: {
                    Label("사주 정보 편집", systemImage: "person.text.rectangle")
                        .font(.pretendard(14))
                        .foregroundStyle(.ink1)
                }
            }
        }
    }

    private var subscriptionSection: some View {
        Section(header: Text("구독")) {
            if sub.isPremium {
                HStack {
                    Label("PRO 구독 중", systemImage: "star.fill")
                        .font(.pretendard(14))
                        .foregroundStyle(.ink1)
                    Spacer()
                    ProBadge()
                }

                if let expires = user?.subscriptionExpiresAt {
                    settingsRow(
                        icon: "calendar",
                        title: "구독 만료일",
                        value: expires.formatted(date: .abbreviated, time: .omitted)
                    )
                }

                Button {
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("구독 관리", systemImage: "creditcard")
                        .font(.pretendard(14))
                        .foregroundStyle(.ink1)
                }
            } else {
                Button { vm.showPaywall = true } label: {
                    HStack {
                        Label("PRO로 업그레이드", systemImage: "sparkles")
                            .font(.pretendard(14, .semibold))
                            .foregroundStyle(Color.lavenderDeep)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.ink4)
                    }
                }
            }
        }
    }

    private var notificationSection: some View {
        Section(header: Text("알림")) {
            Toggle(isOn: $vm.pushEnabled) {
                Label("오늘의 운세 알림", systemImage: "bell")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
            }
            .tint(Color.lavenderDeep)
            .onChange(of: vm.pushEnabled) { _, newValue in
                vm.setPushEnabled(newValue, modelContext: modelContext)
            }

            if vm.pushEnabled {
                DatePicker(
                    selection: $vm.pushTime,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("알림 시간", systemImage: "clock")
                        .font(.pretendard(14))
                        .foregroundStyle(.ink1)
                }
                .tint(Color.lavenderDeep)
                .onChange(of: vm.pushTime) { _, newValue in
                    vm.setPushTime(newValue, modelContext: modelContext)
                }
            }
        }
    }

    private var supportSection: some View {
        Section(header: Text("지원")) {
            Link(destination: URL(string: "mailto:support@unse.kr")!) {
                HStack {
                    Label("문의하기", systemImage: "envelope")
                        .font(.pretendard(14))
                        .foregroundStyle(.ink1)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.ink4)
                }
            }

            NavigationLink {
                LegalDocumentView(kind: .terms)
            } label: {
                Label("이용약관", systemImage: "doc.text")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
            }

            NavigationLink {
                LegalDocumentView(kind: .privacy)
            } label: {
                Label("개인정보처리방침", systemImage: "hand.raised")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
            }

            NavigationLink {
                LegalDocumentView(kind: .disclaimer)
            } label: {
                Label("면책 고지", systemImage: "exclamationmark.shield")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
            }

            HStack {
                Label("버전", systemImage: "info.circle")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
                Spacer()
                Text(appVersion)
                    .font(.pretendard(13))
                    .foregroundStyle(.ink3)
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button {
                vm.showLogoutAlert = true
            } label: {
                Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
            }

            Button(role: .destructive) {
                vm.showDeleteAlert = true
            } label: {
                Label("계정 삭제", systemImage: "trash")
                    .font(.pretendard(14))
            }
        }
    }

    #if DEBUG
    @ViewBuilder
    private var debugSection: some View {
        Section(header: Text("DEBUG")) {
            Button {
                sub.debugTogglePremium()
            } label: {
                Label(sub.isPremium ? "PRO 끄기 (현재: ON)" : "PRO 켜기 (현재: OFF)",
                      systemImage: sub.isPremium ? "star.fill" : "star")
                    .font(.pretendard(13))
                    .foregroundStyle(.lavenderDeep)
            }
        }
    }
    #endif

    // MARK: - Helpers

    private func settingsRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.pretendard(14))
                .foregroundStyle(.ink1)
            Spacer()
            Text(value)
                .font(.pretendard(13))
                .foregroundStyle(.ink3)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

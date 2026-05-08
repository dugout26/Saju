import SwiftUI
import SwiftData

struct SettingsView: View {
    var user: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var sub
    @State private var showPaywall = false
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false
    @State private var logoutError: String?
    @State private var pushEnabled = false
    @State private var pushTime = Date()
    @State private var pushSaveError: String?
    @State private var deleteError: String?

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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environment(sub)
            }
            .alert("계정 삭제", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) { deleteAccount() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("모든 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
            .alert("로그아웃", isPresented: $showLogoutAlert) {
                Button("로그아웃", role: .destructive) { logout() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("로그아웃하면 시작 화면으로 돌아갑니다.")
            }
            .alert("로그아웃 실패", isPresented: Binding(
                get: { logoutError != nil },
                set: { if !$0 { logoutError = nil } }
            )) {
                Button("확인") { logoutError = nil }
            } message: {
                Text(logoutError ?? "")
            }
            .alert("저장 실패", isPresented: Binding(
                get: { pushSaveError != nil },
                set: { if !$0 { pushSaveError = nil } }
            )) {
                Button("확인") { pushSaveError = nil }
            } message: {
                Text(pushSaveError ?? "")
            }
            .alert("삭제 실패", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("확인") { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
            .onAppear { loadPushSettings() }
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
                Button { showPaywall = true } label: {
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
            Toggle(isOn: $pushEnabled) {
                Label("오늘의 운세 알림", systemImage: "bell")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
            }
            .tint(Color.lavenderDeep)
            .onChange(of: pushEnabled) { _, newValue in
                guard let user else { return }
                do {
                    try SettingsService.updatePushEnabled(newValue, user: user, modelContext: modelContext)
                } catch {
                    pushSaveError = "알림 설정 저장 실패. 다시 시도해주세요."
                }
            }

            if pushEnabled {
                DatePicker(
                    selection: $pushTime,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("알림 시간", systemImage: "clock")
                        .font(.pretendard(14))
                        .foregroundStyle(.ink1)
                }
                .tint(Color.lavenderDeep)
                .onChange(of: pushTime) { _, newValue in
                    guard let user else { return }
                    do {
                        try SettingsService.updatePushTime(
                            newValue, user: user, nickname: nickname, modelContext: modelContext
                        )
                    } catch {
                        pushSaveError = "알림 시간 저장 실패. 다시 시도해주세요."
                    }
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
                showLogoutAlert = true
            } label: {
                Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.pretendard(14))
                    .foregroundStyle(.ink1)
            }

            Button(role: .destructive) {
                showDeleteAlert = true
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

    private func loadPushSettings() {
        pushEnabled = user?.pushEnabled ?? false
        pushTime = user?.pushTime ?? defaultPushTime
    }

    private func deleteAccount() {
        guard let user else { return }
        do {
            try SettingsService.deleteAccount(user: user, modelContext: modelContext)
        } catch {
            deleteError = "계정 삭제 실패. 다시 시도해주세요.\n(\(error.localizedDescription))"
        }
    }

    private func logout() {
        guard let user else { return }
        Task { @MainActor in
            do {
                try await SettingsService.logout(user: user, modelContext: modelContext)
            } catch {
                logoutError = "로그아웃 실패. 잠시 후 다시 시도해주세요.\n(\(error.localizedDescription))"
            }
        }
    }

    private var defaultPushTime: Date {
        var comps = DateComponents()
        comps.hour = 8
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

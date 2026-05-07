import SwiftUI
import SwiftData

/// 본인 + 추가 사주 목록. 추가/편집/삭제. PRO cap 4명.
struct SajuListView: View {
    let user: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var sub
    @State private var showAdd = false
    @State private var editingSaju: SajuProfile?
    @State private var showPaywall = false
    @State private var showCapAlert = false

    /// 본인 + 추가 (본인 우선)
    private var allSajus: [SajuProfile] {
        var result: [SajuProfile] = []
        if let owner = user.sajuProfile { result.append(owner) }
        result.append(contentsOf: user.savedSajus)
        return result
    }

    private var sajuCap: Int { sub.isPremium ? 4 : 1 }

    var body: some View {
        List {
            Section {
                ForEach(allSajus) { saju in
                    sajuRow(saju)
                        .contentShape(Rectangle())
                        .onTapGesture { editingSaju = saju }
                }
                .onDelete(perform: deleteAdditional)
            } header: {
                HStack {
                    Text("등록된 사주")
                    Spacer()
                    Text("\(allSajus.count) / \(sajuCap)명")
                        .foregroundStyle(.ink3)
                }
            }

            Section {
                Button {
                    if allSajus.count >= sajuCap {
                        if sub.isPremium { showCapAlert = true }
                        else { showPaywall = true }
                    } else {
                        showAdd = true
                    }
                } label: {
                    Label("사주 추가", systemImage: "plus")
                        .font(.pretendard(14, .semibold))
                        .foregroundStyle(.lavenderDeep)
                }
            } footer: {
                if !sub.isPremium {
                    Text("PRO 회원은 가족·친구 사주를 4명까지 등록할 수 있어요")
                        .font(.pretendard(11))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("사주 관리")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            AddSajuView(user: user)
        }
        .sheet(item: $editingSaju) { saju in
            AddSajuView(user: user, editingSaju: saju)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environment(sub)
        }
        .alert("최대 4명까지", isPresented: $showCapAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("PRO 회원은 본인 포함 4명까지 등록할 수 있어요. 기존 사주를 삭제 후 추가해주세요.")
        }
    }

    private func sajuRow(_ saju: SajuProfile) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.lavenderSoft)
                    .frame(width: 38, height: 38)
                Text(saju.dayStem)
                    .font(.serifKR(15, .semibold))
                    .foregroundStyle(.lavenderDeep)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(saju.displayName)
                        .font(.pretendard(15, .semibold))
                        .foregroundStyle(.ink1)
                    if saju.relation != "본인" {
                        Text(saju.relation)
                            .font(.pretendard(10, .medium))
                            .foregroundStyle(.ink3)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.line)
                            .clipShape(Capsule())
                    }
                }
                Text("\(saju.birthYear). \(String(format: "%02d", saju.birthMonth)). \(String(format: "%02d", saju.birthDay)) · \(saju.gender)")
                    .font(.pretendard(12))
                    .foregroundStyle(.ink3)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.ink4)
        }
        .padding(.vertical, 4)
    }

    private func deleteAdditional(at offsets: IndexSet) {
        for index in offsets {
            let saju = allSajus[index]
            if saju.relation == "본인" { continue }   // 본인은 삭제 X
            modelContext.delete(saju)
        }
        try? modelContext.save()
    }
}

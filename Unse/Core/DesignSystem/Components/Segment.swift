import SwiftUI

struct Segment: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { opt in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selection = opt }
                } label: {
                    Text(String(localized: String.LocalizationValue(opt)))
                        .font(.pretendard(15, .semibold))
                        .foregroundStyle(selection == opt ? .ink1 : .ink3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            Group {
                                if selection == opt {
                                    RoundedRectangle(cornerRadius: 11)
                                        .fill(Color.surface)
                                        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(hex: 0xF4F2EC))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .frame(height: 52)
    }
}

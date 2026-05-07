import SwiftUI

struct CheckBox: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isOn ? Color.ink1 : Color.surface)
                        .frame(width: 20, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isOn ? .clear : Color.ink4, lineWidth: 1.5)
                        )
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                Text(String(localized: String.LocalizationValue(label)))
                    .font(.pretendard(14))
                    .foregroundStyle(.ink2)
            }
        }
        .buttonStyle(.plain)
        .minTapTarget()
        .contentShape(Rectangle())
    }
}

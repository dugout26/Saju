import SwiftUI

struct PrimaryButton: View {
    let title: String
    var color: Color = .ink1
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(localized: String.LocalizationValue(title)))
                .font(.pretendard(17, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(localized: String.LocalizationValue(title)))
                .font(.pretendard(16, .medium))
                .foregroundStyle(.ink2)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
    }
}

struct OutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(localized: String.LocalizationValue(title)))
                .font(.pretendard(14, .medium))
                .foregroundStyle(.ink2)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.line, lineWidth: 1)
                )
        }
    }
}

struct PillButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(String(localized: String.LocalizationValue(title)))
            }
            .font(.pretendard(13, .semibold))
            .foregroundStyle(.lavenderDeep)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Color.lavenderSoft)
            .clipShape(Capsule())
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

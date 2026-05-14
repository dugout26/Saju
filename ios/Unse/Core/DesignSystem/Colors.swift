import SwiftUI
import UIKit

extension Color {
    // MARK: - Base (Dynamic — light/dark)
    // Dark variant은 base white(0xFBFAF7) → dark slate(0x111114), surface white → dark gray.
    // ink scale은 dark에서 거꾸로 (배경이 어두우면 텍스트 밝게).
    // 라벤더 등 accent는 양 모드에서 같은 hue 유지 (브랜드 일관성).
    static let bg        = Color(light: 0xFBFAF7, dark: 0x111114)
    static let surface   = Color(light: 0xFFFFFF, dark: 0x1C1C20)
    static let ink1      = Color(light: 0x1B1A2E, dark: 0xF2F1F8)
    static let ink2      = Color(light: 0x4A4860, dark: 0xC7C5D6)
    static let ink3      = Color(light: 0x8B89A0, dark: 0x8B89A0)   // 중간 단계는 양쪽 동일
    static let ink4      = Color(light: 0xC7C5D6, dark: 0x4A4860)
    static let line      = Color(light: 0xEFEDE6, dark: 0x2D2D33)

    // MARK: - Pastel accents
    static let lavender     = Color(hex: 0xC9B8F0)
    static let lavenderDeep = Color(hex: 0x8B7BC9)
    static let lavenderSoft = Color(hex: 0xEDE5FB)
    static let peach        = Color(hex: 0xFFC9B0)
    static let peachDeep    = Color(hex: 0xE89576)
    static let peachSoft    = Color(hex: 0xFFE8DC)
    static let mint         = Color(hex: 0xB8E0D2)
    static let mintDeep     = Color(hex: 0x6FB9A0)
    static let mintSoft     = Color(hex: 0xDEF1EA)
    static let cream        = Color(hex: 0xF8EFD9)

    // MARK: - 오행 (Five Elements)
    static let elWood  = Color(hex: 0x6FB99F)
    static let elFire  = Color(hex: 0xE08585)
    static let elEarth = Color(hex: 0xD4B675)
    static let elMetal = Color(hex: 0xB8B8C9)
    static let elWater = Color(hex: 0x7B95C9)
}

// MARK: - Element background/text pairs
struct ElementColors {
    let background: Color
    let text: Color
}

extension Element {
    var colors: ElementColors {
        switch self {
        case .wood:  return ElementColors(background: Color(hex: 0xDCEFE5), text: Color(hex: 0x2D6B52))
        case .fire:  return ElementColors(background: Color(hex: 0xF9DEDE), text: Color(hex: 0x8C3A3A))
        case .earth: return ElementColors(background: Color(hex: 0xF1E4C7), text: Color(hex: 0x7E6228))
        case .metal: return ElementColors(background: Color(hex: 0xE8E8EE), text: Color(hex: 0x4A4A5C))
        case .water: return ElementColors(background: Color(hex: 0xDDE6F2), text: Color(hex: 0x2F4773))
        }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue: Double(hex          & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// 다크모드 자동 전환 — UIColor.dynamicProvider로 trait 변화에 반응.
    init(light: UInt32, dark: UInt32) {
        self = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension ShapeStyle where Self == Color {
    static var bg: Color { Color.bg }
    static var surface: Color { Color.surface }
    static var ink1: Color { Color.ink1 }
    static var ink2: Color { Color.ink2 }
    static var ink3: Color { Color.ink3 }
    static var ink4: Color { Color.ink4 }
    static var line: Color { Color.line }
    static var lavender: Color { Color.lavender }
    static var lavenderDeep: Color { Color.lavenderDeep }
    static var lavenderSoft: Color { Color.lavenderSoft }
    static var peach: Color { Color.peach }
    static var peachDeep: Color { Color.peachDeep }
    static var peachSoft: Color { Color.peachSoft }
    static var mint: Color { Color.mint }
    static var mintDeep: Color { Color.mintDeep }
    static var mintSoft: Color { Color.mintSoft }
    static var cream: Color { Color.cream }
    static var elWood: Color { Color.elWood }
    static var elFire: Color { Color.elFire }
    static var elEarth: Color { Color.elEarth }
    static var elMetal: Color { Color.elMetal }
    static var elWater: Color { Color.elWater }
}

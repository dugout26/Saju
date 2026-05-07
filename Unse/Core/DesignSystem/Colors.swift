import SwiftUI

extension Color {
    // MARK: - Base
    static let bg        = Color(hex: 0xFBFAF7)
    static let surface   = Color.white
    static let ink1      = Color(hex: 0x1B1A2E)
    static let ink2      = Color(hex: 0x4A4860)
    static let ink3      = Color(hex: 0x8B89A0)
    static let ink4      = Color(hex: 0xC7C5D6)
    static let line      = Color(hex: 0xEFEDE6)

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
            red:     Double((hex >> 16) & 0xFF) / 255,
            green:   Double((hex >> 8)  & 0xFF) / 255,
            blue:    Double(hex          & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension ShapeStyle where Self == Color {
    static var bg: Color           { Color.bg }
    static var surface: Color      { Color.surface }
    static var ink1: Color         { Color.ink1 }
    static var ink2: Color         { Color.ink2 }
    static var ink3: Color         { Color.ink3 }
    static var ink4: Color         { Color.ink4 }
    static var line: Color         { Color.line }
    static var lavender: Color     { Color.lavender }
    static var lavenderDeep: Color { Color.lavenderDeep }
    static var lavenderSoft: Color { Color.lavenderSoft }
    static var peach: Color        { Color.peach }
    static var peachDeep: Color    { Color.peachDeep }
    static var peachSoft: Color    { Color.peachSoft }
    static var mint: Color         { Color.mint }
    static var mintDeep: Color     { Color.mintDeep }
    static var mintSoft: Color     { Color.mintSoft }
    static var cream: Color        { Color.cream }
    static var elWood: Color       { Color.elWood }
    static var elFire: Color       { Color.elFire }
    static var elEarth: Color      { Color.elEarth }
    static var elMetal: Color      { Color.elMetal }
    static var elWater: Color      { Color.elWater }
}

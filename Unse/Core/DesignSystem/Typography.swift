import SwiftUI

extension Font {
    // MARK: - Noto Serif KR
    static func serifKR(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .custom("NotoSerifKR-\(weight.notoSerifName)", size: size)
    }

    // MARK: - Pretendard
    static func pretendard(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Pretendard-\(weight.pretendardName)", size: size)
    }
}

extension Font.Weight {
    var notoSerifName: String {
        switch self {
        case .light:     return "Light"
        case .regular:   return "Regular"
        case .medium:    return "Medium"
        case .semibold:  return "SemiBold"
        case .bold:      return "Bold"
        case .heavy:     return "ExtraBold"
        default:         return "Regular"
        }
    }

    var pretendardName: String {
        switch self {
        case .ultraLight: return "Thin"
        case .thin:       return "ExtraLight"
        case .light:      return "Light"
        case .regular:    return "Regular"
        case .medium:     return "Medium"
        case .semibold:   return "SemiBold"
        case .bold:       return "Bold"
        case .heavy:      return "ExtraBold"
        case .black:      return "Black"
        default:          return "Regular"
        }
    }
}

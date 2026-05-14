import SwiftUI

extension Font {
    // MARK: - Noto Serif KR
    // relativeTo:로 Dynamic Type 자동 스케일 — 사용자 시스템 글자 크기 변경 반영.
    static func serifKR(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .custom("NotoSerifKR-\(weight.notoSerifName)", size: size, relativeTo: .body)
    }

    // MARK: - Pretendard
    static func pretendard(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Pretendard-\(weight.pretendardName)", size: size, relativeTo: .body)
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

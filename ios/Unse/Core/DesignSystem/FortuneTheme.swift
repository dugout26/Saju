import SwiftUI

// MARK: - 운세 테마 (separated here to keep SajuModels free of SwiftUI)
enum FortuneTheme: String, CaseIterable, Codable {
    case lavender, peach, mint

    var name: String {
        switch self {
        case .lavender: return "라벤더"
        case .peach:    return "피치"
        case .mint:     return "민트"
        }
    }

    var hex: String {
        switch self {
        case .lavender: return "#C9B8F0"
        case .peach:    return "#FFC9B0"
        case .mint:     return "#B8E0D2"
        }
    }

    var accent: Color {
        switch self {
        case .lavender: return .lavenderDeep
        case .peach:    return .peachDeep
        case .mint:     return .mintDeep
        }
    }

    var soft: Color {
        switch self {
        case .lavender: return .lavenderSoft
        case .peach:    return .peachSoft
        case .mint:     return .mintSoft
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [soft, .bg], startPoint: .top, endPoint: .center)
    }
}

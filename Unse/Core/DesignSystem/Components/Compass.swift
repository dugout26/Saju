import SwiftUI

enum CompassDirection: String {
    case east = "동"
    case west = "서"
    case south = "남"
    case north = "북"
}

struct Compass: View {
    let direction: CompassDirection
    var accent: Color = .lavenderDeep
    var soft: Color = .lavenderSoft
    var size: CGFloat = 44

    private var dotOffset: CGSize {
        let r = size * 0.28
        switch direction {
        case .east:  return CGSize(width: r,  height: 0)
        case .west:  return CGSize(width: -r, height: 0)
        case .south: return CGSize(width: 0,  height: r)
        case .north: return CGSize(width: 0,  height: -r)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(soft)
                .frame(width: size, height: size)
            Circle()
                .strokeBorder(accent, lineWidth: 1.5)
                .opacity(0.4)
                .frame(width: size * 0.45, height: size * 0.45)
            Circle()
                .fill(accent)
                .frame(width: 6, height: 6)
                .offset(dotOffset)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(direction.rawValue + "쪽")
    }
}

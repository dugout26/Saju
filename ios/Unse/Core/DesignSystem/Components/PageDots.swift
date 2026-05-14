import SwiftUI

struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.ink1 : Color(hex: 0xD6D3CC))
                    .frame(width: i == current ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: current)
            }
        }
    }
}

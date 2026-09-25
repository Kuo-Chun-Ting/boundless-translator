import SwiftUI

extension View {
    @ViewBuilder
    func appControlSurface() -> some View {
        if #available(macOS 26, *) {
            glassEffect(.regular, in: Rectangle())
        } else {
            background(.bar)
        }
    }

    /// Keep the same native controls on older macOS releases.
    @ViewBuilder
    func appControlStyle(prominent: Bool = false) -> some View {
        if #available(macOS 26, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else if prominent {
            buttonStyle(.borderedProminent)
        } else {
            buttonStyle(.bordered)
        }
    }
}

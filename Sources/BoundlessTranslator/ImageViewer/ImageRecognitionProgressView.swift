import SwiftUI

struct ImageRecognitionProgressView: View {
    let message: String

    var body: some View {
        surface
            .padding(8)
            .allowsHitTesting(false)
    }

    @ViewBuilder private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: 16)
        if #available(macOS 26, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            ProgressView().controlSize(.small)
                .accessibilityHidden(true)
            Text(verbatim: message)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

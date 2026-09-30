import AppKit
import SwiftUI

struct HintView: View {
    let title: Text
    let message: Text?
    let icon: Image
    let width: CGFloat
    let localization: AppLocalization
    let identifier: String
    let onClose: (Bool) -> Void

    @State private var doNotShowAgain = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    title.font(.headline)
                    message
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Toggle(localization.string("hint.doNotShowAgain"), isOn: $doNotShowAgain)
                    .toggleStyle(.checkbox)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            closeButton
        }
        .padding(12)
        .frame(width: width)
        .fixedSize(horizontal: false, vertical: true)
        .modifier(HintMaterial())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    private var closeButton: some View {
        Button { onClose(doNotShowAgain) } label: {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(localization.string("hint.close"))
        .accessibilityLabel(localization.string("hint.close"))
    }
}

private struct HintMaterial: ViewModifier {
    private var tint: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(white: isDark ? 0.18 : 0.80, alpha: 0.55)
        })
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12)
        if #available(macOS 26, *) {
            content.glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else {
            content.background(tint, in: shape).background(.regularMaterial, in: shape)
        }
    }
}

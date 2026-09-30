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
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                description.fixedSize(horizontal: true, vertical: true)
                Spacer(minLength: 16)
                dismissOption.fixedSize()
                closeButton
            }
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    description
                    dismissOption.padding(.leading, 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                closeButton
            }
        }
        .padding(16)
        .frame(width: width)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.primary.opacity(0.06))
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) { Divider().allowsHitTesting(false) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    private var description: some View {
        HStack(alignment: .top, spacing: 12) {
            icon.resizable().scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                title.font(.headline)
                message.font(.subheadline).foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var dismissOption: some View {
        Toggle(localization.string("hint.doNotShowAgain"), isOn: $doNotShowAgain)
            .toggleStyle(.checkbox)
            .font(.caption)
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

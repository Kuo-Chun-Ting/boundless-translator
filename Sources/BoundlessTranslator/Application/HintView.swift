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
    var presentation: HintPresentation = .inline

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
        .environment(\.locale, Locale(identifier: localization.languageIdentifier))
        .environment(
            \.layoutDirection,
            Locale.Language(identifier: localization.languageIdentifier).characterDirection == .rightToLeft
                ? .rightToLeft : .leftToRight
        )
        .padding(16)
        .frame(width: width - (presentation == .callout ? 8 : 0))
        .padding(.leading, presentation == .callout ? 8 : 0)
        .fixedSize(horizontal: false, vertical: true)
        .background(HintSurface(presentation: presentation).fill(Color.primary.opacity(0.06)))
        .background(HintSurface(presentation: presentation).fill(Color(nsColor: .windowBackgroundColor)))
        .overlay {
            if presentation == .callout {
                HintSurface(presentation: presentation)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottom) {
            if presentation == .inline { Divider().allowsHitTesting(false) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
        // The callout stays on the physical right of Settings, including in RTL languages.
        .environment(\.layoutDirection, .leftToRight)
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
            .fixedSize(horizontal: false, vertical: true)
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

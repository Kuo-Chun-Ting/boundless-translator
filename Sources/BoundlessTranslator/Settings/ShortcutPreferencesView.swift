import SwiftUI

struct ShortcutPreferencesView: View {
    @ObservedObject var controller: GlobalShortcutController
    let titleKey: String
    let accessibilityIdentifier: String
    let localization: AppLocalization

    var body: some View {
        Group {
            LabeledContent(localization.string(titleKey)) {
                ShortcutRecorderControl(
                    definition: controller.definition,
                    localization: localization,
                    accessibilityIdentifier: accessibilityIdentifier,
                    accessibilityLabel: localization.string(titleKey),
                    onRecordingStarted: {
                        controller.beginRecording()
                    },
                    onRecordingCancelled: {
                        controller.cancelRecording()
                    },
                    onShortcutRecorded: { candidate in
                        controller.updateShortcut(candidate)
                    }
                )
                .fixedSize()
            }

            if let errorMessage = controller.failureMessage(
                localization: localization
            ) {
                Text(verbatim: errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

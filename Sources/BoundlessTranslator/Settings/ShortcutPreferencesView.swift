import SwiftUI

struct ShortcutPreferencesView: View {
    @ObservedObject var controller: GlobalShortcutController
    let otherController: GlobalShortcutController
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
                        otherController.beginRecording()
                    },
                    onRecordingCancelled: {
                        controller.cancelRecording()
                        otherController.cancelRecording()
                    },
                    onShortcutRecorded: { candidate in
                        controller.updateShortcut(candidate, reserved: [otherController.definition])
                        otherController.cancelRecording()
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

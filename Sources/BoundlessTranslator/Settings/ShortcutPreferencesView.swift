import SwiftUI

struct ShortcutPreferencesView: View {
    @ObservedObject var controller: GlobalShortcutController
    let localization: AppLocalization

    var body: some View {
        Group {
            LabeledContent(localization.string("shortcut.section")) {
                ShortcutRecorderControl(
                    definition: controller.definition,
                    localization: localization,
                    onRecordingStarted: controller.beginRecording,
                    onRecordingCancelled: controller.cancelRecording,
                    onShortcutRecorded: controller.updateShortcut
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

import SwiftUI

struct ShortcutPreferencesView: View {
    @ObservedObject var controller: GlobalShortcutController

    var body: some View {
        Section("Keyboard Shortcut") {
            LabeledContent("Translate Selection") {
                ShortcutRecorderControl(
                    definition: controller.definition,
                    onRecordingStarted: controller.beginRecording,
                    onRecordingCancelled: controller.cancelRecording,
                    onShortcutRecorded: controller.updateShortcut
                )
                .fixedSize()
            }

            if let errorMessage = controller.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

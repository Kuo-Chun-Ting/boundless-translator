import SwiftUI

struct TranslationFailureView: View {
    let failure: TranslationFailure
    let localization: AppLocalization
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: localization.string("panel.failureTitle"))
                .font(.headline)
                .foregroundStyle(.primary)
            Text(verbatim: failure.message(localization: localization))
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.8))
                .textSelection(.enabled)
            if failure.canRetry {
                Button(localization.string("panel.tryAgain"), action: onRetry)
                    .appControlStyle()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(14)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }
}

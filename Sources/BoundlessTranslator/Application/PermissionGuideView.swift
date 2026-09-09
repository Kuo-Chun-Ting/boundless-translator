import SwiftUI

struct PermissionGuideView: View {
    let configuration: PermissionGuideConfiguration
    let localization: AppLocalization
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(nsImage: AppBrand.iconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)

            Text(verbatim: localization.string(configuration.titleKey))
                .font(.title.bold())

            permissionCard

            if let instructionKey = configuration.instructionKey {
                Label {
                    Text(verbatim: localization.string(instructionKey))
                } icon: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.tint)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(width: 520)
    }

    private var permissionCard: some View {
        HStack(spacing: 18) {
            Image(systemName: configuration.symbolName)
                .font(.system(size: 36))
                .foregroundStyle(.tint)
                .frame(width: 56, height: 56)

            Text(verbatim: localization.string(configuration.messageKey))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Button(action: onContinue) {
                Text(verbatim: localization.string(configuration.buttonKey))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
    }
}

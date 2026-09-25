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
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("permissionGuide.title")

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
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 18) {
                Image(systemName: configuration.symbolName)
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
                    .frame(width: 48, height: 48)

                Text(verbatim: localization.string(configuration.messageKey))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onContinue) {
                Text(verbatim: localization.string(configuration.buttonKey))
                    .frame(maxWidth: .infinity)
            }
            .appControlStyle(prominent: true)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("permissionGuide.continueButton")
        }
        .padding(20)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

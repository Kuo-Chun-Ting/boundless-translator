import SwiftUI

struct SubscriptionView: View {
    @ObservedObject var access: SubscriptionAccessController
    @ObservedObject var store: SubscriptionStoreController
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings
    let configuration: SubscriptionConfiguration?
    var onContentSizeChange: (CGSize) -> Void = { _ in }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            VStack(alignment: .leading, spacing: 20) {
                if let entitlement = access.activeEntitlement {
                    SubscribedView(
                        entitlement: entitlement,
                        localization: localization,
                        locale: interfaceLanguageSettings.locale
                    )
                } else if !access.hasLoaded && access.isRefreshing {
                    loading.padding(30)
                } else if let configuration {
                    SubscriptionProductView(
                        productID: configuration.productID,
                        store: store,
                        localization: localization,
                        locale: interfaceLanguageSettings.locale
                    )
                } else {
                    messageText("subscription.configurationMissing").padding(30)
                }
                if let message = store.messageKey {
                    messageText(message).padding(.horizontal, 30)
                } else if access.refreshFailed {
                    messageText("subscription.refreshFailed").padding(.horizontal, 30)
                }
                SubscriptionFooter(
                    store: store,
                    localization: localization,
                    configuration: configuration
                )
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .frame(width: 480)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { onContentSizeChange($0) }
        }
        .task { await access.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await access.refresh() }
        }
        .interfaceLanguage(interfaceLanguageSettings)
    }

    private var loading: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            messageText("subscription.loading")
        }
        .frame(maxWidth: .infinity)
    }

    private func messageText(_ key: String, arguments: CVarArg...) -> some View {
        Text(verbatim: String(format: localization.string(key), locale: interfaceLanguageSettings.locale, arguments: arguments))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var localization: AppLocalization {
        AppLocalization(languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier)
    }
}

struct SubscriptionFooter: View {
    @ObservedObject var store: SubscriptionStoreController
    let localization: AppLocalization
    let configuration: SubscriptionConfiguration?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 18) { footerLinks }.fixedSize(horizontal: true, vertical: false)
            VStack(spacing: 12) { footerLinks }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .tint(.secondary)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var footerLinks: some View {
        if let configuration {
            Button {
                Task { await store.restore() }
            } label: {
                HStack(spacing: 6) {
                    if store.isRestoring { ProgressView().controlSize(.mini) }
                    Text(verbatim: localization.string("subscription.restore"))
                }
            }
            .buttonStyle(.plain)
            .disabled(store.isBusy)
            Link(localization.string("subscription.terms"), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Link(localization.string("subscription.privacy"), destination: configuration.privacyPolicyURL)
        }
    }
}

struct SubscriptionAppIcon: View {
    var body: some View {
        Image(nsImage: AppBrand.iconImage)
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}

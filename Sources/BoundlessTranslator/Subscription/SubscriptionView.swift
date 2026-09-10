import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @ObservedObject var access: SubscriptionAccessController
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings
    let configuration: SubscriptionConfiguration?

    var body: some View {
        VStack(spacing: 12) {
            if let configuration {
                SubscriptionStoreView(productIDs: [configuration.productID]) {
                    VStack(spacing: 8) {
                        Text(verbatim: AppBrand.displayName).font(.title2.bold())
                        Text(verbatim: localization.string("subscription.features"))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                .storeButton(.visible, for: .restorePurchases, .policies)
                .subscriptionStorePolicyDestination(url: configuration.privacyPolicyURL, for: .privacyPolicy)
                .subscriptionStorePolicyDestination(
                    url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
                    for: .termsOfService
                )
            } else {
                ContentUnavailableView {
                    Label(localization.string("subscription.unavailable"), systemImage: "exclamationmark.triangle")
                } description: {
                    Text(verbatim: localization.string("subscription.configurationMissing"))
                }
            }

            TimelineView(.periodic(from: .now, by: 1)) { _ in
                if access.isRefreshing && !access.hasLoaded {
                    ProgressView().controlSize(.small)
                } else {
                    Text(verbatim: localization.string(access.hasAccess ? "subscription.active" : "subscription.required"))
                        .font(.callout)
                }
            }
            if access.refreshFailed {
                Text(verbatim: localization.string("subscription.refreshFailed"))
                    .font(.callout).foregroundStyle(.secondary)
            }
            HStack {
                Button(localization.string("subscription.refresh")) {
                    Task { await access.refresh() }
                }
                .disabled(access.isRefreshing)
                Link(localization.string("subscription.manage"), destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
            }
            .padding(.bottom)
        }
        .task { await access.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await access.refresh() }
        }
        .interfaceLanguage(interfaceLanguageSettings)
    }

    private var localization: AppLocalization {
        AppLocalization(languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier)
    }
}

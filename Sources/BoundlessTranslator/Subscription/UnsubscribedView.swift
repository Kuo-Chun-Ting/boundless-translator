import StoreKit
import SwiftUI

struct SubscriptionProductView: View {
    let productID: String
    @ObservedObject var store: SubscriptionStoreController
    let localization: AppLocalization
    let locale: Locale
    @State private var productState: Product.TaskState = .loading
    @State private var reloadCount = 0

    var body: some View {
        Group {
            if let product = productState.product {
                SubscriptionStoreView(subscriptions: [product]) {
                    SubscriptionIntroductionView(localization: localization)
                        .frame(width: 420, alignment: .leading)
                        .padding(.top, 30)
                }
                .subscriptionStoreControlStyle(AnnualSubscriptionControlStyle(
                    store: store, localization: localization, locale: locale
                ), placement: .scrollView)
                .storeButton(.hidden, for: .cancellation, .restorePurchases, .policies)
                .onInAppPurchaseStart { _ in store.purchaseStarted() }
                .onInAppPurchaseCompletion { _, result in await store.purchaseCompleted(result) }
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    SubscriptionIntroductionView(localization: localization)
                    if case .loading = productState {
                        ProgressView(localization.string("subscription.loading"))
                    } else {
                        Text(verbatim: localization.string("subscription.loadFailed"))
                            .foregroundStyle(.secondary)
                        Button(localization.string("subscription.retry")) { reloadCount += 1 }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
            }
        }
        .storeProductTask(for: productID) { productState = $0 }
        .id(reloadCount)
        .fixedSize(horizontal: false, vertical: true)
    }

}

struct SubscriptionIntroductionView: View {
    let localization: AppLocalization

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SubscriptionAppIcon()
            Text(verbatim: localization.string("subscription.features"))
                .font(.system(size: 22, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AnnualSubscriptionControlStyle: SubscriptionStoreControlStyle {
    let store: SubscriptionStoreController
    let localization: AppLocalization
    let locale: Locale

    func makeBody(configuration: Configuration) -> some View {
        if let option = configuration.options.first {
            UnsubscribedView(
                offer: SubscriptionOffer(displayPrice: option.displayPrice, activeOffer: option.activeOffer),
                store: store, localization: localization, locale: locale,
                subscribe: option.subscribe
            )
            .padding(.horizontal, 30)
        }
    }
}

struct UnsubscribedView: View {
    let offer: SubscriptionOffer
    @ObservedObject var store: SubscriptionStoreController
    let localization: AppLocalization
    let locale: Locale
    let subscribe: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 16) { planName; Spacer(minLength: 16); price }
                    VStack(alignment: .leading, spacing: 8) { planName; price }
                }
                if let duration = offer.trialDuration(locale: locale) {
                    Text(verbatim: localization.string("subscription.trialOffer", arguments: duration, offer.displayPrice))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
            VStack(spacing: 10) {
                Button(action: subscribe) {
                    HStack {
                        if store.isPurchasing { ProgressView().controlSize(.small) }
                        Text(verbatim: purchaseTitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(store.isBusy)
                Text(verbatim: localization.string("subscription.autoRenewal"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var planName: some View {
        Text(verbatim: localization.string("subscription.annualPlan")).font(.body.weight(.semibold))
    }

    private var price: some View {
        Text(verbatim: localization.string("subscription.pricePerYear", arguments: offer.displayPrice))
            .font(.title3.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var purchaseTitle: String {
        if let duration = offer.trialDuration(locale: locale) {
            return localization.string("subscription.trialAction", arguments: duration)
        }
        return localization.string("subscription.subscribe")
    }
}

struct SubscriptionOffer {
    let displayPrice: String
    var freeTrialPeriod: DateComponents?

    init(displayPrice: String, activeOffer: Product.SubscriptionOffer?) {
        self.displayPrice = displayPrice
        guard let activeOffer, activeOffer.paymentMode == .freeTrial else { return }
        let value = activeOffer.period.value * activeOffer.periodCount
        switch activeOffer.period.unit {
        case .day: freeTrialPeriod = DateComponents(day: value)
        case .week: freeTrialPeriod = DateComponents(weekOfMonth: value)
        case .month: freeTrialPeriod = DateComponents(month: value)
        case .year: freeTrialPeriod = DateComponents(year: value)
        @unknown default: break
        }
    }

    func trialDuration(locale: Locale) -> String? {
        guard let freeTrialPeriod else { return nil }
        let formatter = DateComponentsFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.year, .month, .weekOfMonth, .day]
        return formatter.string(from: freeTrialPeriod)
    }
}

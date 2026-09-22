import SwiftUI

struct SubscribedView: View {
    let entitlement: SubscriptionEntitlement
    let localization: AppLocalization
    let locale: Locale

    var body: some View {
        VStack(spacing: 20) {
            SubscriptionAppIcon()
            VStack(alignment: .leading, spacing: 16) {
                planDetails
                Link(
                    localization.string("subscription.manage"),
                    destination: URL(string: "https://apps.apple.com/account/subscriptions")!
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 30)
    }

    private var planDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack { planName; Spacer(minLength: 16); activeStatus }
                VStack(alignment: .leading, spacing: 8) { planName; activeStatus }
            }
            if let amount = entitlement.renewalPrice, let currency = entitlement.currencyCode {
                Divider()
                detailRow("subscription.price", value: localization.string(
                    "subscription.pricePerYear",
                    arguments: amount.formatted(.currency(code: currency).locale(locale))
                ))
            }
            Divider()
            detailRow(
                entitlement.renewsAutomatically == true ? "subscription.nextRenewal" : "subscription.expires",
                value: entitlement.expiresAt.formatted(.dateTime.year().month().day().locale(locale))
            )
        }
        .padding(18)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private var planName: some View {
        Text(verbatim: localization.string("subscription.annualPlan")).font(.body.weight(.semibold))
    }

    private var activeStatus: some View {
        Label(localization.string("subscription.active"), systemImage: "checkmark")
            .foregroundStyle(.green)
    }

    private func detailRow(_ key: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(verbatim: localization.string(key)).foregroundStyle(.secondary)
                Spacer(minLength: 16)
                Text(verbatim: value)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: localization.string(key)).foregroundStyle(.secondary)
                Text(verbatim: value).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

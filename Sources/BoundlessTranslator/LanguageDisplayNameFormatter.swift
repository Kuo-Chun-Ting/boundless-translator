import Foundation

struct LanguageDisplayNameFormatter {
    private let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    func name(for option: LanguageOption) -> String {
        name(for: option.id)
    }

    func name(for identifier: String) -> String {
        guard let localizedName = locale.localizedString(forIdentifier: identifier) else {
            return identifier
        }

        let parts = localizedName.split(
            separator: ",",
            maxSplits: 1,
            omittingEmptySubsequences: true
        )
        guard parts.count == 2 else {
            return localizedName
        }

        return "\(parts[1].trimmingCharacters(in: .whitespaces)) \(parts[0])"
    }
}

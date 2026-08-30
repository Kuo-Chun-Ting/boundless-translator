import Combine
import Foundation
@preconcurrency import Translation

@MainActor
final class SupportedLanguageCatalog: ObservableObject {
    typealias Loader = @MainActor () async -> [Locale.Language]
    typealias DisplayNameProvider = (String) -> String

    @Published private(set) var languages: [Locale.Language] = []

    private let loadLanguages: Loader
    private let displayName: DisplayNameProvider
    private var loadingTask: Task<[Locale.Language], Never>?
    private var didLoad = false

    init(
        loadLanguages: @escaping Loader = {
            await LanguageAvailability().supportedLanguages
        },
        displayName: @escaping DisplayNameProvider = {
            LanguageDisplayNameFormatter().name(for: $0)
        }
    ) {
        self.loadLanguages = loadLanguages
        self.displayName = displayName
    }

    func load() async -> [Locale.Language] {
        if didLoad {
            return languages
        }
        if let loadingTask {
            return await loadingTask.value
        }

        let task = Task {
            let availableLanguages = await loadLanguages()
            return availableLanguages.sorted {
                displayName($0.minimalIdentifier).localizedStandardCompare(
                    displayName($1.minimalIdentifier)
                ) == .orderedAscending
            }
        }
        loadingTask = task
        let sortedLanguages = await task.value

        languages = sortedLanguages
        didLoad = true
        loadingTask = nil
        return sortedLanguages
    }
}

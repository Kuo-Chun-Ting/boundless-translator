import Combine
import Foundation

struct DictionaryDefinition: Equatable, Sendable {
    let term: String
    let text: String
}

enum DictionaryLookupStatus: Equatable, Sendable {
    case idle
    case found(DictionaryDefinition)
    case notFound(String)
}

@MainActor
final class DictionaryLookupCoordinator: ObservableObject {
    @Published private(set) var status: DictionaryLookupStatus = .idle

    private let service: any DictionaryLookupServicing
    private var cachedTerm: String?

    init(service: any DictionaryLookupServicing) {
        self.service = service
    }

    func lookUp(_ selectedText: SelectedText) {
        let term = selectedText.value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard term != cachedTerm else {
            return
        }

        cachedTerm = term
        status = makeStatus(term: term, definition: service.lookUp(term))
    }

    func reset() {
        cachedTerm = nil
        status = .idle
    }

    private func makeStatus(
        term: String,
        definition: String?
    ) -> DictionaryLookupStatus {
        guard let definition else {
            return .notFound(term)
        }

        return .found(DictionaryDefinition(term: term, text: definition))
    }
}

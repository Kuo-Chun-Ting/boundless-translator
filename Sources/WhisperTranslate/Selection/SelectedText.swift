import Foundation

enum SelectedTextError: Error, Equatable {
    case empty
}

struct SelectedText: Equatable, Sendable {
    let value: String

    init(_ rawValue: String) throws {
        guard !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SelectedTextError.empty
        }

        value = rawValue
    }
}

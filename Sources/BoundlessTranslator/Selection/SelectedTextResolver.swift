@MainActor
protocol SelectedTextReading: AnyObject {
    func readSelectedText() async throws -> SelectedText
}

@MainActor
final class SelectedTextResolver: SelectedTextReading {
    private let primaryReader: any SelectedTextReading
    private let fallbackReader: any SelectedTextReading

    init(
        primaryReader: any SelectedTextReading,
        fallbackReader: any SelectedTextReading
    ) {
        self.primaryReader = primaryReader
        self.fallbackReader = fallbackReader
    }

    func readSelectedText() async throws -> SelectedText {
        do {
            return try await primaryReader.readSelectedText()
        } catch {
            return try await fallbackReader.readSelectedText()
        }
    }
}

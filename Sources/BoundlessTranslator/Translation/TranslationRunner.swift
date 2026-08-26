@MainActor
protocol TranslationRunning {
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput
}

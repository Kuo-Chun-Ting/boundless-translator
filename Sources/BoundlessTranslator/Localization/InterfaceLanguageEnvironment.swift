import SwiftUI

private struct InterfaceLanguageEnvironmentModifier: ViewModifier {
    @ObservedObject var settings: InterfaceLanguageSettings

    func body(content: Content) -> some View {
        content
            .environment(\.locale, settings.locale)
            .environment(
                \.layoutDirection,
                settings.isRightToLeft ? .rightToLeft : .leftToRight
            )
    }
}

extension View {
    func interfaceLanguage(
        _ settings: InterfaceLanguageSettings
    ) -> some View {
        modifier(InterfaceLanguageEnvironmentModifier(settings: settings))
    }
}

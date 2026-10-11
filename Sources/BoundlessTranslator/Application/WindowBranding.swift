import AppKit

@MainActor
enum WindowBranding {
    static func install(on window: NSWindow, identifier: String) -> Void {
        configureWindow(window, identifier: identifier)
        let accessory = makeTitlebarAccessory()
        window.addTitlebarAccessoryViewController(accessory)
    }

    private static func configureWindow(_ window: NSWindow, identifier: String) -> Void {
        window.title = AppBrand.displayName
        window.setAccessibilityIdentifier(identifier)
        window.titleVisibility = .hidden
    }

    private static func makeTitlebarAccessory() -> NSTitlebarAccessoryViewController {
        let icon = NSImageView(image: AppBrand.spriteImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityElement(false)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
        ])

        let label = NSTextField(labelWithString: AppBrand.displayName)
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        label.setAccessibilityIdentifier("windowBrandTitle")
        let stack = NSStackView(views: [icon, label])
        stack.spacing = 6
        stack.alignment = .centerY
        stack.setFrameSize(stack.fittingSize)

        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .left
        accessory.view = stack
        return accessory
    }
}

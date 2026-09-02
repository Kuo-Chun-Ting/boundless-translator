# Test Layer Separation and GUI Cursor Validation Design

## Goal

Separate unit, component, and GUI tests by target, directory, and command. Add a GUI test that reproduces the lower-line dictionary-button cursor bug through real AppKit event routing.

## Test Layers

### Unit

- Target: `BoundlessTranslatorUnitTests`
- Path: `Tests/Unit`
- Covers deterministic logic without visible windows, event loops, system input, or framework behavior.
- Runs through `Scripts/test_unit.sh`.

### Component

- Target: `BoundlessTranslatorComponentTests`
- Path: `Tests/Component`
- Covers one or more production components in memory.
- May inspect view hierarchy, layout, hit testing, state, and direct method contracts.
- Does not claim to verify WindowServer input routing or the final system cursor.
- Runs through `Scripts/test_component.sh`.

### GUI

- Target: `BoundlessTranslatorGUITests`
- Path: `Tests/GUI`
- Project: `Tests/GUIProject/BoundlessTranslatorGUITests.xcodeproj`
- Launches a dedicated host application in an active desktop session and uses XCUITest to move the real pointer through AppKit routing.
- Runs only through `Scripts/test_gui.sh`; default unit and component commands never move the pointer.
- Terminates the host application during cleanup.

Deployment shell tests remain under `Tests/Deployment` because they validate packaging and signing workflows rather than application behavior.

## GUI Cursor Test

The first GUI test uses production `TranslationPanelView` and `SourceTextLookupView` with long source text.

1. Present the panel and select a word below the fourth rendered line.
2. Confirm the dictionary button is positioned over that lower selection and owns hit testing at its center.
3. Use XCUITest to move the pointer from outside the dictionary button onto it.
4. Wait for AppKit to finish cursor routing, then assert `NSCursor.current` is `pointingHand`.
5. Repeat the transition three times to catch stale tracking regions and one-time success.

The test must fail against the current bug before production code changes. A production fix is accepted only after this GUI test and the unit/component suites pass.

## Execution

- `Scripts/test_unit.sh`: unit target only.
- `Scripts/test_component.sh`: component target only.
- `Scripts/test_gui.sh`: GUI target only, serial execution, normal macOS GUI session.
- GUI tests are skipped unless `Scripts/test_gui.sh` enables them, so plain
  `swift test` never moves the pointer.
- Project validation runs unit and component suites after every code change. It also runs the GUI suite when changing windows, pointer handling, tracking areas, hit testing, selection overlays, or dictionary-button interaction.

## Environment

- No third-party testing framework or package is required.
- Xcode supplies Swift Testing, XCTest, AppKit, and CoreGraphics.
- GUI tests require an active logged-in macOS desktop and cannot run in a headless session.
- macOS may require permission to control the test host. The test script does not request or modify that permission.

## Non-Goals

- No DMG installation, production App launch, or cross-application shortcut flow in this GUI test.
- No production-only test state or accessibility label used solely to make the test pass.

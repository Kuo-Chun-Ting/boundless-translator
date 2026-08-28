# Dictionary Mode Design

## Goal

Add an explicit Dictionary mode to the existing translation panel while preserving the current translation shortcut and translation behavior. Make both translation and dictionary providers replaceable behind API-agnostic application workflows.

## Confirmed User Flow

1. The existing `Command-Shift-T` shortcut continues to read the current selection and start translation exactly as it does today.
2. Every newly presented panel starts in Translate mode.
3. The user switches between Translate and Dictionary with a two-option system segmented control.
4. Switching to Dictionary looks up the same selected text. The user does not need to select or copy it again.
5. Switching back to Translate reveals the current translation state without resubmitting or changing its language settings.
6. No character-count, word-count, or language heuristic chooses a mode automatically.

## Dictionary Lookup Behavior

Dictionary mode uses the public macOS Dictionary Services API through `CoreServices`.

1. Trim leading and trailing whitespace from the selected text.
2. Pass the complete trimmed text and its complete UTF-16 range to `DCSCopyTextDefinition` with a `nil` dictionary parameter.
3. Display the returned plain-text definition when the API finds a record.
4. Display a calm empty state when the API returns `nil`.
5. Stay in Dictionary mode when no definition is found. Do not switch modes or fall back to translation automatically.
6. Do not use `DCSGetTermRangeInString` to silently reduce a multiword selection to one term because the selection does not identify which internal word the user intended.

The public API searches the dictionaries enabled in Dictionary.app and returns the first matching record as plain text. It cannot enumerate installed dictionaries, identify the source dictionary, choose a specific dictionary, or return structured pronunciation, part-of-speech, meaning, or example fields.

## Panel Design

Use system controls and materials so the panel follows the appearance of the running macOS version. Keep content visually dominant and give controls only the weight needed to communicate state and affordance.

### Shared toolbar

- Replace the custom top strip with an actual compact `NSToolbar` integrated with the title bar.
- Keep the standard traffic-light window controls at the leading edge.
- Place a text-only system `NSSegmentedControl` labeled `Translate | Dictionary` in the center.
- Keep Pin as a trailing system toolbar action with a tooltip and accessibility label.
- Remove the Pin button's permanent rounded background. Use the system accent color only to communicate the pinned state.
- The segmented control changes selection by clicking or keyboard interaction; it is not a draggable switch.
- Use the system toolbar height, control size, materials, spacing, and active/inactive appearance instead of reproducing them in SwiftUI.

### Translate mode

- Preserve the existing source-language menu, target-language menu, source text, translation task, retry behavior, and translated result behavior.
- Remove the directional arrow.
- Remove the standalone language bar styling.
- Present each language menu as the quiet header of its corresponding content column.
- Use one consistent content inset for each column and avoid an additional background, border, or shadow behind the language headers.
- Keep the central vertical divider between source and translated content.

### Dictionary mode

- Hide translation language controls because Dictionary Services does not accept a source or target language.
- Replace the two-column content with one full-width scrollable definition view.
- Show the selected term as a clear heading and the returned definition as selectable body text.
- For no result, show a book symbol, `No definition found`, and concise guidance to try a different selection or return to Translate.
- Preserve panel position, Pin state, and mode selection while switching modes within the same presentation.

## Architecture

Keep Dictionary Services isolated from the existing Translation framework path.

### High-level workflow

Add a `PanelWorkflowCoordinator` as the application-level entry point for panel mode changes. Its top-level method expresses only the user intent:

```swift
func select(_ mode: TranslationPanelMode, text: SelectedText) {
    switch mode {
    case .translate:
        translate(text)
    case .dictionary:
        lookUp(text)
    }
}
```

The high-level coordinator depends on `TranslationWorkflowing` and `DictionaryWorkflowing` interfaces. It does not import Apple's `Translation` framework or `CoreServices`, construct platform sessions, convert Core Foundation values, or name a concrete provider.

Each workflow is idempotent for the current selection. The first Translate activation starts the existing translation flow; returning from Dictionary exposes the existing request and status without submitting again. The first Dictionary activation performs the lookup; returning to it reuses the cached result.

Keep translation and dictionary as separate workflows because their requests, results, failures, and lifecycle requirements differ. Do not combine them into a generic text-service interface or an untyped result enum.

### Translation boundary

- Retain `TranslationRunning` as the replaceable translation-provider interface.
- Add an `AppleTranslationRunner` adapter that owns Apple response conversion and produces the existing `TranslationOutput` contract.
- Keep `TranslationTaskHost` only as the low-level SwiftUI lifecycle bridge that receives an Apple `TranslationSession` and invokes the adapter.
- Remove Apple response mapping from `TranslationPanelView`.
- A future translation provider replaces the adapter and its composition without changing `PanelWorkflowCoordinator`, translation state, or result presentation.

### Dictionary boundary

Add a focused `Dictionary` source group containing:

- `DictionaryLookupServicing`: a protocol that accepts a normalized term and returns an optional plain-text definition.
- `DictionaryServicesLookupService`: the production adapter that imports `CoreServices` and calls `DCSCopyTextDefinition`.
- `DictionaryLookupCoordinator`: observable state that normalizes the selection, invokes the service on demand, caches the result for the current term, and publishes idle, found, or not-found status.

Keep `CoreServices` types and retained-value handling private to the production adapter. Its public method accepts and returns Swift `String` values with explicit types. The adapter performs the synchronous local API call directly because Dictionary Services exposes no asynchronous, progress, cancellation, or error-detail interface. The coordinator prevents repeat calls when the user switches away and back for the same selection.

### Presentation state

- Add an explicit `TranslationPanelMode` with `translate` and `dictionary` cases.
- Extend `TranslationPanelState` to own the current mode in addition to Pin state.
- Reset the mode to Translate only when presenting a new selection or auxiliary panel.
- Do not reset the mode when the user switches content within the current panel.

### Composition

- `AppController` continues to read the selection and submit translation through the existing language-resolution flow without platform API details or changed translation parameters.
- `PanelWorkflowCoordinator` receives mode changes from the segmented control and routes them through the two workflow interfaces.
- The panel receives separate translation and dictionary coordinators for the same selected text.
- `TranslationPanelView` renders `TranslationPanelState.mode` and reports user intent; it does not call either provider directly.
- Concrete Apple adapters are selected only in the application composition or the platform lifecycle bridge.
- Dictionary failures and empty results never mutate `TranslationCoordinator`.

## Testing

Follow the existing Swift Testing style and the project Unit Test Principle:

- Use top-level `@Test` functions with `test_{function}_when_{condition}_then_{result}` names and 3A sections.
- Use a `stub_` service when a test only needs a definition or no-result response.
- Use a `mock_` service when a test verifies the normalized term, invocation count, or same-term caching.
- Use mock workflows to verify that `PanelWorkflowCoordinator` routes Translate only to the translation workflow and Dictionary only to the dictionary workflow.
- Verify that returning to Translate preserves the current translation request and does not resubmit it.
- Test normalization, exact full-term forwarding, found and not-found states, and same-term caching through the service protocol.
- Test that a new panel starts in Translate, mode switching preserves Pin state, and reset restores Translate.
- Test Dictionary layout sizing and Translate layout regression behavior.
- Do not assert Apple dictionary contents or test Dictionary Services itself.
- Keep all existing translation coordinator, language selection, layout, and failure tests unchanged and passing.

## Verification and Deployment

After implementation, complete the full AGENTS.md workflow:

1. Run the complete `swift test` suite with SwiftPM and Clang caches under `/private/tmp`, with no compilation warnings.
2. Lint the build script and Info.plist.
3. Build a fresh signed Release app.
4. Verify signature, signing authority, plist, macOS 15.0 minimum version, and linked system frameworks.
5. Deploy with `Scripts/deploy_app.sh`, verify the installed app, and leave it closed.

## Non-Goals

- No new global shortcut.
- No automatic choice between Translate and Dictionary.
- No change to translation language detection, requests, retry behavior, settings, or results.
- No dictionary installation, activation, enumeration, or source selection.
- No private Dictionary framework symbols or direct parsing of dictionary bundles.
- No structured pronunciation, word class, multiple meanings, or examples beyond the plain text returned by Dictionary Services.
- No network dictionary fallback.

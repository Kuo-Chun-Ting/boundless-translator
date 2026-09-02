# Clipboard Image Text Selection Design

## Goal

Let users translate text from screenshots without saving and reopening image files. Boundless Translator opens the current clipboard image in its own persistent window, uses macOS Live Text for selection, and sends the selected text through the existing translation and Dictionary workflow.

## User Flow

1. The user copies a screenshot or another image to the clipboard.
2. With no text selected, the user presses the configured translation shortcut.
3. Boundless Translator opens the clipboard image in an image workspace window on the active screen.
4. Apple Live Text makes recognized text selectable in the image.
5. The user selects a word, sentence, or paragraph and presses the same shortcut again.
6. The existing translation panel shows the selected source text and translation.
7. The existing book action remains available for Dictionary lookup inside the translation panel.
8. The image workspace stays open until the user closes it. The user can return to it, select another passage, and translate again.

Pressing the shortcut with no selected text opens the current clipboard image. If the workspace already exists, the image is replaced and the existing window is brought forward.

## Image Workspace UI

Use a standard, resizable macOS window with native title-bar controls. Do not add Pin because the window already remains open until explicitly closed.

- Keep the image as the visual focus.
- Preserve its aspect ratio and fit the initial window to the active screen's usable area.
- Use Apple VisionKit's `ImageAnalysisOverlayView` for Live Text selection and system selection feedback.
- Keep the window open when the user clicks elsewhere, changes applications, or opens the translation panel.
- Do not add persistent OCR outlines, numbered regions, translation icons, custom selection colors, or instructional chrome.
- When neither selected text nor a clipboard image is available, do nothing.

The first version does not launch the macOS screenshot interface. It opens an image that is already present on the clipboard. A user can place a region screenshot directly on the clipboard with `Control-Shift-Command-4`.

## Input Routing

One shortcut handles both inputs in this order:

1. If selected text is available, start the existing translation workflow and do not read the clipboard image.
2. Otherwise, if the clipboard contains an image, present the image workspace.
3. Otherwise, do nothing.

When the translation shortcut is pressed, a Live Text selection has priority only while the image workspace is the active window and its overlay owns the selection. If the workspace is inactive or has no selected text, the existing external text-selection workflow runs unchanged. This prevents an old image selection from overriding text selected later in another application.

Reading the image workspace selection directly avoids synthesizing `Command-C`, depending on Accessibility APIs, or relying on another application's selection state. External text selection keeps its current Accessibility and clipboard-copy fallback behavior.

## Architecture

Add a focused image-workspace group without adding image behavior to translation presentation components.

### Clipboard image input

`ClipboardImageReading` defines the operation that reads an image from the clipboard. `PasteboardClipboardImageReader` is the AppKit adapter and returns an optional `NSImage`.

### Image workspace

`ImageWorkspaceWindowController` owns one standard window, replaces its current image, presents it on the active screen, and exposes the current Live Text selection.

`LiveTextImageView` bridges the AppKit image view and VisionKit overlay. It is responsible only for displaying the image, keeping overlay coordinates synchronized with the displayed image, and publishing selected text. It does not translate text or call Dictionary.

### Translation selection

An image-selection reader adapts the active workspace selection to the existing `SelectedTextReading` contract. Compose it ahead of the current external selection resolver so `AppController` continues to receive one `SelectedText` value and the existing language-resolution and translation path remains unchanged.

### Shortcut and Preferences

Reuse the existing `GlobalShortcutController` and its single configurable shortcut. Preferences continues to show one `Translate` shortcut recorder.

## Failure Behavior

- No selected text and no clipboard image: do nothing and keep existing windows unchanged.
- Image contains no recognizable text: display the image normally without adding custom OCR feedback.
- Live Text analysis is still running: show the image immediately and allow selection when analysis completes.
- Unsupported or failed translation: preserve the existing translation error and retry behavior.
- Closing the image window clears its active selection so later translation shortcuts cannot use stale image text.

## Testing

### Unit tests

- Clipboard image reading returns an image for supported pasteboard image data and `nil` otherwise.
- Image selection reading returns the current nonempty selection and rejects empty selection.
- Image selection has priority when present; the existing external reader is used when it is absent.
- An inactive image workspace cannot override text selected in another application.
- Selected text takes priority over a clipboard image.
- A clipboard image opens only when selected text is unavailable.
- Missing text and image inputs resolve to no action.

### Component tests

- The image workspace reuses one window and replaces its image on later presentations.
- The image workspace remains visible across application deactivation and translation-panel presentation.
- Closing the workspace clears the exposed selection.
- The Live Text overlay tracks the displayed image bounds after window resizing.
- Existing translation and Dictionary component behavior remains unchanged.

Do not unit-test Apple's OCR accuracy or reimplement VisionKit behavior in mocks. Unit and component tests verify Boundless Translator's routing and lifecycle without asserting VisionKit's recognition quality.

## Verification

After implementation:

1. Run the complete `swift test` suite.
2. Build the latest signed Release app and DMG.
3. Verify the App signature, minimum macOS version, linked system frameworks, and DMG installation layout.
4. Leave the installed App closed; deployment is not part of verification.

## Non-Goals

- Capturing the screen from inside Boundless Translator.
- Automatic translation of the complete image.
- Grouping OCR results into semantic text blocks.
- Translation icons or hover actions inside the image.
- Replacing original pixels with translated text.
- Speech controls inside the image workspace.
- Persisting screenshots or maintaining image history.
- Custom OCR or third-party OCR services.

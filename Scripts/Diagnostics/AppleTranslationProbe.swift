import Foundation
import Translation

@available(macOS 26.0, *)
@main
struct AppleTranslationProbe {
    @MainActor private static var shortLatencyLimit = 1.0
    @MainActor private static var shortLatencyMet = true

    @MainActor
    static func main() async {
        let args = CommandLine.arguments
        guard args.count == 8,
              let cancelDelay = Double(args[5]), cancelDelay.isFinite, cancelDelay >= 0,
              let timeout = Double(args[6]), timeout.isFinite, timeout > cancelDelay else {
            print("Invalid probe arguments.")
            exit(2)
        }
        let mode = args[1]
        let source = Locale.Language(identifier: args[3])
        let target = Locale.Language(identifier: args[4])
        let shortText = args[7]
        if let rawLimit = ProcessInfo.processInfo.environment["APPLE_TRANSLATION_SHORT_LATENCY_LIMIT"] {
            guard let limit = Double(rawLimit), limit.isFinite, limit > 0 else { exit(2) }
            shortLatencyLimit = limit
        }
        log("run_begin", detail: "mode=\(mode) source=\(args[3]) target=\(args[4]) pid=\(ProcessInfo.processInfo.processIdentifier)")
        // An independent deadline also works if a framework call never returns.
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            FileHandle.standardError.write(Data("event=timeout seconds=\(timeout); outstanding work is not confirmed stopped\n".utf8))
            exit(124)
        }
        let availability = await LanguageAvailability().status(from: source, to: target)
        guard availability == .installed else {
            log("languages_not_installed", detail: "status=\(availability)")
            print("Download this language pair using Apple's translation UI, then run again.")
            exit(2)
        }
        if mode == "short-only" {
            let session = TranslationSession(installedSource: source, target: target)
            finish(succeeded: await translate(shortText, session: session, label: "short"))
        }
        // Warm both conditions identically; do not confuse model startup with cancellation.
        let warmup = TranslationSession(installedSource: source, target: target)
        guard await translate(shortText, session: warmup, label: "warmup") else { exit(1) }
        let shortSession = TranslationSession(installedSource: source, target: target)
        if mode == "baseline" {
            let succeeded = await translate(shortText, session: shortSession, label: "short")
            finish(succeeded: succeeded)
        }
        guard ["cancel", "concurrent", "cancel-both", "task-cancel", "chunked"].contains(mode) else { exit(2) }
        do {
            var text = try String(contentsOfFile: args[2], encoding: .utf8)
            if let rawLimit = ProcessInfo.processInfo.environment["APPLE_TRANSLATION_CHARACTER_LIMIT"] {
                guard let limit = Int(rawLimit), limit > 0 else { exit(2) }
                text = String(text.prefix(limit))
            }
            let longSession = TranslationSession(installedSource: source, target: target)
            var longReturned = false
            var heartbeatCount = 0
            var maximumHeartbeatGap = 0.0
            let heartbeat = Task { @MainActor in
                var lastTick = ProcessInfo.processInfo.systemUptime
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                    let now = ProcessInfo.processInfo.systemUptime
                    maximumHeartbeatGap = max(maximumHeartbeatGap, now - lastTick)
                    lastTick = now
                    heartbeatCount += 1
                    if heartbeatCount.isMultiple(of: 5) { log("main_actor_heartbeat") }
                }
            }
            defer { heartbeat.cancel() }
            let longTask = Task { @MainActor in
                let succeeded = mode == "chunked"
                    ? await translateInChunks(text, session: longSession)
                    : await translate(text, session: longSession, label: "long")
                longReturned = true
                return succeeded
            }
            try await Task.sleep(for: .seconds(cancelDelay))
            guard !longReturned else {
                log("invalid_condition", detail: "long request returned before cancellation")
                exit(2)
            }
            if mode == "cancel" || mode == "cancel-both" || mode == "chunked" {
                log("cancel_call_begin", label: "long")
                longSession.cancel()
                log("cancel_call_returned", label: "long")
                guard await checkCancelledSession(longSession, text: shortText) else { exit(2) }
            }
            if mode == "task-cancel" || mode == "cancel-both" || mode == "chunked" {
                log("task_cancel_begin", label: "long")
                longTask.cancel()
                log("task_cancel_returned", label: "long")
            }
            if mode == "concurrent" { log("no_cancellation", label: "long") }
            // Do not await longTask before submitting the short request.
            let succeeded = await translate(shortText, session: shortSession, label: "short")
            log("waiting_for_long_return")
            _ = await longTask.value
            log("main_actor_responsiveness", detail: "ticks=\(heartbeatCount) maximum_gap_seconds=\(maximumHeartbeatGap)")
            _ = await translate(shortText, session: shortSession, label: "recovery")
            finish(succeeded: succeeded)
        } catch {
            let failure = error as NSError
            log("setup_error", detail: "domain=\(failure.domain) code=\(failure.code)")
            exit(1)
        }
    }

    @MainActor
    private static func checkCancelledSession(_ session: TranslationSession, text: String) async -> Bool {
        let start = ProcessInfo.processInfo.systemUptime
        do {
            _ = try await session.translate(text)
            log("cancelled_session_unexpected_success")
            return false
        } catch {
            let cancelled = TranslationError.alreadyCancelled ~= error
            log("cancelled_session_checked", detail: "already_cancelled=\(cancelled) elapsed_seconds=\(ProcessInfo.processInfo.systemUptime - start)")
            return cancelled
        }
    }

    @MainActor
    private static func translateInChunks(_ text: String, session: TranslationSession) async -> Bool {
        var start = text.startIndex
        var chunk = 0
        while start < text.endIndex {
            guard !Task.isCancelled else {
                log("chunk_sequence_cancelled", detail: "chunks_submitted=\(chunk)")
                return false
            }
            let end = text.index(start, offsetBy: 1000, limitedBy: text.endIndex) ?? text.endIndex
            chunk += 1
            guard await translate(String(text[start..<end]), session: session, label: "chunk_\(chunk)") else {
                log("chunk_sequence_stopped", detail: "chunks_submitted=\(chunk)")
                return false
            }
            start = end
        }
        return true
    }

    @MainActor
    private static func translate(_ text: String, session: TranslationSession, label: String) async -> Bool {
        let start = ProcessInfo.processInfo.systemUptime
        log("translate_begin", label: label, detail: "utf8_bytes=\(text.utf8.count)")
        do {
            let response = try await session.translate(text)
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            log("translate_returned", label: label,
                detail: "elapsed_seconds=\(elapsed) target_utf8_bytes=\(response.targetText.utf8.count)")
            if label == "short" {
                shortLatencyMet = elapsed <= shortLatencyLimit
                log("short_latency_verdict", detail: "passed=\(shortLatencyMet) limit_seconds=\(shortLatencyLimit) elapsed_seconds=\(elapsed)")
            }
            return true
        } catch {
            let failure = error as NSError
            log("translate_error", label: label,
                detail: "elapsed_seconds=\(ProcessInfo.processInfo.systemUptime - start) cancellation_error=\(error is CancellationError) domain=\(failure.domain) code=\(failure.code)")
            return false
        }
    }

    @MainActor
    private static func finish(succeeded: Bool) -> Never {
        log("run_end", detail: "short_success=\(succeeded) short_latency_met=\(shortLatencyMet)")
        exit(succeeded ? (shortLatencyMet ? 0 : 3) : 1)
    }

    @MainActor
    private static func log(_ event: String, label: String = "run", detail: String = "") {
        let line = "epoch=\(Date().timeIntervalSince1970) uptime=\(ProcessInfo.processInfo.systemUptime) label=\(label) event=\(event) \(detail)\n"
        FileHandle.standardOutput.write(Data(line.utf8))
    }
}

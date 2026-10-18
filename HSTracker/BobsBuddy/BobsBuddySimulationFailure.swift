//
//  BobsBuddySimulationFailure.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/18/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import Sentry

/// A failed BobsBuddy simulation, parsed out of the .NET exception text that
/// `SimulationRunner.SimulateMultiThreaded` hands back through Mono.
///
/// Every failure that is not an `UnsupportedInteractionException` reaches Sentry as the same
/// `RuntimeError(description: "System.AggregateException: One or more errors occurred...")`
/// string with no Swift stacktrace, so Sentry groups unrelated simulator bugs, broken .NET
/// installs and everything else into a single issue. Pulling out the innermost exception type
/// and the BobsBuddy frame it was thrown from gives each distinct failure its own title and
/// fingerprint, and lets the failures that are a broken install rather than a bug be dropped.
struct BobsBuddySimulationFailure {
    /// Exception types that mean the user's .NET runtime is incomplete. The simulator cannot
    /// run at all on such an install, so every combat fails the same way for as long as the
    /// app is open. Nothing in HSTracker can act on them and they drown out the real bugs.
    private static let environmentExceptions: Set<String> = [
        "System.IO.FileNotFoundException",
        "System.IO.FileLoadException",
        "System.BadImageFormatException",
        "System.TypeLoadException",
        "System.DllNotFoundException"
    ]

    /// `Class.<>c__DisplayClass5_0.<OnRally>b__0` -> `Class.OnRally`
    private static let closureFrame = Regex("\\.<>[A-Za-z0-9_]+\\.<([A-Za-z0-9_]+)>b__[0-9_]+")
    /// `Class.<>c__DisplayClass0_0.<SimulateMultiThreaded>g__RunSimulator|1` -> `Class.SimulateMultiThreaded.RunSimulator`
    private static let localFunctionFrame = Regex("\\.<>[A-Za-z0-9_]+\\.<([A-Za-z0-9_]+)>g__([A-Za-z0-9_]+)\\|[0-9_]+")
    /// `Class.<RunAsync>d__7.MoveNext` -> `Class.RunAsync`
    private static let asyncFrame = Regex("\\.<([A-Za-z0-9_]+)>d__[0-9]+\\.MoveNext")
    /// Generic arguments, which carry assembly versions and public key tokens on System frames
    private static let genericArguments = Regex("\\[[^\\]]*\\]")

    private static var reportedSignatures = Set<String>()
    private static let reportedSignaturesLock = NSLock()

    /// The full text as thrown, attached to the Sentry event
    let text: String
    /// The innermost .NET exception type, e.g. `System.NullReferenceException`
    let exceptionType: String
    /// The BobsBuddy frame it was thrown from, e.g. `BobsBuddy.Minions.Dragon.BronzeTimewalker.OnRally`
    let failureFrame: String?
    /// The stacktrace of the innermost exception of the primary chain, in the order .NET prints
    /// it: innermost call first
    let frames: [DotNetFrame]

    /// One `at ...` line of a .NET stacktrace
    struct DotNetFrame {
        /// The method, e.g. `OnRally`
        let function: String
        /// The type it is declared on, e.g. `BobsBuddy.Minions.Dragon.BronzeTimewalker`
        let module: String?
        /// The source file, only when the runtime had a real path for it
        let fileName: String?
        /// The line in `fileName`, only when it is a real line
        let lineNumber: Int?
        /// Whether the method is one of ours rather than the .NET runtime or a library
        let inApp: Bool
    }

    /// `in /src/Sim.cs:line 42` (.NET Core) or `[0x0001c] in /src/Sim.cs:42` (Mono). The path
    /// is captured as is, so `<8f2a...>` placeholders are left for the caller to reject.
    private static let sourceLocation = Regex("(?:^|\\s)in (.+?):(?:line )?([0-9]+)$")

    init(text: String) {
        self.text = text

        var type: String?
        var frames = [String]()
        var innerFrames = [DotNetFrame]()
        var reachedInnerBoundary = false

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("at ") {
                let frame = String(trimmed.dropFirst(3))
                frames.append(BobsBuddySimulationFailure.normalize(frame))
                if !reachedInnerBoundary {
                    innerFrames.append(BobsBuddySimulationFailure.parseFrame(frame))
                }
                continue
            }
            // The stacktrace of the primary chain ends at the end-of-inner marker, and the
            // `(Inner Exception #N)` copies an AggregateException appends come after it.
            if trimmed.hasPrefix("--- End of inner exception stack trace ---") || trimmed.contains("(Inner Exception #") {
                reachedInnerBoundary = true
                continue
            }
            // .NET prints the outermost exception first and each inner one below it, so the last
            // header before the first frame is the innermost exception of the primary chain. The
            // `(Inner Exception #N)` headers an AggregateException appends come after the frames.
            if let parsed = BobsBuddySimulationFailure.exceptionType(in: trimmed) {
                if frames.isEmpty {
                    type = parsed
                }
                // Frames printed above a later header belong to an outer exception, so only the
                // ones below the last header are the innermost exception's.
                if !reachedInnerBoundary {
                    innerFrames = []
                }
            }
        }

        exceptionType = type ?? "Unknown"
        self.frames = innerFrames

        let ours = frames.filter { $0.hasPrefix("BobsBuddy.") }
        // Utils frames are shared helpers, so the frame below one of them names the actual card
        // or simulation step and makes a far more useful group.
        failureFrame = ours.first { !$0.hasPrefix("BobsBuddy.Utils.") } ?? ours.first
    }

    /// True when the failure is a broken .NET install rather than something we can fix
    var isEnvironmentFailure: Bool {
        return BobsBuddySimulationFailure.environmentExceptions.contains(exceptionType)
    }

    var errorState: BobsBuddyErrorState {
        return isEnvironmentFailure ? .failedToLoad : .none
    }

    /// What this failure is grouped by, both for Sentry and for the once-per-run reporting
    var signature: String {
        return "\(exceptionType)|\(failureFrame ?? "unknown")"
    }

    /// Reports the failure to Sentry, unless it is a broken install or the same failure has
    /// already been reported in this run. A failing simulation repeats on every single combat,
    /// so without this one user can send thousands of copies of one event.
    func report(input: InputProxy?) {
        if isEnvironmentFailure {
            logger.error("BobsBuddy cannot run on this install: \(exceptionType). Not reporting.")
            return
        }

        BobsBuddySimulationFailure.reportedSignaturesLock.lock()
        let isNew = BobsBuddySimulationFailure.reportedSignatures.insert(signature).inserted
        BobsBuddySimulationFailure.reportedSignaturesLock.unlock()

        guard isNew else {
            logger.error("Already reported \(signature) this run. Not reporting again.")
            return
        }

        let event = makeEvent()
        let exceptionText = text
        let inputString = input?.unitestCopyableVersion() ?? ""
        SentrySDK.capture(event: event, block: { scope in
            // An attachment rather than extra, because the project's data scrubbing rules
            // replace the whole extra value with [Filtered]
            scope.addAttachment(Attachment(data: exceptionText.data(using: .utf8) ?? Data(), filename: "exception.txt", contentType: "text/plain"))
            if inputString.count != 0 {
                scope.addAttachment(Attachment(data: inputString.data(using: .utf8) ?? Data(), filename: "input.cs", contentType: "application/text"))
            }
        })
    }

    /// The Sentry event for this failure. The .NET frames are attached as the exception's
    /// stacktrace, because otherwise Sentry only shows the Swift threads, which say nothing
    /// about the simulator.
    func makeEvent() -> Event {
        let exception = Exception(value: failureFrame ?? "Unknown frame", type: exceptionType)
        exception.mechanism = Mechanism(type: "bobsbuddy")
        if !frames.isEmpty {
            // .NET prints the innermost call first, and Sentry wants the outermost call first
            let sentryFrames = frames.reversed().map { frame -> Frame in
                let sentryFrame = Frame()
                sentryFrame.platform = "csharp"
                sentryFrame.function = frame.function
                sentryFrame.module = frame.module
                sentryFrame.fileName = frame.fileName
                sentryFrame.lineNumber = frame.lineNumber.map { NSNumber(value: $0) }
                sentryFrame.inApp = NSNumber(value: frame.inApp)
                return sentryFrame
            }
            exception.stacktrace = SentryStacktrace(frames: sentryFrames, registers: [:])
        }

        let event = Event()
        event.level = .error
        event.exceptions = [exception]
        event.fingerprint = ["bobsbuddy", exceptionType, failureFrame ?? "unknown"]
        return event
    }

    /// For events whose first exception is a BobsBuddy failure, drops the threads and debug
    /// meta. The SDK attaches the current Swift threads to any event that has exceptions, which
    /// buries the .NET stacktrace under them. This has to run in `beforeSend`: an empty threads
    /// array does not stop the SDK from adding its own.
    static func stripNativeThreads(from event: Event) -> Event {
        guard event.exceptions?.first?.mechanism?.type == "bobsbuddy" else {
            return event
        }
        event.threads = nil
        event.debugMeta = nil
        return event
    }

    private static func parseFrame(_ frame: String) -> DotNetFrame {
        let symbolEnd = frame.firstIndex(of: "(") ?? frame.endIndex
        let symbol = normalize(String(frame[frame.startIndex ..< symbolEnd]).trimmingCharacters(in: .whitespaces))

        // The source location follows the parameter list
        var fileName: String?
        var lineNumber: Int?
        let location = frame.firstIndex(of: ")").map { String(frame[frame.index(after: $0)...]) } ?? ""
        let matches = sourceLocation.matches(location)
        if matches.count == 2, let line = Int(matches[1].value), line > 0, !matches[0].value.hasPrefix("<") {
            fileName = matches[0].value
            lineNumber = line
        }

        let lastDot = symbol.lastIndex(of: ".")
        return DotNetFrame(function: lastDot.map { String(symbol[symbol.index(after: $0)...]) } ?? symbol,
                           module: lastDot.map { String(symbol[..<$0]) },
                           fileName: fileName,
                           lineNumber: lineNumber,
                           inApp: symbol.hasPrefix("BobsBuddy."))
    }

    private static func exceptionType(in line: String) -> String? {
        var candidate = line
        if candidate.hasPrefix("---> ") {
            candidate = String(candidate.dropFirst("---> ".count))
        }
        guard let colon = candidate.firstIndex(of: ":") else {
            return nil
        }
        let name = String(candidate[candidate.startIndex ..< colon])
        guard name.hasSuffix("Exception"),
              name.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" }) else {
            return nil
        }
        return name
    }

    private static func normalize(_ frame: String) -> String {
        var symbol = frame
        if let parameters = symbol.firstIndex(of: "(") {
            symbol = String(symbol[symbol.startIndex ..< parameters])
        }
        symbol = symbol.replace(localFunctionFrame, with: ".$1.$2")
        symbol = symbol.replace(closureFrame, with: ".$1")
        symbol = symbol.replace(asyncFrame, with: ".$1")
        return symbol.replace(genericArguments, with: "")
    }
}

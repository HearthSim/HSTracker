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

    /// The full text as thrown, kept for the Sentry event body
    let text: String
    /// The innermost .NET exception type, e.g. `System.NullReferenceException`
    let exceptionType: String
    /// The BobsBuddy frame it was thrown from, e.g. `BobsBuddy.Minions.Dragon.BronzeTimewalker.OnRally`
    let failureFrame: String?

    init(text: String) {
        self.text = text

        var type: String?
        var frames = [String]()

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("at ") {
                frames.append(BobsBuddySimulationFailure.normalize(String(trimmed.dropFirst(3))))
                continue
            }
            // .NET prints the outermost exception first and each inner one below it, so the last
            // header before the first frame is the innermost exception of the primary chain. The
            // `(Inner Exception #N)` headers an AggregateException appends come after the frames.
            if frames.isEmpty, let parsed = BobsBuddySimulationFailure.exceptionType(in: trimmed) {
                type = parsed
            }
        }

        exceptionType = type ?? "Unknown"

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

        let exception = Exception(value: failureFrame ?? "Unknown frame", type: exceptionType)
        exception.mechanism = Mechanism(type: "bobsbuddy")

        let event = Event()
        event.level = .error
        event.exceptions = [exception]
        event.fingerprint = ["bobsbuddy", exceptionType, failureFrame ?? "unknown"]
        event.extra = ["exception": text]

        let inputString = input?.unitestCopyableVersion() ?? ""
        SentrySDK.capture(event: event, block: { scope in
            if inputString.count != 0 {
                scope.addAttachment(Attachment(data: inputString.data(using: .utf8) ?? Data(), filename: "input.cs", contentType: "application/text"))
            }
        })
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

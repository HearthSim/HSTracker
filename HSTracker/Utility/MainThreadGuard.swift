//
//  MainThreadGuard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/2/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Reports AppKit work that runs off the main thread.
///
/// HSTracker drives its overlays from a large number of long lived watcher
/// threads. View drawing and the `NSGraphicsContext` state stack are
/// main thread only; touching them from another thread damages the process
/// heap. macOS 26 validates the malloc freelist on every allocation and traps
/// when it finds damage, so the resulting crash surfaces at whatever unrelated
/// allocation happens next instead of at the code that broke the rule. That is
/// why a single defect shows up in Sentry as a family of unrelated
/// `EXC_BREAKPOINT` groups (HSTRACKER-2M7, HSTRACKER-22Y and their siblings).
///
/// `assertMainThread()` reports from the place that actually broke the rule, so
/// the captured stack names the offending thread and call path. It traps in
/// debug builds and reports once per call site in release builds.
enum MainThreadGuard {
    private static let lock = UnfairLock()
    private static var reported = Set<String>()

    /// Maximum number of distinct call sites reported per run, so a violation in
    /// a hot drawing path cannot flood Sentry.
    private static let maxReportedCallSites = 20

    static func violation(_ context: String, file: String, line: UInt) {
        let location = "\(file):\(line)"

        #if DEBUG
        assertionFailure("\(context) must run on the main thread, was \(Thread.current)")
        #endif

        let shouldReport: Bool = lock.around {
            if reported.contains(location) || reported.count >= maxReportedCallSites {
                return false
            }
            reported.insert(location)
            return true
        }

        guard shouldReport else { return }

        Influx.sendEvent(eventName: "off_main_thread_ui", withProperties: [
            "context": context,
            "location": location,
            "thread": Thread.current.name ?? "unnamed"
        ])
    }
}

/// Asserts that the caller is running on the main thread.
///
/// See `MainThreadGuard` for why this matters. The check is a single boolean
/// test on the fast path, so it is safe to call from `draw(_:)`.
@inline(__always)
func assertMainThread(_ context: @autoclosure () -> String = #function,
                      file: StaticString = #fileID,
                      line: UInt = #line) {
    if Thread.isMainThread {
        return
    }
    MainThreadGuard.violation(context(), file: "\(file)", line: line)
}

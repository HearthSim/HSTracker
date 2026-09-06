//
//  Watcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/1/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

/// Base class for all the Hearthstone memory watchers.
///
/// Each watcher polls the game from its own serial queue. `run()` and `stop()`
/// are called from the log reader thread and from the main thread, so the queue
/// is created once in `init` and the start/stop bookkeeping happens under a
/// lock. Every watcher used to keep the queue in a plain `var` and create it
/// lazily inside `run()`, which over-released the queue when two threads
/// entered `run()` at the same time (Sentry HSTRACKER-2MM).
class Watcher {
    private let delay: TimeInterval
    private let queue: DispatchQueue
    private let _running = ManagedAtomic<Bool>(false)
    private let _watch = ManagedAtomic<Bool>(false)

    /// Guards the `_watch` / `_running` transitions in `run()` and at the end
    /// of the watch loop.
    private let stateLock = NSLock()

    /// Serializes `update()` so a manual `tick()` never runs concurrently with
    /// the watch loop.
    private let updateLock = NSLock()

    init(delay: TimeInterval) {
        self.delay = delay
        self.queue = DispatchQueue(label: "\(Self.self)", attributes: [])
    }

    /// True while the watcher is supposed to keep polling.
    var isWatching: Bool {
        return _watch.load(ordering: .sequentiallyConsistent)
    }

    func run() {
        stateLock.lock()
        defer { stateLock.unlock() }

        _watch.store(true, ordering: .sequentiallyConsistent)
        if _running.load(ordering: .sequentiallyConsistent) {
            return
        }
        _running.store(true, ordering: .sequentiallyConsistent)
        queue.async { [weak self] in
            guard let self else { return }
            Thread.current.name = self.queue.label
            self.watch()
        }
    }

    func stop() {
        _watch.store(false, ordering: .sequentiallyConsistent)
    }

    /// Runs a single update, serialized against the watch loop. Call this
    /// rather than `update()` when polling the watcher from the outside.
    @discardableResult
    func tick() -> Bool {
        updateLock.lock()
        defer { updateLock.unlock() }

        return update()
    }

    /// Called on the watcher queue before the loop starts. Subclasses reset
    /// their per-run state here.
    func setup() {
    }

    /// A single poll. Return true when the watcher is done, which ends the loop
    /// without clearing the watch flag, so a later `run()` restarts it.
    func update() -> Bool {
        return false
    }

    /// Called on the watcher queue once the loop has ended.
    func cleanup() {
    }

    private func watch() {
        while true {
            setup()
            var finished = false
            while isWatching {
                Thread.sleep(forTimeInterval: delay)
                if !isWatching {
                    break
                }
                if tick() {
                    finished = true
                    break
                }
            }
            cleanup()

            stateLock.lock()
            if !finished && isWatching {
                // run() re-armed the watcher while we were winding down. That
                // call saw us as running and did not queue a loop of its own,
                // so start over instead of leaving nothing watching.
                stateLock.unlock()
                continue
            }
            _running.store(false, ordering: .sequentiallyConsistent)
            stateLock.unlock()
            return
        }
    }
}

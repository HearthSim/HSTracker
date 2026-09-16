//
//  ArenaMouseDirectionWatcher.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import Foundation

/// Port of HDT's `Utility/MouseWatcher.cs`.
///
/// Watches the cursor while it travels from a draft choice down to the bottom
/// panel. Two things end that journey: going still (the timeout restarts on every
/// movement, so it fires only after the cursor has stopped for `timeout`), or
/// changing direction to one the caller objects to.
@available(macOS 10.15, *)
final class ArenaMouseDirectionWatcher {
    struct Direction: OptionSet {
        let rawValue: Int
        static let up = Direction(rawValue: 1)
        static let down = Direction(rawValue: 1 << 1)
        static let left = Direction(rawValue: 1 << 2)
        static let right = Direction(rawValue: 1 << 3)
    }

    private static let minHistoryThreshold = 5
    private static let maxHistory = 10
    private static let interval: TimeInterval = 0.05

    private let timeout: TimeInterval
    private let minDirectionDistance: CGFloat

    private var history = [NSPoint]()
    private var timeoutStart = Date()
    private var previousDirection: Direction = []
    private var timer: Timer?

    var onTimeout: (() -> Void)?
    var onDirectionChange: ((Direction) -> Void)?

    init(timeout: TimeInterval = 0.4, minDirectionDistance: CGFloat = 10) {
        self.timeout = timeout
        self.minDirectionDistance = minDirectionDistance
    }

    var isRunning: Bool { timer != nil }

    func start() {
        guard timer == nil else { return }
        timeoutStart = Date()
        previousDirection = []
        history.removeAll()
        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        if Date().timeIntervalSince(timeoutStart) >= timeout {
            stop()
            onTimeout?()
            return
        }

        let position = NSEvent.mouseLocation
        if let previous = history.first {
            if previous.x != position.x || previous.y != position.y {
                // Any movement restarts the clock: the timeout means "has gone
                // still", not "has taken too long".
                timeoutStart = Date()
                history.insert(position, at: 0)
            }
        } else {
            history.insert(position, at: 0)
        }

        if history.count > Self.maxHistory {
            history.removeSubrange(Self.maxHistory..<history.count)
        }

        guard history.count > Self.minHistoryThreshold, let start = history.last else { return }

        // Screen coordinates are y-up on macOS and y-down on Windows, so the
        // vertical test is inverted relative to HDT's.
        var direction: Direction = []
        if position.y - start.y > minDirectionDistance {
            direction.insert(.up)
        } else if start.y - position.y > minDirectionDistance {
            direction.insert(.down)
        }
        if start.x - position.x > minDirectionDistance {
            direction.insert(.left)
        } else if position.x - start.x > minDirectionDistance {
            direction.insert(.right)
        }

        if direction != previousDirection {
            previousDirection = direction
            onDirectionChange?(direction)
        }
    }
}

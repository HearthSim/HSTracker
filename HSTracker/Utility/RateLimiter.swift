//
//  RateLimiter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/15/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class RateLimiter {
    var _maxCount: Int
    var _lastRun: Deque<Date>
    var _timeSpan: TimeInterval
    var _nextTask: (() /*async*/ -> Void)?
    var _running: Bool
    
    init(maxCount: Int, timeSpan: TimeInterval) {
        _maxCount = maxCount
        _timeSpan = timeSpan
        _lastRun = Deque<Date>()
        _running = false
    }
    
    func run(task: @escaping () /*async*/ -> Void, onThrottled: (() -> Void)? = nil) /*async*/ {
        _nextTask = task
        if _running {
            return
        }
        _running = true
        /*await*/ rateLimit(onThrottled: onThrottled)
        _lastRun.enqueue(Date())
        if let nextTask = _nextTask {
            /*await*/ nextTask()
        }
        _running = false
    }
    
    func rateLimit(onThrottled: (() -> Void)?) /*async*/ {
        let now = Date()
        while !_lastRun.isEmpty {
            if now.timeIntervalSince(_lastRun.peekFront() ?? now) >= _timeSpan {
                break
            }
            _ = _lastRun.dequeue()
        }
        if _lastRun.count >= _maxCount {
            onThrottled?()
            Thread.sleep(forTimeInterval: _timeSpan - now.timeIntervalSince(_lastRun.peekFront() ?? now))
        }
    }
}

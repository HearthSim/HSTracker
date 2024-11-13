//
//  SceneWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct SceneEventArgs: Equatable {
    static func == (lhs: SceneEventArgs, rhs: SceneEventArgs) -> Bool {
        return lhs.prevMode == rhs.prevMode && lhs.mode == rhs.mode && lhs.sceneLoaded == rhs.sceneLoaded && lhs.transitioning == rhs.transitioning
    }
    
    let prevMode: Int
    let mode: Int
    let sceneLoaded: Bool
    let transitioning: Bool
}

class SceneWatcher {
    var change: ((_ sender: SceneWatcher, _ args: SceneEventArgs) -> Void)?
    private let delay: TimeInterval
    private var _running = false
    private var _watch = false
    private var _prev: SceneEventArgs?
    internal var queue: DispatchQueue?

    init(delay: TimeInterval = 0.200) {
        self.delay = delay
    }
    
    func run() {
        _watch = true
        if _running {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "\(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async { [weak self] in
                Thread.current.name = queue.label
                self?.update()
            }
        }
    }
    
    func stop() {
        _watch = false
    }
    
    private func update() {
        _running = true
        while _watch {
            Thread.sleep(forTimeInterval: delay)
            if !_watch {
                break
            }
            
            let state = MirrorHelper.getSceneMgrState()
            let curr = SceneEventArgs(prevMode: state?.prevMode.intValue ?? 0, mode: state?.mode.intValue ?? 0, sceneLoaded: state?.sceneLoaded ?? false, transitioning: state?.transitioning ?? false)
            if curr == _prev {
                continue
            }
            change?(self, curr)
            _prev = curr
        }
        _prev = nil
        _running = false
    }
}

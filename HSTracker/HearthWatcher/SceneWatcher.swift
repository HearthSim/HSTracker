//
//  SceneWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

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
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    private var _prev: SceneEventArgs?
    internal var queue: DispatchQueue?

    init(delay: TimeInterval = 0.200) {
        self.delay = delay
    }
    
    func run() {
        _watch.store(true, ordering: .sequentiallyConsistent)
        if _running.load(ordering: .sequentiallyConsistent) {
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
        _watch.store(false, ordering: .sequentiallyConsistent)
    }
    
    private func update() {
        _running.store(true, ordering: .sequentiallyConsistent)
        while _watch.load(ordering: .sequentiallyConsistent) {
            Thread.sleep(forTimeInterval: delay)
            if !_watch.load(ordering: .sequentiallyConsistent) {
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
        _running.store(false, ordering: .sequentiallyConsistent)
    }
}

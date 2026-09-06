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

class SceneWatcher: Watcher {
    var change: ((_ sender: SceneWatcher, _ args: SceneEventArgs) -> Void)?
    private var _prev: SceneEventArgs?

    override init(delay: TimeInterval = 0.200) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let state = MirrorHelper.getSceneMgrState()
        let curr = SceneEventArgs(prevMode: state?.prevMode.intValue ?? 0, mode: state?.mode.intValue ?? 0, sceneLoaded: state?.sceneLoaded ?? false, transitioning: state?.transitioning ?? false)
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}

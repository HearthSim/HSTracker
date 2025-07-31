//
//  ExperienceWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

struct ExperienceEvent {
    var experience: Int
    var experienceNeeded: Int
    var level: Int
    var levelChange: Int
    var animate: Bool
}

class ExperienceWatcher {
    var newExperienceHandler: ((_ sender: ExperienceWatcher, _ args: ExperienceEvent) -> Void)?
    private let delay: TimeInterval
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    var _rewardTrackData: MirrorRewardTrackData?
    internal var queue: DispatchQueue?
    
    init(delay: TimeInterval = 1.000) {
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
                guard let self else { return }
                Thread.current.name = queue.label
                self.update()
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
            
            if !MirrorHelper.isInitialized() {
                continue
            }
            
            if let newRewards = MirrorHelper.getRewardTrackData() {
                if _rewardTrackData == nil || _rewardTrackData?.xp != newRewards.xp || _rewardTrackData?.level != newRewards.level || _rewardTrackData?.xpNeeded != newRewards.xpNeeded {
                    var levelChange = 0
                    if let temp = _rewardTrackData {
                        levelChange = temp.level.intValue - newRewards.level.intValue
                    }
                    newExperienceHandler?(self, ExperienceEvent(experience: newRewards.xp.intValue, experienceNeeded: newRewards.xpNeeded.intValue, level: newRewards.level.intValue, levelChange: levelChange, animate: _rewardTrackData != nil))
                    _rewardTrackData = newRewards
                }
            }
        }
        _running.store(false, ordering: .sequentiallyConsistent)
    }
}

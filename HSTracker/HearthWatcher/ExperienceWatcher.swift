//
//  ExperienceWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

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
    private var _running = false
    private var _watch = false
    var _rewardTrackData: MirrorRewardTrackData?
    internal var queue: DispatchQueue?
    
    init(delay: TimeInterval = 1.000) {
        self.delay = delay
    }
    
    func run() {
        _watch = true
        if _running {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "net.hearthsim.hstracker.watchers.\(type(of: self))",
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
        _running = false
    }
}

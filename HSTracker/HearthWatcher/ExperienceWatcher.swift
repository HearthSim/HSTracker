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

class ExperienceWatcher: Watcher {
    var newExperienceHandler: ((_ sender: ExperienceWatcher, _ args: ExperienceEvent) -> Void)?
    var _rewardTrackData: MirrorRewardTrackData?

    override init(delay: TimeInterval = 1.000) {
        super.init(delay: delay)
    }

    override func update() -> Bool {
        if !MirrorHelper.isInitialized() {
            return false
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
        return false
    }
}

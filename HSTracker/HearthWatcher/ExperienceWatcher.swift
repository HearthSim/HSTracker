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
            let prev = _rewardTrackData
            if prev == nil || prev?.xp != newRewards.xp || prev?.level != newRewards.level || prev?.xpNeeded != newRewards.xpNeeded {
                // HDT's ExperienceTracker.Update measures the change from the
                // previous reading to the new one - `data.Level - prev.Level` -
                // so a level gained is a positive number. OverlayWindow's
                // animation loop runs once per level, so the old subtraction the
                // other way round meant it never ran at all.
                var levelChange = 0
                if let prev {
                    levelChange = newRewards.level.intValue - prev.level.intValue
                }
                newExperienceHandler?(self, ExperienceEvent(experience: newRewards.xp.intValue, experienceNeeded: newRewards.xpNeeded.intValue, level: newRewards.level.intValue, levelChange: levelChange, animate: ExperienceWatcher.shouldAnimate(prev, newRewards)))
                _rewardTrackData = newRewards
            }
        }
        return false
    }

    // ExperienceTracker.ShouldAnimate. Besides never animating the first
    // reading of a session, HDT throws away one case it could not reproduce
    // reliably: Hearthstone sometimes reports the reward track once with a
    // level of 0 or 1 before the real value, and taking that at face value
    // plays a level-up animation for every level of the jump back.
    private static func shouldAnimate(_ prev: MirrorRewardTrackData?, _ curr: MirrorRewardTrackData) -> Bool {
        guard let prev else {
            return false
        }
        if prev.level.intValue <= 1 && curr.level.intValue - prev.level.intValue > 5 {
            return false
        }
        return true
    }
}

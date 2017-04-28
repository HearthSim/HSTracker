//
//  ArenaInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/01/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

struct ArenaInfo {
    //@property MirrorDeck *_Nonnull deck;
    let losses: Int
    let wins: Int
    let currentSlot: Int
    let rewards: [RewardData]

    init(info: MirrorArenaInfo) {
        losses = info.losses as? Int ?? 0
        wins = info.wins as? Int ?? 0
        currentSlot = info.currentSlot as? Int ?? 0
        rewards = ArenaInfo.parseRewards(mirrorRewards: info.rewards)
    }

    private static func parseRewards(mirrorRewards: [MirrorRewardData]) -> [RewardData] {
        var rewards: [RewardData] = []

        for mirrorReward in mirrorRewards {
            if let mirror = mirrorReward as? MirrorArcaneDustRewardData {
                rewards.append(ArcaneDustRewardData(mirror: mirror))
            } else if let mirror = mirrorReward as? MirrorBoosterPackRewardData {
                rewards.append(BoosterPackRewardData(mirror: mirror))
            } else if let mirror = mirrorReward as? MirrorCardRewardData {
                rewards.append(CardRewardData(mirror: mirror))
            } else if let mirror = mirrorReward as? MirrorCardBackRewardData {
                rewards.append(CardBackRewardData(mirror: mirror))
            } else if let mirror = mirrorReward as? MirrorForgeTicketRewardData {
                rewards.append(ForgeTicketRewardData(mirror: mirror))
            } else if let mirror = mirrorReward as? MirrorGoldRewardData {
                rewards.append(GoldRewardData(mirror: mirror))
            } else if let mirror = mirrorReward as? MirrorMountRewardData {
                rewards.append(MountRewardData(mirror: mirror))
            }
        }

        return rewards
    }
}

protocol RewardData {}
struct ArcaneDustRewardData: RewardData {
    let amount: Int

    init(mirror: MirrorArcaneDustRewardData) {
        amount = mirror.amount as? Int ?? 0
    }
}

struct BoosterPackRewardData: RewardData {
    let boosterId: Int
    let count: Int

    init(mirror: MirrorBoosterPackRewardData) {
        boosterId = mirror.boosterId as? Int ?? 0
        count = mirror.count as? Int ?? 0
    }
}

struct CardRewardData: RewardData {
    let cardId: String
    let count: Int
    let premium: Bool

    init(mirror: MirrorCardRewardData) {
        cardId = mirror.cardId as String
        count = mirror.count as? Int ?? 0
        premium = mirror.premium
    }
}

struct CardBackRewardData: RewardData {
    let cardbackId: Int

    init(mirror: MirrorCardBackRewardData) {
        cardbackId = mirror.cardbackId as? Int ?? 0
    }
}

struct ForgeTicketRewardData: RewardData {
    let quantity: Int

    init(mirror: MirrorForgeTicketRewardData) {
        quantity = mirror.quantity as? Int ?? 0
    }
}

struct GoldRewardData: RewardData {
    let amount: Int

    init(mirror: MirrorGoldRewardData) {
        amount = mirror.amount as? Int ?? 0
    }
}

struct MountRewardData: RewardData {
    let mountType: Int

    init(mirror: MirrorMountRewardData) {
        mountType = mirror.mountType as? Int ?? 0
    }
}

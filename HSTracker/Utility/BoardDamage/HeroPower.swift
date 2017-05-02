//
//  HeroPower.swift
//  HSTracker
//
//  Created by Christopher Herrera on 3/16/17.
//  Copyright (c) 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class HeroPower {
    var _entity: Entity
    var id: String
    var cost: Int
    var name: String?

    var damage: Int {
        switch id {
        case CardIds.NonCollectible.Druid.Shapeshift,
             CardIds.NonCollectible.Mage.Fireblast,
             CardIds.NonCollectible.Mage.Fireblast_FireblastHeroSkins1,
             CardIds.NonCollectible.Mage.Fireblast_FireblastHeroSkins2:
            return 1
        case CardIds.NonCollectible.Druid.JusticarTrueheart_DireClaws,
             CardIds.NonCollectible.Priest.Shadowform_MindSpikeToken,
             CardIds.NonCollectible.Hunter.SteadyShot,
             CardIds.NonCollectible.Neutral.Eruption,
             CardIds.NonCollectible.Neutral.BoomBotJrTavernBrawl,
             CardIds.NonCollectible.Mage.FireblastRank2HeroSkins1,
             CardIds.NonCollectible.Mage.FireblastRank2HeroSkins2,
             CardIds.NonCollectible.Mage.JusticarTrueheart_FireblastRank2,
             CardIds.NonCollectible.Shaman.ChargedHammer_LightningJoltToken:
            return 2
        case CardIds.NonCollectible.Priest.Shadowform_MindShatterToken,
             CardIds.NonCollectible.Neutral.EruptionHeroic,
             "TB_FW_HeroPower_Boom",
             CardIds.NonCollectible.Neutral.ThrowRocks,
             CardIds.NonCollectible.Hunter.BallistaShotHeroSkins,
             CardIds.NonCollectible.Hunter.JusticarTrueheart_BallistaShot:
            return 3
        case CardIds.NonCollectible.Neutral.UnbalancingStrike:
            return 4
        case CardIds.NonCollectible.Neutral.MajordomoExecutus_DieInsectHeroPower:
            return 8
        case CardIds.NonCollectible.Neutral.MajordomoExecutus_DieInsects:
            return 16
        default:
            return 0
        }
    }

    init(entity: Entity) {
        self.cost = entity[.cost]
        self.name = entity.name
        self.id = entity.cardId
        self._entity = entity
    }
}

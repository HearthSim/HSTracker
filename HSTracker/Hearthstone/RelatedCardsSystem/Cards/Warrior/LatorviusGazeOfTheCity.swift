//
//  LatorviusGazeOfTheCity.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class LatorviusGazeOfTheCity: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.NonCollectible.Warrior.EntertheLostCity_LatorviusGazeOfTheCityToken
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Druid.JungleGiants_BarnabusTheStomperToken),
            Cards.any(byId: CardIds.NonCollectible.Hunter.TheMarshQueen_QueenCarnassaToken),
            Cards.any(byId: CardIds.NonCollectible.Mage.OpentheWaygate_TimeWarpToken),
            Cards.any(byId: CardIds.NonCollectible.Paladin.TheLastKaleidosaur_GalvadonToken),
            Cards.any(byId: CardIds.NonCollectible.Priest.AwakentheMakers_AmaraWardenOfHopeToken),
            Cards.any(byId: CardIds.NonCollectible.Rogue.TheCavernsBelow_CrystalCoreToken),
            Cards.any(byId: CardIds.NonCollectible.Shaman.UnitetheMurlocs_MegafinToken),
            Cards.any(byId: CardIds.NonCollectible.Warlock.LakkariSacrifice_NetherPortalToken1),
            Cards.any(byId: CardIds.NonCollectible.Warrior.FirePlumesHeart_SulfurasToken)
        ]
    }
}

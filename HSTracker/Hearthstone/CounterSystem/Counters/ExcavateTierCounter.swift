//
//  ExcavateTierCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/28/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ExcavateTierCounter: NumericCounter {
    
    override var localizedName: String {
        return String.localizedString("Counter_ExcavateTier", comment: "")
    }
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.KoboldMiner
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.KoboldMiner,
            CardIds.Collectible.Neutral.BurrowBuster,
            CardIds.Collectible.Rogue.BloodrockCoShovel,
            CardIds.Collectible.Rogue.DrillyTheKid,
            CardIds.Collectible.Warlock.Smokestack,
            CardIds.Collectible.Warlock.MoargDrillfist,
            CardIds.Collectible.Warrior.BlastCharge,
            CardIds.Collectible.Warrior.ReinforcedPlating,
            CardIds.Collectible.Mage.Cryopreservation,
            CardIds.Collectible.Mage.BlastmageMiner,
            CardIds.Collectible.Paladin.Shroomscavate,
            CardIds.Collectible.Paladin.FossilizedKaleidosaur,
            CardIds.Collectible.Deathknight.ReapWhatYouSow,
            CardIds.Collectible.Deathknight.SkeletonCrew,
            CardIds.Collectible.Shaman.DiggingStraightDown
        ]
    }

    private var excavated: Bool = false
    
    private var excavateTierLabel: String {
        switch counter {
        case 0: return String.localizedString("Counter_Excavate_Tier0", comment: "")
        case 1: return String.localizedString("Counter_Excavate_Tier1", comment: "")
        case 2: return String.localizedString("Counter_Excavate_Tier2", comment: "")
        case 3: return String.localizedString("Counter_Excavate_Tier3", comment: "")
        default: return "\(counter + 1)"
        }
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return counter > 0 || inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    private func getExcavateRewards() -> [String] {
        switch counter {
        case 0:
            return [
                CardIds.NonCollectible.Neutral.KoboldMiner_EscapingTroggToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_FoolsAzeriteToken,
                CardIds.NonCollectible.Neutral.HeartblossomToken1,
                CardIds.NonCollectible.Neutral.KoboldMiner_PouchOfCoinsToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_RockToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_WaterSourceToken
            ]
        case 1:
            return [
                CardIds.NonCollectible.Neutral.KoboldMiner_AzeriteChunkToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_CanaryToken,
                CardIds.NonCollectible.Neutral.DeepholmGeodeToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_FallingStalactiteToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_GlowingGlyphToken1,
                CardIds.NonCollectible.Neutral.KoboldMiner_LivingStoneToken
            ]
        case 2:
            return [
                CardIds.NonCollectible.Neutral.KoboldMiner_AzeriteGemToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_CollapseToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_MotherlodeDrakeToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_OgrefistBoulderToken,
                CardIds.NonCollectible.Neutral.KoboldMiner_SteelhideMoleToken,
                CardIds.NonCollectible.Neutral.WorldPillarFragmentToken
            ]
        case 3:
            return [
                CardIds.NonCollectible.Paladin.TheAzeriteDragonToken,
                CardIds.NonCollectible.Mage.KoboldMiner_TheAzeriteHawkToken,
                CardIds.NonCollectible.Warlock.KoboldMiner_TheAzeriteSnakeToken,
                CardIds.NonCollectible.Warrior.KoboldMiner_TheAzeriteOxToken,
                CardIds.NonCollectible.Rogue.KoboldMiner_TheAzeriteScorpionToken,
                CardIds.NonCollectible.Shaman.TheAzeriteMurlocToken,
                CardIds.NonCollectible.Deathknight.KoboldMiner_TheAzeriteRatToken
            ]
        default:
            return []
        }
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ? filterCardsByClassAndFormat(cardIds: getExcavateRewards(), playerClass: game.player.playerClass) : filterCardsByClassAndFormat(cardIds: getExcavateRewards(), playerClass: game.opponent.playerClass)
    }

    override func valueToShow() -> String {
        return excavateTierLabel
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag == .current_excavate_tier {
            let controller = entity[.controller]
            if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
                excavated = true
                counter = value
            }
        }
    }
}

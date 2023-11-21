//
//  WotogCounterHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

extension Game {
    static let spellCounterCards = [
        CardIds.Collectible.Neutral.YoggSaronHopesEnd,
        CardIds.Collectible.Neutral.ArcaneGiant,
        CardIds.Collectible.Priest.GraveHorror,
        CardIds.Collectible.Druid.UmbralOwlDARKMOON_FAIRE,
        CardIds.Collectible.Druid.UmbralOwlPLACEHOLDER_202204
    ]
    
	var playerCthun: Entity? {
		return self.player.playerEntities
			.first { $0.cardId == CardIds.Collectible.Neutral.Cthun }
	}
	
	var playerCthunProxy: Entity? {
		return self.player.playerEntities
			.first { $0.cardId == CardIds.NonCollectible.Neutral.Cthun }
	}
	
	var playerYogg: Entity? {
		return self.player.playerEntities
			.first { $0.cardId == CardIds.Collectible.Neutral.YoggSaronHopesEnd }
	}
	
	var playerNzoth: Entity? {
		return self.player.playerEntities
			.first { $0.cardId == CardIds.Collectible.Neutral.NzothTheCorruptor }
	}
	
	var opponentCthun: Entity? {
		return self.opponent.playerEntities
			.first { $0.cardId == CardIds.Collectible.Neutral.Cthun }
	}
	
	var opponentCthunProxy: Entity? {
		return self.opponent.playerEntities
			.first { $0.cardId == CardIds.NonCollectible.Neutral.Cthun }
	}
	
    var playerSeenCthun: Bool {
        let cthun = playerCthun
        return cthun != nil
    }

    var opponentSeenCthun: Bool {
        return opponentCthun != nil
    }
    
	var playerSeenJade: Bool {
		return self.playerEntity?.has(tag: .jade_golem) ?? false
	}
	
	var playerNextJadeGolem: Int {
		let jade = self.playerEntity?[.jade_golem] ?? 0
		return playerSeenJade ? min(jade + 1, 30) : 1
	}
	
	var opponentSeenJade: Bool {
		return self.opponentEntity?.has(tag: .jade_golem) ?? false
	}
	
	var opponentNextJadeGolem: Int {
		let jade = self.opponentEntity?[.jade_golem] ?? 0
		return opponentSeenJade ? min(jade + 1, 30) : 1
	}
	
	private func deckContains(cardId: String) -> Bool {
		return self.currentDeck?.cards.any({ $0.id == cardId }) ?? false
	}
	
	var cthunInDeck: Bool {
		return deckContains(cardId: CardIds.Collectible.Neutral.Cthun)
	}
	
	var nzothInDeck: Bool {
		return deckContains(cardId: CardIds.Collectible.Neutral.NzothTheCorruptor)
	}
	
	var showPlayerCthunCounter: Bool {
		return Settings.showPlayerCthun && playerSeenCthun
	}
	
    var showPlayerSpellsCounter: Bool {
        guard Settings.showPlayerSpell else {
            return false
        }
        return true
    }
		
	
	var showPlayerDeathrattleCounter: Bool {
		return Settings.showPlayerDeathrattle
			&& (playerYogg != nil || nzothInDeck == true)
	}
	
	var showPlayerJadeCounter: Bool {
		return Settings.showPlayerJadeCounter && playerSeenJade
	}
	
	var showOpponentJadeCounter: Bool {
		return Settings.showOpponentJadeCounter && opponentSeenJade
	}
	
	var showOpponentCthunCounter: Bool {
		return Settings.showOpponentCthun && opponentSeenCthun
	}
    
    var playerLibramCounter: Int {
        return self.player.libramReductionCount
    }

    var opponentLibramCounter: Int {
        return self.opponent.libramReductionCount
    }

    static private func inDeckOrKnown(cardId: String) -> Bool {
        let game = AppDelegate.instance().coreManager.game
        let contains = game.deckContains(cardId: cardId)
        return  contains || game.player.playerEntities.first { x in x.cardId == cardId && x.info.originalZone != nil } != nil
    }
}

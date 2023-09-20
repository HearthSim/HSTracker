//
//  WotogCounterHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

extension Game {
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
	
	var playerArcaneGiant: Entity? {
		return self.player.playerEntities.first {
				$0.cardId == CardIds.Collectible.Neutral.ArcaneGiant
					&& $0.info.originalZone != nil
			}
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
	
	var yoggInDeck: Bool {
		return deckContains(cardId: CardIds.Collectible.Neutral.YoggSaronHopesEnd)
	}
	
	var arcaneGiantInDeck: Bool {
		return deckContains(cardId: CardIds.Collectible.Neutral.ArcaneGiant)
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
		
		return (playerYogg != nil || yoggInDeck == true)
			|| (playerArcaneGiant != nil || arcaneGiantInDeck == true)
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
}

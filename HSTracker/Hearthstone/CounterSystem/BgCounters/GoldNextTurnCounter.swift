//
//  GoldNextTurnCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class GoldNextTurnCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.CarefulInvestment
    }

    override var localizedName: String {
        return String.localizedString("Counter_GoldNextTurn", comment: "")
    }

    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.SouthseaBusker_ExtraGoldNextTurnDntEnchantment,
            CardIds.NonCollectible.Neutral.Overconfidence_OverconfidentDntEnchantment,
            CardIds.NonCollectible.Neutral.GraceFarsail_ExtraGoldIn2TurnsDntEnchantment
        ]
    }

    private var _overconfidence = 0
    private var overconfidence: Int {
        get {
            return _overconfidence
        }
        set {
            _overconfidence = max(0, newValue)
        }
    }
    
    private var _goldSureAmount = 0
    private var goldSureAmount: Int {
        get {
            return _goldSureAmount
        }
        set {
            _goldSureAmount = max(0, newValue)
        }
    }
    
    private var extraGoldFromOverconfidence: Int {
        return overconfidence * 3
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && (goldSureAmount > 0 || overconfidence > 0)
    }

    override func getCardsToDisplay() -> [String] {
        return [
            CardIds.NonCollectible.Neutral.SouthseaBusker,
            CardIds.NonCollectible.Neutral.Overconfidence,
            CardIds.NonCollectible.Neutral.GraceFarsailBATTLEGROUNDS,
            CardIds.NonCollectible.Neutral.AccordOTron,
            CardIds.NonCollectible.Neutral.RecordSmuggler,
            CardIds.NonCollectible.Neutral.CarefulInvestment
        ]
    }

    override func valueToShow() -> String {
        if extraGoldFromOverconfidence > 0 {
            return "\(goldSureAmount) (\(goldSureAmount + extraGoldFromOverconfidence))"
        }
        return "\(goldSureAmount)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if !game.isBattlegroundsMatch() {
            return
        }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }
        
        if tag == .bacon_player_extra_gold_next_turn {
            goldSureAmount = value
            onCounterChanged()
        }

        if entity.cardId == CardIds.NonCollectible.Neutral.Overconfidence_OverconfidentDntEnchantment {
            if tag == .zone && value == Zone.play.rawValue && prevValue != Zone.play.rawValue {
                overconfidence += 1
                onCounterChanged()
            } else if tag == .zone && value != Zone.play.rawValue && prevValue == Zone.play.rawValue {
                overconfidence -= 1
                onCounterChanged()
            }
        }
    }
}

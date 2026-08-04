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
    private var _accordotron = 0
    private var accordotron: Int {
        get {
            return _accordotron
        }
        set {
            _accordotron = max(0, newValue)
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
        return game.isBattlegroundsMatch() && (goldSureAmount > 0 || overconfidence > 0 || accordotron > 0)
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
        let sureAmount = goldSureAmount + accordotron
        if extraGoldFromOverconfidence > 0 {
            return "\(sureAmount) (\(sureAmount + extraGoldFromOverconfidence))"
        }
        return "\(sureAmount)"
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
        
        let isAccordotronMinion = entity.cardId == CardIds.NonCollectible.Neutral.AccordOTron || entity.cardId == CardIds.NonCollectible.Neutral.AccordoTron_AccordOTron
        let isAccordotronEnchantment = entity.cardId == CardIds.NonCollectible.Neutral.AccordoTron_AccordOTronEnchantment
        if (isAccordotronMinion && tag == GameTag.zone)
            || (isAccordotronEnchantment && (tag == GameTag.zone || tag == GameTag.tag_script_data_num_1)) {
            updateAccordotron()
        }
    }
    
    private func updateAccordotron() {
        let controllerId = isPlayerCounter ? game.player.id : game.opponent.id
        let total = game.entities.values
            .filter { e in e.isInPlay && e.isControlled(by: controllerId) }
            .reduce(0, { (curr, e) in
                let val = switch e.cardId {
                case CardIds.NonCollectible.Neutral.AccordOTron:  1
                case CardIds.NonCollectible.Neutral.AccordoTron_AccordOTron: 2
                case CardIds.NonCollectible.Neutral.AccordoTron_AccordOTronEnchantment: e[GameTag.tag_script_data_num_1]
                default: 0
                }
                return curr + val
            })
        if total != accordotron {
            accordotron = total
            onCounterChanged()
        }
    }
}

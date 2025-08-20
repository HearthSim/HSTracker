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

        if relatedCards.contains(entity.cardId) {
            if entity.cardId == CardIds.NonCollectible.Neutral.Overconfidence_OverconfidentDntEnchantment {
                if tag == .zone && value == Zone.play.rawValue && prevValue != Zone.play.rawValue {
                    overconfidence += 1
                    onCounterChanged()
                } else if tag == .zone && value != Zone.play.rawValue && prevValue == Zone.play.rawValue {
                    overconfidence -= 1
                    onCounterChanged()
                }
            } else if entity.cardId == CardIds.NonCollectible.Neutral.SouthseaBusker_ExtraGoldNextTurnDntEnchantment {
                if tag == .tag_script_data_num_1 {
                    if entity[.zone] == Zone.play.rawValue {
                        goldSureAmount += value - prevValue
                        onCounterChanged()
                    }
                } else if tag == .zone {
                    if value == Zone.play.rawValue && prevValue != Zone.play.rawValue {
                        goldSureAmount += entity[.tag_script_data_num_1]
                        onCounterChanged()
                    } else if value != Zone.play.rawValue && prevValue == Zone.play.rawValue {
                        goldSureAmount -= entity[.tag_script_data_num_1]
                        onCounterChanged()
                    }
                }
            } else if entity.cardId == CardIds.NonCollectible.Neutral.GraceFarsail_ExtraGoldIn2TurnsDntEnchantment {
                if tag == .tag_script_data_num_2 && value == 1 {
                    goldSureAmount += entity[.tag_script_data_num_1]
                    onCounterChanged()
                } else if tag == .tag_script_data_num_2 && prevValue == 1 {
                    goldSureAmount -= entity[.tag_script_data_num_1]
                    onCounterChanged()
                }
            } else if entity.cardId == CardIds.NonCollectible.Neutral.CarefulInvestment {
                if tag == .zone && value == Zone.play.rawValue && prevValue != Zone.play.rawValue {
                    goldSureAmount += 2
                    onCounterChanged()
                } else if value == Zone.removedfromgame.rawValue && prevValue == Zone.graveyard.rawValue {
                    goldSureAmount -= 2
                    onCounterChanged()
                }
            }
            return
        }

        if tag != .zone || entity.cardId == "" {
            return
        }

        let goldValue = GoldNextTurnCounter.getGoldFromCard(cardId: entity.cardId, golden: entity[.premium] != 0)

        if goldValue <= 0 {
            return
        }

        if value == Zone.play.rawValue && prevValue != Zone.play.rawValue {
            goldSureAmount += goldValue
            onCounterChanged()
        } else if value != Zone.play.rawValue && prevValue == Zone.play.rawValue {
            goldSureAmount -= goldValue
            onCounterChanged()
        }
    }

    private static func getGoldFromCard(cardId: String, golden: Bool) -> Int {
        switch cardId {
        case CardIds.NonCollectible.Neutral.AccordOTron: return golden ? 2 : 1
        case CardIds.NonCollectible.Neutral.RecordSmuggler: return golden ? 2 : 4
        default: return 0
        }
    }
}

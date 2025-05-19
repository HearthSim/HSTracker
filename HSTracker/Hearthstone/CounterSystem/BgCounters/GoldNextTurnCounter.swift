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

    private var overconfidence = 0
    private var goldSureAmount = 0
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
        guard game.isBattlegroundsMatch() else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if relatedCards.contains(entity.cardId) {
            if entity.cardId == CardIds.NonCollectible.Neutral.Overconfidence_OverconfidentDntEnchantment {
                handleOverconfidence(tag: tag, value: value, prevValue: prevValue)
            } else if entity.cardId == CardIds.NonCollectible.Neutral.SouthseaBusker_ExtraGoldNextTurnDntEnchantment {
                handleSouthseaBusker(tag: tag, entity: entity, value: value, prevValue: prevValue)
            } else if entity.cardId == CardIds.NonCollectible.Neutral.GraceFarsail_ExtraGoldIn2TurnsDntEnchantment {
                handleGraceFarsail(tag: tag, entity: entity, value: value, prevValue: prevValue)
            }
        }

        if tag != .zone || entity.cardId.isEmpty { return }

        let goldValue = getGoldForMinion(cardId: entity.cardId, isGolden: entity.has(tag: .premium))
        if goldValue > 0 {
            adjustGoldAmount(tag: tag, value: value, prevValue: prevValue, goldValue: goldValue)
        }
    }

    private func handleOverconfidence(tag: GameTag, value: Int, prevValue: Int) {
        if tag == .zone && value == Zone.play.rawValue && prevValue != Zone.play.rawValue {
            overconfidence += 1
            onCounterChanged()
        } else if tag == .zone && value != Zone.play.rawValue && prevValue == Zone.play.rawValue {
            overconfidence -= 1
            onCounterChanged()
        }
    }

    private func handleSouthseaBusker(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if tag == .tag_script_data_num_1 && entity[.zone] == Zone.play.rawValue {
            goldSureAmount += (value - prevValue)
            onCounterChanged()
        } else if tag == .zone {
            adjustGoldAmount(tag: tag, value: value, prevValue: prevValue, goldValue: entity[.tag_script_data_num_1])
        }
    }

    private func handleGraceFarsail(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if tag == .tag_script_data_num_2 && value == 1 {
            goldSureAmount += entity[.tag_script_data_num_1]
            onCounterChanged()
        } else if tag == .tag_script_data_num_2 && prevValue == 1 {
            goldSureAmount -= entity[.tag_script_data_num_2]
            onCounterChanged()
        }
    }

    private func adjustGoldAmount(tag: GameTag, value: Int, prevValue: Int, goldValue: Int) {
        if value == Zone.play.rawValue && prevValue != Zone.play.rawValue {
            goldSureAmount += goldValue
            onCounterChanged()
        } else if value != Zone.play.rawValue && prevValue == Zone.play.rawValue {
            goldSureAmount -= goldValue
            onCounterChanged()
        }
    }

    private func getGoldForMinion(cardId: String, isGolden: Bool) -> Int {
        switch cardId {
        case CardIds.NonCollectible.Neutral.AccordOTron:
            return isGolden ? 2 : 1
        case CardIds.NonCollectible.Neutral.RecordSmuggler:
            return isGolden ? 2 : 4
        default:
            return 0
        }
    }
}

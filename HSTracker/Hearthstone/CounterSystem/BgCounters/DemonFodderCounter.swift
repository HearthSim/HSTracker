//
//  DemonFodderCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class DemonFodderCounter: NumericCounter {

    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.LaboratoryAssistant_DemonFodderToken1
    }

    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.LaboratoryAssistant_DemonFodderToken1,
            CardIds.NonCollectible.Neutral.LaboratoryAssistant,
            CardIds.NonCollectible.Neutral.WoodlandDefiler,
            CardIds.NonCollectible.Neutral.TwistedWrathguard
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override var localizedName: String {
        return String.localizedString("Counter_NextRefreshDemonFodder", comment: "")
    }

    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && counter > 0
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if entity[.zone] == Zone.setaside.rawValue {
            return
        }

        if tag == .bacon_fodders_in_refresh {
            counter = value
            onCounterChanged()
        }
    }
}

//
//  TimethiefRafaamCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class TimethiefRafaamCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        CardIds.Collectible.Warlock.TimethiefRafaam
    }

    override var relatedCards: [String] {
        [CardIds.Collectible.Warlock.TimethiefRafaam]
    }

    private let rafaams = [
        CardIds.NonCollectible.Warlock.TimethiefRafaam_TinyRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_GreenRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_MurlocRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_ExplorerRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_WarchiefRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_CalamitousRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_MindflayerRfaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_GiantRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_ArchmageRafaamToken
    ]

    private var playedRafaams = [Int: String]()

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }
    
    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        playedRafaams.sorted(by: { $0.key < $1.key }).compactMap({ $0.value })
    }

    override func valueToShow() -> String {
        "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag != .zone || AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type != "PLAY" {
            return
        }

        let isCurrentController = isPlayerCounter
        ? entity.isControlled(by: game.player.id)
        : entity.isControlled(by: game.opponent.id)

        guard isCurrentController else { return }

        let cardId = entity.card.id
        guard rafaams.contains(cardId), !playedRafaams.values.contains(cardId) else { return }

        playedRafaams[entity.card.cost] = cardId
        counter += 1
    }
}

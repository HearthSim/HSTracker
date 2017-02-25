//
// Created by Benjamin Michotte on 25/02/17.
// Copyright (c) 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import Unbox
import CleanroomLogger

class ArenaWatcher {
    private let heroes: [CardClass] = [
            .warrior,
            .shaman,
            .rogue,
            .paladin,
            .hunter,
            .druid,
            .warlock,
            .mage,
            .priest
    ]
    var hero: CardClass = .neutral
    private var cardTiers: [ArenaCard] = []
    private var currentCards: [String] = []

    private var queue: DispatchQueue?
    var isRunning = false

    func start() {
        loadCardTiers()

        Log.info?.message("Starting arena watcher")
        queue = DispatchQueue(label: "be.michotte.hstracker.watchers.arena", attributes: [])
        if let queue = queue {
            isRunning = true
            queue.async { [weak self] in
                self?.waitForCard()
            }
        }
    }

    func stop() {
        Log.info?.message("Stopping arena watcher")
        isRunning = false

        DispatchQueue.main.async {
            guard let game = (NSApp.delegate as? AppDelegate)?.game,
                let secretTracker = game.windowManager?.secretTracker else { return }
            game.windowManager?.show(controller: secretTracker, show: false)
        }
    }

    private func waitForCard() {
        while isRunning {
            guard let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
                  let mirror = hearthstone.mirror else {
                Thread.sleep(forTimeInterval: 0.4)
                continue
            }

            let choices = mirror.getArenaDraftChoices()
            if choices.count != 3 {
                Thread.sleep(forTimeInterval: 0.4)
                continue
            }

            var cards: [Card] = []
            for item in choices {
                if let mirrorCard = item as? MirrorCard,
                    let cardInfo = getCardTierInfo(id: mirrorCard.cardId),
                    let card = Cards.by(cardId: mirrorCard.cardId),
                    let index = heroes.indexOf(hero) {
                    card.cost = Int(cardInfo.values[index]) ?? 0
                    card.count = 1
                    cards.append(card)
                }
            }

            if cards.count == 3 {
                let ids = cards.map { $0.id }
                if ids.sorted() != currentCards.sorted() {
                    Log.debug?.message("cards: \(cards)")
                    currentCards = ids

                    DispatchQueue.main.async {
                        guard let game = (NSApp.delegate as? AppDelegate)?.game,
                            let secretTracker = game.windowManager?.secretTracker else { return }

                        secretTracker.set(secrets: cards.sorted { $0.cost > $1.cost })
                        game.windowManager?.show(controller: secretTracker,
                                                  show: true,
                                                  frame: SizeHelper.arenaHelperFrame())
                    }
                }
            }

            Thread.sleep(forTimeInterval: 0.4)
        }
    }

    private func getCardTierInfo(id: String) -> ArenaCard? {
        return cardTiers.first {
            $0.id == id
        }
    }

    private func loadCardTiers() {
        let cardFile = URL(fileURLWithPath: "\(Bundle.main.resourcePath!)/Resources/cardtier.json")
        guard let data = try? Data(contentsOf: cardFile) else {
            Log.warning?.message("Can not load cardtier.json")
            return
        }
        guard let cardTiers: [ArenaCard] = try? unbox(data: data) else {
            Log.warning?.message("Can not parse cardtier.json")
            return
        }
        self.cardTiers = cardTiers
    }
}

struct ArenaCard {
    let id: String
    let values: [String]
}

extension ArenaCard: Unboxable {
    init(unboxer: Unboxer) throws {
        self.id = try unboxer.unbox(key: "id")
        self.values = try unboxer.unbox(key: "value")
    }
}

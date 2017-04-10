//
// Created by Benjamin Michotte on 25/02/17.
// Copyright (c) 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import Unbox
import CleanroomLogger

class ArenaWatcher: Watcher {
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

    override func clean() {
        DispatchQueue.main.async {
            guard let game = (NSApp.delegate as? AppDelegate)?.game,
                let secretTracker = game.windowManager?.secretTracker else { return }
            game.windowManager?.show(controller: secretTracker, show: false)
        }
    }

    override func run() {
        if cardTiers.count == 0 {
            loadCardTiers()
        }

        while isRunning {
            guard let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
                let mirror = hearthstone.mirror else {
                    Thread.sleep(forTimeInterval: refreshInterval)
                    continue
            }

            let choices = mirror.getArenaDraftChoices()
            if choices.count != 3 {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }

            var cards: [Card] = []
            for mirrorCard in choices {
                if let cardInfo = cardTiers.first({ $0.id == mirrorCard.cardId }),
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
            
            Thread.sleep(forTimeInterval: refreshInterval)
        }
        
        queue = nil
    }

    private func loadCardTiers() {
        let jsonFile = Paths.arenaJson.appendingPathComponent("cardtier.json")
        var jsonData = try? Data(contentsOf: jsonFile)
        if jsonData != nil {
            Log.info?.message("Using \(jsonFile)")
        } else {
            Log.error?.message("\(jsonFile) is not a valid file")
            let cardFile = URL(fileURLWithPath:
                "\(Bundle.main.resourcePath!)/Resources/cardtier.json")
            jsonData = try? Data(contentsOf: cardFile)
        }
        guard let data = jsonData else {
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

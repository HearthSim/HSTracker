//
// Created by Benjamin Michotte on 25/02/17.
// Copyright (c) 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import Unbox
import CleanroomLogger

class ArenaWatcher: Watcher {
	
	static let _instance = ArenaWatcher()
	
	static func start(handler: PowerEventHandler) {
		_instance.handler = handler
		_instance.startWatching()
	}
	
	static func stop() {
		_instance.stopWatching()
	}
	
	static func isRunning() -> Bool {
		return _instance.isRunning
	}
	
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
	
	static var hero: CardClass = .neutral
    private var cardTiers: [ArenaCard] = []
    private var currentCards: [String] = []
	private var handler: PowerEventHandler?
	
    override func run() {
        if cardTiers.count == 0 {
            loadCardTiers()
        }

        while isRunning {
			
			guard let choices = MirrorHelper.getArenaDraftChoices() else {
				Thread.sleep(forTimeInterval: refreshInterval)
				continue

			}
            if choices.count != 3 {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }

            var cards: [Card] = []
            for mirrorCard in choices {
                if let cardInfo = cardTiers.first({ $0.id == mirrorCard.cardId }),
                    let card = Cards.by(cardId: mirrorCard.cardId),
                    let index = heroes.indexOf(ArenaWatcher.hero) {

                    let value = cardInfo.values[index]
                    let costs = value.matches("([0-9]+)")
                    card.cost = Int(costs.first?.value ?? "0") ?? 0
                    card.isBadAsMultiple = value.contains("^")
                    card.count = 1
                    cards.append(card)
                }
            }

            if cards.count == 3 {
                let ids = cards.map { $0.id }
                if ids.sorted() != currentCards.sorted() {
                    Log.debug?.message("cards: \(cards)")
                    currentCards = ids
					
					handler?.setArenaOptions(cards: cards.sorted { $0.cost > $1.cost })
                }
            }
            
            Thread.sleep(forTimeInterval: refreshInterval)
        }
		
		handler?.setArenaOptions(cards: [])
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

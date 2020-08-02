//
//  BattlegroundsTierDetailsView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import kotlin_hslog

class BattlegroundsTierDetailsView: NSStackView {
    
    init() {
        super.init(frame: NSRect.zero)
        self.orientation = .vertical
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.orientation = .vertical
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.orientation = .vertical
    }
    
    func score(race: Race?) -> Int {
        guard let r = race else {
            return 0
        }
        return Race.allCases.firstIndex { $0 == r } ?? 0
    }
    
    func setTier(tier: Int) {
        let cardJson = AppDelegate.instance().coreManager.cardJson!
        let availableRaces = AppDelegate.instance().coreManager.game.availableRaces
        let cardBars: [CardBar] = BattlegroundsKt.battlegroundsMinions.filter {
            let ktCard = cardJson.getCard(id: $0.cardId)
            let race = Race(rawValue: ktCard.race?.lowercased() ?? "")
            return ($0.techLevel == tier && (race == nil || (availableRaces?.firstIndex(of: race!) != nil)))
        }.map {
            let card = Card()

            let ktCard = cardJson.getCard(id: $0.cardId)
            card.cost = -1
            card.id = $0.cardId
            card.name = ktCard.name
            if let race = Race(rawValue: ktCard.race?.lowercased() ?? "") {
                card.race = race
            }
            card.count = 1
            if let rarity = Rarity(rawValue: ktCard.rarity?.lowercased() ?? "") {
                card.rarity = rarity
            }

            let cardBar = CardBar.factory()
            cardBar.card = card
            return cardBar
        }.sorted(by: {(a: CardBar, b: CardBar) -> Bool in
            score(race: a.card?.race) > score(race: b.card?.race)
        })
        
        while self.subviews.count > 0 {
            self.subviews[0].removeFromSuperviewWithoutNeedingDisplay()
        }
        
        var cardHeight: CGFloat
        switch Settings.cardSize {
        case .tiny: cardHeight = CGFloat(kTinyRowHeight)
        case .small: cardHeight = CGFloat(kSmallRowHeight)
        case .medium: cardHeight = CGFloat(kMediumRowHeight)
        case .huge: cardHeight = CGFloat(kHighRowHeight)
        case .big: cardHeight = CGFloat(kRowHeight)
        }

        var totalHeight = CGFloat(cardBars.count) * cardHeight
        if totalHeight > self.frame.height {
            totalHeight = self.frame.height
            cardHeight = totalHeight / CGFloat(cardBars.count)
        }
        
        for i in 0...(cardBars.count - 1) {
            let y = CGFloat(i) * cardHeight + self.frame.height - totalHeight
            let cardBar = cardBars[i]
            cardBar.frame = NSRect(x: 0, y: y, width: self.frame.width, height: cardHeight)
            self.addSubview(cardBar)
        }
    }
}

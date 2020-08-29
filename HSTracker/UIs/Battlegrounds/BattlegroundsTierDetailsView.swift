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
    let battlegroundsMinions = [
        BattlegroundMinion(cardId: "AT_121", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_001", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_002", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_004", techLevel: 1),
        BattlegroundMinion(cardId: "BGS_006", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_008", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_009", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_010", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_012", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_014", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_017", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_018", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_019", techLevel: 1),
        BattlegroundMinion(cardId: "BGS_020", techLevel: 4),
        BattlegroundMinion(cardId: "BGS_021", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_022", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_023", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_027", techLevel: 1),
        BattlegroundMinion(cardId: "BGS_028", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_029", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_030", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_032", techLevel: 4),
        BattlegroundMinion(cardId: "BGS_033", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_034", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_035", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_036", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_037", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_038", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_039", techLevel: 1),
        BattlegroundMinion(cardId: "BGS_040", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_041", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_043", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_044", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_045", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_046", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_047", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_048", techLevel: 4),
        BattlegroundMinion(cardId: "BGS_049", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_053", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_055", techLevel: 1),
        BattlegroundMinion(cardId: "BGS_056", techLevel: 4),
        BattlegroundMinion(cardId: "BGS_060", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_061", techLevel: 1),
        BattlegroundMinion(cardId: "BGS_066", techLevel: 4),
        BattlegroundMinion(cardId: "BGS_067", techLevel: 4),
        BattlegroundMinion(cardId: "BGS_069", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_071", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_072", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_075", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_078", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_079", techLevel: 6),
        BattlegroundMinion(cardId: "BGS_080", techLevel: 5),
        BattlegroundMinion(cardId: "BGS_081", techLevel: 3),
        BattlegroundMinion(cardId: "BGS_082", techLevel: 2),
        BattlegroundMinion(cardId: "BGS_083", techLevel: 4),
        BattlegroundMinion(cardId: "BOT_218", techLevel: 4),
        BattlegroundMinion(cardId: "BOT_312", techLevel: 3),
        BattlegroundMinion(cardId: "BOT_445", techLevel: 1),
        BattlegroundMinion(cardId: "BOT_537", techLevel: 4),
        BattlegroundMinion(cardId: "BOT_606", techLevel: 2),
        BattlegroundMinion(cardId: "BOT_911", techLevel: 4),
        BattlegroundMinion(cardId: "BRM_006", techLevel: 3),
        BattlegroundMinion(cardId: "BT_010", techLevel: 3),
        BattlegroundMinion(cardId: "CFM_315", techLevel: 1),
        BattlegroundMinion(cardId: "CFM_316", techLevel: 3),
        BattlegroundMinion(cardId: "CFM_610", techLevel: 3),
        BattlegroundMinion(cardId: "CFM_816", techLevel: 4),
        BattlegroundMinion(cardId: "DAL_077", techLevel: 4),
        BattlegroundMinion(cardId: "DAL_575", techLevel: 3),
        BattlegroundMinion(cardId: "DS1_070", techLevel: 3),
        BattlegroundMinion(cardId: "EX1_062", techLevel: 2),
        BattlegroundMinion(cardId: "EX1_093", techLevel: 4),
        BattlegroundMinion(cardId: "EX1_103", techLevel: 3),
        BattlegroundMinion(cardId: "EX1_185", techLevel: 4),
        BattlegroundMinion(cardId: "EX1_506", techLevel: 1),
        BattlegroundMinion(cardId: "EX1_507", techLevel: 2),
        BattlegroundMinion(cardId: "EX1_509", techLevel: 1),
        BattlegroundMinion(cardId: "EX1_531", techLevel: 1),
        BattlegroundMinion(cardId: "EX1_534", techLevel: 4),
        BattlegroundMinion(cardId: "EX1_556", techLevel: 2),
        BattlegroundMinion(cardId: "EX1_577", techLevel: 3),
        BattlegroundMinion(cardId: "FP1_010", techLevel: 6),
        BattlegroundMinion(cardId: "FP1_024", techLevel: 2),
        BattlegroundMinion(cardId: "FP1_031", techLevel: 5),
        BattlegroundMinion(cardId: "GVG_021", techLevel: 5),
        BattlegroundMinion(cardId: "GVG_027", techLevel: 4),
        BattlegroundMinion(cardId: "GVG_048", techLevel: 2),
        BattlegroundMinion(cardId: "GVG_055", techLevel: 3),
        BattlegroundMinion(cardId: "GVG_100", techLevel: 4),
        BattlegroundMinion(cardId: "GVG_106", techLevel: 5),
        BattlegroundMinion(cardId: "GVG_113", techLevel: 6),
        BattlegroundMinion(cardId: "ICC_029", techLevel: 4),
        BattlegroundMinion(cardId: "ICC_038", techLevel: 1),
        BattlegroundMinion(cardId: "ICC_807", techLevel: 5),
        BattlegroundMinion(cardId: "ICC_858", techLevel: 4),
        BattlegroundMinion(cardId: "KAR_005", techLevel: 2),
        BattlegroundMinion(cardId: "LOE_077", techLevel: 5),
        BattlegroundMinion(cardId: "LOOT_013", techLevel: 1),
        BattlegroundMinion(cardId: "LOOT_078", techLevel: 4),
        BattlegroundMinion(cardId: "LOOT_368", techLevel: 5),
        BattlegroundMinion(cardId: "NEW1_027", techLevel: 2),
        BattlegroundMinion(cardId: "OG_216", techLevel: 3),
        BattlegroundMinion(cardId: "OG_221", techLevel: 1),
        BattlegroundMinion(cardId: "OG_256", techLevel: 2),
        BattlegroundMinion(cardId: "TRL_232", techLevel: 5),
        BattlegroundMinion(cardId: "UNG_073", techLevel: 1),
        BattlegroundMinion(cardId: "YOD_026", techLevel: 1)
    ]
    
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
        var cardBars: [CardBar] = battlegroundsMinions.filter {
            let ktCard = cardJson.getCard(id: $0.cardId)
            let race = Race(rawValue: ktCard.race?.lowercased() ?? "")
            return ($0.techLevel == tier && (race == nil || (availableRaces?.firstIndex(of: race!) != nil)))
        }.map {
            let card = Card()

            let ktCard = cardJson.getCard(id: $0.cardId)
            card.cost = -1
            card.id = $0.cardId
            card.name = ktCard.name
            if let race = Race(rawValue: ktCard.race?.lowercased() ?? "invalid") {
                card.race = race
            }
            card.count = 1
            if let rarity = Rarity(rawValue: ktCard.rarity?.lowercased() ?? "") {
                card.rarity = rarity
            }

            let cardBar = CardBar.factory()
            cardBar.card = card
            return cardBar
        }
        
        var cardBar = CardBar.factory()

        let size = NSSize(width: cardBar.imageRect.width, height: cardBar.imageRect.height)
        let blackImage = NSImage(color: NSColor(red: 35/255.0, green: 39/255.0, blue: 42/255.0, alpha: 1.0), size: size)

        cardBar.playerName = "Neutral"
        let race = Race(rawValue: "invalid")
        cardBar.playerRace = race
        cardBar.backgroundImage = blackImage
        cardBars.append(cardBar)
        for i in 0..<availableRaces!.count {
            let race: String = availableRaces![i].rawValue
            cardBar = CardBar.factory()
                cardBar.playerName = NSLocalizedString(race, comment: "")
            let cardRace = Race(rawValue: race)
            cardBar.playerRace = cardRace
            cardBar.backgroundImage = blackImage
            cardBars.append(cardBar)
        }
        cardBars = cardBars.sorted(by: {(a: CardBar, b: CardBar) -> Bool in
            var raceA: String
            var nameA: String
            var isTitleA: Int
            if a.card?.race != nil {
                raceA = a.card!.race.rawValue
                nameA = a.card!.name
                isTitleA = 1
            } else {
                raceA = a.playerRace!.rawValue
                nameA = a.playerName!
                isTitleA = 0
            }
            if raceA == "invalid" {
                raceA = "neutral"
            }
            var raceB: String
            var nameB: String
            var isTitleB: Int
            if b.card?.race != nil {
                raceB = b.card!.race.rawValue
                nameB = b.card!.name
                isTitleB = 1
            } else {
                raceB = b.playerRace!.rawValue
                nameB = b.playerName!
                isTitleB = 0
            }
            if raceB == "invalid" {
                raceB = "neutral"
            }
            return (raceA, isTitleA, nameA) > (raceB, isTitleB, nameB)
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

//
//  BattlegroundsTierDetailsView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundMinion {
    let cardId: String
    let techLevel: Int
    
    init(cardId: String, techLevel: Int) {
        self.cardId = cardId
        self.techLevel = techLevel
    }
}

class BattlegroundsTierDetailsView: NSStackView {
    var contentFrame = NSRect.zero
    
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
        var availableRaces = AppDelegate.instance().coreManager.game.availableRaces
        availableRaces?.append(Race.all)
        var counts = [Race: Int]()
        var cardBars: [CardBar] = Cards.battlegroundsMinions.filter {
            let race = $0.bgRace
            return ($0.techLevel == tier &&
                        (race == .invalid || (availableRaces?.firstIndex(of: race) != nil)))
        }.map { inCard in
            let card = Card()
            
            let cardBar = CardBar.factory()
            card.cost = -1
            card.id = inCard.id
            card.name = inCard.name
            card.race = inCard.race
            if let count = counts[inCard.race] {
                counts[inCard.race] = count + 1
            } else {
                counts[inCard.race] = 1
            }
            card.count = 1
            card.rarity = inCard.rarity
            cardBar.card = card
            cardBar.isBattlegrounds = true
            cardBar.setDelegate(self)
            return cardBar
        }
        
        let cardBar = CardBar.factory()
        let size = NSSize(width: cardBar.imageRectBG.width, height: cardBar.imageRectBG.height)
        let blueBackground = NSImage(color: NSColor(red: 0x1d/255.0, green: 0x36/255.0, blue: 0x57/255.0, alpha: 1.0), size: size)
        let blackImage = NSImage(color: NSColor(red: 0x23/255.0, green: 0x27/255.0, blue: 0x2a/255.0, alpha: 1.0), size: size)

        if let cnt = counts[.invalid], cnt > 0 {
            cardBar.playerName = NSLocalizedString("neutral", comment: "")
            let race = Race(rawValue: "invalid")
            cardBar.playerRace = race
            cardBar.backgroundImage = blueBackground
            cardBar.isBattlegrounds = true
            cardBar.playerType = .deckManager
            cardBars.append(cardBar)
        }
        if let availableRaces = availableRaces {
            for i in 0..<availableRaces.count {
                if let cnt = counts[availableRaces[i]], cnt > 0 {
                    let race: String = availableRaces[i].rawValue
                    let cardBar = CardBar.factory()
                    cardBar.playerName = NSLocalizedString(race, comment: "")
                    let cardRace = Race(rawValue: race)
                    cardBar.playerRace = cardRace
                    cardBar.backgroundImage = blueBackground
                    cardBar.isBattlegrounds = true
                    cardBar.playerType = .deckManager
                    cardBars.append(cardBar)
                }
            }
        }
        if let unavailable = AppDelegate.instance().coreManager.game.unavailableRaces {
            var cardBar = CardBar.factory()
            cardBar.playerName = NSLocalizedString("unavailable", comment: "")
            cardBar.playerRace = .blank
            cardBar.backgroundImage = blueBackground
            cardBar.isBattlegrounds = true
            cardBar.playerType = .deckManager
            cardBars.append(cardBar)

            let text = unavailable.compactMap({ race in NSLocalizedString(race.rawValue, comment: "")}).joined(separator: ", ")
            cardBar = CardBar.factory()
            cardBar.playerName = text
            cardBar.playerRace = .blank
            cardBar.backgroundImage = blackImage
            cardBar.isBattlegrounds = true
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
            } else if a.playerRace == .blank && a.playerType != .deckManager {
                raceA = a.playerRace!.rawValue
                nameA = a.playerName!
                isTitleA = 1
            } else {
                raceA = a.playerRace!.rawValue
                nameA = a.playerName!
                isTitleA = 0
            }
            if raceA == "invalid" {
                raceA = "neutral"
            } else if raceA == "blank" {
                raceA = "unavailable"
            }
            var raceB: String
            var nameB: String
            var isTitleB: Int
            if b.card?.race != nil {
                raceB = b.card!.race.rawValue
                nameB = b.card!.name
                isTitleB = 1
            } else if b.playerRace == .blank && b.playerType != .deckManager {
                raceB = b.playerRace!.rawValue
                nameB = b.playerName!
                isTitleB = 1
            } else {
                raceB = b.playerRace!.rawValue
                nameB = b.playerName!
                isTitleB = 0
            }
            if raceB == "invalid" {
                raceB = "neutral"
            } else if raceB == "blank" {
                raceB = "unavailable"
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
        if totalHeight > contentFrame.height {
            totalHeight = contentFrame.height
            cardHeight = totalHeight / CGFloat(cardBars.count)
        }
        
        for i in 0...(cardBars.count - 1) {
            let y = CGFloat(i) * cardHeight + contentFrame.height - totalHeight
            let cardBar = cardBars[i]
            cardBar.frame = NSRect(x: 0, y: y, width: contentFrame.width, height: cardHeight)
            self.addSubview(cardBar)
        }
    }
}

// MARK: - CardCellHover
extension BattlegroundsTierDetailsView: CardCellHover {
    func hover(cell: CardBar, card: Card) {
        let windowRect = self.window!.frame

        let hoverFrame = NSRect(x: 0, y: 0, width: 256, height: 350)

        var x: CGFloat
        // decide if the popup window should on the left or right side of the tracker
        if windowRect.origin.x < hoverFrame.size.width {
            x = windowRect.origin.x + windowRect.size.width
        } else {
            x = windowRect.origin.x - hoverFrame.size.width
        }
        
        let tierFrame = SizeHelper.battlegroundsTierOverlayFrame()

        let cellFrameRelativeToWindow = cell.convert(cell.bounds, to: nil)
        let cellFrameRelativeToScreen = cell.window?.convertToScreen(cellFrameRelativeToWindow)

        var y: CGFloat = cellFrameRelativeToScreen!.origin.y
        if (y + hoverFrame.height/2) >= tierFrame.minY {
            y = tierFrame.minY - hoverFrame.height/2
        } else if (y - hoverFrame.height/2) < 0 {
            y = hoverFrame.height/2
        }

        let frame = [x, y, hoverFrame.width, hoverFrame.height]

        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.show_floating_card),
                                  object: nil,
                                  userInfo: [
                                    "card": card,
                                    "frame": frame,
                                    "battlegrounds": true
                ])
    }

    func out(card: Card) {
        let userinfo = [
            "card": card
            ] as [String: Any]

        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil, userInfo: userinfo)
    }
}

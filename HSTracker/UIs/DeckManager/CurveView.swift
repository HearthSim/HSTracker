//
//  CurveView.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import TextAttributes
import QuartzCore

struct CardCount {
    var count, minion, spell, weapon: Int
}

class CurveView: NSView {
    var deck: Deck?
    var counts = [Int: CardCount]()

    private func countCards() {
        counts = [:]
        guard let deck = self.deck else { return }

        // let's count that stuff
        for card in deck.sortedCards {
            var cost = card.cost
            if cost > 7 {
                cost = 7
            }

            if counts[cost] == nil {
                counts[cost] = CardCount(count: 0, minion: 0, spell: 0, weapon: 0)
            }
            var cardCount = self.counts[cost]
            cardCount!.count += card.count
            switch card.type {
            case .minion: cardCount!.minion += card.count
            case .spell: cardCount!.spell += card.count
            case .weapon: cardCount!.weapon += card.count
            default: continue
            }
            counts[cost] = cardCount
        }
    }

    func reload() {
        countCards()
        self.needsDisplay = true
    }

    override func draw(_ rect: NSRect) {
        super.draw(rect)
        guard self.deck != nil else { return }
        if self.counts.isEmpty {
            countCards()
        }
        if self.counts.isEmpty { return }

        let barWidth: CGFloat = floor(rect.width / 8)
        let padding: CGFloat = (rect.width - (barWidth * 8)) / 8
        let barHeight: CGFloat = rect.height - (padding * 4) - 25
        let manaHeight: CGFloat = 25
        var x: CGFloat = 0

        let types = [
            "minion": [
                NSColor(red: 106.0 / 255.0, green: 210.0 / 255.0, blue: 199.0 / 255.0, alpha: 1),
                NSColor(red: 167.0 / 255.0, green: 231.0 / 255.0, blue: 229.0 / 255.0, alpha: 1)
            ],
            "spell": [
                NSColor(red: 234.0 / 255.0, green: 107.0 / 255.0, blue: 85.0 / 255.0, alpha: 1),
                NSColor(red: 233.0 / 255.0, green: 156.0 / 255.0, blue: 148.0 / 255.0, alpha: 1)
            ],
            "weapon": [
                NSColor(red: 138.0 / 255.0, green: 228.0 / 255.0, blue: 113.0 / 255.0, alpha: 1),
                NSColor(red: 206.0 / 255.0, green: 230.0 / 255.0, blue: 184.0 / 255.0, alpha: 1)]
        ]

        // get the biggest value
        let biggest: Int = counts.map({ $0.1.count }).max(by: { $0 < $1 })!
        // and get a unit based on this value
        let oneUnit = Int(barHeight) / biggest

        let attributes = TextAttributes()
            .alignment(.center)
            .font(NSFont(name: "Belwe Bd BT", size: 20))
            .foregroundColor(.white)
            .strokeColor(.black)
            .strokeWidth(-1.5)
        let costAttributes = TextAttributes()
            .alignment(.center)
            .font(NSFont.boldSystemFont(ofSize: 22))
            .foregroundColor(.white)
            .strokeColor(.black)
            .strokeWidth(-1.5)
        let countAttributes = TextAttributes()
            .alignment(.center)
            .font(NSFont.boldSystemFont(ofSize: 22))
            .foregroundColor(.white)
            .strokeColor(.black)
            .strokeWidth(-1.5)

        for count in 0 ... 7 {
            NSGraphicsContext.saveGraphicsState()

            x += padding

            if let mana = NSImage(named: "mana") {
                mana.draw(in: NSRect(x: x, y: padding, width: manaHeight, height: manaHeight),
                    from: NSRect.zero,
                    operation: .sourceOver,
                    fraction: 1.0)
            }

            var cost = NSAttributedString(string: "\(count)", attributes: attributes)

            var costX = x + 1
            if count == 7 {
                costX = x - 4
            }
            cost.draw(in: NSRect(
                x: costX,
                y: padding + 6,
                width: manaHeight,
                height: manaHeight + 2))
            if count == 7 {
                cost = NSAttributedString(string: "+", attributes: costAttributes)
                cost.draw(in: NSRect(
                    x: x + 5,
                    y: padding + 3,
                    width: manaHeight,
                    height: manaHeight + 2))
            }

            var current = counts[count]
            if current == nil {
                current = CardCount(count: 0, minion: 0, spell: 0, weapon: 0)
            }

            let howMany = current!.count
            if howMany > 0 {
                var y = padding * 2 + manaHeight
                for (type, colors) in types {
                    var currentType: Int?
                    switch type {
                    case "minion": currentType = current?.minion
                    case "spell": currentType = current?.spell
                    case "weapon": currentType = current?.weapon
                    default: continue
                    }
                    if currentType == nil || currentType == 0 {
                        continue
                    }

                    let barRect = NSRect(x: x, y: y,
                                         width: barWidth,
                                         height: CGFloat(currentType! * oneUnit))
                    y += CGFloat(currentType! * oneUnit)

                    let path = NSBezierPath(roundedRect: barRect, xRadius: 0, yRadius: 0)
                    if let gradient = NSGradient(colors: colors) {
                        gradient.draw(in: path, angle: 270)
                    }
                }
                let countCards = NSAttributedString(string: "\(howMany)",
                                                    attributes: countAttributes)

                let doublePadding: CGFloat = padding * 2
                let tHowMany: CGFloat = CGFloat(howMany * oneUnit)
                let currentY: CGFloat = doublePadding + manaHeight + tHowMany - 20
                countCards.draw(in: NSRect(x: x, y: currentY, width: barWidth, height: 30))
            }
            x += barWidth
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}

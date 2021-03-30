//
//  CardList.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 10/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class CardList: OverWindowController {

    @IBOutlet weak var table: NSTableView?

    fileprivate var animatedCards: [CardBar] = []
    let semaphore = DispatchSemaphore(value: 1)
    var isSecretPanel = false

    var observer: NSObjectProtocol?

    override func windowDidLoad() {
        super.windowDidLoad()

        table?.intercellSpacing = NSSize(width: 0, height: 0)

        table?.backgroundColor = NSColor.clear
        table?.autoresizingMask = [NSView.AutoresizingMask.width,
                                       NSView.AutoresizingMask.height]

        self.observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Settings.card_size), object: nil, queue: OperationQueue.main) { _ in
            self.cardSizeChange()
        }
    }
    
    deinit {
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func cardSizeChange() {
        setWindowSizes()
    }
    
    func cardCount() -> Int {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return animatedCards.count
    }

    fileprivate func internalSet(cards: [Card]) {
        semaphore.wait()
        
        var newCards = [Card]()
        cards.forEach({ (card: Card) in
            let existing = animatedCards.first { areEqualForList($0.card!, card) }
            if existing == nil {
                newCards.append(card)
            }
        })

        var toRemove: [Int] = []
        animatedCards.forEach({ (c: CardBar) in
            if !cards.any({ areEqualForList($0, c.card!) }) {
                toRemove.append(animatedCards.firstIndex(of: c)!)
            }
        })
        
        table?.beginUpdates()
        var indexSet = IndexSet(toRemove)
        table?.removeRows(at: indexSet, withAnimation: [.effectFade, .slideRight])
        for index in indexSet.reversed() {
            animatedCards.remove(at: index)
        }
        indexSet.removeAll()
        newCards.forEach({
            let newCard = CardBar.factory()
            newCard.setDelegate(self)
            newCard.card = $0
            newCard.playerType = .secrets
            let index = cards.firstIndex(of: $0)!
            animatedCards.insert(newCard, at: index)
            indexSet.insert(index)
        })
        table?.insertRows(at: indexSet, withAnimation: .slideLeft)
        // need to signal here to avoid a deadlock
        semaphore.signal()

        table?.endUpdates()
    }
    
    func set(cards: [Card]) {
        if Thread.isMainThread {
            internalSet(cards: cards)
        } else {
            DispatchQueue.main.async { [self] in
                self.internalSet(cards: cards)
            }
        }
    }
    
    fileprivate func areEqualForList(_ c1: Card, _ c2: Card) -> Bool {
        return c1.id == c2.id
    }
    
    var frameHeight: CGFloat {
        var rowHeight: CGFloat = 0
        switch Settings.cardSize {
        case .tiny: rowHeight = CGFloat(kTinyRowHeight)
        case .small: rowHeight = CGFloat(kSmallRowHeight)
        case .medium: rowHeight = CGFloat(kMediumRowHeight)
        case .huge: rowHeight = CGFloat(kHighRowHeight)
        case .big: rowHeight = CGFloat(kRowHeight)
        }
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return rowHeight * CGFloat(self.animatedCards.count)
    }
}

// MARK: - NSTableViewDataSource
extension CardList: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return cardCount()
    }
}

// MARK: - NSTableViewDelegate
extension CardList: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        let cell = row >= 0 && row < animatedCards.count ? animatedCards[row] : nil
        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch Settings.cardSize {
        case .tiny: return CGFloat(kTinyRowHeight)
        case .small: return CGFloat(kSmallRowHeight)
        case .medium: return CGFloat(kMediumRowHeight)
        case .huge: return CGFloat(kHighRowHeight)
        case .big: return CGFloat(kRowHeight)
        }
    }

    func selectionShouldChange(in tableView: NSTableView) -> Bool {
        return false
    }
}

// MARK: - CardCellHover
extension CardList: CardCellHover {
    func hover(cell: CardBar, card: Card) {
        let row = table!.row(for: cell)
        let rect = table!.frameOfCell(atColumn: 0, row: row)

        let offset = rect.origin.y - table!.enclosingScrollView!.documentVisibleRect.origin.y
        let windowRect = self.window!.frame

        let hoverFrame = NSRect(x: 0, y: 0, width: 200, height: 300)

        var x: CGFloat
        if windowRect.origin.x < hoverFrame.size.width || isSecretPanel {
            x = windowRect.origin.x + windowRect.size.width
        } else {
            x = windowRect.origin.x - hoverFrame.size.width
        }

        var y = windowRect.origin.y + windowRect.height - offset - 30
        if y < hoverFrame.height {
            y = hoverFrame.height
        }
        if let screen = self.window?.screen {
            if y + hoverFrame.height > screen.frame.height {
                y = screen.frame.height - hoverFrame.height
            }
        }

        let frame = [x, y, hoverFrame.width, hoverFrame.height]
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.show_floating_card),
                                  object: nil,
                                  userInfo: [
                                    "card": card,
                                    "frame": frame
                ])
    }

    func out(card: Card) {
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil)
    }
}

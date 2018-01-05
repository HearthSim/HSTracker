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

    var cards = [Card]()

    override func windowDidLoad() {
        super.windowDidLoad()

        table?.intercellSpacing = NSSize(width: 0, height: 0)

        table?.backgroundColor = NSColor.clear
        table?.autoresizingMask = [NSView.AutoresizingMask.width,
                                       NSView.AutoresizingMask.height]

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(cardSizeChange),
                         name: NSNotification.Name(rawValue: Settings.card_size),
                         object: nil)
    }

    @objc func cardSizeChange() {
        setWindowSizes()
    }

    func set(cards: [Card]) {
        self.cards = cards
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
        return rowHeight * CGFloat(self.cards.count)
    }
}

// MARK: - NSTableViewDataSource
extension CardList: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return cards.count
    }
}

// MARK: - NSTableViewDelegate
extension CardList: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        let card = cards[row]
        let cell = CardBar.factory()
        cell.card = card
        cell.playerType = .secrets
        cell.setDelegate(self)

        if card.hasChanged {
            card.hasChanged = false
        }
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
        if windowRect.origin.x < hoverFrame.size.width {
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

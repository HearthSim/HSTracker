//
//  SecretTracker.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 10/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class SecretTracker : NSWindowController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var table: NSTableView!

    var cards = [Card]()

    override func windowDidLoad() {
        super.windowDidLoad()

        let locked = Settings.instance.windowsLocked
        if locked {
            self.window!.styleMask = NSBorderlessWindowMask
        } else {
            self.window!.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
        }
        self.window!.ignoresMouseEvents = locked
        self.window!.acceptsMouseMovedEvents = true

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(Settings.instance.trackerOpacity / 100.0))

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "opacityChange:", name: "tracker_opacity", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cardSizeChange:", name: "card_size", object: nil)

        self.table.intercellSpacing = NSSize(width: 0, height: 0)

        self.table.backgroundColor = NSColor.clearColor()
        self.table.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable, NSAutoresizingMaskOptions.ViewHeightSizable]

        self.table.reloadData()
    }

    func windowLockedChange(notification: NSNotification) {
        let locked = Settings.instance.windowsLocked
        if locked {
            self.window!.styleMask = NSBorderlessWindowMask
        } else {
            self.window!.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
        }
        self.window!.ignoresMouseEvents = locked
    }

    func opacityChange(notification: NSNotification) {
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(Settings.instance.trackerOpacity / 100.0))
    }

    func setSecrets(opponentSecrets: OpponentSecrets) {
        cards.removeAll()
        opponentSecrets.secrets.forEach { (secret) in
            secret.possibleSecrets.forEach { (cardId, possible) in
                if let card = Cards.byId(cardId) {
                    card.count = possible ? 1 : 0
                    cards.append(card)
                }
            }
        }
        table.reloadData()
    }

    // MARK: - NSTableViewDelegate / NSTableViewDataSource
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return cards.count
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let card = cards[row]
        let cell = CardCellView()
        cell.card = card
        cell.playerType = .Secrets
        // cell.setDelegate(self)

        if card.hasChanged {
            card.hasChanged = false
        }
        return cell
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch Settings.instance.cardSize {
        case .Small:
            return CGFloat(kSmallRowHeight)

        case .Medium:
            return CGFloat(kMediumRowHeight)

        default:
            return CGFloat(kRowHeight)
        }
    }

    func selectionShouldChangeInTableView(tableView: NSTableView) -> Bool {
        return false;
    }
}
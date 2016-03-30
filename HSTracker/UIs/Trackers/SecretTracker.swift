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

        self.window!.styleMask = NSBorderlessWindowMask
        self.window!.ignoresMouseEvents = true
        self.window!.acceptsMouseMovedEvents = true

        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor.clearColor()

        var width: Double
        let settings = Settings.instance
        switch settings.cardSize {
        case .Small:
            width = kSmallFrameWidth

        case .Medium:
            width = kMediumFrameWidth

        default:
            width = kFrameWidth
        }

        self.window!.setFrame(NSRect(x: 0, y: 0, width: width, height: 350), display: true)
        self.window!.contentMinSize = NSSize(width: width, height: 350)
        self.window!.contentMaxSize = NSSize(width: width, height: Double(NSHeight(NSScreen.mainScreen()!.frame)))

        self.table.intercellSpacing = NSSize(width: 0, height: 0)

        self.table.backgroundColor = NSColor.clearColor()
        self.table.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable, NSAutoresizingMaskOptions.ViewHeightSizable]

        self.table.reloadData()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setSecrets(opponentSecrets: OpponentSecrets) {
        cards.removeAll()
        opponentSecrets.getSecrets().forEach { (secret) in
            if let card = Cards.byId(secret.cardId) {
                card.count = secret.count
                cards.append(card)
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
        return false
    }
}
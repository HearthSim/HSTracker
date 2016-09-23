//
//  SecretTracker.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 10/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class SecretTracker: NSWindowController {

    @IBOutlet weak var table: NSTableView!

    var cards = [Card]()

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window!.styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask
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
        self.window!.contentMaxSize = NSSize(width: width,
                                             height: Double(NSScreen.mainScreen()!.frame.height))

        table.intercellSpacing = NSSize(width: 0, height: 0)

        table.backgroundColor = NSColor.clearColor()
        table.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable,
                                       NSAutoresizingMaskOptions.ViewHeightSizable]

        table.reloadData()

        NSNotificationCenter.defaultCenter()
            .addObserver(self,
                         selector: #selector(SecretTracker.hearthstoneActive(_:)),
                         name: "hearthstone_active",
                         object: nil)
        NSNotificationCenter.defaultCenter()
            .addObserver(self,
                         selector: #selector(SecretTracker.updateTheme(_:)),
                         name: "theme",
                         object: nil)
        
        self.window!.collectionBehavior = [.CanJoinAllSpaces, .FullScreenAuxiliary]
        
        if let panel = self.window as? NSPanel {
            panel.floatingPanel = true
        }
        
        NSWorkspace.sharedWorkspace().notificationCenter
            .addObserver(self, selector: #selector(SecretTracker.bringToFront),
                         name: NSWorkspaceActiveSpaceDidChangeNotification, object: nil)
        
        self.window?.orderFront(nil) // must be called after style change
    }
    
    func bringToFront() {
        self.window?.orderFront(nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func updateTheme(notification: NSNotification) {
        table.reloadData()
    }

    func hearthstoneActive(notification: NSNotification) {
        let hs = Hearthstone.instance

        let level: Int
        if hs.hearthstoneActive {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
        self.window!.level = level
    }

    func setSecrets(opponentSecrets: OpponentSecrets) {
        cards.removeAll()
        opponentSecrets.getSecrets().forEach({ (secret) in
            if let card = Cards.byId(secret.cardId) where secret.count > 0 {
                card.count = secret.count
                cards.append(card)
            }
        })
        table.reloadData()
    }
}

// MARK: - NSTableViewDataSource
extension SecretTracker: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return cards.count
    }
}

// MARK: - NSTableViewDelegate
extension SecretTracker: NSTableViewDelegate {
    func tableView(tableView: NSTableView,
                   viewForTableColumn tableColumn: NSTableColumn?,
                                      row: Int) -> NSView? {
        let card = cards[row]
        let cell = CardBar.factory()
        cell.card = card
        cell.playerType = .Secrets
        cell.setDelegate(self)

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

// MARK: - CardCellHover
extension SecretTracker: CardCellHover {
    func hover(cell: CardBar, card: Card) {
        let row = table.rowForView(cell)
        let rect = table.frameOfCellAtColumn(0, row: row)

        let offset = rect.origin.y - table.enclosingScrollView!.documentVisibleRect.origin.y
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
        NSNotificationCenter.defaultCenter()
            .postNotificationName("show_floating_card",
                                  object: nil,
                                  userInfo: [
                                    "card": card,
                                    "frame": frame
                ])
    }

    func out(card: Card) {
        NSNotificationCenter.defaultCenter()
            .postNotificationName("hide_floating_card", object: nil)
    }
}

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

        self.window!.styleMask = [NSBorderlessWindowMask, NSNonactivatingPanelMask]
        self.window!.ignoresMouseEvents = true
        self.window!.acceptsMouseMovedEvents = true

        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow))

        self.window!.isOpaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor.clear

        var width: Double
        let settings = Settings.instance
        switch settings.cardSize {
        case .tiny: width = kTinyFrameWidth
        case .small: width = kSmallFrameWidth
        case .medium: width = kMediumFrameWidth
        case .big: width = kFrameWidth
        case .huge: width = kHighRowFrameWidth
        }

        self.window!.setFrame(NSRect(x: 0, y: 0, width: width, height: 350), display: true)
        self.window!.contentMinSize = NSSize(width: width, height: 350)
        self.window!.contentMaxSize = NSSize(width: width,
                                             height: Double(NSScreen.main()!.frame.height))

        table.intercellSpacing = NSSize(width: 0, height: 0)

        table.backgroundColor = NSColor.clear
        table.autoresizingMask = [NSAutoresizingMaskOptions.viewWidthSizable,
                                       NSAutoresizingMaskOptions.viewHeightSizable]

        table.reloadData()

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(SecretTracker.hearthstoneActive(_:)),
                         name: NSNotification.Name(rawValue: "hearthstone_active"),
                         object: nil)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(SecretTracker.updateTheme(_:)),
                         name: NSNotification.Name(rawValue: "theme"),
                         object: nil)
        
        self.window!.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        if let panel = self.window as? NSPanel {
            panel.isFloatingPanel = true
        }
        
        NSWorkspace.shared().notificationCenter
            .addObserver(self, selector: #selector(SecretTracker.bringToFront),
                         name: NSNotification.Name.NSWorkspaceActiveSpaceDidChange, object: nil)
        
        self.window?.orderFront(nil) // must be called after style change
    }
    
    func bringToFront() {
        self.window?.orderFront(nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func updateTheme(_ notification: Notification) {
        table.reloadData()
    }

    func hearthstoneActive(_ notification: Notification) {
        let hs = Hearthstone.instance

        let level: Int
        if hs.hearthstoneActive {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow))
        }
        self.window!.level = level
    }

    func setSecrets(_ opponentSecrets: OpponentSecrets) {
        cards.removeAll()
        opponentSecrets.getSecrets().forEach({ (secret) in
            if let card = Cards.by(cardId: secret.cardId), secret.count > 0 {
                card.count = secret.count
                cards.append(card)
            }
        })
        table.reloadData()
    }
}

// MARK: - NSTableViewDataSource
extension SecretTracker: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return cards.count
    }
}

// MARK: - NSTableViewDelegate
extension SecretTracker: NSTableViewDelegate {
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
        switch Settings.instance.cardSize {
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
extension SecretTracker: CardCellHover {
    func hover(cell: CardBar, card: Card) {
        let row = table.row(for: cell)
        let rect = table.frameOfCell(atColumn: 0, row: row)

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
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: "show_floating_card"),
                                  object: nil,
                                  userInfo: [
                                    "card": card,
                                    "frame": frame
                ])
    }

    func out(card: Card) {
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: "hide_floating_card"), object: nil)
    }
}

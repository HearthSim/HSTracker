//
//  TimerHud.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class TimerHud: NSWindowController {

    @IBOutlet weak var opponentLabel: NSTextField!
    @IBOutlet weak var turnLabel: NSTextField!
    @IBOutlet weak var playerLabel: NSTextField!
    var currentPlayer: PlayerType?
    let attributes = TextAttributes()
    let largeAttributes = TextAttributes()

    override func windowDidLoad() {
        super.windowDidLoad()

        opponentLabel.stringValue = ""
        turnLabel.stringValue = ""
        playerLabel.stringValue = ""

        attributes
            .font(NSFont(name: "Belwe Bd BT", size: 18))
            .foregroundColor(NSColor.whiteColor())
            .strokeWidth(-1.5)
            .strokeColor(NSColor.blackColor())
            .alignment(.Right)
        largeAttributes
            .font(NSFont(name: "Belwe Bd BT", size: 26))
            .foregroundColor(NSColor.whiteColor())
            .strokeWidth(-1.5)
            .strokeColor(NSColor.blackColor())
            .alignment(.Right)

        self.window!.styleMask = NSBorderlessWindowMask
        self.window!.ignoresMouseEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor.clearColor()

        // swiftlint:disable line_length
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(TimerHud.hearthstoneActive(_:)),
                                                         name: "hearthstone_active",
                                                         object: nil)
        // swiftlint:enable line_length
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

    func tick(seconds: Int, playerSeconds: Int, opponentSeconds: Int) {
        guard Settings.instance.showTimer else {
            turnLabel.attributedStringValue = NSAttributedString(string: "")
            playerLabel.attributedStringValue = NSAttributedString(string: "")
            opponentLabel.attributedStringValue = NSAttributedString(string: "")
            return
        }

        turnLabel.attributedStringValue = NSAttributedString(string:
            String(format: "%d:%02d", (seconds / 60) % 60, seconds % 60),
                                                             attributes: largeAttributes)
        playerLabel.attributedStringValue = NSAttributedString(string:
            String(format: "%d:%02d", (playerSeconds / 60) % 60, playerSeconds % 60),
                                                               attributes: attributes)
        opponentLabel.attributedStringValue = NSAttributedString(string:
            String(format: "%d:%02d", (opponentSeconds / 60) % 60, opponentSeconds % 60),
                                                                 attributes: attributes)
    }
}

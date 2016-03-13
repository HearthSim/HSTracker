//
//  TimerHud.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class TimerHud: NSWindowController {

    @IBOutlet weak var opponentLabel: NSTextField!
    @IBOutlet weak var turnLabel: NSTextField!
    @IBOutlet weak var playerLabel: NSTextField!
    var currentPlayer: PlayerType?

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window!.styleMask = NSBorderlessWindowMask
        self.window!.ignoresMouseEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
    }

    func tick(seconds: Int, _ playerSeconds: Int, _ opponentSeconds: Int) {
        turnLabel.stringValue = String(format: "%d:%02d", (seconds / 60) % 60, seconds % 60)
        playerLabel.stringValue = String(format: "%d:%02d", (playerSeconds / 60) % 60, playerSeconds % 60)
        opponentLabel.stringValue = String(format: "%d:%02d", (opponentSeconds / 60) % 60, opponentSeconds % 60)
    }
}
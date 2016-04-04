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
    var attributes = [String:AnyObject]()
    var largeAttributes = [String:AnyObject]()

    override func windowDidLoad() {
        super.windowDidLoad()
        
        opponentLabel.stringValue = ""
        turnLabel.stringValue = ""
        playerLabel.stringValue = ""
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .Right
        attributes = [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 18)!,
            NSForegroundColorAttributeName: NSColor.whiteColor(),
            NSStrokeWidthAttributeName: -1.5,
            NSStrokeColorAttributeName: NSColor.blackColor(),
            NSParagraphStyleAttributeName: paragraph
        ]
        largeAttributes = [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 26)!,
            NSForegroundColorAttributeName: NSColor.whiteColor(),
            NSStrokeWidthAttributeName: -1.5,
            NSStrokeColorAttributeName: NSColor.blackColor(),
            NSParagraphStyleAttributeName: paragraph
        ]

        self.window!.styleMask = NSBorderlessWindowMask
        self.window!.ignoresMouseEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
    }

    func tick(seconds: Int, _ playerSeconds: Int, _ opponentSeconds: Int) {
        guard Settings.instance.showTimer else { return }
        
        turnLabel.attributedStringValue = NSAttributedString(string: String(format: "%d:%02d", (seconds / 60) % 60, seconds % 60), attributes: largeAttributes)
        playerLabel.attributedStringValue = NSAttributedString(string: String(format: "%d:%02d", (playerSeconds / 60) % 60, playerSeconds % 60), attributes: attributes)
        opponentLabel.attributedStringValue = NSAttributedString(string: String(format: "%d:%02d", (opponentSeconds / 60) % 60, opponentSeconds % 60), attributes: attributes)
    }
}
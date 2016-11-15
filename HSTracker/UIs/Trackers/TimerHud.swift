//
//  TimerHud.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class TimerHud: OverWindowController {

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
            .foregroundColor(.white)
            .strokeWidth(-1.5)
            .strokeColor(.black)
            .alignment(.right)
        largeAttributes
            .font(NSFont(name: "Belwe Bd BT", size: 26))
            .foregroundColor(.white)
            .strokeWidth(-1.5)
            .strokeColor(.black)
            .alignment(.right)

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

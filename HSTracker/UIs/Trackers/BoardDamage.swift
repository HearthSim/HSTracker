//
//  BoardDamage.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class BoardDamage: OverWindowController {
    
    @IBOutlet weak var damage: NSTextField!
    let attributes = TextAttributes()
    var player: PlayerType?
    
    var hasValidFrame = false
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        attributes
            .font(NSFont(name: "Belwe Bd BT", size: 18))
            .foregroundColor(.white)
            .strokeWidth(-1.5)
            .strokeColor(.black)
            .alignment(.center)
    }

    func update(attack: Int) {      
        damage.attributedStringValue = NSAttributedString(string: "\(attack)",
                                                          attributes: attributes)
    }
}

extension BoardDamage: NSWindowDelegate {
    
    func windowDidMove(_ notification: Notification) {
        onWindowMove()
    }
    
    private func onWindowMove() {
        if !self.isWindowLoaded || !self.hasValidFrame {return}
        if player == .player {
            Settings.playerBoardDamageFrame = self.window?.frame
        } else {
            Settings.opponentBoardDamageFrame = self.window?.frame
        }
    }
}

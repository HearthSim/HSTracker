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

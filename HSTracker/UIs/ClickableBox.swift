//
//  ClickableBox.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/24/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class ClickableBox: NSBox {
    var clicked: ((_: NSEvent) -> Void)?
    
    // MARK: - Mouse Events
    override func mouseDown(with event: NSEvent) {
        if let click = clicked {
            click(event)
        }
    }
}

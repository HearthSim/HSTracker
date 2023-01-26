//
//  NSButton.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/11/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSButton {
    func underlined() {
        let text = stringValue
        
        let attrString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single])
        attributedStringValue = attrString
    }
}

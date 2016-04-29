//
//  Color.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSColor {
    func darken(amount: CGFloat = 0.5) -> NSColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return NSColor(hue: hue,
                       saturation: saturation,
                       brightness: brightness * amount,
                       alpha: alpha)
    }
}

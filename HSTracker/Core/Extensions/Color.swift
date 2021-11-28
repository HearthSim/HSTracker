//
//  Color.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

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
    
    class func fromHexString(hex: String, alpha: CGFloat = 1.0) -> NSColor? {
        // Handle two types of literals: 0x and # prefixed
        var cleanedString = ""
        if hex.hasPrefix("0x") {
            cleanedString = hex.substring(from: 2)
        } else if hex.hasPrefix("#") {
            cleanedString = hex.substring(from: 1)
        }
        var theInt: UInt32 = 0
        let scanner = Scanner(string: cleanedString)
        scanner.scanHexInt32(&theInt)
        let red = CGFloat((theInt & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((theInt & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((theInt & 0xFF)) / 255.0
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

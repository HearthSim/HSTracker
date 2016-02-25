//
//  ClassColor.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class ClassColor  {
    static let Druid = NSColor(red: 255.0 / 255.0, green: 125.0 / 255.0, blue: 10.0 / 255.0, alpha: 1)
    static let Hunter = NSColor(red: 171.0 / 255.0, green: 212.0 / 255.0, blue: 115.0 / 255.0, alpha: 1)
    static let Mage = NSColor(red: 105.0 / 255.0, green: 204.0 / 255.0, blue: 240.0 / 255.0, alpha: 1)
    static let Paladin = NSColor(red: 245.0 / 255.0, green: 140.0 / 255.0, blue: 186.0 / 255.0, alpha: 1)
    static let Priest = NSColor(red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
    static let Rogue = NSColor(red: 255.0 / 255.0, green: 245.0 / 255.0, blue: 105.0 / 255.0, alpha: 1)
    static let Shaman = NSColor(red: 0.0 / 255.0, green: 112.0 / 255.0, blue: 222.0 / 255.0, alpha: 1)
    static let Warlock = NSColor(red: 148.0 / 255.0, green: 130.0 / 255.0, blue: 201.0 / 255.0, alpha: 1)
    static let Warrior = NSColor(red: 199.0 / 255.0, green: 156.0 / 255.0, blue: 110.0 / 255.0, alpha: 1)

    static func color(playerClass:String) -> NSColor? {
        switch playerClass.lowercaseString {
            case "druid": return Druid
            case "hunter": return Hunter
            case "mage": return Mage
            case "paladin": return Paladin
            case "priest": return Priest
            case "rogue": return Rogue
            case "shaman": return Shaman
            case "warlock": return Warlock
            case "warrior": return Warrior
            default: return nil
        }
    }
}
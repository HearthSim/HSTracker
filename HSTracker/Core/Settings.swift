//
//  Settings.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Settings {

    static let instance = Settings()

    var flashColor: NSColor {
        set {
            NSUserDefaults.standardUserDefaults().setObject(NSArchiver.archivedDataWithRootObject(newValue), forKey: "flash_color")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("flash_color") as? NSData {
                return NSUnarchiver.unarchiveObjectWithData(returnValue) as! NSColor
            } else {
                return NSColor(red: 55, green: 189, blue: 223, alpha: 1)
            }
        }
    }
    var cardSize: CardSize {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue.rawValue, forKey: "card_size")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("card_size") as? Int {
                return CardSize(rawValue: returnValue)!
            } else {
                return .Big
            }
        }
    }
    var hearthstoneLogPath: String {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "hearthstone_log_path")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("hearthstone_log_path") as? String {
                return returnValue
            } else {
                return "/Applications/Hearthstone/Logs/"
            }
        }
    }
    var hearthstoneLanguage: String? {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "hearthstone_language")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("hearthstone_language") as? String {
                return returnValue
            } else {
                return nil
            }
        }
    }
    var hsTrackerLanguage: String? {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "hstracker_language")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("hstracker_language") as? String {
                return returnValue
            } else {
                return nil
            }
        }
    }
    var databaseVersion: Int {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "database_version")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("database_version") as? Int {
                return returnValue
            } else {
                return 0
            }
        }
    }
    var showRarityColors: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "rarity_colors")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("rarity_colors") as? Bool {
                return returnValue
            } else {
                return true
            }
        }
    }
    var showOneCard: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "show_one_card")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("show_one_card") as? Bool {
                return returnValue
            } else {
                return false
            }
        }
    }
    var inHandAsPlayed: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "in_hand_as_played")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("in_hand_as_played") as? Bool {
                return returnValue
            } else {
                return true
            }
        }
    }
    var windowsLocked: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "window_locked")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("window_locked") as? Bool {
                return returnValue
            } else {
                return true
            }
        }
    }
    var handCountWindow: HandCountPosition {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue.rawValue, forKey: "hand_count_window")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("hand_count_window") as? Int {
                return HandCountPosition(rawValue: returnValue)!
            } else {
                return .Tracker
            }
        }
    }
    var fixedWindowNames: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "fixed_window_names")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("fixed_window_names") as? Bool {
                return returnValue
            } else {
                return true
            }
        }
    }
    var removeCardsFromDeck: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "remove_cards_from_deck")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("remove_cards_from_deck") as? Bool {
                return returnValue
            } else {
                return true
            }
        }
    }
    var highlightLastDrawn: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "highlight_last_drawn")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("highlight_last_drawn") as? Bool {
                return returnValue
            } else {
                return true
            }
        }
    }
    var highlightCardsInHand: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "highlight_cards_in_hand")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("highlight_cards_in_hand") as? Bool {
                return returnValue
            } else {
                return true
            }
        }
    }
    var highlightDiscarded: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "highlight_discarded")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("highlight_discarded") as? Bool {
                return returnValue
            } else {
                return true
            }
        }
    }
    var showPlayerGet: Bool {
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "show_player_get")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("show_player_get") as? Bool {
                return returnValue
            } else {
                return false
            }
        }
    }
    
    var isCyrillicOrAsian: Bool {
        get {
            if let language = hearthstoneLanguage {
                return language.isMatch(NSRegularExpression.rx("^(zh|ko|ru|ja)"))
            } else {
                return false
            }
        }
    }
}

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

    private func set(name: String, _ value: AnyObject?) {
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: name)
        NSUserDefaults.standardUserDefaults().synchronize()

        NSNotificationCenter.defaultCenter().postNotificationName(name, object: value)
    }

    private func get(name: String, _ defaultValue: AnyObject?) -> AnyObject? {
        if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey(name) {
            return returnValue
        } else {
            return defaultValue
        }
    }

    /*var showOpponentDraw: Bool {
     set { set("show_opponent_draw", newValue) }
     get { return get("show_opponent_draw", false) as! Bool }
     }
     var showOpponentMulligan: Bool {
     set { set("show_opponent_mulligan", newValue) }
     get { return get("show_opponent_mulligan", false) as! Bool }
     }
     var showOpponentPlay: Bool {
     set { set("show_opponent_play", newValue) }
     get { return get("show_opponent_play", true) as! Bool }
     }
     var showPlayerDraw: Bool {
     set { set("show_player_draw", newValue) }
     get { return get("show_player_draw", false) as! Bool }
     }
     var showPlayerMulligan: Bool {
     set { set("show_player_mulligan", newValue) }
     get { return get("show_player_mulligan", false) as! Bool }
     }
     var showPlayerPlay: Bool {
     set { set("show_player_play", newValue) }
     get { return get("show_player_play", true) as! Bool }
     }*/

    var trackerOpacity: Double {
        set { set("tracker_opacity", newValue) }
        get { return get("tracker_opacity", 0) as! Double }
    }

    var activeDeck: String? {
        set { set("active_deck", newValue) }
        get { return get("active_deck", nil) as? String }
    }

    /*var flashColor: NSColor {
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
     }*/
    var cardSize: CardSize {
        set { set("card_size", newValue.rawValue) }
        get { return CardSize(rawValue: get("card_size", CardSize.Big.rawValue) as! Int)! }
    }
    var hearthstoneLogPath: String {
        set { set("hearthstone_log_path", newValue) }
        get { return get("hearthstone_log_path", "/Applications/Hearthstone/Logs/") as! String }
    }
    var hearthstoneLanguage: String? {
        set { set("hearthstone_language", newValue) }
        get { return get("hearthstone_language", nil) as? String }
    }
    var hsTrackerLanguage: String? {
        set { set("hstracker_language", newValue) }
        get { return get("hstracker_language", nil) as? String }
    }

    var showRarityColors: Bool {
        set { set("rarity_colors", newValue) }
        get { return get("rarity_colors", true) as! Bool }
    }

    var autoGrayoutSecrets: Bool {
        set { set("auto_grayout_secrets", newValue) }
        get { return get("auto_grayout_secrets", true) as! Bool }
    }
    /*var showOneCard: Bool {
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
     }*/
    var windowsLocked: Bool {
        set { set("window_locked", newValue) }
        get { return get("window_locked", true) as! Bool }
    }
    /*var handCountWindow: HandCountPosition {
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
     }*/
    var removeCardsFromDeck: Bool {
        set { set("remove_cards_from_deck", newValue) }
        get { return get("remove_cards_from_deck", false) as! Bool }
    }
    var highlightLastDrawn: Bool {
        set { set("highlight_last_drawn", newValue) }
        get { return get("highlight_last_drawn", true) as! Bool }
    }
    var highlightCardsInHand: Bool {
        set { set("highlight_cards_in_hand", newValue) }
        get { return get("highlight_cards_in_hand", false) as! Bool }
    }
    var highlightDiscarded: Bool {
        set { set("highlight_discarded", newValue) }
        get { return get("highlight_discarded", false) as! Bool }
    }
    var showPlayerGet: Bool {
        set { set("show_player_get", newValue) }
        get { return get("show_player_get", false) as! Bool }
    }
    var showPlayerTracker: Bool {
        set { set("show_player_tracker", newValue) }
        get { return get("show_player_tracker", true) as! Bool }
    }
    var showOpponentTracker: Bool {
        set { set("show_opponent_tracker", newValue) }
        get { return get("show_opponent_tracker", true) as! Bool }
    }

    var deckPath: String? {
        set { set("decks_path", newValue) }
        get {
            if let returnValue = NSUserDefaults.standardUserDefaults().objectForKey("decks_path") as? String {
                return returnValue
            }
            else if let appSupport = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).first {
                let path = "\(appSupport)/HSTracker/decks"
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    return nil
                }
                return path
            }
            return nil
        }
    }

    var isCyrillicOrAsian: Bool {
        if let language = hearthstoneLanguage {
            return language.isMatch(NSRegularExpression.rx("^(zh|ko|ru|ja)"))
        } else {
            return false
        }
    }
}

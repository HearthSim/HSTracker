//
//  Settings.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

final class Settings {

    static let instance = Settings()
    
    private let defaults:NSUserDefaults? = {
        return NSUserDefaults.standardUserDefaults()
    }()

    private func set(name: String, _ value: AnyObject?) {
        defaults?.setObject(value, forKey: name)
        defaults?.synchronize()

        NSNotificationCenter.defaultCenter().postNotificationName(name, object: value)
    }

    private func get(name: String, _ defaultValue: AnyObject?) -> AnyObject? {
        if let returnValue = defaults?.objectForKey(name) {
            return returnValue
        } else {
            return defaultValue
        }
    }
    var deckManagerZoom: Double {
        set { set("deck_manager_zoom", newValue) }
        get { return get("deck_manager_zoom", 100) as! Double }
    }
    var trackerOpacity: Double {
        set { set("tracker_opacity", newValue) }
        get { return get("tracker_opacity", 0) as! Double }
    }
    var activeDeck: String? {
        set { set("active_deck", newValue) }
        get { return get("active_deck", nil) as? String }
    }
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
        set {
            if let locale = newValue {
                defaults?.setObject([locale], forKey: "AppleLanguages")
            }
            set("hstracker_language", newValue)
        }
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
    var autoPositionTrackers: Bool {
        set { set("auto_position_trackers", newValue) }
        get { return get("auto_position_trackers", false) as! Bool }
    }
    
    var windowsLocked: Bool {
        set { set("window_locked", newValue) }
        get { return get("window_locked", true) as! Bool }
    }

    var showPlayerDrawChance: Bool {
        set { set("player_draw_chance", newValue) }
        get { return get("player_draw_chance", true) as! Bool }
    }
    var showPlayerCardCount: Bool {
        set { set("player_card_count", newValue) }
        get { return get("player_card_count", true) as! Bool }
    }
    var showOpponentCardCount: Bool {
        set { set("opponent_card_count", newValue) }
        get { return get("opponent_card_count", true) as! Bool }
    }
    var showOpponentDrawChance: Bool {
        set { set("opponent_draw_chance", newValue) }
        get { return get("opponent_draw_chance", true) as! Bool }
    }
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
    var showTimer: Bool {
        set { set("show_timer", newValue) }
        get { return get("show_timer", true) as! Bool }
    }
    var showCardHuds: Bool {
        set { set("show_card_huds", newValue) }
        get { return get("show_card_huds", true) as! Bool }
    }
    var showSecretHelper: Bool {
        set { set("show_secret_helper", newValue) }
        get { return get("show_secret_helper", true) as! Bool }
    }
    
    var playerTrackerFrame: NSRect? {
        set { set("player_tracker_frame", newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get("player_tracker_frame", nil) as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }
    
    var opponentTrackerFrame: NSRect? {
        set { set("opponent_tracker_frame", newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get("opponent_tracker_frame", nil) as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }
    
    // MARK: - Notifications
    var notifyGameStart: Bool {
        set { set("notify_game_start", newValue) }
        get { return get("notify_game_start", true) as! Bool }
    }
    var notifyTurnStart: Bool {
        set { set("notify_turn_start", newValue) }
        get { return get("notify_turn_start", true) as! Bool }
    }
    var notifyOpponentConcede: Bool {
        set { set("notify_opponent_concede", newValue) }
        get { return get("notify_opponent_concede", true) as! Bool }
    }
    
    // MARK: - Hearthstats
    var hearthstatsLogin: String? {
        set { set("hearthstats_login", newValue) }
        get { return get("hearthstats_login", nil) as? String }
    }
    var hearthstatsToken: String? {
        set { set("hearthstats_token", newValue) }
        get { return get("hearthstats_token", nil) as? String }
    }
    var hearthstatsLastDecksSync: Double {
        set { set("hearthstats_last_decks_sync", newValue) }
        get { return get("hearthstats_last_decks_sync", 0) as! Double }
    }
    var hearthstatsLastMatchesSync: Double {
        set { set("hearthstats_last_matches_sync", newValue) }
        get { return get("hearthstats_last_matches_sync", 0) as! Double }
    }
    var hearthstatsAutoSynchronize: Bool {
        set { set("hearthstats_auto_synchronize_decks", newValue) }
        get { return get("hearthstats_auto_synchronize_decks", true) as! Bool }
    }
    var hearthstatsSynchronizeMatches: Bool {
        set { set("hearthstats_auto_synchronize_matches", newValue) }
        get { return get("hearthstats_auto_synchronize_matches", true) as! Bool }
    }

    // MARK: - Paths / utils
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
            return language.match("^(zh|ko|ru|ja|th)")
        } else {
            return false
        }
    }
}

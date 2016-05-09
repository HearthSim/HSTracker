//
//  Settings.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

final class Settings {

    static let instance = Settings()

    func validated() -> Bool {
        return Hearthstone.validatedHearthstonePath()
            && hearthstoneLanguage != nil && hsTrackerLanguage != nil
    }

    private let defaults: NSUserDefaults? = {
        return NSUserDefaults.standardUserDefaults()
    }()

    private func set(name: String, _ value: AnyObject?) {
        defaults?.setObject(value, forKey: name)
        defaults?.synchronize()

        NSNotificationCenter.defaultCenter().postNotificationName(name, object: value)
    }

    private func get(name: String) -> AnyObject? {
        if let returnValue = defaults?.objectForKey(name) {
            return returnValue
        }
        return nil
    }
    var deckManagerZoom: Double {
        set { set("deck_manager_zoom", newValue) }
        get { return get("deck_manager_zoom") as? Double ?? 100.0 }
    }
    var trackerOpacity: Double {
        set { set("tracker_opacity", newValue) }
        get { return get("tracker_opacity") as? Double ?? 0.0 }
    }
    var activeDeck: String? {
        set { set("active_deck", newValue) }
        get { return get("active_deck") as? String }
    }
    var cardSize: CardSize {
        set { set("card_size", newValue.rawValue) }
        get { return CardSize(rawValue: get("card_size") as? Int
            ?? CardSize.Big.rawValue) ?? CardSize.Big }
    }
    var hearthstoneLogPath: String {
        set { set("hearthstone_log_path", newValue) }
        get { return get("hearthstone_log_path") as? String ?? "/Applications/Hearthstone" }
    }
    var hearthstoneLanguage: String? {
        set { set("hearthstone_language", newValue) }
        get { return get("hearthstone_language") as? String }
    }
    var hsTrackerLanguage: String? {
        set {
            if let locale = newValue {
                defaults?.setObject([locale], forKey: "AppleLanguages")
            }
            set("hstracker_language", newValue)
        }
        get { return get("hstracker_language") as? String }
    }
    var showRarityColors: Bool {
        set { set("rarity_colors", newValue) }
        get { return get("rarity_colors") as? Bool ?? true }
    }
    var autoGrayoutSecrets: Bool {
        set { set("auto_grayout_secrets", newValue) }
        get { return get("auto_grayout_secrets") as? Bool ?? true }
    }
    var autoPositionTrackers: Bool {
        set { set("auto_position_trackers", newValue) }
        get { return get("auto_position_trackers") as? Bool ?? false }
    }
    var deckManagerPreferCards: Bool {
        set { set("deckmanager_prefer_cards", newValue) }
        get { return get("deckmanager_prefer_cards") as? Bool ?? true }
    }
    var showFloatingCard: Bool {
        set { set("show_floating_card", newValue) }
        get { return get("show_floating_card") as? Bool ?? true }
    }
    var windowsLocked: Bool {
        set { set("window_locked", newValue) }
        get { return get("window_locked") as? Bool ?? true }
    }

    var showPlayerDrawChance: Bool {
        set { set("player_draw_chance", newValue) }
        get { return get("player_draw_chance") as? Bool ?? true }
    }
    var showPlayerCardCount: Bool {
        set { set("player_card_count", newValue) }
        get { return get("player_card_count") as? Bool ?? true }
    }
    var showOpponentCardCount: Bool {
        set { set("opponent_card_count", newValue) }
        get { return get("opponent_card_count") as? Bool ?? true }
    }
    var showOpponentDrawChance: Bool {
        set { set("opponent_draw_chance", newValue) }
        get { return get("opponent_draw_chance") as? Bool ?? true }
    }
    var showPlayerCthun: Bool {
        set { set("player_cthun_frame", newValue) }
        get { return get("player_cthun_frame") as? Bool ?? true }
    }
    var showPlayerYogg: Bool {
        set { set("player_yogg_frame", newValue) }
        get { return get("player_yogg_frame") as? Bool ?? true }
    }
    var showOpponentCthun: Bool {
        set { set("opponent_cthun_frame", newValue) }
        get { return get("opponent_cthun_frame") as? Bool ?? true }
    }
    var showOpponentYogg: Bool {
        set { set("opponent_yogg_frame", newValue) }
        get { return get("opponent_yogg_frame") as? Bool ?? true }
    }
    var removeCardsFromDeck: Bool {
        set { set("remove_cards_from_deck", newValue) }
        get { return get("remove_cards_from_deck") as? Bool ?? false }
    }
    var highlightLastDrawn: Bool {
        set { set("highlight_last_drawn", newValue) }
        get { return get("highlight_last_drawn") as? Bool ?? true }
    }
    var highlightCardsInHand: Bool {
        set { set("highlight_cards_in_hand", newValue) }
        get { return get("highlight_cards_in_hand") as? Bool ?? false }
    }
    var highlightDiscarded: Bool {
        set { set("highlight_discarded", newValue) }
        get { return get("highlight_discarded") as? Bool ?? false }
    }
    var showPlayerGet: Bool {
        set { set("show_player_get", newValue) }
        get { return get("show_player_get") as? Bool ?? false }
    }
    var showOpponentCreated: Bool {
        set { set("show_opponent_created", newValue) }
        get { return get("show_opponent_created") as? Bool ?? true }
    }
    var showPlayerTracker: Bool {
        set { set("show_player_tracker", newValue) }
        get { return get("show_player_tracker") as? Bool ?? true }
    }
    var clearTrackersOnGameEnd: Bool {
        set { set("clear_trackers_end", newValue) }
        get { return get("clear_trackers_end") as? Bool ?? false }
    }
    var showOpponentTracker: Bool {
        set { set("show_opponent_tracker", newValue) }
        get { return get("show_opponent_tracker") as? Bool ?? true }
    }
    var showTimer: Bool {
        set { set("show_timer", newValue) }
        get { return get("show_timer") as? Bool ?? true }
    }
    var showCardHuds: Bool {
        set { set("show_card_huds", newValue) }
        get { return get("show_card_huds") as? Bool ?? true }
    }
    var showSecretHelper: Bool {
        set { set("show_secret_helper", newValue) }
        get { return get("show_secret_helper") as? Bool ?? true }
    }

    var playerTrackerFrame: NSRect? {
        set { set("player_tracker_frame", newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get("player_tracker_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }

    var opponentTrackerFrame: NSRect? {
        set { set("opponent_tracker_frame", newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get("opponent_tracker_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }

    // MARK: - Notifications
    var notifyGameStart: Bool {
        set { set("notify_game_start", newValue) }
        get { return get("notify_game_start") as? Bool ?? true }
    }
    var notifyTurnStart: Bool {
        set { set("notify_turn_start", newValue) }
        get { return get("notify_turn_start") as? Bool ?? true }
    }
    var notifyOpponentConcede: Bool {
        set { set("notify_opponent_concede", newValue) }
        get { return get("notify_opponent_concede") as? Bool ?? true }
    }

    // MARK: - Hearthstats
    var hearthstatsLogin: String? {
        set { set("hearthstats_login", newValue) }
        get { return get("hearthstats_login") as? String }
    }
    var hearthstatsToken: String? {
        set { set("hearthstats_token", newValue) }
        get { return get("hearthstats_token") as? String }
    }
    var hearthstatsLastDecksSync: Double {
        set { set("hearthstats_last_decks_sync", newValue) }
        get { return get("hearthstats_last_decks_sync") as? Double
            ?? NSDate.distantPast().timeIntervalSince1970 }
    }
    var hearthstatsLastMatchesSync: Double {
        set { set("hearthstats_last_matches_sync", newValue) }
        get { return get("hearthstats_last_matches_sync") as? Double ?? 0.0 }
    }
    var hearthstatsAutoSynchronize: Bool {
        set { set("hearthstats_auto_synchronize_decks", newValue) }
        get { return get("hearthstats_auto_synchronize_decks") as? Bool ?? true }
    }
    var hearthstatsSynchronizeMatches: Bool {
        set { set("hearthstats_auto_synchronize_matches", newValue) }
        get { return get("hearthstats_auto_synchronize_matches") as? Bool ?? true }
    }

    // MARK: - Paths / utils
    var logSeverity: LogSeverity {
        set { set("file_logger_severity", newValue.rawValue) }
        get {
            if let rawSeverity = get("file_logger_severity") as? Int,
                severity = LogSeverity(rawValue: rawSeverity) {
                return severity
            }
            return .Verbose
        }
    }

    var deckPath: String? {
        set { set("decks_path", newValue) }
        get {
            if let returnValue = get("decks_path") as? String {
                return returnValue
            } else if let appSupport = NSSearchPathForDirectoriesInDomains(
                .ApplicationSupportDirectory,
                .UserDomainMask,
                true).first {
                let path = "\(appSupport)/HSTracker/decks"
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(
                        path,
                        withIntermediateDirectories: true,
                        attributes: nil)
                } catch {
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

//
//  Settings.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import AppKit

final class Settings {

    static var fullGameLog: Bool = false

    static func validated() -> Bool {
        return CoreManager.validatedHearthstonePath()
            && hearthstoneLanguage != nil && hsTrackerLanguage != nil
    }

    private static let defaults: UserDefaults? = {
        return UserDefaults.standard
    }()

    private static func set(name: String, value: Any?) {
        defaults?.set(value, forKey: name)
        defaults?.synchronize()

        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: value)
    }

    private static func get(name: String) -> Any? {
        if let returnValue = defaults?.object(forKey: name) {
            return returnValue as Any?
        }
        return nil
    }
	
	static var showMemoryReadingWarning: Bool {
		set { set(name: "showMemoryReadingWarning", value: newValue) }
		get { return get(name: "showMemoryReadingWarning") as? Bool ?? true }
	}
    static var canJoinFullscreen: Bool {
        set { set(name: "can_join_fullscreen", value: newValue) }
        get { return get(name: "can_join_fullscreen") as? Bool ?? true }
    }
    static var quitWhenHearthstoneCloses: Bool {
        set { set(name: "quit_when_hs_closes", value: newValue) }
        get { return get(name: "quit_when_hs_closes") as? Bool ?? false }
    }
    static var deckManagerZoom: Double {
        set { set(name: "deck_manager_zoom", value: newValue) }
        get { return get(name: "deck_manager_zoom") as? Double ?? 100.0 }
    }
    static var trackerOpacity: Double {
        set { set(name: "tracker_opacity", value: newValue) }
        get { return get(name: "tracker_opacity") as? Double ?? 0.0 }
    }
    static var activeDeck: String? {
        set { set(name: "active_deck", value: newValue) }
        get { return get(name: "active_deck") as? String }
    }
    static var cardSize: CardSize {
        set { set(name: "card_size", value: newValue.rawValue) }
        get { return CardSize(rawValue: get(name: "card_size") as? Int
            ?? CardSize.big.rawValue) ?? .big }
    }
    static var deckSortCriteria: String {
        set { set(name: "deck_sort_criteria", value: newValue) }
        get { return get(name: "deck_sort_criteria") as? String ?? "name" }
    }
    static var deckSortOrder: String {
        set { set(name: "deck_sort_order", value: newValue) }
        get { return get(name: "deck_sort_order") as? String ?? "ascending" }
    }
    static var autoArchiveArenaDeck: Bool {
        set { set(name: "archive_arena_deck", value: newValue) }
        get { return get(name: "archive_arena_deck") as? Bool ?? true }
    }
    static var hearthstonePath: String {
        set { set(name: "hearthstone_log_path", value: newValue) }
        get { return get(name: "hearthstone_log_path") as? String ?? "/Applications/Hearthstone" }
    }
    static var hearthstoneLanguage: Language.Hearthstone? {
        set { set(name: "hearthstone_language", value: newValue?.rawValue) }
        get {
            guard let locale = get(name: "hearthstone_language") as? String else {
                return nil
            }
            return Language.Hearthstone(rawValue: locale)
        }
    }
    static var hsTrackerLanguage: Language.HSTracker? {
        set {
            if let locale = newValue {
                defaults?.set([locale.rawValue], forKey: "AppleLanguages")
            }
            set(name: "hstracker_language", value: newValue?.rawValue)
        }
        get {
            guard let locale = get(name: "hstracker_language") as? String else {
                return nil
            }
            return Language.HSTracker(rawValue: locale)
        }
    }
    static var showRarityColors: Bool {
        set { set(name: "rarity_colors", value: newValue) }
        get { return get(name: "rarity_colors") as? Bool ?? true }
    }
    /*static var promptNotes: Bool {
        set { set(name: "prompt_for_notes", value: newValue) }
        get { return get(name: "prompt_for_notes") as? Bool ?? false }
    }*/
    static var autoPositionTrackers: Bool {
        set { set(name: "auto_position_trackers", value: newValue) }
        get { return get(name: "auto_position_trackers") as? Bool ?? true }
    }
    static var hideAllTrackersWhenNotInGame: Bool {
        set { set(name: "hide_all_trackers_when_not_in_game", value: newValue) }
        get { return get(name: "hide_all_trackers_when_not_in_game") as? Bool ?? false }
    }
    static var hideAllWhenGameInBackground: Bool {
        set { set(name: "hide_all_trackers_when_game_in_background", value: newValue) }
        get { return get(name: "hide_all_trackers_when_game_in_background") as? Bool ?? false }
    }
    static var deckManagerPreferCards: Bool {
        set { set(name: "deckmanager_prefer_cards", value: newValue) }
        get { return get(name: "deckmanager_prefer_cards") as? Bool ?? true }
    }
    static var showFloatingCard: Bool {
        set { set(name: "show_floating_card", value: newValue) }
        get { return get(name: "show_floating_card") as? Bool ?? true }
    }
    static var floatingCardStyle: FloatingCardStyle {
        set { set(name: "floating_card_style", value: newValue.rawValue) }
        get {
            if let _style = get(name: "floating_card_style") as? String,
               let style = FloatingCardStyle(rawValue: _style) {
                return style
            }
            return .image
        }
    }

    static var showTopdeckchance: Bool {
        set { set(name: "show_topdeck_chance", value: newValue) }
        get { return get(name: "show_topdeck_chance") as? Bool ?? true }
    }
    static var windowsLocked: Bool {
        set { set(name: "window_locked", value: newValue) }
        get { return get(name: "window_locked") as? Bool ?? true }
    }
    static var preferGoldenCards: Bool {
        set { set(name: "prefer_golden_cards", value: newValue) }
        get { return get(name: "prefer_golden_cards") as? Bool ?? false }
    }
    static var autoDeckDetection: Bool {
        set { set(name: "auto_deck_detection", value: newValue) }
        get { return get(name: "auto_deck_detection") as? Bool ?? true }
    }
    static var showPlayerDrawChance: Bool {
        set { set(name: "player_draw_chance", value: newValue) }
        get { return get(name: "player_draw_chance") as? Bool ?? true }
    }
    static var showPlayerCardCount: Bool {
        set { set(name: "player_card_count", value: newValue) }
        get { return get(name: "player_card_count") as? Bool ?? true }
    }
    static var showOpponentCardCount: Bool {
        set { set(name: "opponent_card_count", value: newValue) }
        get { return get(name: "opponent_card_count") as? Bool ?? true }
    }
    static var showOpponentDrawChance: Bool {
        set { set(name: "opponent_draw_chance", value: newValue) }
        get { return get(name: "opponent_draw_chance") as? Bool ?? true }
    }
    static var showPlayerCthun: Bool {
        set { set(name: "player_cthun_frame", value: newValue) }
        get { return get(name: "player_cthun_frame") as? Bool ?? true }
    }
    static var showPlayerDeathrattle: Bool {
        set { set(name: "player_deathrattle_frame", value: newValue) }
        get { return get(name: "player_deathrattle_frame") as? Bool ?? true }
    }
    static var showPlayerSpell: Bool {
        set { set(name: "player_yogg_frame", value: newValue) }
        get { return get(name: "player_yogg_frame") as? Bool ?? true }
    }
    static var showPlayerGraveyard: Bool {
        set { set(name: "player_graveyard_frame", value: newValue) }
        get { return get(name: "player_graveyard_frame") as? Bool ?? true }
    }
    static var showPlayerGraveyardDetails: Bool {
        set { set(name: "player_graveyard_details_frame", value: newValue) }
        get { return get(name: "player_graveyard_details_frame") as? Bool ?? true }
    }
    static var showPlayerJadeCounter: Bool {
        set { set(name: "player_jade_frame", value: newValue) }
        get { return get(name: "player_jade_frame") as? Bool ?? true }
    }
    static var showOpponentCthun: Bool {
        set { set(name: "opponent_cthun_frame", value: newValue) }
        get { return get(name: "opponent_cthun_frame") as? Bool ?? true }
    }
    static var showOpponentSpell: Bool {
        set { set(name: "opponent_yogg_frame", value: newValue) }
        get { return get(name: "opponent_yogg_frame") as? Bool ?? true }
    }
    static var showOpponentDeathrattle: Bool {
        set { set(name: "opponent_deathrattle_frame", value: newValue) }
        get { return get(name: "opponent_deathrattle_frame") as? Bool ?? true }
    }
    static var showOpponentGraveyard: Bool {
        set { set(name: "opponent_graveyard_frame", value: newValue) }
        get { return get(name: "opponent_graveyard_frame") as? Bool ?? true }
    }
    static var showOpponentGraveyardDetails: Bool {
        set { set(name: "opponent_graveyard_details_frame", value: newValue) }
        get { return get(name: "opponent_graveyard_details_frame") as? Bool ?? true }
    }
    static var showOpponentJadeCounter: Bool {
        set { set(name: "opponent_jade_frame", value: newValue) }
        get { return get(name: "opponent_jade_frame") as? Bool ?? true }
    }
    static var removeCardsFromDeck: Bool {
        set { set(name: "remove_cards_from_deck", value: newValue) }
        get { return get(name: "remove_cards_from_deck") as? Bool ?? false }
    }
    static var highlightLastDrawn: Bool {
        set { set(name: "highlight_last_drawn", value: newValue) }
        get { return get(name: "highlight_last_drawn") as? Bool ?? true }
    }
    static var highlightCardsInHand: Bool {
        set { set(name: "highlight_cards_in_hand", value: newValue) }
        get { return get(name: "highlight_cards_in_hand") as? Bool ?? false }
    }
    static var highlightDiscarded: Bool {
        set { set(name: "highlight_discarded", value: newValue) }
        get { return get(name: "highlight_discarded") as? Bool ?? false }
    }
    static var showPlayerGet: Bool {
        set { set(name: "show_player_get", value: newValue) }
        get { return get(name: "show_player_get") as? Bool ?? false }
    }
    static var showOpponentCreated: Bool {
        set { set(name: "show_opponent_created", value: newValue) }
        get { return get(name: "show_opponent_created") as? Bool ?? true }
    }
    static var showPlayerTracker: Bool {
        set { set(name: "show_player_tracker", value: newValue) }
        get { return get(name: "show_player_tracker") as? Bool ?? true }
    }
    static var clearTrackersOnGameEnd: Bool {
        set { set(name: "clear_trackers_end", value: newValue) }
        get { return get(name: "clear_trackers_end") as? Bool ?? false }
    }
    static var showOpponentTracker: Bool {
        set { set(name: "show_opponent_tracker", value: newValue) }
        get { return get(name: "show_opponent_tracker") as? Bool ?? true }
    }
    static var showTimer: Bool {
        set { set(name: "show_timer", value: newValue) }
        get { return get(name: "show_timer") as? Bool ?? true }
    }
    
    static var timerHudFrame: NSRect? {
        set { set(name: "timer_hud_frame",
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: "timer_hud_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }
    
    static var showCardHuds: Bool {
        set { set(name: "show_card_huds", value: newValue) }
        get { return get(name: "show_card_huds") as? Bool ?? true }
    }
    static var showSecretHelper: Bool {
        set { set(name: "show_secret_helper", value: newValue) }
        get { return get(name: "show_secret_helper") as? Bool ?? true }
    }
    static var showArenaHelper: Bool {
        set { set(name: "show_arena_helper", value: newValue) }
        get { return get(name: "show_arena_helper") as? Bool ?? true }
    }
    static var showWinLossRatio: Bool {
        set { set(name: "show_win_loss_ratio", value: newValue) }
        get { return get(name: "show_win_loss_ratio") as? Bool ?? false }
    }
    static var playerInHandColor: NSColor {
        set { set(name: "player_in_hand_color", value: [
            newValue.redComponent,
            newValue.greenComponent,
            newValue.blueComponent])
        }
        get {
            if let hexColor = get(name: "player_in_hand_color") as? [CGFloat], hexColor.count == 3 {
                return NSColor(red: hexColor[0], green: hexColor[1], blue: hexColor[2], alpha: 1)
            }
            return NSColor(red: 0.678, green: 1, blue: 0.184, alpha: 1)
        }
    }
    static var showAppHealth: Bool {
        set { set(name: "show_apphealth", value: newValue) }
        get { return get(name: "show_apphealth") as? Bool ?? true }
    }

    static var playerTrackerFrame: NSRect? {
        set { set(name: "player_tracker_frame",
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: "player_tracker_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }

    static var opponentTrackerFrame: NSRect? {
        set { set(name: "opponent_tracker_frame",
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: "opponent_tracker_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }

    static var playerBoardDamage: Bool {
        set { set(name: "player_board_damage", value: newValue) }
        get { return get(name: "player_board_damage") as? Bool ?? true }
    }
    
    static var playerBoardDamageFrame: NSRect? {
        set { set(name: "player_board_damage_frame",
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: "player_board_damage_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }
    
    static var opponentBoardDamage: Bool {
        set { set(name: "opponent_board_damage", value: newValue) }
        get { return get(name: "opponent_board_damage") as? Bool ?? true }
    }
    
    static var opponentBoardDamageFrame: NSRect? {
        set { set(name: "opponent_board_damage_frame",
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: "opponent_board_damage_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }
    
    static var fatigueIndicator: Bool {
        set { set(name: "show_fatigue", value: newValue) }
        get { return get(name: "show_fatigue") as? Bool ?? true }
    }

    // MARK: - Notifications
    static var useToastNotification: Bool {
        set { set(name: "useToastNotification", value: newValue) }
        get { return get(name: "useToastNotification") as? Bool ?? true }
    }
    static var notifyGameStart: Bool {
        set { set(name: "notify_game_start", value: newValue) }
        get { return get(name: "notify_game_start") as? Bool ?? true }
    }
    static var notifyTurnStart: Bool {
        set { set(name: "notify_turn_start", value: newValue) }
        get { return get(name: "notify_turn_start") as? Bool ?? true }
    }
    static var notifyOpponentConcede: Bool {
        set { set(name: "notify_opponent_concede", value: newValue) }
        get { return get(name: "notify_opponent_concede") as? Bool ?? true }
    }
    static var flashOnDraw: Bool {
        set { set(name: "flash_draw", value: newValue) }
        get { return get(name: "flash_draw") as? Bool ?? true }
    }
    static var showOpponentClassInTracker: Bool {
        set { set(name: "show_opponent_class", value: newValue) }
        get { return get(name: "show_opponent_class") as? Bool ?? false }
    }
    static var showDeckNameInTracker: Bool {
        set { set(name: "show_deck_name", value: newValue) }
        get { return get(name: "show_deck_name") as? Bool ?? false }
    }

    // MARK: - Track-o-Bot
    static var trackobotUsername: String? {
        set { set(name: "trackobot_username", value: newValue) }
        get { return get(name: "trackobot_username") as? String }
    }
    static var trackobotToken: String? {
        set { set(name: "trackobot_token", value: newValue) }
        get { return get(name: "trackobot_token") as? String }
    }
    static var trackobotSynchronizeMatches: Bool {
        set { set(name: "trackobot_auto_synchronize_matches", value: newValue) }
        get { return get(name: "trackobot_auto_synchronize_matches") as? Bool ?? true }
    }

    // MARK: - HSReplay
    static var saveReplays: Bool {
        set { set(name: "save_replays", value: newValue) }
        get { return get(name: "save_replays") as? Bool ?? false }
    }
    static var hsReplayUploadToken: String? {
        set { set(name: "hsreplay_upload_token", value: newValue) }
        get { return get(name: "hsreplay_upload_token") as? String }
    }
    static var hsReplayUsername: String? {
        set { set(name: "hsreplay_username", value: newValue) }
        get { return get(name: "hsreplay_username") as? String }
    }
    static var hsReplayId: Int? {
        set { set(name: "hsreplay_id", value: newValue) }
        get { return get(name: "hsreplay_id") as? Int }
    }
    static var hsReplaySynchronizeMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_matches") as? Bool ?? true }
    }
    static var showHSReplayPushNotification: Bool {
        set { set(name: "hsreplay_show_push_notification", value: newValue) }
        get { return get(name: "hsreplay_show_push_notification") as? Bool ?? true }
    }
    static var hsReplayUploadRankedMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_ranked_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_ranked_matches") as? Bool ?? true }
    }
    static var hsReplayUploadCasualMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_casual_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_casual_matches") as? Bool ?? true }
    }
    static var hsReplayUploadArenaMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_arena_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_arena_matches") as? Bool ?? true }
    }
    static var hsReplayUploadBrawlMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_brawl_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_brawl_matches") as? Bool ?? true }
    }
    static var hsReplayUploadFriendlyMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_friendly_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_friendly_matches") as? Bool ?? true }
    }
    static var hsReplayUploadAdventureMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_adventure_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_adventure_matches") as? Bool ?? true }
    }
    static var hsReplayUploadSpectatorMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_spectator_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_spectator_matches") as? Bool ?? true }
    }

    static var theme: String {
        set { set(name: "theme", value: newValue) }
        get { return get(name: "theme") as? String ?? "dark" }
    }

    // MARK: - Paths / utils
    static var logSeverity: LogSeverity {
        set { set(name: "file_logger_severity", value: newValue.rawValue) }
        get {
            if let rawSeverity = get(name: "file_logger_severity") as? Int,
                let severity = LogSeverity(rawValue: rawSeverity) {
                return severity
            }
            return .verbose
        }
    }

    static var isCyrillicLanguage: Bool {
        guard let language = hearthstoneLanguage else { return false }

        return language == .ruRU
    }

    static var isAsianLanguage: Bool {
        guard let language = hearthstoneLanguage else { return false }

        let asianLanguages: [Language.Hearthstone] = [.zhCN, .zhTW, .jaJP, .thTH, .koKR]
        return asianLanguages.contains(language)
    }

    // MARK: - HearthAssets / HearthMirror
    static var useHearthstoneAssets: Bool {
        set { set(name: "use_hearthstone_assets", value: newValue) }
        get { return get(name: "use_hearthstone_assets") as? Bool ?? false }
    }
}

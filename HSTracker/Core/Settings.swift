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

    private let defaults: UserDefaults? = {
        return UserDefaults.standard
    }()

    private func set(name: String, value: Any?) {
        defaults?.set(value, forKey: name)
        defaults?.synchronize()

        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: value)
    }

    private func get(name: String) -> Any? {
        if let returnValue = defaults?.object(forKey: name) {
            return returnValue as Any?
        }
        return nil
    }

    var canJoinFullscreen: Bool {
        set { set(name: "can_join_fullscreen", value: newValue) }
        get { return get(name: "can_join_fullscreen") as? Bool ?? true }
    }
    var quitWhenHearthstoneCloses: Bool {
        set { set(name: "quit_when_hs_closes", value: newValue) }
        get { return get(name: "quit_when_hs_closes") as? Bool ?? false }
    }
    var deckManagerZoom: Double {
        set { set(name: "deck_manager_zoom", value: newValue) }
        get { return get(name: "deck_manager_zoom") as? Double ?? 100.0 }
    }
    var trackerOpacity: Double {
        set { set(name: "tracker_opacity", value: newValue) }
        get { return get(name: "tracker_opacity") as? Double ?? 0.0 }
    }
    var activeDeck: String? {
        set { set(name: "active_deck", value: newValue) }
        get { return get(name: "active_deck") as? String }
    }
    var cardSize: CardSize {
        set { set(name: "card_size", value: newValue.rawValue) }
        get { return CardSize(rawValue: get(name: "card_size") as? Int
            ?? CardSize.big.rawValue) ?? .big }
    }
    var deckSortCriteria: String {
        set { set(name: "deck_sort_criteria", value: newValue) }
        get { return get(name: "deck_sort_criteria") as? String ?? "name" }
    }
    var deckSortOrder: String {
        set { set(name: "deck_sort_order", value: newValue) }
        get { return get(name: "deck_sort_order") as? String ?? "ascending" }
    }
    var autoArchiveArenaDeck: Bool {
        set { set(name: "archive_arena_deck", value: newValue) }
        get { return get(name: "archive_arena_deck") as? Bool ?? true }
    }
    var hearthstoneLogPath: String {
        set { set(name: "hearthstone_log_path", value: newValue) }
        get { return get(name: "hearthstone_log_path") as? String ?? "/Applications/Hearthstone" }
    }
    var hearthstoneLanguage: String? {
        set { set(name: "hearthstone_language", value: newValue) }
        get { return get(name: "hearthstone_language") as? String }
    }
    var hsTrackerLanguage: String? {

        set {
            if let locale = newValue {
                defaults?.set([locale], forKey: "AppleLanguages")
            }
            set(name: "hstracker_language", value: newValue)
        }
        get { return get(name: "hstracker_language") as? String }
    }
    var showRarityColors: Bool {
        set { set(name: "rarity_colors", value: newValue) }
        get { return get(name: "rarity_colors") as? Bool ?? true }
    }
    var promptNotes: Bool {
        set { set(name: "prompt_for_notes", value: newValue) }
        get { return get(name: "prompt_for_notes") as? Bool ?? false }
    }
    var autoPositionTrackers: Bool {
        set { set(name: "auto_position_trackers", value: newValue) }
        get { return get(name: "auto_position_trackers") as? Bool ?? false }
    }
    var deckManagerPreferCards: Bool {
        set { set(name: "deckmanager_prefer_cards", value: newValue) }
        get { return get(name: "deckmanager_prefer_cards") as? Bool ?? true }
    }
    var showFloatingCard: Bool {
        set { set(name: "show_floating_card", value: newValue) }
        get { return get(name: "show_floating_card") as? Bool ?? true }
    }
    var showTopdeckchance: Bool {
        set { set(name: "show_topdeck_chance", value: newValue) }
        get { return get(name: "show_topdeck_chance") as? Bool ?? true }
    }
    var windowsLocked: Bool {
        set { set(name: "window_locked", value: newValue) }
        get { return get(name: "window_locked") as? Bool ?? true }
    }

    var showPlayerDrawChance: Bool {
        set { set(name: "player_draw_chance", value: newValue) }
        get { return get(name: "player_draw_chance") as? Bool ?? true }
    }
    var showPlayerCardCount: Bool {
        set { set(name: "player_card_count", value: newValue) }
        get { return get(name: "player_card_count") as? Bool ?? true }
    }
    var showOpponentCardCount: Bool {
        set { set(name: "opponent_card_count", value: newValue) }
        get { return get(name: "opponent_card_count") as? Bool ?? true }
    }
    var showOpponentDrawChance: Bool {
        set { set(name: "opponent_draw_chance", value: newValue) }
        get { return get(name: "opponent_draw_chance") as? Bool ?? true }
    }
    var showPlayerCthun: Bool {
        set { set(name: "player_cthun_frame", value: newValue) }
        get { return get(name: "player_cthun_frame") as? Bool ?? true }
    }
    var showPlayerDeathrattle: Bool {
        set { set(name: "player_deathrattle_frame", value: newValue) }
        get { return get(name: "player_deathrattle_frame") as? Bool ?? true }
    }
    var showPlayerSpell: Bool {
        set { set(name: "player_yogg_frame", value: newValue) }
        get { return get(name: "player_yogg_frame") as? Bool ?? true }
    }
    var showPlayerGraveyard: Bool {
        set { set(name: "player_graveyard_frame", value: newValue) }
        get { return get(name: "player_graveyard_frame") as? Bool ?? true }
    }
    var showPlayerGraveyardDetails: Bool {
        set { set(name: "player_graveyard_details_frame", value: newValue) }
        get { return get(name: "player_graveyard_details_frame") as? Bool ?? true }
    }
    var showPlayerJadeCounter: Bool {
        set { set(name: "player_jade_frame", value: newValue) }
        get { return get(name: "player_jade_frame") as? Bool ?? true }
    }
    var showOpponentCthun: Bool {
        set { set(name: "opponent_cthun_frame", value: newValue) }
        get { return get(name: "opponent_cthun_frame") as? Bool ?? true }
    }
    var showOpponentSpell: Bool {
        set { set(name: "opponent_yogg_frame", value: newValue) }
        get { return get(name: "opponent_yogg_frame") as? Bool ?? true }
    }
    var showOpponentDeathrattle: Bool {
        set { set(name: "opponent_deathrattle_frame", value: newValue) }
        get { return get(name: "opponent_deathrattle_frame") as? Bool ?? true }
    }
    var showOpponentGraveyard: Bool {
        set { set(name: "opponent_graveyard_frame", value: newValue) }
        get { return get(name: "opponent_graveyard_frame") as? Bool ?? true }
    }
    var showOpponentGraveyardDetails: Bool {
        set { set(name: "opponent_graveyard_details_frame", value: newValue) }
        get { return get(name: "opponent_graveyard_details_frame") as? Bool ?? true }
    }
    var showOpponentJadeCounter: Bool {
        set { set(name: "opponent_jade_frame", value: newValue) }
        get { return get(name: "opponent_jade_frame") as? Bool ?? true }
    }
    var removeCardsFromDeck: Bool {
        set { set(name: "remove_cards_from_deck", value: newValue) }
        get { return get(name: "remove_cards_from_deck") as? Bool ?? false }
    }
    var highlightLastDrawn: Bool {
        set { set(name: "highlight_last_drawn", value: newValue) }
        get { return get(name: "highlight_last_drawn") as? Bool ?? true }
    }
    var highlightCardsInHand: Bool {
        set { set(name: "highlight_cards_in_hand", value: newValue) }
        get { return get(name: "highlight_cards_in_hand") as? Bool ?? false }
    }
    var highlightDiscarded: Bool {
        set { set(name: "highlight_discarded", value: newValue) }
        get { return get(name: "highlight_discarded") as? Bool ?? false }
    }
    var showPlayerGet: Bool {
        set { set(name: "show_player_get", value: newValue) }
        get { return get(name: "show_player_get") as? Bool ?? false }
    }
    var showOpponentCreated: Bool {
        set { set(name: "show_opponent_created", value: newValue) }
        get { return get(name: "show_opponent_created") as? Bool ?? true }
    }
    var showPlayerTracker: Bool {
        set { set(name: "show_player_tracker", value: newValue) }
        get { return get(name: "show_player_tracker") as? Bool ?? true }
    }
    var clearTrackersOnGameEnd: Bool {
        set { set(name: "clear_trackers_end", value: newValue) }
        get { return get(name: "clear_trackers_end") as? Bool ?? false }
    }
    var showOpponentTracker: Bool {
        set { set(name: "show_opponent_tracker", value: newValue) }
        get { return get(name: "show_opponent_tracker") as? Bool ?? true }
    }
    var showTimer: Bool {
        set { set(name: "show_timer", value: newValue) }
        get { return get(name: "show_timer") as? Bool ?? true }
    }
    var showCardHuds: Bool {
        set { set(name: "show_card_huds", value: newValue) }
        get { return get(name: "show_card_huds") as? Bool ?? true }
    }
    var showSecretHelper: Bool {
        set { set(name: "show_secret_helper", value: newValue) }
        get { return get(name: "show_secret_helper") as? Bool ?? true }
    }
    var showWinLossRatio: Bool {
        set { set(name: "show_win_loss_ratio", value: newValue) }
        get { return get(name: "show_win_loss_ratio") as? Bool ?? false }
    }
    var playerInHandColor: NSColor {
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
    var showAppHealth: Bool {
        set { set(name: "show_apphealth", value: newValue) }
        get { return get(name: "show_apphealth") as? Bool ?? true }
    }

    var playerTrackerFrame: NSRect? {
        set { set(name: "player_tracker_frame",
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: "player_tracker_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }

    var opponentTrackerFrame: NSRect? {
        set { set(name: "opponent_tracker_frame",
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: "opponent_tracker_frame") as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }

    var playerBoardDamage: Bool {
        set { set(name: "player_board_damage", value: newValue) }
        get { return get(name: "player_board_damage") as? Bool ?? true }
    }
    var opponentBoardDamage: Bool {
        set { set(name: "opponent_board_damage", value: newValue) }
        get { return get(name: "opponent_board_damage") as? Bool ?? true }
    }
    var fatigueIndicator: Bool {
        set { set(name: "show_fatigue", value: newValue) }
        get { return get(name: "show_fatigue") as? Bool ?? true }
    }

    // MARK: - Notifications
    var notifyGameStart: Bool {
        set { set(name: "notify_game_start", value: newValue) }
        get { return get(name: "notify_game_start") as? Bool ?? true }
    }
    var notifyTurnStart: Bool {
        set { set(name: "notify_turn_start", value: newValue) }
        get { return get(name: "notify_turn_start") as? Bool ?? true }
    }
    var notifyOpponentConcede: Bool {
        set { set(name: "notify_opponent_concede", value: newValue) }
        get { return get(name: "notify_opponent_concede") as? Bool ?? true }
    }
    var flashOnDraw: Bool {
        set { set(name: "flash_draw", value: newValue) }
        get { return get(name: "flash_draw") as? Bool ?? true }
    }
    var showOpponentClassInTracker: Bool {
        set { set(name: "show_opponent_class", value: newValue) }
        get { return get(name: "show_opponent_class") as? Bool ?? false }
    }
    var showDeckNameInTracker: Bool {
        set { set(name: "show_deck_name", value: newValue) }
        get { return get(name: "show_deck_name") as? Bool ?? false }
    }

    // MARK: - Track-o-Bot
    var trackobotUsername: String? {
        set { set(name: "trackobot_username", value: newValue) }
        get { return get(name: "trackobot_username") as? String }
    }
    var trackobotToken: String? {
        set { set(name: "trackobot_token", value: newValue) }
        get { return get(name: "trackobot_token") as? String }
    }
    var trackobotSynchronizeMatches: Bool {
        set { set(name: "trackobot_auto_synchronize_matches", value: newValue) }
        get { return get(name: "trackobot_auto_synchronize_matches") as? Bool ?? true }
    }

    // MARK: - HSReplay
    var saveReplays: Bool {
        set { set(name: "save_replays", value: newValue) }
        get { return get(name: "save_replays") as? Bool ?? false }
    }
    var hsReplayUploadToken: String? {
        set { set(name: "hsreplay_upload_token", value: newValue) }
        get { return get(name: "hsreplay_upload_token") as? String }
    }
    var hsReplayUsername: String? {
        set { set(name: "hsreplay_username", value: newValue) }
        get { return get(name: "hsreplay_username") as? String }
    }
    var hsReplayId: Int? {
        set { set(name: "hsreplay_id", value: newValue) }
        get { return get(name: "hsreplay_id") as? Int }
    }
    var hsReplaySynchronizeMatches: Bool {
        set { set(name: "hsreplay_auto_synchronize_matches", value: newValue) }
        get { return get(name: "hsreplay_auto_synchronize_matches") as? Bool ?? true }
    }
    var showHSReplayPushNotification: Bool {
        set { set(name: "hsreplay_show_push_notification", value: newValue) }
        get { return get(name: "hsreplay_show_push_notification") as? Bool ?? true }
    }

    // MARK: - Hearthstats
    var hearthstatsLogin: String? {
        set { set(name: "hearthstats_login", value: newValue) }
        get { return get(name: "hearthstats_login") as? String }
    }
    var hearthstatsToken: String? {
        set { set(name: "hearthstats_token", value: newValue) }
        get { return get(name: "hearthstats_token") as? String }
    }
    var hearthstatsLastDecksSync: Double {
        set { set(name: "hearthstats_last_decks_sync", value: newValue) }
        get { return get(name: "hearthstats_last_decks_sync") as? Double
            ?? Date.distantPast.timeIntervalSince1970 }
    }
    var hearthstatsLastMatchesSync: Double {
        set { set(name: "hearthstats_last_matches_sync", value: newValue) }
        get { return get(name: "hearthstats_last_matches_sync") as? Double ?? 0.0 }
    }
    var hearthstatsAutoSynchronize: Bool {
        set { set(name: "hearthstats_auto_synchronize_decks", value: newValue) }
        get { return get(name: "hearthstats_auto_synchronize_decks") as? Bool ?? false }
    }
    var hearthstatsSynchronizeMatches: Bool {
        set { set(name: "hearthstats_auto_synchronize_matches", value: newValue) }
        get { return get(name: "hearthstats_auto_synchronize_matches") as? Bool ?? false }
    }

    var theme: String {
        set { set(name: "theme", value: newValue) }
        get { return get(name: "theme") as? String ?? "dark" }
    }

    // MARK: - Paths / utils
    var logSeverity: LogSeverity {
        set { set(name: "file_logger_severity", value: newValue.rawValue) }
        get {
            if let rawSeverity = get(name: "file_logger_severity") as? Int,
                let severity = LogSeverity(rawValue: rawSeverity) {
                return severity
            }
            return .verbose
        }
    }

    var isCyrillicLanguage: Bool {
        guard let language = hearthstoneLanguage else { return false }

        return language == "ruRU"
    }

    var isAsianLanguage: Bool {
        guard let language = hearthstoneLanguage else { return false }

        return language.match("^(zh|ko|ja|th)")
    }

    // MARK: - Updates
    var releaseChannel: ReleaseChannel {
        set { set(name: "release_channel", value: newValue.rawValue) }
        get {
            if let rawChannel = get(name: "release_channel") as? Int,
                let channel = ReleaseChannel(rawValue: rawChannel) {
                return channel
            }
            return .stable
        }
    }
    var automaticallyDownloadsUpdates: Bool {
        set { set(name: "automatically_downloads_updates", value: newValue) }
        get { return get(name: "automatically_downloads_updates") as? Bool ?? true }
    }
}

//
//  Settings.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

final class Settings {

    static var fullGameLog: Bool = false

    static func validated() -> Bool {
        // fix hearthstone log folder path
        let hs_path = Settings.hearthstonePath
        let suffix = "/Logs"
        if hs_path.hasSuffix(suffix) {
            Settings.hearthstonePath = hs_path.substring(from: 0, length: hs_path.count-suffix.count)
        }
        return CoreManager.validatedHearthstonePath()
            && hearthstoneLanguage != nil && hsTrackerLanguage != nil
    }

    private static let defaults: UserDefaults = {
        return UserDefaults.standard
    }()

    private static func set(name: String, value: Any?) {
        defaults.set(value, forKey: name)
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: value)
    }

    private static func get(name: String) -> Any? {
        if let returnValue = defaults.object(forKey: name) {
            return returnValue as Any?
        }
        return nil
    }
	
	static var showMemoryReadingWarning: Bool {
		set { set(name: Settings.show_memory_reading_warning, value: newValue) }
		get { return get(name: Settings.show_memory_reading_warning) as? Bool ?? true }
	}
    static var canJoinFullscreen: Bool {
        set { set(name: Settings.can_join_fullscreen, value: newValue) }
        get { return get(name: Settings.can_join_fullscreen) as? Bool ?? true }
    }
    static var quitWhenHearthstoneCloses: Bool {
        set { set(name: Settings.quit_when_hs_closes, value: newValue) }
        get { return get(name: Settings.quit_when_hs_closes) as? Bool ?? false }
    }
    static var deckManagerZoom: Double {
        set { set(name: Settings.deck_manager_zoom, value: newValue) }
        get { return get(name: Settings.deck_manager_zoom) as? Double ?? 100.0 }
    }
    static var trackerOpacity: Double {
        set { set(name: Settings.tracker_opacity, value: newValue) }
        get { return get(name: Settings.tracker_opacity) as? Double ?? 0.0 }
    }
    static var activeDeck: String? {
        set { set(name: Settings.active_deck, value: newValue) }
        get { return get(name: Settings.active_deck) as? String }
    }
    static var cardSize: CardSize {
        set { set(name: Settings.card_size, value: newValue.rawValue) }
        get { return CardSize(rawValue: get(name: Settings.card_size) as? Int
            ?? CardSize.big.rawValue) ?? .big }
    }
    static var deckSortCriteria: String {
        set { set(name: Settings.deck_sort_criteria, value: newValue) }
        get { return get(name: Settings.deck_sort_criteria) as? String ?? "name" }
    }
    static var deckSortOrder: String {
        set { set(name: Settings.deck_sort_order, value: newValue) }
        get { return get(name: Settings.deck_sort_order) as? String ?? "ascending" }
    }
    static var autoArchiveArenaDeck: Bool {
        set { set(name: Settings.archive_arena_deck, value: newValue) }
        get { return get(name: Settings.archive_arena_deck) as? Bool ?? true }
    }
    static var hearthstonePath: String {
        set { set(name: Settings.hearthstone_log_path, value: newValue) }
        get { return get(name: Settings.hearthstone_log_path) as? String ?? "/Applications/Hearthstone" }
    }
    static var hearthstoneLanguage: Language.Hearthstone? {
        set { set(name: Settings.hearthstone_language, value: newValue?.rawValue) }
        get {
            guard let locale = get(name: Settings.hearthstone_language) as? String else {
                return nil
            }
            return Language.Hearthstone(rawValue: locale)
        }
    }
    static var hsTrackerLanguage: Language.HSTracker? {
        set {
            if let locale = newValue {
                defaults.set([locale.rawValue], forKey: "AppleLanguages")
            }
            set(name: Settings.hstracker_language, value: newValue?.rawValue)
        }
        get {
            guard let locale = get(name: Settings.hstracker_language) as? String else {
                return nil
            }
            return Language.HSTracker(rawValue: locale)
        }
    }
    static var showRarityColors: Bool {
        set { set(name: Settings.rarity_colors, value: newValue) }
        get { return get(name: Settings.rarity_colors) as? Bool ?? true }
    }
    /*static var promptNotes: Bool {
        set { set(name: Settings.prompt_for_notes, value: newValue) }
        get { return get(name: Settings.prompt_for_notes) as? Bool ?? false }
    }*/
    static var autoPositionTrackers: Bool {
        set { set(name: Settings.auto_position_trackers, value: newValue) }
        get { return get(name: Settings.auto_position_trackers) as? Bool ?? true }
    }
    static var hideAllTrackersWhenNotInGame: Bool {
        set { set(name: Settings.hide_all_trackers_when_not_in_game, value: newValue) }
        get { return get(name: Settings.hide_all_trackers_when_not_in_game) as? Bool ?? false }
    }
    static var hideAllWhenGameInBackground: Bool {
        set { set(name: Settings.hide_all_trackers_when_game_in_background, value: newValue) }
        get { return get(name: Settings.hide_all_trackers_when_game_in_background) as? Bool ?? false }
    }
    static var deckManagerPreferCards: Bool {
        set { set(name: Settings.deckmanager_prefer_cards, value: newValue) }
        get { return get(name: Settings.deckmanager_prefer_cards) as? Bool ?? true }
    }
    static var showFloatingCard: Bool {
        set { set(name: Settings.show_floating_card, value: newValue) }
        get { return get(name: Settings.show_floating_card) as? Bool ?? true }
    }
    static var floatingCardStyle: FloatingCardStyle {
        set { set(name: Settings.floating_card_style, value: newValue.rawValue) }
        get {
            if let _style = get(name: Settings.floating_card_style) as? String,
               let style = FloatingCardStyle(rawValue: _style) {
                return style
            }
            return .image
        }
    }
    
    static var dontTrackWhileSpectating: Bool {
        set { set(name: Settings.disable_tracking_in_spectator_mode, value: newValue) }
        get { return get(name: Settings.disable_tracking_in_spectator_mode) as? Bool ?? true }
    }
    static var showTopdeckchance: Bool {
        set { set(name: Settings.show_topdeck_chance, value: newValue) }
        get { return get(name: Settings.show_topdeck_chance) as? Bool ?? true }
    }
    static var windowsLocked: Bool {
        set { set(name: Settings.window_locked, value: newValue) }
        get { return get(name: Settings.window_locked) as? Bool ?? true }
    }
    static var preferGoldenCards: Bool {
        set { set(name: Settings.prefer_golden_cards, value: newValue) }
        get { return get(name: Settings.prefer_golden_cards) as? Bool ?? false }
    }
    static var autoDeckDetection: Bool {
        set { set(name: Settings.auto_deck_detection, value: newValue) }
        get { return get(name: Settings.auto_deck_detection) as? Bool ?? true }
    }
    static var showPlayerDrawChance: Bool {
        set { set(name: Settings.player_draw_chance, value: newValue) }
        get { return get(name: Settings.player_draw_chance) as? Bool ?? true }
    }
    static var showPlayerCardCount: Bool {
        set { set(name: Settings.player_card_count, value: newValue) }
        get { return get(name: Settings.player_card_count) as? Bool ?? true }
    }
    static var showOpponentCardCount: Bool {
        set { set(name: Settings.opponent_card_count, value: newValue) }
        get { return get(name: Settings.opponent_card_count) as? Bool ?? true }
    }
    static var showOpponentDrawChance: Bool {
        set { set(name: Settings.opponent_draw_chance, value: newValue) }
        get { return get(name: Settings.opponent_draw_chance) as? Bool ?? true }
    }
    static var showPlayerCthun: Bool {
        set { set(name: Settings.player_cthun_frame, value: newValue) }
        get { return get(name: Settings.player_cthun_frame) as? Bool ?? true }
    }
    static var showPlayerDeathrattle: Bool {
        set { set(name: Settings.player_deathrattle_frame, value: newValue) }
        get { return get(name: Settings.player_deathrattle_frame) as? Bool ?? true }
    }
    static var showPlayerSpell: Bool {
        set { set(name: Settings.player_yogg_frame, value: newValue) }
        get { return get(name: Settings.player_yogg_frame) as? Bool ?? true }
    }
    static var showPlayerGraveyard: Bool {
        set { set(name: Settings.player_graveyard_frame, value: newValue) }
        get { return get(name: Settings.player_graveyard_frame) as? Bool ?? true }
    }
    static var showPlayerGraveyardDetails: Bool {
        set { set(name: Settings.player_graveyard_details_frame, value: newValue) }
        get { return get(name: Settings.player_graveyard_details_frame) as? Bool ?? true }
    }
    static var showPlayerJadeCounter: Bool {
        set { set(name: Settings.player_jade_frame, value: newValue) }
        get { return get(name: Settings.player_jade_frame) as? Bool ?? true }
    }
    static var showOpponentCthun: Bool {
        set { set(name: Settings.opponent_cthun_frame, value: newValue) }
        get { return get(name: Settings.opponent_cthun_frame) as? Bool ?? true }
    }
    static var showOpponentSpell: Bool {
        set { set(name: Settings.opponent_yogg_frame, value: newValue) }
        get { return get(name: Settings.opponent_yogg_frame) as? Bool ?? true }
    }
    static var showOpponentDeathrattle: Bool {
        set { set(name: Settings.opponent_deathrattle_frame, value: newValue) }
        get { return get(name: Settings.opponent_deathrattle_frame) as? Bool ?? true }
    }
    static var showOpponentGraveyard: Bool {
        set { set(name: Settings.opponent_graveyard_frame, value: newValue) }
        get { return get(name: Settings.opponent_graveyard_frame) as? Bool ?? true }
    }
    static var showOpponentGraveyardDetails: Bool {
        set { set(name: Settings.opponent_graveyard_details_frame, value: newValue) }
        get { return get(name: Settings.opponent_graveyard_details_frame) as? Bool ?? true }
    }
    static var showOpponentJadeCounter: Bool {
        set { set(name: Settings.opponent_jade_frame, value: newValue) }
        get { return get(name: Settings.opponent_jade_frame) as? Bool ?? true }
    }
    static var removeCardsFromDeck: Bool {
        set { set(name: Settings.remove_cards_from_deck, value: newValue) }
        get { return get(name: Settings.remove_cards_from_deck) as? Bool ?? false }
    }
    static var highlightLastDrawn: Bool {
        set { set(name: Settings.highlight_last_drawn, value: newValue) }
        get { return get(name: Settings.highlight_last_drawn) as? Bool ?? true }
    }
    static var highlightCardsInHand: Bool {
        set { set(name: Settings.highlight_cards_in_hand, value: newValue) }
        get { return get(name: Settings.highlight_cards_in_hand) as? Bool ?? false }
    }
    static var highlightDiscarded: Bool {
        set { set(name: Settings.highlight_discarded, value: newValue) }
        get { return get(name: Settings.highlight_discarded) as? Bool ?? false }
    }
    static var showPlayerGet: Bool {
        set { set(name: Settings.show_player_get, value: newValue) }
        get { return get(name: Settings.show_player_get) as? Bool ?? false }
    }
    static var showOpponentCreated: Bool {
        set { set(name: Settings.show_opponent_created, value: newValue) }
        get { return get(name: Settings.show_opponent_created) as? Bool ?? true }
    }
    static var showPlayerTracker: Bool {
        set { set(name: Settings.show_player_tracker, value: newValue) }
        get { return get(name: Settings.show_player_tracker) as? Bool ?? true }
    }
    static var clearTrackersOnGameEnd: Bool {
        set { set(name: Settings.clear_trackers_end, value: newValue) }
        get { return get(name: Settings.clear_trackers_end) as? Bool ?? false }
    }
    static var showOpponentTracker: Bool {
        set { set(name: Settings.show_opponent_tracker, value: newValue) }
        get { return get(name: Settings.show_opponent_tracker) as? Bool ?? true }
    }
    static var showTimer: Bool {
        set { set(name: Settings.show_timer, value: newValue) }
        get { return get(name: Settings.show_timer) as? Bool ?? true }
    }
    
    static var timerHudFrame: NSRect? {
        set { set(name: Settings.timer_hud_frame,
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: Settings.timer_hud_frame) as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }
    
    static var showCardHuds: Bool {
        set { set(name: Settings.show_card_huds, value: newValue) }
        get { return get(name: Settings.show_card_huds) as? Bool ?? true }
    }
    static var showSecretHelper: Bool {
        set { set(name: Settings.show_secret_helper, value: newValue) }
        get { return get(name: Settings.show_secret_helper) as? Bool ?? true }
    }
    static var showArenaHelper: Bool {
        set { set(name: Settings.show_arena_helper, value: newValue) }
        get { return get(name: Settings.show_arena_helper) as? Bool ?? true }
    }
    static var showWinLossRatio: Bool {
        set { set(name: Settings.show_win_loss_ratio, value: newValue) }
        get { return get(name: Settings.show_win_loss_ratio) as? Bool ?? false }
    }
    static var playerInHandColor: NSColor {
        set { set(name: Settings.player_in_hand_color, value: [
            newValue.redComponent,
            newValue.greenComponent,
            newValue.blueComponent])
        }
        get {
            if let hexColor = get(name: Settings.player_in_hand_color) as? [CGFloat], hexColor.count == 3 {
                return NSColor(red: hexColor[0], green: hexColor[1], blue: hexColor[2], alpha: 1)
            }
            return NSColor(red: 0.678, green: 1, blue: 0.184, alpha: 1)
        }
    }
    static var showAppHealth: Bool {
        set { set(name: Settings.show_apphealth, value: newValue) }
        get { return get(name: Settings.show_apphealth) as? Bool ?? true }
    }

    static var playerTrackerFrame: NSRect? {
        set { set(name: Settings.player_tracker_frame,
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: Settings.player_tracker_frame) as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }

    static var opponentTrackerFrame: NSRect? {
        set { set(name: Settings.opponent_tracker_frame,
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: Settings.opponent_tracker_frame) as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }

    static var playerBoardDamage: Bool {
        set { set(name: Settings.player_board_damage, value: newValue) }
        get { return get(name: Settings.player_board_damage) as? Bool ?? true }
    }
    
    static var playerBoardDamageFrame: NSRect? {
        set { set(name: Settings.player_board_damage_frame,
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: Settings.player_board_damage_frame) as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }
    
    static var opponentBoardDamage: Bool {
        set { set(name: Settings.opponent_board_damage, value: newValue) }
        get { return get(name: Settings.opponent_board_damage) as? Bool ?? true }
    }
    
    static var opponentBoardDamageFrame: NSRect? {
        set { set(name: Settings.opponent_board_damage_frame,
                  value: newValue == nil ? nil : NSStringFromRect(newValue!)) }
        get {
            if let stringRect = get(name: Settings.opponent_board_damage_frame) as? String {
                return NSRectFromString(stringRect)
            }
            return nil
        }
    }
    
    static var fatigueIndicator: Bool {
        set { set(name: Settings.show_fatigue, value: newValue) }
        get { return get(name: Settings.show_fatigue) as? Bool ?? true }
    }

    // MARK: - Notifications
    static var useToastNotification: Bool {
        set { set(name: Settings.use_toast_notification, value: newValue) }
        get { return get(name: Settings.use_toast_notification) as? Bool ?? true }
    }
    static var notifyGameStart: Bool {
        set { set(name: Settings.notify_game_start, value: newValue) }
        get { return get(name: Settings.notify_game_start) as? Bool ?? true }
    }
    static var notifyTurnStart: Bool {
        set { set(name: Settings.notify_turn_start, value: newValue) }
        get { return get(name: Settings.notify_turn_start) as? Bool ?? true }
    }
    static var notifyOpponentConcede: Bool {
        set { set(name: Settings.notify_opponent_concede, value: newValue) }
        get { return get(name: Settings.notify_opponent_concede) as? Bool ?? true }
    }
    static var flashOnDraw: Bool {
        set { set(name: Settings.flash_draw, value: newValue) }
        get { return get(name: Settings.flash_draw) as? Bool ?? true }
    }
    static var showOpponentClassInTracker: Bool {
        set { set(name: Settings.show_opponent_class, value: newValue) }
        get { return get(name: Settings.show_opponent_class) as? Bool ?? false }
    }
    static var preventOpponentNameCovering: Bool {
        set { set(name: Settings.prevent_opponent_name_covering, value: newValue) }
        get { return get(name: Settings.prevent_opponent_name_covering) as? Bool ?? false }
    }
    static var showDeckNameInTracker: Bool {
        set { set(name: Settings.show_deck_name, value: newValue) }
        get { return get(name: Settings.show_deck_name) as? Bool ?? false }
    }

    // MARK: - Track-o-Bot
    static var trackobotUsername: String? {
        set { set(name: Settings.trackobot_username, value: newValue) }
        get { return get(name: Settings.trackobot_username) as? String }
    }
    static var trackobotToken: String? {
        set { set(name: Settings.trackobot_token, value: newValue) }
        get { return get(name: Settings.trackobot_token) as? String }
    }
    static var trackobotSynchronizeMatches: Bool {
        set { set(name: Settings.trackobot_auto_synchronize_matches, value: newValue) }
        get { return get(name: Settings.trackobot_auto_synchronize_matches) as? Bool ?? true }
    }

    // MARK: - HSReplay
    static var saveReplays: Bool {
        set { set(name: Settings.save_replays, value: newValue) }
        get { return get(name: Settings.save_replays) as? Bool ?? false }
    }
    static var hsReplayUploadToken: String? {
        set { set(name: Settings.hsreplay_upload_token, value: newValue) }
        get { return get(name: Settings.hsreplay_upload_token) as? String }
    }
    static var hsReplayUsername: String? {
        set { set(name: Settings.hsreplay_username, value: newValue) }
        get { return get(name: Settings.hsreplay_username) as? String }
    }
    static var hsReplayId: Int? {
        set { set(name: Settings.hsreplay_id, value: newValue) }
        get { return get(name: Settings.hsreplay_id) as? Int }
    }
    static var hsReplaySynchronizeMatches: Bool {
        set { set(name: Settings.hsreplay_auto_synchronize_matches, value: newValue) }
        get { return get(name: Settings.hsreplay_auto_synchronize_matches) as? Bool ?? true }
    }
    static var showHSReplayPushNotification: Bool {
        set { set(name: Settings.hsreplay_show_push_notification, value: newValue) }
        get { return get(name: Settings.hsreplay_show_push_notification) as? Bool ?? true }
    }
    static var hsReplayUploadRankedMatches: Bool {
        set { set(name: Settings.hsreplay_auto_synchronize_ranked_matches, value: newValue) }
        get { return get(name: Settings.hsreplay_auto_synchronize_ranked_matches) as? Bool ?? true }
    }
    static var hsReplayUploadCasualMatches: Bool {
        set { set(name: Settings.hsreplay_auto_synchronize_casual_matches, value: newValue) }
        get { return get(name: Settings.hsreplay_auto_synchronize_casual_matches) as? Bool ?? true }
    }
    static var hsReplayUploadArenaMatches: Bool {
        set { set(name: Settings.hsreplay_auto_synchronize_arena_matches, value: newValue) }
        get { return get(name: Settings.hsreplay_auto_synchronize_arena_matches) as? Bool ?? true }
    }
    static var hsReplayUploadBrawlMatches: Bool {
        set { set(name: Settings.hsreplay_auto_synchronize_brawl_matches, value: newValue) }
        get { return get(name: Settings.hsreplay_auto_synchronize_brawl_matches) as? Bool ?? true }
    }
    static var hsReplayUploadFriendlyMatches: Bool {
        set { set(name: Settings.hsreplay_auto_synchronize_friendly_matches, value: newValue) }
        get { return get(name: Settings.hsreplay_auto_synchronize_friendly_matches) as? Bool ?? true }
    }
    static var hsReplayUploadAdventureMatches: Bool {
        set { set(name: Settings.hsreplay_auto_synchronize_adventure_matches, value: newValue) }
        get { return get(name: Settings.hsreplay_auto_synchronize_adventure_matches) as? Bool ?? true }
    }
    static var hsReplayUploadSpectatorMatches: Bool {
        set { set(name: Settings.hsreplay_auto_synchronize_spectator_matches, value: newValue) }
        get { return get(name: Settings.hsreplay_auto_synchronize_spectator_matches) as? Bool ?? true }
    }

    static var theme: String {
        set { set(name: Settings.theme_token, value: newValue) }
        get { return get(name: Settings.theme_token) as? String ?? "dark" }
    }

    // MARK: - Paths / utils
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
    /*static var useHearthstoneAssets: Bool {
        set { set(name: Settings.use_hearthstone_assets, value: newValue) }
        get { return get(name: Settings.use_hearthstone_assets) as? Bool ?? false }
    }*/
}

// settings strings
extension Settings {

    static let show_memory_reading_warning = "showMemoryReadingWarning"
    
    static let theme_token = "theme"

    static let can_join_fullscreen = "can_join_fullscreen"
    static let quit_when_hs_closes = "quit_when_hs_closes"
    static let deck_manager_zoom = "deck_manager_zoom"
    static let tracker_opacity = "tracker_opacity"
    static let active_deck = "active_deck"
    static let card_size = "card_size"
    
    static let deck_sort_criteria = "deck_sort_criteria"
    static let deck_sort_order = "deck_sort_order"
    
    static let hearthstone_log_path = "hearthstone_log_path"
    static let hearthstone_language = "hearthstone_language"
    static let hstracker_language = "hstracker_language"
    
    static let rarity_colors = "rarity_colors"
    static let auto_position_trackers = "auto_position_trackers"
    static let hide_all_trackers_when_not_in_game = "hide_all_trackers_when_not_in_game"
    static let hide_all_trackers_when_game_in_background = "hide_all_trackers_when_game_in_background"
    static let deckmanager_prefer_cards = "deckmanager_prefer_cards"
    static let show_floating_card = "show_floating_card"
    static let floating_card_style = "floating_card_style"
    static let disable_tracking_in_spectator_mode = "disable_tracking_in_spectator_mode"
    static let show_topdeck_chance = "show_topdeck_chance"
    static let window_locked = "window_locked"
    static let prefer_golden_cards = "prefer_golden_cards"
    static let auto_deck_detection = "auto_deck_detection"

    static let player_draw_chance = "player_draw_chance"
    static let player_card_count = "player_card_count"
    static let opponent_card_count = "opponent_card_count"
    static let opponent_draw_chance = "opponent_draw_chance"
    static let player_cthun_frame = "player_cthun_frame"
    static let player_deathrattle_frame = "player_deathrattle_frame"
    static let player_yogg_frame = "player_yogg_frame"
    static let player_graveyard_frame = "player_graveyard_frame"

    static let player_graveyard_details_frame = "player_graveyard_details_frame"
    static let player_jade_frame = "player_jade_frame"
    static let opponent_cthun_frame = "opponent_cthun_frame"
    static let opponent_yogg_frame = "opponent_yogg_frame"
    static let opponent_deathrattle_frame = "opponent_deathrattle_frame"
    static let opponent_graveyard_frame = "opponent_graveyard_frame"
    static let opponent_graveyard_details_frame = "opponent_graveyard_details_frame"
    static let opponent_jade_frame = "opponent_jade_frame"

    static let remove_cards_from_deck = "remove_cards_from_deck"
    static let highlight_last_drawn = "highlight_last_drawn"
    static let highlight_cards_in_hand = "highlight_cards_in_hand"
    static let highlight_discarded = "highlight_discarded"
    static let show_player_get = "show_player_get"
    static let show_opponent_created = "show_opponent_created"
    static let show_player_tracker = "show_player_tracker"
    static let clear_trackers_end = "clear_trackers_end"
    static let show_opponent_tracker = "show_opponent_tracker"
    static let show_timer = "show_timer"

    static let timer_hud_frame = "timer_hud_frame"
    static let show_card_huds = "show_card_huds"
    static let show_secret_helper = "show_secret_helper"
    static let show_arena_helper = "show_arena_helper"
    static let show_win_loss_ratio = "show_win_loss_ratio"
    static let player_in_hand_color = "player_in_hand_color"
    static let show_apphealth = "show_apphealth"
    static let player_tracker_frame = "player_tracker_frame"
    static let opponent_tracker_frame = "opponent_tracker_frame"
    static let player_board_damage = "player_board_damage"
    static let player_board_damage_frame = "player_board_damage_frame"
    static let opponent_board_damage = "opponent_board_damage"
    static let opponent_board_damage_frame = "opponent_board_damage_frame"
    static let show_fatigue = "show_fatigue"
    
    // MARK: - Notifications related preferences
    static let use_toast_notification = "useToastNotification"
    static let notify_game_start = "notify_game_start"
    static let notify_turn_start = "notify_turn_start"
    static let notify_opponent_concede = "notify_opponent_concede"
    static let flash_draw = "flash_draw"
    static let show_opponent_class = "show_opponent_class"
    static let prevent_opponent_name_covering = "prevent_opponent_name_covering"
    static let show_deck_name = "show_deck_name"
    
    // MARK: - Track-o-Bot related preferences
    static let trackobot_username = "trackobot_username"
    static let trackobot_token = "trackobot_token"
    static let trackobot_auto_synchronize_matches = "trackobot_auto_synchronize_matches"
    
    static let save_replays = "save_replays"
    static let archive_arena_deck = "archive_arena_deck"
    
    // MARK: - HSReplay related preferences
    static let hsreplay_upload_token = "hsreplay_upload_token"
    static let hsreplay_username = "hsreplay_username"
    static let hsreplay_id = "hsreplay_id"
    static let hsreplay_show_push_notification = "hsreplay_show_push_notification"
    static let hsreplay_auto_synchronize_matches = "hsreplay_auto_synchronize_matches"
    static let hsreplay_auto_synchronize_ranked_matches = "hsreplay_auto_synchronize_ranked_matches"
    static let hsreplay_auto_synchronize_casual_matches = "hsreplay_auto_synchronize_casual_matches"
    static let hsreplay_auto_synchronize_arena_matches = "hsreplay_auto_synchronize_arena_matches"
    static let hsreplay_auto_synchronize_brawl_matches = "hsreplay_auto_synchronize_brawl_matches"
    static let hsreplay_auto_synchronize_friendly_matches = "hsreplay_auto_synchronize_friendly_matches"
    static let hsreplay_auto_synchronize_adventure_matches = "hsreplay_auto_synchronize_adventure_matches"
    static let hsreplay_auto_synchronize_spectator_matches = "hsreplay_auto_synchronize_spectator_matches"
}

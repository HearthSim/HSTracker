//
//  Settings.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

protocol UserDefaultConvertible {
    associatedtype ConvertedType
    
    func convert() -> ConvertedType
    
    static func reverse(from object: ConvertedType) -> Self?
}

@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    var container: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            return container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                container.removeObject(forKey: key)
            } else {
                container.setValue(newValue, forKey: key)
            }
        }
    }
}

@propertyWrapper
struct UserDefaultRawRepresentable<Value: RawRepresentable> {
    let key: String
    let defaultValue: Value
    let container: UserDefaults = .standard
    
    var wrappedValue: Value {
        get {
            guard let object = container.object(forKey: key) as? Value.RawValue else {
                return defaultValue
            }
            
            return Value(rawValue: object) ?? defaultValue
        }
        set {
            container.set(newValue.rawValue, forKey: key)
        }
    }
}

@propertyWrapper
struct UserDefaultCustom<Value: UserDefaultConvertible> {
    let key: String
    let defaultValue: Value?
    var container: UserDefaults = .standard

    var wrappedValue: Value? {
        get {
            if let value = container.object(forKey: key) as? Value.ConvertedType {
                if let result = Value.reverse(from: value) {
                    return result
                }
            }
            return defaultValue
        }
        set {
            if let value = newValue {
                container.setValue(value.convert(), forKey: key)
            } else {
                container.removeObject(forKey: key)
            }
        }
    }
}

extension NSRect: UserDefaultConvertible {
    func convert() -> String {
        return NSStringFromRect(self)
    }
    
    static func reverse(from object: String) -> CGRect? {
        return NSRectFromString(object)
    }
}

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
    
    @UserDefault(key: Settings.show_memory_reading_warning, defaultValue: true)
    static var showMemoryReadingWarning: Bool
    @UserDefault(key: Settings.can_join_fullscreen, defaultValue: true)
    static var canJoinFullscreen: Bool
    @UserDefault(key: Settings.quit_when_hs_closes, defaultValue: false)
    static var quitWhenHearthstoneCloses: Bool
    @UserDefault(key: Settings.deck_manager_zoom, defaultValue: 100.0)
    static var deckManagerZoom: Double
    @UserDefault(key: Settings.tracker_opacity, defaultValue: 0.0)
    static var trackerOpacity: Double
    @UserDefault(key: Settings.active_deck, defaultValue: nil)
    static var activeDeck: String?
    @UserDefaultRawRepresentable(key: Settings.card_size, defaultValue: .big)
    static var cardSize: CardSize
    @UserDefault(key: Settings.deck_sort_criteria, defaultValue: "name")
    static var deckSortCriteria: String
    @UserDefault(key: Settings.deck_sort_order, defaultValue: "ascending")
    static var deckSortOrder: String
    @UserDefault(key: Settings.archive_arena_deck, defaultValue: true)
    static var autoArchiveArenaDeck: Bool
    @UserDefault(key: Settings.hearthstone_log_path, defaultValue: "/Applications/Hearthstone")
    static var hearthstonePath: String
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
    
    @UserDefault(key: Settings.rarity_colors, defaultValue: true)
    static var showRarityColors: Bool
    /*static var promptNotes: Bool {
        set { set(name: Settings.prompt_for_notes, value: newValue) }
        get { return get(name: Settings.prompt_for_notes) as? Bool ?? false }
    }*/
    @UserDefault(key: Settings.auto_position_trackers, defaultValue: true)
    static var autoPositionTrackers: Bool
    @UserDefault(key: Settings.hide_all_trackers_when_not_in_game, defaultValue: false)
    static var hideAllTrackersWhenNotInGame: Bool
    @UserDefault(key: Settings.hide_all_trackers_when_game_in_background, defaultValue: false)
    static var hideAllWhenGameInBackground: Bool
    @UserDefault(key: Settings.deckmanager_prefer_cards, defaultValue: true)
    static var deckManagerPreferCards: Bool
    @UserDefault(key: Settings.show_floating_card, defaultValue: true)
    static var showFloatingCard: Bool
    @UserDefaultRawRepresentable(key: Settings.floating_card_style, defaultValue: .image)
    static var floatingCardStyle: FloatingCardStyle
    @UserDefault(key: Settings.disable_tracking_in_spectator_mode, defaultValue: true)
    static var dontTrackWhileSpectating: Bool
    @UserDefault(key: Settings.show_topdeck_chance, defaultValue: true)
    static var showTopdeckchance: Bool
    @UserDefault(key: Settings.window_locked, defaultValue: true)
    static var windowsLocked: Bool
    @UserDefault(key: Settings.prefer_golden_cards, defaultValue: false)
    static var preferGoldenCards: Bool
    @UserDefault(key: Settings.auto_deck_detection, defaultValue: true)
    static var autoDeckDetection: Bool
    @UserDefault(key: Settings.show_experience_counter, defaultValue: true)
    static var showExperienceCounter: Bool
    
    // MARK: - Battlegrounds
    @UserDefault(key: Settings.show_bobs_buddy, defaultValue: true)
    static var showBobsBuddy: Bool
    @UserDefault(key: Settings.show_bobs_buddy_during_combat, defaultValue: true)
    static var showBobsBuddyDuringCombat: Bool
    @UserDefault(key: Settings.show_bobs_buddy_during_shopping, defaultValue: true)
    static var showBobsBuddyDuringShopping: Bool
    @UserDefault(key: Settings.show_turn_counter, defaultValue: true)
    static var showTurnCounter: Bool
    @UserDefault(key: Settings.show_average_damage, defaultValue: true)
    static var showAverageDamage: Bool
    @UserDefault(key: Settings.show_opponent_warband, defaultValue: true)
    static var showOpponentWarband: Bool
    @UserDefault(key: Settings.show_tiers, defaultValue: true)
    static var showTiers: Bool

    @UserDefault(key: Settings.player_draw_chance, defaultValue: true)
    static var showPlayerDrawChance: Bool
    @UserDefault(key: Settings.player_card_count, defaultValue: true)
    static var showPlayerCardCount: Bool
    @UserDefault(key: Settings.opponent_card_count, defaultValue: true)
    static var showOpponentCardCount: Bool
    @UserDefault(key: Settings.opponent_draw_chance, defaultValue: true)
    static var showOpponentDrawChance: Bool
    @UserDefault(key: Settings.player_cthun_frame, defaultValue: true)
    static var showPlayerCthun: Bool
    @UserDefault(key: Settings.player_deathrattle_frame, defaultValue: false)
    static var showPlayerDeathrattle: Bool
    @UserDefault(key: Settings.player_yogg_frame, defaultValue: true)
    static var showPlayerSpell: Bool
    @UserDefault(key: Settings.player_graveyard_frame, defaultValue: true)
    static var showPlayerGraveyard: Bool
    @UserDefault(key: Settings.player_graveyard_details_frame, defaultValue: true)
    static var showPlayerGraveyardDetails: Bool
    @UserDefault(key: Settings.player_jade_frame, defaultValue: true)
    static var showPlayerJadeCounter: Bool
    @UserDefault(key: Settings.player_galakrond_invoke_frame, defaultValue: true)
    static var showPlayerGalakrondCounter: Bool
    @UserDefault(key: Settings.opponent_galakrond_invoke_frame, defaultValue: true)
    static var showOpponentGalakrondCounter: Bool
    @UserDefault(key: Settings.opponent_cthun_frame, defaultValue: true)
    static var showOpponentCthun: Bool
    @UserDefault(key: Settings.opponent_yogg_frame, defaultValue: true)
    static var showOpponentSpell: Bool
    @UserDefault(key: Settings.opponent_deathrattle_frame, defaultValue: false)
    static var showOpponentDeathrattle: Bool
    @UserDefault(key: Settings.opponent_graveyard_frame, defaultValue: true)
    static var showOpponentGraveyard: Bool
    @UserDefault(key: Settings.opponent_graveyard_details_frame, defaultValue: true)
    static var showOpponentGraveyardDetails: Bool
    @UserDefault(key: Settings.opponent_jade_frame, defaultValue: true)
    static var showOpponentJadeCounter: Bool
    @UserDefault(key: Settings.remove_cards_from_deck, defaultValue: false)
    static var removeCardsFromDeck: Bool
    @UserDefault(key: Settings.highlight_last_drawn, defaultValue: true)
    static var highlightLastDrawn: Bool
    @UserDefault(key: Settings.highlight_cards_in_hand, defaultValue: false)
    static var highlightCardsInHand: Bool
    @UserDefault(key: Settings.highlight_discarded, defaultValue: false)
    static var highlightDiscarded: Bool
    @UserDefault(key: Settings.show_player_get, defaultValue: false)
    static var showPlayerGet: Bool
    @UserDefault(key: Settings.show_opponent_created, defaultValue: true)
    static var showOpponentCreated: Bool
    @UserDefault(key: Settings.show_player_tracker, defaultValue: true)
    static var showPlayerTracker: Bool
    @UserDefault(key: Settings.clear_trackers_end, defaultValue: false)
    static var clearTrackersOnGameEnd: Bool
    @UserDefault(key: Settings.show_opponent_tracker, defaultValue: true)
    static var showOpponentTracker: Bool
    @UserDefault(key: Settings.show_timer, defaultValue: false)
    static var showTimer: Bool
    
    @UserDefaultCustom(key: Settings.timer_hud_frame, defaultValue: nil)
    static var timerHudFrame: NSRect?
    
    @UserDefault(key: Settings.show_card_huds, defaultValue: true)
    static var showCardHuds: Bool
    @UserDefault(key: Settings.show_secret_helper, defaultValue: true)
    static var showSecretHelper: Bool
    @UserDefault(key: Settings.show_arena_helper, defaultValue: true)
    static var showArenaHelper: Bool
    @UserDefault(key: Settings.show_win_loss_ratio, defaultValue: false)
    static var showWinLossRatio: Bool
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
    @UserDefault(key: Settings.show_apphealth, defaultValue: true)
    static var showAppHealth: Bool

    @UserDefaultCustom(key: Settings.player_tracker_frame, defaultValue: nil)
    static var playerTrackerFrame: NSRect?
    
    @UserDefaultCustom(key: Settings.opponent_tracker_frame, defaultValue: nil)
    static var opponentTrackerFrame: NSRect?

    @UserDefault(key: Settings.player_board_damage, defaultValue: true)
    static var playerBoardDamage: Bool
    
    @UserDefaultCustom(key: Settings.player_board_damage_frame, defaultValue: nil)
    static var playerBoardDamageFrame: NSRect?
    
    @UserDefault(key: Settings.opponent_board_damage, defaultValue: true)
    static var opponentBoardDamage: Bool
    
    @UserDefaultCustom(key: Settings.opponent_board_damage_frame, defaultValue: nil)
    static var opponentBoardDamageFrame: NSRect?
    
    @UserDefault(key: Settings.show_fatigue, defaultValue: true)
    static var fatigueIndicator: Bool

    // MARK: - Notifications
    @UserDefault(key: Settings.use_toast_notification, defaultValue: true)
    static var useToastNotification: Bool
    @UserDefault(key: Settings.notify_game_start, defaultValue: true)
    static var notifyGameStart: Bool
    @UserDefault(key: Settings.notify_turn_start, defaultValue: true)
    static var notifyTurnStart: Bool
    @UserDefault(key: Settings.notify_opponent_concede, defaultValue: true)
    static var notifyOpponentConcede: Bool
    @UserDefault(key: Settings.flash_draw, defaultValue: true)
    static var flashOnDraw: Bool
    @UserDefault(key: Settings.show_opponent_class, defaultValue: false)
    static var showOpponentClassInTracker: Bool
    @UserDefault(key: Settings.prevent_opponent_name_covering, defaultValue: false)
    static var preventOpponentNameCovering: Bool
    @UserDefault(key: Settings.show_deck_name, defaultValue: false)
    static var showDeckNameInTracker: Bool

    // MARK: - Importing
    @UserDefault(key: Settings.import_dungeon_include_passives, defaultValue: true)
    static var importDungeonIncludePassives: Bool
    @UserDefault(key: Settings.import_dungeon_template, defaultValue: "Dungeon Run {Date dd-MM HH:mm}")
    static var importDungeonTemplate: String
    @UserDefault(key: Settings.import_monster_hunt_template, defaultValue: "Monster Hunt {Date dd-MM HH:mm}")
    static var importMonsterHuntTemplate: String
    @UserDefault(key: Settings.import_rumble_run_template, defaultValue: "Rumble Run {Date dd-MM HH:mm}")
    static var importRumbleRunTemplate: String
    @UserDefault(key: Settings.import_dalaran_heist_template, defaultValue: "Dalaran Heist {Date dd-MM HH:mm}")
    static var importDalaranHeistTemplate: String
    @UserDefault(key: Settings.import_tombs_of_terror_template, defaultValue: "Tombs of Terror {Date dd-MM HH:mm}")
    static var importTombsOfTerrorTemplate: String
    @UserDefault(key: Settings.import_duels_template, defaultValue: "Duels Run {Date dd-MM HH:mm}")
    static var importDuelsTemplate: String

    // MARK: - HSReplay.net
    @UserDefault(key: Settings.save_replays, defaultValue: false)
    static var saveReplays: Bool
    @UserDefault(key: Settings.hsreplay_upload_token, defaultValue: nil)
    static var hsReplayUploadToken: String?
    @UserDefault(key: Settings.hsreplay_oauth_token, defaultValue: nil)
    static var hsReplayOAuthToken: String?
    @UserDefault(key: Settings.hsreplay_oauth_refresh_token, defaultValue: nil)
    static var hsReplayOAuthRefreshToken: String?
    @UserDefault(key: Settings.hsreplay_username, defaultValue: nil)
    static var hsReplayUsername: String?
    @UserDefault(key: Settings.hsreplay_id, defaultValue: nil)
    static var hsReplayId: Int?
    @UserDefault(key: Settings.hsreplay_auto_synchronize_matches, defaultValue: true)
    static var hsReplaySynchronizeMatches: Bool
    @UserDefault(key: Settings.hsreplay_show_push_notification, defaultValue: true)
    static var showHSReplayPushNotification: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_ranked_matches, defaultValue: true)
    static var hsReplayUploadRankedMatches: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_casual_matches, defaultValue: true)
    static var hsReplayUploadCasualMatches: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_arena_matches, defaultValue: true)
    static var hsReplayUploadArenaMatches: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_brawl_matches, defaultValue: true)
    static var hsReplayUploadBrawlMatches: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_friendly_matches, defaultValue: true)
    static var hsReplayUploadFriendlyMatches: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_adventure_matches, defaultValue: true)
    static var hsReplayUploadAdventureMatches: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_spectator_matches, defaultValue: false)
    static var hsReplayUploadSpectatorMatches: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_battlegrounds_matches, defaultValue: true)
    static var hsReplayUploadBattlegroundsMatches: Bool
    @UserDefault(key: Settings.hsreplay_auto_synchronize_duels_matches, defaultValue: true)
    static var hsReplayUploadDuelsMatches: Bool
    
    @UserDefault(key: Settings.theme_token, defaultValue: "dark")
    static var theme: String

    // MARK: - Paths / utils
    static var isCyrillicLanguage: Bool {
        guard let language = hearthstoneLanguage else { return false }

        return language == .ruRU
    }

    static var isSimplifiedChinese: Bool {
        guard let language = hearthstoneLanguage else { return false }

        return language == .zhCN
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
    
    static let auto_import_dungeon_run = "auto_import_dungeon_run"
    static let include_dungeon_run_passive_cards = "include_dungeon_run_passive_cards"
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
    static let show_experience_counter = "show_experience_counter"
    
    // MARK: Battlegrounds
    static let show_bobs_buddy = "show_bobs_buddy"
    static let show_bobs_buddy_during_combat = "show_bobs_buddy_during_combat"
    static let show_bobs_buddy_during_shopping = "show_bobs_buddy_during_shopping"
    static let show_turn_counter = "show_turn_counter"
    static let show_average_damage = "show_average_damage"
    static let show_opponent_warband = "show_opponent_warband"
    static let show_tiers = "show_tiers"

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
    static let player_galakrond_invoke_frame = "player_galakrond_invoke_frame"
    static let opponent_galakrond_invoke_frame = "opponent_galakrond_invoke_frame"
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
    
    static let save_replays = "save_replays"
    static let archive_arena_deck = "archive_arena_deck"
    
    // MARK: - Importing
    static let import_dungeon_include_passives = "import_dungeon_include_passives"
    static let import_dungeon_template = "import_dungeon_template"
    static let import_monster_hunt_template = "import_monster_hunt_template"
    static let import_rumble_run_template = "import_rumble_run_template"
    static let import_dalaran_heist_template = "import_dalaran_heist_template"
    static let import_tombs_of_terror_template = "import_tombs_of_terror_template"
    static let import_duels_template = "import_duels_template"
    
    // MARK: - HSReplay.net related preferences
    static let hsreplay_upload_token = "hsreplay_upload_token"
    static let hsreplay_username = "hsreplay_username"
    static let hsreplay_id = "hsreplay_id"
    static let hsreplay_oauth_token = "hsreplay_oauth_token"
    static let hsreplay_oauth_refresh_token = "hsreplay_oauth_refresh_token"
    static let hsreplay_show_push_notification = "hsreplay_show_push_notification"
    static let hsreplay_auto_synchronize_matches = "hsreplay_auto_synchronize_matches"
    static let hsreplay_auto_synchronize_ranked_matches = "hsreplay_auto_synchronize_ranked_matches"
    static let hsreplay_auto_synchronize_casual_matches = "hsreplay_auto_synchronize_casual_matches"
    static let hsreplay_auto_synchronize_arena_matches = "hsreplay_auto_synchronize_arena_matches"
    static let hsreplay_auto_synchronize_brawl_matches = "hsreplay_auto_synchronize_brawl_matches"
    static let hsreplay_auto_synchronize_friendly_matches = "hsreplay_auto_synchronize_friendly_matches"
    static let hsreplay_auto_synchronize_adventure_matches = "hsreplay_auto_synchronize_adventure_matches"
    static let hsreplay_auto_synchronize_spectator_matches = "hsreplay_auto_synchronize_spectator_matches"
    static let hsreplay_auto_synchronize_battlegrounds_matches = "hsreplay_auto_synchronize_battlegrounds_matches"
    static let hsreplay_auto_synchronize_duels_matches = "hsreplay_auto_synchronize_duels_matches"
}

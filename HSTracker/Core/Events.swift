//
//  Events.swift
//  HSTracker+
//
//  Created by Fehervari, Istvan on 1/4/18.
//  Copyright © 2018 Benjamin Michotte. All rights reserved.
//

import Foundation

class Events {
    
    static let reload_decks = "reload_decks"
    
    static let space_changed = "space_changed"
    
    static let hearthstone_closed = "hearthstone_closed"
    static let hearthstone_running = "hearthstone_running"
    static let hearthstone_active = "hearthstone_active"
    static let hearthstone_deactived = "hearthstone_deactived"
    
    // Fired by Tier7Trial once a trial token has been obtained, mirroring HDT's
    // Tier7Trial.OnTrialActivated event. Lets the Battlegrounds Minions tab turn
    // its inspiration indicators on the moment a trial starts rather than at the
    // next match.
    static let tier7_trial_activated = "tier7_trial_activated"
    static let tier7_trial_status_updated = "tier7_trial_status_updated"

    // HDT's HSReplayNetOAuth.Authenticated, AccountDataUpdated and LoggedOut events.
    static let hsreplay_authenticated = "hsreplay_authenticated"
    static let hsreplay_account_data_updated = "hsreplay_account_data_updated"
    static let hsreplay_logged_out = "hsreplay_logged_out"

    // HDT's BattlegroundsDbSingleton.Updated: the assembled database of a game
    // mode was replaced after its live meta period loaded. The userInfo carries
    // the game mode under "isDuos".
    static let battlegrounds_db_updated = "battlegrounds_db_updated"
}

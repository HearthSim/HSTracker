//
//  StatusMessageConverter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/23/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class StatusMessageConverter {
    static func getStatusMessage(state: BobsBuddyState, errorState: BobsBuddyErrorState, statsShown: Bool, errorMessage: String?) -> String {
        if errorState != .none {
            if let errorMessage {
                return errorMessage
            }
            switch errorState {
            case .notEnoughData:
                return String.localizedString("Could not get accurate results", comment: "")
            case .secretsNotSupported:
                return String.localizedString("Secrets are not yet supported", comment: "")
            case .unknownCards:
                return String.localizedString("Found unknown cards", comment: "")
            case .failedToLoad:
                return String.localizedString("Failed to load BobsBuddy", comment: "")
            case .monoNotFound:
                return String.localizedString("Mono not found", comment: "")
            //case .updateRequired:
            case .unsupportedCards:
                return String.localizedString("Found unsupported cards", comment: "")
            case .unsupportedInteraction:
                return String.localizedString("BobsBuddyStatusMessage_UnsupportedInteraction", comment: "")
            default:
                return String.localizedString("Unknown error", comment: "")
            }
        }
        switch state {
        case .initial:
            return String.localizedString("Waiting For Combat", comment: "")
        case .waitingForTeammates:
            return String.localizedString("BobsBuddyStatusMessage_WaitingForTeammates", comment: "")
        case .combat:
            return statsShown ? String.localizedString("Current Combat", comment: "") : String.localizedString("Show Current Combat", comment: "")
        case .shopping:
            return statsShown ? String.localizedString("Previous Combat", comment: "") : String.localizedString("Show Previous Combat", comment: "")
        case .gameOver:
            return statsShown ? String.localizedString("Final Combat", comment: "") : String.localizedString("Show Final Combat", comment: "")
        case .combatPartial:
            return String.localizedString(statsShown ? "BobsBuddyStatusMessage_CurrentCombatPartial" : "BobsBuddyStatusMessage_ShowCurrentCombatPartial", comment: "")
        case .shoppingAfterPartial:
            return String.localizedString(statsShown ? "BobsBuddyStatusMessage_PreviousCombatPartial" : "BobsBuddyStatusMessage_ShowPreviousCombatPartial", comment: "")
        case .gameOverAfterPartial:
            return String.localizedString(statsShown ? "BobsBuddyStatusMessage_FinalCombatPartial" : "BobsBuddyStatusMessage_ShowFinalCombatPartial", comment: "")
        case .combatWithoutSimulation:
            return String.localizedString("Awaiting Shopping Phase", comment: "")
        }
    }
}

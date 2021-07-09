//
//  StatusMessageConverter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/23/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class StatusMessageConverter {
    static func getStatusMessage(state: BobsBuddyState, errorState: BobsBuddyErrorState, statsShown: Bool) -> String {
        if errorState != .none {
            switch errorState {
            case .notEnoughData:
                return NSLocalizedString("Could not get accurate results", comment: "")
            case .secretsNotSupported:
                return NSLocalizedString("Secrets are not yet supported", comment: "")
            case .unknownCards:
                return NSLocalizedString("Found unknown cards", comment: "")
            case .failedToLoad:
                return NSLocalizedString("Failed to load BobsBuddy", comment: "")
            case .monoNotFound:
                return NSLocalizedString("Mono not found", comment: "")
            //case .updateRequired:
            default:
                return NSLocalizedString("Unknown error", comment: "")
            }
        }
        switch state {
        case .initial:
            return NSLocalizedString("Waiting For Combat", comment: "")
        case .combat:
            return statsShown ? NSLocalizedString("Current Combat", comment: "") : NSLocalizedString("Show Current Combat", comment: "")
        case .shopping:
            return statsShown ? NSLocalizedString("Previous Combat", comment: "") : NSLocalizedString("Show Previous Combat", comment: "")
        case .combatWithoutSimulation:
            return NSLocalizedString("Awaiting Shopping Phase", comment: "")
        }
    }
}

//
//  RemoteArenaSettings.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/27/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

struct RemoteArenaSettings: AvailableSecretsProvider {
    var byType: [String: Set<String>]? {
        return RemoteConfig.liveSecrets?.by_game_type_and_format_type
    }
    var createdByTypeByCreator: [String: [String: Set<String>]]? {
        return RemoteConfig.liveSecrets?.created_by_game_type_and_format_type
    }
}

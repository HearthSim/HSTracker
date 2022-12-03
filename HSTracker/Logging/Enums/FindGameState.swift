//
//  FindGameState.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/2/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

enum FindGameState: Int, CaseIterable {
    case INVALID,
    CLIENT_STARTED,
    CLIENT_CANCELED,
    CLIENT_ERROR,
    BNET_QUEUE_ENTERED,
    BNET_QUEUE_DELAYED,
    BNET_QUEUE_UPDATED,
    BNET_QUEUE_CANCELED,
    BNET_ERROR,
    SERVER_GAME_CONNECTING,
    SERVER_GAME_STARTED,
    SERVER_GAME_CANCELED
}

//
//  Mode.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 27/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum Mode : String {
    case INVALID = "INVALID",
    STARTUP = "STARTUP",
    LOGIN = "LOGIN",
    HUB = "HUB",
    GAMEPLAY = "GAMEPLAY",
    COLLECTIONMANAGER = "COLLECTIONMANAGER",
    PACKOPENING = "PACKOPENING",
    TOURNAMENT = "TOURNAMENT",
    FRIENDLY = "FRIENDLY",
    FATAL_ERROR = "FATAL_ERROR",
    DRAFT = "DRAFT",
    CREDITS = "CREDITS",
    RESET = "RESET",
    ADVENTURE = "ADVENTURE",
    TAVERN_BRAWL = "TAVERN_BRAWL"
}
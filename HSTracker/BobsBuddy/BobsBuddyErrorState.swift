//
//  BobsBuddyErrorState.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/24/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

enum BobsBuddyErrorState: Int {
    case none
    case updateRequired
    case notEnoughData
    case secretsNotSupported
    case unknownCards
    case failedToLoad
    case monoNotFound
}

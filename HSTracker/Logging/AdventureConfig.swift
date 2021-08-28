//
//  AdventureConfig.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/26/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct AdventureConfig {
    var adventureId: AdventureDbId = .invalid
    var adventureModeId: AdventureModeDbId = .invalid
    var selectedDeckId: Int = 0
    var selectedMission: Int = 0
}

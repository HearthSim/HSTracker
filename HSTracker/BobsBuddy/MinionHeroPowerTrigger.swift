//
//  MinionHeroPowerTrigger.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/25/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import PromiseKit

class MinionHeroPowerTrigger {
    let minion: MinionProxy
    let heroPowerId: String
    let semaphore: DispatchSemaphore
    
    init(m: MinionProxy, heroPower: String) {
        self.minion = m
        self.heroPowerId = heroPower
        self.semaphore = DispatchSemaphore(value: 0)
    }
}

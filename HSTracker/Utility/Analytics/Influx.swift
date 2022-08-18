//
//  Influx.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppCenterAnalytics

class Influx {
    private static let lock = UnfairLock()
    private static var sentEvents = Set<String>()
    
    static func sendSingleEvent(eventName: String, withProperties: [String: String] = [:]) {
        let send: Bool = lock.around {
            if !sentEvents.contains(eventName) {
                sentEvents.insert(eventName)
                return true
            }
            return false
        }
        if send {
            Analytics.trackEvent(eventName, withProperties: withProperties)
        }
    }
}

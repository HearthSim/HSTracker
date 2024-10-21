//
//  Influx.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import Sentry

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
            if withProperties.count > 0 {
                SentrySDK.capture(message: eventName, block: { scope in
                    scope.setContext(value: withProperties, key: "properties")
                })
            } else {
                SentrySDK.capture(message: eventName)
            }
        }
    }
    
    static func sendEvent(eventName: String, withProperties: [String: String] = [:], level: SentryLevel = .error) {
        if withProperties.count > 0 {
            SentrySDK.capture(message: eventName, block: { scope in
                scope.setContext(value: withProperties, key: "properties")
                scope.setLevel(level)
            })
        } else {
            SentrySDK.capture(message: eventName)
        }
    }
    
    static func breadcrumb(eventName: String, message: String? = nil, withProperties: [String: String]? = nil, level: SentryLevel = .info) {
        let crumb = Breadcrumb()
        crumb.category = eventName
        crumb.level = level
        crumb.data = withProperties
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }
}

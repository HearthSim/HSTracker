//
//  MixpanelEvents.swift
//  HSTracker
//
//  Created by IHume on 2025-09-30.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Mixpanel

enum HstEvent: String {
    case EndMatch = "End Match Action HSTracker"
}

class MixpanelEvents {
    private static let defaults: UserDefaults = {
        return UserDefaults.standard
    }()

    private static func set(name: String, value: Any?) {
        defaults.set(value, forKey: name)
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: value)
    }

    private static func get(name: String) -> Any? {
        if let returnValue = defaults.object(forKey: name) {
            return returnValue as Any?
        }
        return nil
    }


    static let end_match_last_sent = "end_match_last_sent"

    @UserDefaultCustom(key: MixpanelEvents.end_match_last_sent, defaultValue: nil)
    static var endMatchLastSent: Date?

    static func sendEvent(event: HstEvent, properties: Properties) {
        if event == .EndMatch {
            let date = Date()
            if let lastEndMatch = endMatchLastSent {
                let curr_day = Calendar.current.component(.day, from: date)
                let prev_sent_day = Calendar.current.component(.day, from: lastEndMatch)

                if (curr_day <= prev_sent_day) {
                    return;
                }
            }

            endMatchLastSent = date;
        }

        Mixpanel.mainInstance().track(
            event: event.rawValue,
            properties: properties
        )
    }
}

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
    @UserDefault(key: linked_mixpanel_token, defaultValue: false)
    static var linkedMixpanelToken: Bool

    @UserDefaultCustom(key: end_match_last_sent, defaultValue: nil)
    static var endMatchLastSent: Date?

    static let end_match_last_sent = "end_match_last_sent"
    static let linked_mixpanel_token = "linked_mixpanel_token"

    static func resetAccount() {
        Mixpanel.mainInstance().reset()
        linkedMixpanelToken = false
    }

    static func sendEvent(event: HstEvent, properties: Properties) {
    // Temporarily disable the daily rate limit per user to get maximum insights into hstracker user behaviour
//        if event == .EndMatch {
//            let date = Date()
//            if let lastEndMatch = endMatchLastSent {
//                let curr_day = Calendar.current.component(.day, from: date)
//                let prev_sent_day = Calendar.current.component(.day, from: lastEndMatch)
//
//                if (curr_day <= prev_sent_day) {
//                    return;
//                }
//            }
//
//            endMatchLastSent = date;
//        }

        Mixpanel.mainInstance().track(
            event: event.rawValue,
            properties: properties
        )
    }
}

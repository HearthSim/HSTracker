//
//  Step.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

// swiftlint:disable type_name

enum Step: Int {
    case invalid = 0,
    begin_first = 1,
    begin_shuffle = 2,
    begin_draw = 3,
    begin_mulligan = 4,
    main_begin = 5,
    main_ready = 6,
    main_resource = 7,
    main_draw = 8,
    main_start = 9,
    main_action = 10,
    main_combat = 11,
    main_end = 12,
    main_next = 13,
    final_wrapup = 14,
    final_gameover = 15,
    main_cleanup = 16,
    main_start_triggers = 17
    
    init?(rawString: String) {
        for _enum in Step.allValues() {
            if "\(_enum)" == rawString.lowercased() {
                self = _enum
                return
            }
        }
        if let value = Int(rawString), let _enum = Step(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }
    
    static func allValues() -> [Step] {
        return [.invalid,
                .begin_first,
                .begin_shuffle,
                .begin_draw,
                .begin_mulligan,
                .main_begin,
                .main_ready,
                .main_resource,
                .main_draw,
                .main_start,
                .main_action,
                .main_combat,
                .main_end,
                .main_next,
                .final_wrapup,
                .final_gameover,
                .main_cleanup,
                .main_start_triggers]
    }
}

//
//  ChoiceType.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/8/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

public enum ChoiceType: Int, CaseIterable {
    case invalid = 0,
    mulligan = 1,
    general = 2,
    target = 3
    
    init?(rawString: String) {
        let string = rawString.lowercased()
        for _enum in ChoiceType.allCases where "\(_enum)" == string {
            self = _enum
            return
        }
        if let value = Int(rawString), let _enum = ChoiceType(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }

}

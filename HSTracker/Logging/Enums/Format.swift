//
//  Format.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 26/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum Format: String {
    case unknown,
    all,
    standard,
    wild

    init(formatType: FormatType) {
        switch formatType {
        case .ft_wild:
            self = .wild
        case .ft_standard:
            self = .standard
        default:
            self = .unknown
        }
    }
}

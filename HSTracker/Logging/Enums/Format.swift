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
    wild,
    classic

    init(formatType: FormatType) {
        switch formatType {
        case .ft_wild:
            self = .wild
        case .ft_standard:
            self = .standard
        case .ft_classic:
            self = .classic
        default:
            self = .unknown
        }
    }

    func toFormatType() -> FormatType {
        switch self {
        case .standard:
            return .ft_standard
        case .wild:
            return .ft_wild
        case .classic:
            return .ft_classic
        default: return .ft_unknown
        }
    }
}

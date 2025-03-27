//
//  HighlightColor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public enum HighlightColor {
    case none,
         teal,
         orange,
         green
}

public class HighlightColorHelper {
    private static let _colorMapping = [
        0: HighlightColor.teal,
        1: HighlightColor.orange,
        2: HighlightColor.green
    ]

    public static func getHighlightColor(_ conditions: Bool...) -> HighlightColor {
        if conditions.count == 0 {
            return HighlightColor.none
        }

        for i in 0 ..< conditions.count {
            if !conditions[i] {
                continue
            }
            if let color = _colorMapping[i] {
                return color
            }
        }

        return HighlightColor.none
    }
}

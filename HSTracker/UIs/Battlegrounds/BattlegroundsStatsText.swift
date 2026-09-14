//
//  BattlegroundsStatsText.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// The two stat formats every Battlegrounds stats header carries -
// StringFormat=N2 on the average placement and StringFormat={}{0:0.0}% on the
// pick rate, both culture-aware, which is what the NSTextField formatters the
// AppKit headers carried did too - and the placeholder they fall back to.
enum BattlegroundsStatsText {
    private static let avgPlacementFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Language.culture
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let pickRateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Language.culture
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    // TargetNullValue on both. HDT's XAML uses an en dash; HSTracker's shared
    // StatsHeaderViewModel already answers a missing tier with an em dash, so
    // all the placeholders in one plate stay the one character.
    static let missingValue = "—"

    static func avgPlacement(_ value: Double?) -> String {
        guard let value else {
            return missingValue
        }
        return avgPlacementFormatter.string(from: NSNumber(value: value)) ?? missingValue
    }

    static func pickRate(_ value: Double?) -> String {
        guard let value else {
            return missingValue
        }
        return pickRateFormatter.string(from: NSNumber(value: value / 100.0)) ?? missingValue
    }
}

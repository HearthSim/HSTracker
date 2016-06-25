//
//  StatsHelper.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/9/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class StatsTableRow: NSObject { // Class instead of struct so we can use sortUsingDescriptors
    // Used for display
    var classIcon = ""
    var opponentClassName = ""
    var record = ""
    var winRate = ""
    var confidenceInterval = ""

    // Used for sorting
    var totalGames = 0
    var winRateNumber = -1.0
    var confidenceWindow = 1.0
}

struct StatsDeckRecord {
    var wins   = 0
    var losses = 0
    var draws  = 0
    var total  = 0
}

class StatsHelper {
    static let playerClassList = [
        "druid", "hunter", "mage", "paladin", "priest",
        "rogue", "shaman", "warlock", "warrior"
        ].sort { NSLocalizedString($0, comment: "") < NSLocalizedString($1, comment: "") }

    static func getStatsUITableData(deck: Deck, mode: GameMode = .Ranked) -> [StatsTableRow] {
        var tableData = [StatsTableRow]()

        for againstClass in ["all"] + StatsHelper.playerClassList {
            let dataRow = StatsTableRow()

            if againstClass == "all"{
                dataRow.classIcon = "AppIcon"
            } else {
                dataRow.classIcon = againstClass
            }
            dataRow.opponentClassName =
                NSLocalizedString(againstClass, comment: "").capitalizedString
            
            let record = getDeckRecord(deck, againstClass: againstClass, mode: mode)
            dataRow.record            = getDeckRecordString(record)
            dataRow.winRate           = getDeckWinRateString(record)
            dataRow.winRateNumber     = getDeckWinRate(record)
            dataRow.totalGames        = record.total
            dataRow.confidenceInterval = getDeckConfidenceString(record,
                                                                 confidence: 0.9)
            let interval = binomialProportionCondifenceInterval(record.wins,
                                                                losses: record.losses,
                                                                confidence: 0.9)
            dataRow.confidenceWindow   = interval.upper - interval.lower

            tableData.append(dataRow)
        }

        return tableData
    }
    
    static func getDeckManagerRecordLabel(deck: Deck) -> String {
        let record = getDeckRecord(deck)
        
        let totalGames = record.total
        if totalGames == 0 {
            return "0 - 0"
        }
        
        return "\(record.wins) - \(record.losses) (\(getDeckWinRateString(record)))"
    }
    static func getDeckRecordString(record: StatsDeckRecord) -> String {
        return "\(record.wins)-\(record.losses)"
    }

    static func getDeckWinRate(record: StatsDeckRecord) -> Double {
        let totalGames = record.wins + record.losses
        var winRate = -1.0
        if totalGames > 0 {
            winRate = Double(record.wins)/Double(totalGames)
        }
        return winRate
    }

    static func getDeckWinRateString(record: StatsDeckRecord) -> String {
        var winRateString = "N/A"
        let winRate = getDeckWinRate(record)
        if winRate >= 0.0 {
            let winPercent = Int(round(winRate * 100))
            winRateString = String(winPercent) + "%"
        }
        return winRateString
    }

    static func getDeckRecord(deck: Deck, againstClass: String = "all", mode: GameMode = .Ranked)
        -> StatsDeckRecord {
        var stats = deck.statistics
        if againstClass.lowercaseString != "all" {
            stats = deck.statistics.filter({$0.opponentClass == againstClass.lowercaseString})
        }
        
        var rankedStats: [Statistic]
        if mode == .All {
            rankedStats = stats
        } else {
            rankedStats = stats.filter({$0.playerMode == mode})
        }
        
        let wins   = rankedStats.filter({$0.gameResult == .Win}).count
        let losses = rankedStats.filter({$0.gameResult == .Loss}).count
        let draws  = rankedStats.filter({$0.gameResult == .Draw}).count

        return StatsDeckRecord(wins: wins, losses: losses, draws: draws, total: wins+losses+draws)
    }

    static func getDeckConfidenceString(record: StatsDeckRecord,
                                        confidence: Double = 0.9) -> String {
        let interval = binomialProportionCondifenceInterval(record.wins,
                                                            losses: record.losses,
                                                            confidence: confidence)
        let intLower = Int(round(interval.lower*100))
        let intUpper = Int(round(interval.upper*100))

        return String(format: "%3d%% - %3d%%", arguments: [intLower, intUpper])
    }


    static func binomialProportionCondifenceInterval(wins: Int, losses: Int,
                                                     confidence: Double = 0.9)
        -> (lower: Double, upper: Double, mean: Double) {
        // Implements the Wilson interval

        let alpha = 1.0 - confidence
        assert(alpha >= 0.0)
        assert(alpha <= 1.0)

        let n = Double(wins + losses)
        // bounds checking
        if n < 1 {
            return (0.0, 1.0, 0.5)
        }

        let quantile = 1 - 0.5 * alpha
        let z = sqrt(2) * erfinv(2 * quantile - 1)

        let p = Double(wins) / Double(n)

        let center = p + z * z / (2 * n)
        let spread = z * sqrt(p * (1 - p) / n + z * z / (4 * n * n))
        let prefactor = 1 / (1 + z * z / n)

        var lower = prefactor * (center - spread)
        var upper = prefactor * (center + spread)
        let mean = prefactor * (center)

        lower = max(lower, 0.0)
        upper = min(upper, 1.0)

        return (lower, upper, mean)
    }

    static func erfinv(y: Double) -> Double {
        // swiftlint:disable line_length
        // Taken from:
        // http://stackoverflow.com/questions/36784763/is-there-an-inverse-error-function-available-in-swifts-foundation-import
        // swiftlint:enable line_length

        let center = 0.7
        let a = [ 0.886226899, -1.645349621, 0.914624893, -0.140543331]
        let b = [-2.118377725, 1.442710462, -0.329097515, 0.012229801]
        let c = [-1.970840454, -1.624906493, 3.429567803, 1.641345311]
        let d = [ 3.543889200, 1.637067800]
        if abs(y) <= center {
            let z = pow(y, 2)
            let num = (((a[3] * z + a[2]) * z + a[1]) * z) + a[0]
            let den = ((((b[3] * z + b[2]) * z + b[1]) * z + b[0]) * z + 1.0)
            var x = y * num / den
            x = x - (erf(x) - y) / (2.0 / sqrt(M_PI) * exp(-x * x))
            x = x - (erf(x) - y) / (2.0 / sqrt(M_PI) * exp(-x * x))
            return x
        } else if abs(y) > center && abs(y) < 1.0 {
            let z = pow(-log((1.0 - abs(y)) / 2), 0.5)
            let num = ((c[3] * z + c[2]) * z + c[1]) * z + c[0]
            let den = (d[1] * z + d[0]) * z + 1
            // should use the sign function instead of pow(pow(y,2),0.5)
            var x = y / pow(pow(y, 2), 0.5) * num / den
            x = x - (erf(x) - y) / (2.0 / sqrt(M_PI) * exp(-x * x))
            x = x - (erf(x) - y) / (2.0 / sqrt(M_PI) * exp(-x * x))
            return x
        } else if abs(y) == 1 {
            return y * Double(Int.max)
        } else {
            return Double.NaN
        }
    }



}

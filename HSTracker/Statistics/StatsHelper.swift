//
//  StatsHelper.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/9/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import CleanroomLogger

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

class LadderTableRow: NSObject { // Class instead of struct so we can use sortUsingDescriptors
    // Used for display
    var rank = ""
    var games = ""
    var gamesCI = ""
    var time = ""
    var timeCI = ""
}

struct StatsDeckRecord {
    var wins   = 0
    var losses = 0
    var draws  = 0
    var total  = 0
}

class StatsHelper {
    static let statsUIConfidence: Double = 0.9 // Maybe this could become user settable
    
    static let lg = LadderGrid()
    
    static func getStatsUITableData(deck: Deck, mode: GameMode = .ranked, season: Int)
        -> [StatsTableRow] {
        var tableData = [StatsTableRow]()
        
        for againstClass in [.neutral] + Cards.classes {
            let dataRow = StatsTableRow()
            
            if againstClass == .neutral {
                dataRow.classIcon = "AppIcon"
            } else {
                dataRow.classIcon = againstClass.rawValue
            }
            dataRow.opponentClassName =
                NSLocalizedString(againstClass.rawValue,
                                  comment: "").capitalized
            
            let record = getDeckRecord(deck: deck, againstClass: againstClass,
                                       mode: mode, season: season)
            dataRow.record = getDeckRecordString(record: record)
            dataRow.winRate = getDeckWinRateString(record: record)
            dataRow.winRateNumber = getDeckWinRate(record: record)
            dataRow.totalGames = record.total
            dataRow.confidenceInterval = getDeckConfidenceString(record: record,
                                                                 confidence: statsUIConfidence)
            let interval = binomialProportionCondifenceInterval(wins: record.wins,
                                                                losses: record.losses,
                                                                confidence: statsUIConfidence)
            dataRow.confidenceWindow   = interval.upper - interval.lower
            
            tableData.append(dataRow)
        }
        
        return tableData
    }
    
    
    static func getLadderTableData(deck: Deck, rank: Int, stars: Int, streak: Bool)
        -> [LadderTableRow] {
            
            var tableData = [LadderTableRow]()
            
            let record = getDeckRecord(deck: deck, againstClass: .neutral, mode: .ranked)
            let tpg = getDeckTimePerGame(deck: deck, againstClass: .neutral, mode: .ranked)
            
            let winRate = getDeckWinRate(record: record)
            
            let totalStars = Ranks.starsAtRank[rank]! + stars
            var bonus: Int = 0
            if streak {
                bonus = 2
            }
            
            for target_rank in [20, 15, 10, 5, 0] {
                let dataRow = LadderTableRow()
                
                if target_rank == 0 {
                    dataRow.rank = "Legend"
                } else {
                    dataRow.rank = String(target_rank)
                }
                
                if rank <= target_rank || winRate == -1.0 {
                    dataRow.games = "--"
                    dataRow.gamesCI = "--"
                    dataRow.time = "--"
                    dataRow.timeCI = "--"
                } else {
                    
                    // Closures for repeated tasks
                    let getGames = {
                        (winp: Double) -> Double? in
                        return lg.getGamesToRank(targetRank: target_rank,
                                                 stars: totalStars,
                                                 bonus: bonus,
                                                 winp: winp)
                    }
                    
                    let formatGames = {
                        (games: Double) -> String in
                        if games > 1000 {
                            return ">1000"
                        } else {
                            return String(Int(round(games)))
                        }
                    }
                    
                    let formatTime = {
                        (games: Double, timePerGame: Double) -> String in
                        let hours = games * timePerGame / 3600
                        if hours > 100 {
                            return ">100"
                        } else {
                            return String(format: "%.1f", hours)
                        }
                    }
                    
                    // Means
                    if let g2r = getGames(winRate) {
                        dataRow.games = formatGames(g2r)
                        dataRow.time = formatTime(g2r, tpg)
                    } else {
                        dataRow.games = "Error"
                        dataRow.time = "Error"
                    }
                    
                    // swiftlint:disable line_length
                    //Confidence intervals
                    let interval = binomialProportionCondifenceInterval(wins: record.wins,
                                                                        losses: record.losses,
                                                                        confidence: statsUIConfidence)
                    // swiftlint:enable line_length
                    if let lg2r = getGames(interval.lower),
                        let ug2r = getGames(interval.upper) {
                        dataRow.gamesCI = "\(formatGames(ug2r)) - \(formatGames(lg2r))"
                        dataRow.timeCI = "\(formatTime(ug2r, tpg)) - \(formatTime(lg2r, tpg))"
                    } else {
                        dataRow.gamesCI = "Error"
                        dataRow.timeCI = "Error"
                    }
                }
                
                tableData.append(dataRow)
            }
            
            return tableData
    }
    
    static func getDeckManagerRecordLabel(deck: Deck, mode: GameMode) -> String {
        let record = getDeckRecord(deck: deck, mode: mode)
        
        let totalGames = record.total
        if totalGames == 0 {
            return "0 - 0"
        }
        
        return "\(record.wins) - \(record.losses) (\(getDeckWinRateString(record: record)))"
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
    
    static func getDeckTimePerGame(deck: Deck, againstClass: CardClass = .neutral,
                                   mode: GameMode = .ranked) -> Double {
        var stats = Array(deck.statistics)
        
        if againstClass != .neutral {
            stats = stats.filter { $0.opponentClass == againstClass }
        }
        
        var rankedStats: [Statistic]
        if mode == .all {
            rankedStats = stats
        } else {
            rankedStats = stats.filter { $0.playerMode == mode }
        }
        
        var time: Double = 0.0
        
        for stat in rankedStats {
            time += Double(stat.duration)
        }
        time /= Double(rankedStats.count)
        
        return time
    }
    
    static func getDeckWinRateString(record: StatsDeckRecord) -> String {
        var winRateString = "N/A"
        let winRate = getDeckWinRate(record: record)
        if winRate >= 0.0 {
            let winPercent = Int(round(winRate * 100))
            winRateString = String(winPercent) + "%"
        }
        return winRateString
    }
    
    static func getDeckRecord(deck: Deck, againstClass: CardClass = .neutral,
                              mode: GameMode = .ranked, season: Int = 0)
        -> StatsDeckRecord {
            var stats = Array(deck.statistics)
            if againstClass != .neutral {
                stats = stats.filter { $0.opponentClass == againstClass }
            }
            if season > 0 {
                stats = stats.filter { $0.season.value == season }
            }
            
            var rankedStats: [Statistic]
            if mode == .all {
                rankedStats = stats
            } else {
                rankedStats = stats.filter { $0.playerMode == mode }
            }
            
            let wins = rankedStats.filter { $0.gameResult == .win }.count
            let losses = rankedStats.filter { $0.gameResult == .loss }.count
            let draws = rankedStats.filter { $0.gameResult == .draw }.count
            
            return StatsDeckRecord(wins: wins,
                                   losses: losses,
                                   draws: draws,
                                   total: wins+losses+draws)
    }
    
    static func getDeckConfidenceString(record: StatsDeckRecord,
                                        confidence: Double = 0.9) -> String {
        let interval = binomialProportionCondifenceInterval(wins: record.wins,
                                                            losses: record.losses,
                                                            confidence: confidence)
        let intLower = Int(round(interval.lower*100))
        let intUpper = Int(round(interval.upper*100))
        
        return String(format: "%3d%% - %3d%%", arguments: [intLower, intUpper])
    }
    
    static func guessRank(deck: Deck) -> Int {
        let isStandard = deck.standardViable()

        var rdecks: [Deck]? = nil
        do {
            let realm = try Realm()
            rdecks = Array(realm.objects(Deck.self))
        } catch {
            Log.error?.message("Can not load decks : \(error)")
            return -1
        }

        guard let sdecks = rdecks else { return -1 }

        let decks = sdecks
            .filter({$0.standardViable() == isStandard})
            .filter({!$0.isArena})
        
        var mostRecent: Statistic?
        for deck_i in decks {
            let datedRankedGames = deck_i.statistics.filter { $0.playerMode == .ranked }

            if let latest = datedRankedGames.max(by: {$0.date < $1.date}) {
                if let mr = mostRecent {
                    if mr.date < latest.date {
                        mostRecent = latest
                    }
                } else {
                    mostRecent = latest
                }
            }
        }

        if let mr = mostRecent {
            return mr.playerRank
        } else {
            return 25
        }
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
            let z = sqrt(2) * erfinv(y: 2 * quantile - 1)
            
            let p = Double(wins) / Double(n)
            
            let center = p + z * z / (2 * n)
            let spl = p * (1 - p) / n + z * z / (4 * n * n)
            let spread = z * sqrt(spl)
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
            return Double.nan
        }
    }
}

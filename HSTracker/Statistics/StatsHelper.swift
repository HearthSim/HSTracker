//
//  StatsHelper.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/9/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class StatsTableRow: NSObject { // Class instead of struct so we can use sortUsingDescriptors
    var classIcon = ""
    var opponentClassName = ""
    var record = ""
    var winRate = ""
    var totalGames = 0
    var winRateNumber = -1.0
}

class StatsHelper {
    static let playerClassList = ["druid", "hunter", "mage", "paladin", "priest",
                                  "rogue", "shaman", "warlock", "warrior"]
    
    static func getStatsUITableData(deck: Deck) -> [StatsTableRow] {
        var tableData = [StatsTableRow]()
        
        for againstClass in ["all"] + StatsHelper.playerClassList {
            let dataRow = StatsTableRow()
            
            if againstClass == "all"{
                dataRow.classIcon = "AppIcon"
            } else {
                dataRow.classIcon = againstClass
            }
            dataRow.opponentClassName = againstClass.capitalizedString
            dataRow.record            = getDeckRecordString(deck, againstClass: againstClass)
            dataRow.winRate           = getDeckWinRateString(deck, againstClass: againstClass)
            dataRow.winRateNumber     = getDeckWinRate(deck, againstClass: againstClass)
            dataRow.totalGames        = getDeckRecord(deck, againstClass: againstClass).total
            
            tableData.append(dataRow)
        }
        
        return tableData
    }
    
    static func getDeckRecordString(deck: Deck, againstClass: String = "all") -> String {
        let record = getDeckRecord(deck, againstClass: againstClass)
        let recordString: String = "\(record.wins)-\(record.losses)"
        
        return recordString
    }
    
    static func getDeckWinRate(deck: Deck, againstClass: String = "all") -> Double {
        let record = getDeckRecord(deck, againstClass: againstClass)
        
        let totalGames = record.wins + record.losses
        var winRate = -1.0
        if totalGames > 0 {
            winRate = Double(record.wins)/Double(totalGames)
        }
        return winRate
    }
    
    static func getDeckWinRateString(deck: Deck, againstClass: String = "all") -> String {
        var winRateString = "N/A"
        let winRate = getDeckWinRate(deck, againstClass: againstClass)
        if winRate >= 0.0 {
            let winPercent = Int(round(winRate * 100))
            winRateString = String(winPercent) + "%"
        }
        return winRateString
    }
    
    static func getDeckRecord(deck: Deck, againstClass: String = "all")
        -> (wins: Int, losses: Int, draws: Int, total: Int) {
        var stats = deck.statistics
        if againstClass.lowercaseString != "all" {
            stats = deck.statistics.filter({$0.opponentClass == againstClass.lowercaseString})
        }
        
        let wins = stats.filter({$0.gameResult == GameResult.Win}).count
        let losses = stats.filter({$0.gameResult == GameResult.Loss}).count
        let draws = stats.filter({$0.gameResult == GameResult.Draw}).count
    
        return (wins, losses, draws, wins+losses+draws)
    }
    
}
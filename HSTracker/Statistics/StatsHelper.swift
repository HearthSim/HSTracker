//
//  StatsHelper.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/9/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class StatsHelper {
    static let playerClassList = ["druid", "hunter", "mage", "rogue", "paladin", "priest", "shaman", "warlock", "warrior"]
    
    static func getStatsUITableData(deck: Deck) -> [Dictionary<String,String>] {
        var tableData = [Dictionary<String,String>]()
        
        for againstClass in ["all"] + StatsHelper.playerClassList{
            var dataRow = [String: String]()
            
            if againstClass == "all"{
                dataRow["classIcon"] = "AppIcon"
            } else {
                dataRow["classIcon"] = againstClass
            }
            dataRow["className"] = againstClass.capitalizedString
            dataRow["record"]    = getDeckRecordString(deck, againstClass: againstClass)
            dataRow["winRate"]   = getDeckWinRateString(deck, againstClass: againstClass)
            
            tableData.append(dataRow)
        }
        
        return tableData
    }
    
    static func getDeckRecordString(deck: Deck, againstClass: String = "all") -> String {
        let record = getDeckRecord(deck, againstClass: againstClass)
        let recordString: String = "\(record.wins)-\(record.losses)"
        
        return recordString
    }
    
    static func getDeckWinRateString(deck: Deck, againstClass: String = "all") -> String {
        let record = getDeckRecord(deck, againstClass: againstClass)
        
        var winRateString = "N/A"
        let totalGames = record.wins + record.losses
        if totalGames > 0 {
            let winRate = Double(record.wins)/Double(totalGames) * 100
            winRateString = String(Int(round(winRate))) + "%"
        }
        
        return winRateString
    }
    
    static func getDeckRecord(deck: Deck, againstClass: String = "all") -> (wins: Int, losses: Int, draws: Int) {
        var stats = deck.statistics
        if againstClass.lowercaseString != "all" {
            stats = deck.statistics.filter({$0.opponentClass == againstClass.lowercaseString})
        }
        
        let wins = stats.filter({$0.gameResult == GameResult.Win}).count
        let losses = stats.filter({$0.gameResult == GameResult.Loss}).count
        let draws = stats.filter({$0.gameResult == GameResult.Draw}).count
    
        return (wins, losses, draws)
    }
    
}
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
    
    static func binomialProportionCondifenceInterval(wins: Int, losses: Int, confidence: Double = 0.1) -> (lower: Double, upper: Double, mean: Double) {
        // Implements the Wilson interval
        
        let alpha = 1.0-confidence
        assert(alpha >= 0.0)
        assert(alpha <= 1.0)
        
        let n = Double(wins + losses)
        // bounds checking
        if n < 1 {
            return (0.0, 1.0, 0.5)
        }
        
        let quantile = 1 - 0.5*alpha
        let z = sqrt(2)*erfinv(2*quantile-1)
        
        let p = Double(wins)/Double(n)
        
        let center = p + z*z/(2*n)
        let spread = z*sqrt(p*(1-p)/n + z*z/(4*n*n))
        let prefactor = 1/(1+z*z/n)
        
        var lower = prefactor*(center-spread)
        var upper = prefactor*(center+spread)
        let mean = prefactor*(center)
        
        lower = max(lower, 0.0)
        upper = min(upper, 1.0)
        
        return (lower, upper, mean)
    }
    
    static func erfinv(y: Double) -> Double {
        // http://stackoverflow.com/questions/36784763/is-there-an-inverse-error-function-available-in-swifts-foundation-import
        
        let center = 0.7
        let a = [ 0.886226899, -1.645349621,  0.914624893, -0.140543331]
        let b = [-2.118377725,  1.442710462, -0.329097515,  0.012229801]
        let c = [-1.970840454, -1.624906493,  3.429567803,  1.641345311]
        let d = [ 3.543889200,  1.637067800]
        if abs(y) <= center {
            let z = pow(y,2)
            let num = (((a[3]*z + a[2])*z + a[1])*z) + a[0]
            let den = ((((b[3]*z + b[2])*z + b[1])*z + b[0])*z + 1.0)
            var x = y*num/den
            x = x - (erf(x) - y)/(2.0/sqrt(M_PI)*exp(-x*x))
            x = x - (erf(x) - y)/(2.0/sqrt(M_PI)*exp(-x*x))
            return x
        }
        else if abs(y) > center && abs(y) < 1.0 {
            let z = pow(-log((1.0-abs(y))/2),0.5)
            let num = ((c[3]*z + c[2])*z + c[1])*z + c[0]
            let den = (d[1]*z + d[0])*z + 1
            // should use the sign function instead of pow(pow(y,2),0.5)
            var x = y/pow(pow(y,2),0.5)*num/den
            x = x - (erf(x) - y)/(2.0/sqrt(M_PI)*exp(-x*x))
            x = x - (erf(x) - y)/(2.0/sqrt(M_PI)*exp(-x*x))
            return x
        }
        else if abs(y) == 1 {
            return y*Double(Int.max)
        }
        else {
            return Double.NaN
        }
    }
    
}
//
//  LadderGrid.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/25/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import SQLite
import CleanroomLogger

// Reads precomputed Monte Carlo data from grid.db
// TODO: run long simulation on cluster for better grid

struct LadderGrid {
    var db: Connection?
    let grid = Table("grid")
    let colTargetRank = Expression<Int64>("target_rank")
    let colStars = Expression<Int64>("stars")
    let colBonus = Expression<Int64>("bonus")
    let colWinp = Expression<Double>("winp")
    let colGames = Expression<Double>("games")
    
    init() {
        do {
            // TODO: put the db in the bundle
            let path = NSBundle.mainBundle().resourcePath! + "/Resources/grid.db"
            Log.info?.message("Loading grid at \(path)")
            db = try Connection(path, readonly: true)
            Log.info?.message("Loaded grid db!")
        } catch {
            db = nil
            // swiftlint:disable line_length
            Log.warning?.message("Failed to load grid db! Will result in Ladder stats tab not working.")
            // swiftlint:enable line_length
        }
    }
    
    func getGamesToRank(targetRank: Int, stars: Int, bonus: Int, winp: Double) -> Double? {
        guard let dbgood = db
            else { return nil }
        
        let query = grid.select(colGames)
            .filter(colTargetRank == Int64(targetRank))
            .filter(colStars == Int64(stars))
            .filter(colBonus == Int64(bonus))
        
        // Round to nearest hundredth
        let lowerWinp = Double(floor(winp*100)/100)
        let upperWinp = Double(ceil(winp*100)/100)
        
        let lower = query.filter(colWinp == lowerWinp)
        let upper = query.filter(colWinp == upperWinp)
        
        guard let lowerResult = dbgood.pluck(lower), upperResult = dbgood.pluck(upper)
            else { return nil }
        
        let l = lowerResult[colGames]
        let u = upperResult[colGames]
        
        // Linear interpolation
        if lowerWinp == upperWinp {
            return l
        } else {
            return l * ( 1 - ( winp - lowerWinp) / 0.01) + u * (winp - lowerWinp)/0.01
        }
    }
    
}

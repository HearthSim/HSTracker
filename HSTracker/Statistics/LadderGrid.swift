//
//  LadderGrid.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/25/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import GRDB

// Reads precomputed Monte Carlo data from grid.db
// TODO: run long simulation on cluster for better grid

class LadderGrid {
    var dbQueue: DatabaseQueue?

    init() {
        do {
            guard let path = Bundle(for: type(of: self))
                .path(forResource: "Resources/grid", ofType: "db") else {
                    logger.warning("Failed to load grid db! "
                        + "Will result in Ladder stats tab not working.")
                    return
            }
            logger.verbose("Loading grid at \(path)")
            dbQueue = try DatabaseQueue(path: path)
        } catch {
            dbQueue = nil
            logger.warning("Failed to load grid db! "
                + "Will result in Ladder stats tab not working.")
        }
    }
    
    func getGamesToRank(targetRank: Int, stars: Int, bonus: Int, winp: Double) -> Double? {
        guard let dbQueue = dbQueue else { return nil }

        // Round to nearest hundredth
        let lowerWinp = Double(floor(winp * 100) / 100)
        let upperWinp = Double(ceil(winp * 100) / 100)

        var lowerResult: Double?
        var upperResult: Double?
        dbQueue.inDatabase { db in
            var query: String = "select games from grid"
                + " where target_rank = \(targetRank)"
                + " and stars = \(stars)"
                + " and bonus = \(bonus)"
                + " and winp = \(lowerWinp)"
            lowerResult = try? Double.fetchOne(db, query) ?? 0

            query = "select games from grid"
            + " where target_rank = \(targetRank)"
            + " and stars = \(stars)"
            + " and bonus = \(bonus)"
            + " and winp = \(upperWinp)"
            upperResult = try? Double.fetchOne(db, query) ?? 0
        }

        guard let lower = lowerResult, let upper = upperResult else { return nil }
        
        // Linear interpolation
        if lowerWinp == upperWinp {
            return lower
        } else {
            return lower * (1 - (winp - lowerWinp) / 0.01) + upper * (winp - lowerWinp) / 0.01
        }
    }
    
}

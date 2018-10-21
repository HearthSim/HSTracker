//
//  LadderGrid.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/25/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import FMDB

// Reads precomputed Monte Carlo data from grid.db
// TODO: run long simulation on cluster for better grid

class LadderGrid {
    var dbQueue: FMDatabaseQueue?

    init() {
        guard let path = Bundle(for: type(of: self))
            .path(forResource: "Resources/grid", ofType: "db") else {
                logger.warning("Failed to load grid db! "
                    + "Will result in Ladder stats tab not working.")
                return
        }
        logger.verbose("Loading grid at \(path)")
        dbQueue = FMDatabaseQueue.init(path: path)

        guard dbQueue != nil else {
            logger.warning("Failed to load grid db! "
                + "Will result in Ladder stats tab not working.")
            return
        }
    }

    deinit {
        dbQueue?.close()
    }
    
    func getGamesToRank(targetRank: Int, stars: Int, bonus: Int, winp: Double) -> Double? {
        guard let dbQueue = dbQueue else { return nil }

        // Round to nearest hundredth
        let lowerWinp = Double(floor(winp * 100) / 100)
        let upperWinp = Double(ceil(winp * 100) / 100)

        var lowerResult: FMResultSet?
        var upperResult: FMResultSet?
        dbQueue.inDatabase { db in
            var query: String = "SELECT games FROM grid"
                + " WHERE target_rank = \(targetRank)"
                + " AND stars = \(stars)"
                + " AND bonus = \(bonus)"
                + " AND winp = \(lowerWinp)"
            lowerResult = try? db.executeQuery(query, values: nil)
            lowerResult?.next()

            query = "SELECT games FROM grid"
            + " WHERE target_rank = \(targetRank)"
            + " AND stars = \(stars)"
            + " AND bonus = \(bonus)"
            + " AND winp = \(upperWinp)"
            upperResult = try? db.executeQuery(query, values: nil)
            upperResult?.next()
        }

        guard let lower = lowerResult?.double(forColumn: "games"),
            let upper = upperResult?.double(forColumn: "games") else {
            return nil
        }

        // Linear interpolation
        if lowerWinp == upperWinp {
            return lower
        } else {
            return lower * (1 - (winp - lowerWinp) / 0.01) + upper * (winp - lowerWinp) / 0.01
        }
    }
    
}

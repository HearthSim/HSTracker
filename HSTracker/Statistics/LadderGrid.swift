//
//  LadderGrid.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/25/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import GRDB
import CleanroomLogger

// Reads precomputed Monte Carlo data from grid.db
// TODO: run long simulation on cluster for better grid

struct LadderGrid {
    var dbQueue: DatabaseQueue?

    init() {
        do {
            // TODO: put the db in the bundle
            let path = Bundle.main.resourcePath! + "/Resources/grid.db"
            Log.verbose?.message("Loading grid at \(path)")
            dbQueue = try DatabaseQueue(path: path)
        } catch {
            dbQueue = nil
            // swiftlint:disable line_length
            Log.warning?.message("Failed to load grid db! Will result in Ladder stats tab not working.")
            // swiftlint:enable line_length
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
            lowerResult = Double.fetchOne(db, query)

            query = "select games from grid"
            + " where target_rank = \(targetRank)"
            + " and stars = \(stars)"
            + " and bonus = \(bonus)"
            + " and winp = \(upperWinp)"
            upperResult = Double.fetchOne(db, query)
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

//
//  LadderGrid.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/25/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import SQLite3

// Reads precomputed Monte Carlo data from grid.db
// TODO: run long simulation on cluster for better grid

class LadderGrid {
    private var db: OpaquePointer?
    // Serializes access to the connection, as FMDatabaseQueue used to
    private let queue = DispatchQueue(label: "net.hearthsim.hstracker.laddergrid")

    init() {
        guard let path = Bundle(for: type(of: self))
            .path(forResource: "Resources/grid", ofType: "db") else {
                logger.warning("Failed to load grid db! "
                    + "Will result in Ladder stats tab not working.")
                return
        }
        logger.verbose("Loading grid at \(path)")

        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            logger.warning("Failed to load grid db! "
                + "Will result in Ladder stats tab not working.")
            sqlite3_close(db)
            db = nil
            return
        }
    }

    deinit {
        sqlite3_close(db)
    }

    private func games(targetRank: Int, stars: Int, bonus: Int, winp: Double) -> Double? {
        let query = "SELECT games FROM grid"
            + " WHERE target_rank = ?"
            + " AND stars = ?"
            + " AND bonus = ?"
            + " AND winp = ?"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            logger.error("LadderGrid query failed: \(String(cString: sqlite3_errmsg(db)))")
            return nil
        }
        defer {
            sqlite3_finalize(statement)
        }
        sqlite3_bind_int64(statement, 1, Int64(targetRank))
        sqlite3_bind_int64(statement, 2, Int64(stars))
        sqlite3_bind_int64(statement, 3, Int64(bonus))
        sqlite3_bind_double(statement, 4, winp)

        // FMResultSet.double(forColumn:) read 0 when no row matched
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }
        return sqlite3_column_double(statement, 0)
    }

    func getGamesToRank(targetRank: Int, stars: Int, bonus: Int, winp: Double) -> Double? {
        guard db != nil else { return nil }

        // Round to nearest hundredth
        let lowerWinp = Double(floor(winp * 100.0) / 100.0)
        let upperWinp = Double(ceil(winp * 100.0) / 100.0)

        let (lowerResult, upperResult) = queue.sync {
            (games(targetRank: targetRank, stars: stars, bonus: bonus, winp: lowerWinp),
             games(targetRank: targetRank, stars: stars, bonus: bonus, winp: upperWinp))
        }

        guard let lower = lowerResult, let upper = upperResult else {
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

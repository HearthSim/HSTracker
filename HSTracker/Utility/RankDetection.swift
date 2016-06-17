//
//  RankDetection.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 17/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct RankDetection {
    
    static func playerRank() -> Int? {
        if let image = ImageUtilities.screenshotPlayerRank() {
            let imageCmp = ImageCompare(original: image)
            let rank = imageCmp.rank()
            Log.info?.message("detected rank : \(rank)")
            if rank > 0 {
                return rank
            }
        }
        return nil
    }
    
}
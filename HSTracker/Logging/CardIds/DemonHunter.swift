//
//  DemonHunter.swift
//  HSTracker
//
//  Created by Martin BONNIN on 07/04/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

extension CardIds.Collectible {
    struct DemonHunter {
        static let Illidan: String = "HERO_10"
        static let Marrowslicer = "SCH_252"
        static let FuryRank1 = "BAR_891"
        static let AzsharanDefector = "TSC_057"
    }
}

extension CardIds.NonCollectible {
    struct DemonHunter {
        static let FuryRank1_FuryRank2Token = "BAR_891t"
        static let FuryRank1_FuryRank3Token = "BAR_891t2"
        static let AzsharanDefector_SunkenDefectorToken = "TSC_057t"
    }
}

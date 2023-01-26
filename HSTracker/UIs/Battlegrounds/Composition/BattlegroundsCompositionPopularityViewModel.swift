//
//  BattlegroundsCompositionPopularityViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/11/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

//swiftlint:disable type_name
class BattlegroundsCompositionPopularityViewModel {
//swiftlint:enable type_name
    init(compsData: [BattlegroundsComposition]) {
        let top3Comps = compsData.take(3)
        let maxVal = Double.maximum(top3Comps[0].popularity, 40.0)
        top3Compositions = top3Comps.compactMap { x in
            return BattlegroundsCompositionPopularityRowViewModel(name: x.name, minionDbfId: x.key_minions_top3[0], available: x.is_valid, popularity: x.popularity, maxPopularity: maxVal)
        }
    }
    
    let top3Compositions: [BattlegroundsCompositionPopularityRowViewModel]
}

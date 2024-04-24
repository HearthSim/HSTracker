//
//  BattlegroundsCompositionPopularityViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/11/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompositionPopularityViewModel {
    init(compsData: [BattlegroundsComposition]) {
        let top3Comps = compsData.sorted(by: { $0.popularity > $1.popularity}).take(3)
        if top3Comps.count > 0 {
            let maxVal = Double.maximum(top3Comps[0].popularity, 40.0)
            top3Compositions = top3Comps.filter { compData in compData.key_minions_top3.count > 0 }.compactMap { x in
                return BattlegroundsCompositionPopularityRowViewModel(name: x.name, minionDbfId: x.key_minions_top3[0], available: x.is_valid, popularity: x.popularity, maxPopularity: maxVal)
            }
        } else {
            top3Compositions = [BattlegroundsCompositionPopularityRowViewModel]()
        }
    }
    
    let top3Compositions: [BattlegroundsCompositionPopularityRowViewModel]
}

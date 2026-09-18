//
//  ConstructedSingleCardStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/17/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SingleCardStats: MulliganGuideData.CardStats {
    init(dbf_id: Int) {
        super.init(dbf_id: dbf_id)
    }
    
    var rank: Int?
    
    var baseWinRate: Double?
    
    static func groupCardStats(stats: [Int: MulliganGuideData.CardStats], baseWinRate: Double?) -> [Int: SingleCardStats] {
        var rank = 1
        let temp = stats.sorted(by: { (a, b) in a.value.opening_hand_winrate ?? 0.0 > b.value.opening_hand_winrate ?? 0.0 }).compactMap { x in
            let stats = x.value
            let res = SingleCardStats(dbf_id: x.key)
            if let ohw = stats.opening_hand_winrate {
                res.opening_hand_winrate = max(min(ohw, 100.0), 0.0)
            }
            if let kp = stats.keep_percentage {
                res.keep_percentage = max(min(kp, 100.0), 0.0)
            }
            // HDT's `Rank = stats.OpeningHandWinrate != null ? rank++ : null`: a
            // card the server has no winrate for takes no rank *and does not
            // consume one*, so the ranks stay 1..n over the cards that have one
            // and the rank gradient keeps lining up with maxRank.
            if stats.opening_hand_winrate != nil {
                res.rank = rank
                rank += 1
            } else {
                res.rank = nil
            }
            res.baseWinRate = baseWinRate
            return res
        }
        return Dictionary(uniqueKeysWithValues: temp.compactMap { x in (x.dbf_id, x) })}
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

// HDT's ConstructedMulliganSingleCardViewModel: one offered card's column in
// the V1 guide. Identifiable so the guide's card row can ForEach over them -
// by identity, since two copies of the same card can be offered at once and a
// dbfId would collide.
class ConstructedMulliganSingleCardViewModel: ObservableObject, Identifiable {
    let cardHeaderVM: ConstructedMulliganSingleCardHeaderViewModel
    let dbfId: Int?

    init(stats: SingleCardStats?, maxRank: Int?) {
        dbfId = stats?.dbf_id
        self.cardHeaderVM = ConstructedMulliganSingleCardHeaderViewModel(rank: stats?.rank, mulliganWr: stats?.opening_hand_winrate, keepRate: stats?.keep_percentage, maxRank: maxRank, baseWinRate: stats?.baseWinRate)
    }
}

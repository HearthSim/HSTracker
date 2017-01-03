//
//  BnetGameType.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 1/11/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum BnetGameType: Int {
    case bgt_unknown = 0,
    bgt_friends = 1,
    bgt_ranked_standard = 2,
    bgt_arena = 3,
    bgt_vs_ai = 4,
    bgt_tutorial = 5,
    bgt_async = 6,
    bgt_casual_standard = 7,
    bgt_test1 = 8,
    bgt_newbie = 9,
    bgt_test3 = 10,
    bgt_tavernbrawl_pvp = 16,
    bgt_tavernbrawl_1p_versus_ai = 17,
    bgt_tavernbrawl_2p_coop = 18,
    bgt_ranked_wild = 30,
    bgt_casual_wild = 31,
    bgt_last = 32
}

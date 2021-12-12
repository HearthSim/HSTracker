//
//  GameType.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum GameType: Int {
    case gt_unknown = 0,
    gt_vs_ai = 1,
    gt_vs_friend = 2,
    gt_tutorial = 4,
    gt_arena = 5,
    gt_test = 6,
    gt_ranked = 7,
    gt_casual = 8,
    gt_tavernbrawl = 16,
    gt_tb_1p_vs_ai = 17,
    gt_tb_2p_coop = 18,
    gt_fsg_brawl_vs_friend = 19,
    gt_fsg_brawl = 20,
    gt_fsg_brawl_1p_vs_ai = 21,
    gt_fsg_brawl_2p_coop = 22,
    gt_battlegrounds = 23,
    gt_battlegrounds_friendly = 24,
    gt_pvpdr_paid = 28,
    gt_pvpdr = 29,
    gt_mercenaries_pvp = 30,
    gt_mercenaries_pve = 31,
    gt_mercenaries_pve_coop = 32,
    gt_mercenaries_ai_vs_ai = 33,
    gt_mercenaries_friendly = 34
}

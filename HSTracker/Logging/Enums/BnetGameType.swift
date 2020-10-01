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
    bgt_newbie = 9,
    //bgt_casual_standard_newbie = 9,
    //bgt_casual_standard_normal = 10,
    bgt_casual_standard = 10,
    bgt_test1 = 11,
    bgt_test2 = 12,
    bgt_test3 = 13,
    bgt_tavernbrawl_pvp = 16,
    bgt_tavernbrawl_1p_versus_ai = 17,
    bgt_tavernbrawl_2p_coop = 18,
    bgt_ranked_wild = 30,
    bgt_casual_wild = 31,
    bgt_fsg_brawl_vs_friend = 40,
    bgt_fsg_brawl_pvp = 41,
    bgt_fsg_brawl_1p_versus_ai = 42,
    bgt_fsg_brawl_2p_coop = 43,
    bgt_battlegrounds = 50,
    bgt_battlegrounds_friendly = 51

    static func getBnetGameType(gameType: GameType, format: Format?) -> BnetGameType {
        switch gameType {
        case .gt_vs_ai:
            return .bgt_vs_ai
        case .gt_vs_friend:
            return .bgt_friends
        case .gt_tutorial:
            return .bgt_tutorial
        case .gt_arena:
            return .bgt_arena
        case .gt_test:
            return .bgt_test1
        case .gt_ranked:
            return format == .standard ? .bgt_ranked_standard : .bgt_ranked_wild
        case .gt_casual:
            return format == .standard ? .bgt_casual_standard : .bgt_casual_wild
        case .gt_tavernbrawl:
            return .bgt_tavernbrawl_pvp
        case .gt_tb_1p_vs_ai:
            return .bgt_tavernbrawl_1p_versus_ai
        case .gt_tb_2p_coop:
            return .bgt_tavernbrawl_2p_coop
        case .gt_fsg_brawl:
            return .bgt_fsg_brawl_vs_friend
        case .gt_fsg_brawl_1p_vs_ai:
            return .bgt_fsg_brawl_1p_versus_ai
        case .gt_fsg_brawl_2p_coop:
            return .bgt_fsg_brawl_2p_coop
        case .gt_fsg_brawl_vs_friend:
            return .bgt_fsg_brawl_vs_friend
        case .gt_battlegrounds:
            return .bgt_battlegrounds
        case .gt_battlegrounds_friendly:
            return .bgt_battlegrounds_friendly
        default:
            return .bgt_unknown
        }
    }

    static func getGameType(mode: GameMode, format: Format?) -> BnetGameType {
        switch mode {
        case .arena:
            return .bgt_arena
        case .ranked:
            return format == .standard ? .bgt_ranked_standard : .bgt_ranked_wild
        case .casual:
            return format == .standard ? .bgt_casual_standard : .bgt_casual_wild
        case .brawl:
            return .bgt_tavernbrawl_pvp
        case .friendly:
            return .bgt_friends
        case .practice:
            return .bgt_vs_ai
        default:
            return .bgt_unknown
        }
    }
}

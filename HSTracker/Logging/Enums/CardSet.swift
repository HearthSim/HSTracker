//
//  CardSet.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 8/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum CardSet: String, CaseIterable {
    case all, invalid // fake one
    case basic,
    expert1,
    naxx,
    missions,
    gvg,
    brm,
    tgt,
    credits,
    loe,
    promo,
    reward,
    hero_skins,
    tb,
    og,
    kara,
    gangs,
    ungoro,
    hof,
    icecrown, // Knights of the frozen Throne
    lootapalooza, // Kobolds & Catacombs
    gilneas, // witchwood
    taverns_of_time,
    boomsday,
    troll, // Rastakhan's Rumble
    dalaran, // rise of the shadows
    uldum, // Saviors of Uldmu
    wild_event,
    dragons, // Descent of Dragons
    year_of_the_dragon,
    black_temple,
    demon_hunter_initiate,
    scholomance,
    battlegrounds,
    darkmoon_faire,
    the_barrens, // Forged in the Barrens
    wailing_caverns,
    stormwind,
    lettuce,
    alterac_valley,
    legacy,
    core,
    vanilla,
    the_sunken_city,
    revendreth,
    mercenaries_dev,
    return_of_the_lich_king,
    path_of_arthas,
    battle_of_the_bands,
    placeholder_202204,
    titans,
    wild_west,
    whizbangs_workshop,
    wonders,
    tutorial,
    event,
    island_vacation,
    space,
    emerald_dream,
    the_lost_city
    
    static func deckManagerValidCardSets() -> [CardSet] {
        return [.all, .vanilla, .core, .basic, .expert1, .naxx, .gvg, .brm, .tgt,
                .loe, .og, .kara, .gangs, .ungoro, .icecrown,
                .lootapalooza, .gilneas, .boomsday, .troll,
                .dalaran, .uldum, .dragons, .year_of_the_dragon,
                .black_temple, .demon_hunter_initiate, .scholomance, .darkmoon_faire,
                .the_barrens, .wailing_caverns, .stormwind, .alterac_valley,
                .the_sunken_city, .revendreth, .return_of_the_lich_king, .path_of_arthas,
                .battle_of_the_bands, .titans, .wonders, .wild_west,
                .whizbangs_workshop, .island_vacation, .space,
                .emerald_dream, .the_lost_city]
    }
    
    static func wildSets() -> [CardSet] {
        return [.brm, .loe, .tgt, .hof,
                .naxx, .gvg, .promo,
                .kara, .og, .gangs,
                .ungoro, .icecrown, .lootapalooza,
                .gilneas, .boomsday, .troll,
                .dalaran, .uldum, .wild_event, .dragons, .year_of_the_dragon,
                .wonders, .legacy,
                .black_temple, .demon_hunter_initiate, .scholomance, .darkmoon_faire,
                .the_barrens, .wailing_caverns, .stormwind, .alterac_valley,
                .the_sunken_city, .revendreth, .return_of_the_lich_king, .path_of_arthas,
                .battle_of_the_bands, .titans, .wild_west]
    }
    
    static func classicSets() -> [CardSet] {
        return [ .vanilla ]
    }
    
    static func twistSets() -> [CardSet] {
        return [ .battle_of_the_bands, .return_of_the_lich_king, .path_of_arthas,
                 .revendreth, .the_sunken_city, .core,
                 .alterac_valley, .stormwind, .the_barrens,
                 .darkmoon_faire, .scholomance, .demon_hunter_initiate,
                 .black_temple]
    }
}

public enum CardSetInt: Int {
    case invalid = 0,
    test_temporary = 1,
    basic = 2,
    expert1 = 3,
    hof = 4,
    missions = 5,
    demo = 6,
    none = 7,
    cheat = 8,
    blank = 9,
    debug_sp = 10,
    promo = 11,
    naxx = 12,
    gvg = 13,
    brm = 14,
    tgt = 15,
    credits = 16,
    hero_skins = 17,
    tb = 18,
    slush = 19,
    loe = 20,
    og = 21,
    og_reserve = 22,
    kara = 23,
    kara_reserve = 24,
    gangs = 25,
    gangs_reserve = 26,
    ungoro = 27,
    icecrown = 1001,
    lootapalooza = 1004,
    gilneas = 1125,
    boomsday = 1127,
    troll = 1129,
    dalaran = 1130,
    taverns_of_time = 1143,
    uldum = 1158,
    dragons = 1347,
    year_of_the_dragon = 1403,
    black_temple = 1414,
    wild_event = 1439,
    scholomance = 1443,
    battlegrounds = 1453,
    demon_hunter_initiate = 1463,
    darkmoon_faire = 1466,
    the_barrens = 1525,
    wailing_caverns = 1559,
    stormwind = 1578,
    lettuce = 1586,
    alterac_valley = 1626,
    legacy = 1635,
    core = 1637,
    vanilla = 1646,
    the_sunken_city = 1658,
    revendreth = 1691,
    mercenaries_dev = 1705,
    return_of_the_lich_king = 1776,
    battle_of_the_bands = 1809,
    placeholder_202204 = 1810,
    titans = 1858,
    path_of_arthas = 1869,
    wild_west = 1892,
    whizbangs_workshop = 1897,
    wonders = 1898,
    tutorial = 1904,
    event = 1941,
    island_vacation = 1905,
    space = 1935,
    emerald_dream = 1946,
    the_lost_city = 1952
}

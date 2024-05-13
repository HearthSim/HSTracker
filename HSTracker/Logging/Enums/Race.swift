//
//  Race.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 13/07/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum Race: String, CaseIterable {
    case invalid,
    bloodelf,
    draenei,
    dwarf,
    gnome,
    goblin,
    human,
    nightelf,
    orc,
    tauren,
    troll,
    undead,
    worgen,
    goblin2,
    murloc,
    demon,
    scourge,
    mechanical,
    elemental,
    ogre,
    beast,
    totem,
    nerubian,
    pirate,
    dragon,
    blank,
    all,
    race_27,
    race_28,
    race_29,
    race_30,
    race_31,
    race_32,
    race_33,
    race_34,
    race_35,
    race_36,
    race_37,
    egg,
    race_39,
    race_40,
    race_41,
    race_42,
    quilboar,
    race_44,
    race_45,
    race_46,
    race_47,
    race_48,
    race_49,
    race_50,
    race_51,
    race_52,
    race_53,
    race_54,
    race_55,
    race_56,
    race_57,
    race_58,
    race_59,
    race_60,
    race_61,
    race_62,
    race_63,
    race_64,
    race_65,
    race_66,
    race_67,
    race_68,
    race_69,
    race_70,
    race_71,
    race_72,
    race_73,
    race_74,
    race_75,
    race_76,
    race_77,
    race_78,
    race_79,
    centaur,
    furbolg,
    race_82,
    highelf,
    treant,
    owlkin,
    race_86,
    race_87,
    halforc,
    lock,
    race_90,
    race_91,
    naga,
    oldgod,
    pandaren,
    gronn,
    celestial,
    gnoll,
    golem,
    harpy,
    vulpera
    
    static var lookup = [Int: Race]()
    static var reverseLookup = [Race: Int]()
    
    static func initialize() {
        var index = 0
        for _enum in Race.allCases {
            Race.lookup[index] = _enum
            Race.reverseLookup[_enum] = index
            index += 1
        }
    }
    
    static func lookup(_ race: Race) -> Int {
        if let res = reverseLookup[race] {
            return res
        }
        return -1
    }
    
    init?(rawValue: Int) {
        if let _enum = Race.lookup[rawValue] {
            self = _enum
            return
        }
        return nil
    }
}

class RaceUtils {
    static let tagRaceMap: [Int: Race] = [
        2524: Race.bloodelf,
        2525: Race.draenei,
        2526: Race.dwarf,
        2527: Race.gnome,
        2528: Race.goblin,
        2529: Race.human,
        2530: Race.nightelf,
        2531: Race.orc,
        2532: Race.tauren,
        2533: Race.troll,
        2534: Race.undead,
        2535: Race.worgen,
        2536: Race.murloc,
        2537: Race.demon,
        2538: Race.scourge,
        2539: Race.mechanical,
        2540: Race.elemental,
        2541: Race.ogre,
        2542: Race.beast,
        2543: Race.totem,
        2544: Race.nerubian,
        2522: Race.pirate,
        2523: Race.dragon,
        2545: Race.egg,
        2546: Race.quilboar,
        2547: Race.centaur,
        2548: Race.furbolg,
        2549: Race.highelf,
        2550: Race.treant,
        2551: Race.owlkin,
        2552: Race.halforc,
        2553: Race.naga,
        2554: Race.oldgod,
        2555: Race.pandaren,
        2556: Race.gronn,
        2584: Race.celestial,
        2585: Race.gnoll,
        2586: Race.golem,
        2587: Race.harpy,
        2588: Race.vulpera
    ]
}

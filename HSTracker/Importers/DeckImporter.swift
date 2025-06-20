//
//  DeckImporter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

final class DeckImporter {
    private static var _arenaInfoCache: MirrorArenaInfo?
    
    public static var arenaInfoCache: MirrorArenaInfo? {
        get {
            if _arenaInfoCache == nil {
                _arenaInfoCache = MirrorHelper.getArenaInfo()
            }
            return _arenaInfoCache
        }
        set {
            _arenaInfoCache = newValue
        }
    }
    
    public static func fromArena(_ log: Bool = true) -> MirrorArenaInfo? {
        arenaInfoCache = MirrorHelper.getArenaInfo()
        if let arenaInfoCache, log {
            logger.info("Found new \(arenaInfoCache.wins)-\(arenaInfoCache.losses) arena deck: hero=\(arenaInfoCache.deck.hero), cards=\(arenaInfoCache.deck.cards.reduce(0, { $0 + $1.count.intValue }))")
        } else if log {
            logger.info("Found no arena deck")
        }
        return arenaInfoCache
    }
}

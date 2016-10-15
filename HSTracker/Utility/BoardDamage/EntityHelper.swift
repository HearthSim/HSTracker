//
//  EntityHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class EntityHelper {
    class func isHero(entity: Entity) -> Bool {
        return entity.hasTag(.cardtype) && entity.getTag(.cardtype) == CardType.hero.rawValue
            && entity.hasTag(.zone) && entity.getTag(.zone) == Zone.play.rawValue
    }
    
    class func getHeroEntity(forPlayer: Bool) -> Entity? {
        return getHeroEntity(forPlayer,
                             entities: Game.instance.entities,
                             id: Game.instance.player.id)
    }
    
    class func getHeroEntity(forPlayer: Bool, entities: [Int: Entity], id: Int) -> Entity? {
        var _id = id
        if !forPlayer {
				_id = (_id % 2) + 1
        }
        let heros = entities.filter { isHero($0.1) }.map { $0.1 }
        return heros.first { $0.getTag(.controller) == id }
    }
    
    class func isPlayersTurn() -> Bool {
        return isPlayersTurn(Game.instance.entities)
    }
    
    class func isPlayersTurn(entities: [Int: Entity]) -> Bool {
        let firstPlayer = entities.map { $0.1 }.first { $0.hasTag(.first_player) }
        if let firstPlayer = firstPlayer {
            let offset = firstPlayer.isPlayer ? 0 : 1
            guard let gameRoot = entities.map({ $0.1 }).first({ $0.name == "GameEntity" }) else {
                return false
            }
            let turn = gameRoot.getTag(.turn)
            return turn > 0 && (turn + offset) % 2 == 1
        }
        return false
    }
}

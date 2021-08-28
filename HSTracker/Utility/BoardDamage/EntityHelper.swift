//
//  EntityHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

// TODO: this class is very messy, clean it up
class EntityHelper {
    class func isHero(entity: Entity) -> Bool {
        return entity.has(tag: .cardtype) && entity[.cardtype] == CardType.hero.rawValue
                && entity.has(tag: .zone) && entity[.zone] == Zone.play.rawValue
    }

	class func getHeroEntity(forPlayer: Bool, game: Game) -> Entity? {
        return getHeroEntity(forPlayer: forPlayer, entities: game.entities, id: game.player.id)
    }

    class func getHeroEntity(forPlayer: Bool, entities: [Int: Entity], id: Int) -> Entity? {
        var _id = id
        if !forPlayer {
            _id = (_id % 2) + 1
        }
        let heros = entities.filter {
            isHero(entity: $0.1)
        }.map {
            $0.1
        }
        return heros.first {
            $0[.controller] == id
        }
    }

	class func isPlayersTurn(eventHandler: PowerEventHandler) -> Bool {
		let entities = eventHandler.entities
        let firstPlayer = entities.map {
            $0.1
        }.first {
            $0.has(tag: .first_player)
        }
        if let firstPlayer = firstPlayer {
			let offset = firstPlayer.isPlayer(eventHandler: eventHandler) ? 0 : 1
            guard let gameRoot = entities.map({ $0.1 })
                .first(where: { $0.name == "GameEntity" }) else {
                return false
            }
            let turn = gameRoot[.turn]
            return turn > 0 && (turn + offset) % 2 == 1
        }
        return false
    }
}

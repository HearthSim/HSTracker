//
//  BoardState.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class BoardState {
    private(set) var player: PlayerBoard
    private(set) var opponent: PlayerBoard

    init(player: PlayerBoard, opponent: PlayerBoard) {
        self.player = player
        self.opponent = opponent
    }

	convenience init(game: Game) {
		self.init(player: BoardState.createPlayerBoard(game: game),
                  opponent: BoardState.createOpponentBoard(game: game))
    }
    
    convenience init(player: [Entity], opponent: [Entity], entities: SynchronizedDictionary<Int, Entity>, playerId: Int) {
        let player = BoardState.createBoard(list: player,
                                            entities: entities,
                                            isPlayer: true,
                                            playerId: playerId)
        let opponent = BoardState.createBoard(list: opponent,
                                              entities: entities,
                                              isPlayer: false,
                                              playerId: playerId)
        
        self.init(player: player, opponent: opponent)
    }
    
    func isPlayerDeadToBoard() -> Bool {
        return player.hero == nil || opponent.damage >= player.hero?.health ?? 0
    }
    
    func isOpponentDeadToBoard() -> Bool {
        return opponent.hero == nil || player.damage >= opponent.hero?.health ?? 0
    }
    
	private class func createPlayerBoard(game: Game?) -> PlayerBoard {
        guard let game = game else {
            return createBoard(list: [], entities: SynchronizedDictionary<Int, Entity>(), isPlayer: true, playerId: -1)
        }
        return createBoard(list: game.player.board,
                           entities: game.entities,
                           isPlayer: true,
                           playerId: game.player.id)
    }
    
    private class func createOpponentBoard(game: Game?) -> PlayerBoard {
        guard let game = game else {
            return createBoard(list: [], entities: SynchronizedDictionary<Int, Entity>(), isPlayer: false, playerId: -1)
        }
        return createBoard(list: game.opponent.board,
                           entities: game.entities,
                           isPlayer: false,
                           playerId: game.player.id)
    }
    
    private class func createBoard(list: [Entity],
                                   entities: SynchronizedDictionary<Int, Entity>,
                                   isPlayer: Bool,
                                   playerId: Int) -> PlayerBoard {
        /*let activeTurn = !(EntityHelper.isPlayersTurn(entities) ^ isPlayer)
        // if there is no hero in the list, try to find it
        let heroFound = list.any { EntityHelper.isHero($0) }
        if !heroFound {
            list?.Add(EntityHelper.GetHeroEntity(isPlayer, entities, playerId))
        }*/
        
        return PlayerBoard(list: list, activeTurn: false)
    }
}

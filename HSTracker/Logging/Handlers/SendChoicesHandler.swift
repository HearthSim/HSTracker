//
//  SendChoicesHandler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/8/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class SendChoicesHandler {
    private var choice: Choice?

    func sendChoices(id: Int, choiceType: ChoiceType, game: Game) {
        choice = Choice(id: id, choiceType: choiceType)
    }

    func sendChoice(index: Int, entityId: Int, game: Game) {
        guard let choice else {
            return
        }

        if let entity = game.entities[entityId] {
            choice.attachChosenEntity(index: index, entity: entity)
        }
    }

    func flush(game: Game) {
        guard let choice else {
            return
        }

        game.handlePlayerSendChoices(choice: choice)
        self.choice = nil
    }
}

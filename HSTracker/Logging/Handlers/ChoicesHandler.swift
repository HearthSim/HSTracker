//
//  ChoicesHandler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/8/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class ChoicesHandler: LogEventParser {
    let game: Game
    private var _tmpChoice: IChoiceWithId?
    
    static let choicesHeaderRegex = Regex(#"id=(\d+) Player=(.+) TaskList=(\d+)? ChoiceType=(\w+)"#)
    static let chosenHeaderRegex = Regex(#"id=(\d+) Player=(.+) EntitiesCount=.*"#)
    static let choicesSourceRegex = Regex(#"Source=.* id=(\d+)"#)
    static let choicesEntityRegex = Regex(#"Entities\[(\d+)]=.* id=(\d+)"#)
    static let endTaskListRegex = Regex(#"m_currentTaskList=(\d+)"#)
    
    init(with game: Game) {
        self.game = game
    }
    
    func handle(logLine: LogLine) {
        var matches = ChoicesHandler.choicesHeaderRegex.matches(logLine.content)
        if matches.count > 0 {
            if _tmpChoice != nil {
                flush()
            }
            if let choiceId = Int(matches[0].value) {
                let taskList = matches.count > 3 ? Int(matches[2].value) : nil
                let playerName = matches[1].value
                let playerId = game.playerIdsByPlayerName[playerName]
                let choiceType = ChoiceType(rawString: matches[matches.count > 3 ? 3 : 2].value) ?? .invalid
                
                if let playerId {
                    _tmpChoice = ChoiceBuilder(id: choiceId, taskList: taskList, playerId: playerId, choiceType: choiceType)
                }
            }
            return
        }
        matches = ChoicesHandler.choicesSourceRegex.matches(logLine.line)
        if matches.count > 0 {
            guard let cb = _tmpChoice as? ChoiceBuilder else {
                return
            }
            cb.sourceEntityId = Int(matches[0].value)
            return
        }
        matches = ChoicesHandler.chosenHeaderRegex.matches(logLine.line)
        if matches.count > 0 {
            let id = Int(matches[0].value) ?? 0
            if _tmpChoice != nil {
                flush()
            }
            
            guard let c = game.choicesById[id], let offeredChoice = c as? OfferedChoice else {
                return
            }
            
            let playerName = matches[1].value
            let playerId = game.playerIdsByPlayerName[playerName]
            if offeredChoice.playerId != playerId {
                // the choice refers to a different player than originally - probably something is corrupt.
                return
            }
            
            _tmpChoice = offeredChoice
            return
        }
        matches = ChoicesHandler.choicesEntityRegex.matches(logLine.line)
        if matches.count > 0 {
            if _tmpChoice == nil {
                return
            }

            let id = Int(matches[1].value) ?? 0

            if let cb = _tmpChoice as? ChoiceBuilder {
                cb.attachOfferedEntity(entityId: id)
            } else if let tc = _tmpChoice as? OfferedChoice {
                tc.attachChosenEntity(entityId: id)
            }
        }
        matches = ChoicesHandler.endTaskListRegex.matches(logLine.line)
        if matches.count > 0 {
            if _tmpChoice != nil {
                flush()
            }
            
            let taskList = Int(matches[0].value) ?? 0
            if let choices = game.choicesByTaskList[taskList] {
                for choice in choices {
                    if let tc = choice as? OfferedChoice {
                        if tc.playerId == game.player.id {
                            game.handlePlayerEntityChoices(choice: tc)
                        }
                    }
                }
                game.choicesByTaskList.removeValue(forKey: taskList)
            }
        }
    }
    
    func flush() {
        guard let tmpChoice = _tmpChoice else {
            return
        }

        if let cb = tmpChoice as? ChoiceBuilder {
            let choice = cb.buildOfferedChoice()
            game.choicesById[cb.id] = choice
            let taskList = cb.taskList
            
            if let tl = taskList {
                // if the choice has a task list, we need to queue it up to show later when the task list ends
                if game.choicesByTaskList[tl] == nil {
                    game.choicesByTaskList[tl] = [IHsChoice]()
                }
                game.choicesByTaskList[tl]?.append(choice)
            } else {
                // without a task list the can emit the choice immediately
                if choice.playerId == game.player.id {
                    game.handlePlayerEntityChoices(choice: choice)
                }
            }
        } else if let tc = tmpChoice as? OfferedChoice {
            let choice = tc.buildCompletedChoice()
            game.choicesById[tc.id] = choice
            if choice.playerId == game.player.id {
                game.handlePlayerEntitiesChosen(choice: choice)
            }
        }
        _tmpChoice = nil
    }

    private protocol IChoiceWithId {
        var id: Int { get }
    }

    private class ChoiceBuilder: IChoiceWithId {
        let id: Int
        let taskList: Int?
        var playerId: Int
        var choiceType: ChoiceType
        var sourceEntityId: Int?

        init(id: Int, taskList: Int?, playerId: Int, choiceType: ChoiceType) {
            self.id = id
            self.taskList = taskList
            self.playerId = playerId
            self.choiceType = choiceType
        }

        private var offeredEntityIds: [Int] = []
        func attachOfferedEntity(entityId: Int) {
            offeredEntityIds.append(entityId)
        }

        func buildOfferedChoice() -> OfferedChoice {
            return OfferedChoice(
                id: id,
                taskList: taskList,
                playerId: playerId,
                choiceType: choiceType,
                sourceEntityId: sourceEntityId ?? 1,
                offeredEntityIds: offeredEntityIds
            )
        }
    }

    private class OfferedChoice: IHsChoice, IChoiceWithId {
        let id: Int
        let taskList: Int?
        var playerId: Int
        var choiceType: ChoiceType
        let sourceEntityId: Int
        let offeredEntityIds: [Int]?

        init(id: Int, taskList: Int?, playerId: Int, choiceType: ChoiceType, sourceEntityId: Int, offeredEntityIds: [Int]?) {
            self.id = id
            self.taskList = taskList
            self.playerId = playerId
            self.choiceType = choiceType
            self.sourceEntityId = sourceEntityId
            self.offeredEntityIds = offeredEntityIds
        }

        private var chosenEntityIds: [Int] = []
        func attachChosenEntity(entityId: Int) {
            chosenEntityIds.append(entityId)
        }

        func buildCompletedChoice() -> CompletedChoice {
            return CompletedChoice(
                id: id,
                taskList: taskList,
                playerId: playerId,
                choiceType: choiceType,
                sourceEntityId: sourceEntityId,
                offeredEntityIds: offeredEntityIds,
                chosenEntityIds: chosenEntityIds
            )
        }
    }

    private class CompletedChoice: OfferedChoice, IHsCompletedChoice {
        let chosenEntityIds: [Int]?

        init(id: Int, taskList: Int?, playerId: Int, choiceType: ChoiceType, sourceEntityId: Int, offeredEntityIds: [Int]?, chosenEntityIds: [Int]) {
            self.chosenEntityIds = chosenEntityIds
            super.init(id: id, taskList: taskList, playerId: playerId, choiceType: choiceType, sourceEntityId: sourceEntityId, offeredEntityIds: offeredEntityIds)
        }
    }

}

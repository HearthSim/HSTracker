/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import Foundation
import CleanroomLogger

class TagChangeHandler {

    let ParseEntityIDRegex = "id=(\\d+)"
    let ParseEntityZonePosRegex = "zonePos=(\\d+)"
    let ParseEntityPlayerRegex = "player=(\\d+)"
    let ParseEntityNameRegex = "name=(\\w+)"
    let ParseEntityZoneRegex = "zone=(\\w+)"
    let ParseEntityCardIDRegex = "cardId=(\\w+)"
    let ParseEntityTypeRegex = "type=(\\w+)"

    private var creationTagActionQueue = [
        (tag: GameTag, game: Game, id: Int, value: Int, prevValue: Int)
        ]()
    private var tagChangeAction = TagChangeActions()

    func tagChange(game: Game, rawTag: String, id: Int,
                   rawValue: String, isCreationTag: Bool = false) {
        if let tag = GameTag(rawString: rawTag) {
            let value = self.parseTag(tag: tag, rawValue: rawValue)
            tagChange(game: game, tag: tag, id: id, value: value,
                      isCreationTag: isCreationTag)
        } else {
            Log.warning?.message("Can't parse \(rawTag) -> \(rawValue)")
        }
    }

    func tagChange(game: Game, tag: GameTag, id: Int,
                   value: Int, isCreationTag: Bool = false) {
        if game.lastId != id {
            if let proposedKeyPoint = game.proposedKeyPoint {
                ReplayMaker.generate(type: proposedKeyPoint.type,
                                     id: proposedKeyPoint.id,
                                     player: proposedKeyPoint.player, game: game)
                game.proposedKeyPoint = nil
            }
        }
        game.lastId = id

        if id > game.maxId {
            game.maxId = id
        }

        if game.entities[id] == .none {
            game.entities[id] = Entity(id: id)
        }

        if !game.determinedPlayers {
            if let entity = game.entities[id],
                tag == .controller && entity.isInHand && String.isNullOrEmpty(entity.cardId) {
                determinePlayers(game: game, playerId: value)
            }
        }

        if let entity = game.entities[id] {
            let prevValue = entity[tag]
            entity[tag ] = value
            //print("Set tag \(tag) with value \(value) to entity \(id)")

            if isCreationTag {
                creationTagActionQueue.append((tag, game, id, value, prevValue))
            } else {
                tagChangeAction.callAction(game: game, tag: tag,
                                           id: id, value: value,
                                           prevValue: prevValue)
            }
        }
    }

    func invokeQueuedActions(game: Game) {
        while creationTagActionQueue.count > 0 {
            let act = creationTagActionQueue.removeFirst()
            tagChangeAction.callAction(game: game, tag: act.tag, id: act.id,
                                       value: act.value, prevValue: act.prevValue)

            if creationTagActionQueue.all({ $0.id != act.id }) && game.entities[act.id] != nil {
                game.entities[act.id]!.info.hasOutstandingTagChanges = false
            }
        }
    }

    func clearQueuedActions() {
        if creationTagActionQueue.count > 0 {
            // swiftlint:disable line_length
            Log.warning?.message("Clearing tagActionQueue with \(creationTagActionQueue.count) elements in it")
            // swiftlint:enable line_length
        }
        creationTagActionQueue.removeAll()
    }

    // parse an entity
    func parseEntity(entity: String) -> (id: Int?, zonePos: Int?, player: Int?,
        name: String?, zone: String?, cardId: String?, type: String?) {

        var id: Int?, zonePos: Int?, player: Int?
        if entity.match(ParseEntityIDRegex) {
            if let match = entity.matches(ParseEntityIDRegex).first {
                id = Int(match.value)
            }
        }
        if entity.match(ParseEntityZonePosRegex) {
            if let match = entity.matches(ParseEntityZonePosRegex).first {
                zonePos = Int(match.value)
            }
        }
        if entity.match(ParseEntityPlayerRegex) {
            if let match = entity.matches(ParseEntityPlayerRegex).first {
                player = Int(match.value)
            }
        }

        var name: String?, zone: String?, cardId: String?, type: String?
        if entity.match(ParseEntityNameRegex) {
            if let match = entity.matches(ParseEntityNameRegex).first {
                name = match.value
            }
        }
        if entity.match(ParseEntityZoneRegex) {
            if let match = entity.matches(ParseEntityZoneRegex).first {
                zone = match.value
            }
        }
        if entity.match(ParseEntityCardIDRegex) {
            if let match = entity.matches(ParseEntityCardIDRegex).first {
                cardId = match.value
            }
        }
        if entity.match(ParseEntityTypeRegex) {
            if let match = entity.matches(ParseEntityTypeRegex).first {
                type = match.value
            }
        }

        return (id, zonePos, player, name, zone, cardId, type)
    }

    // check if the entity is a raw entity
    func isEntity(rawEntity: String) -> Bool {
        let entity = parseEntity(entity: rawEntity)
        let a: [Any?] = [entity.id, entity.zonePos, entity.player,
                               entity.name, entity.zone, entity.cardId, entity.type]
        return a.any {$0 != nil}
    }

    func parseTag(tag: GameTag, rawValue: String) -> Int {
        switch tag {
        case .zone:
            return Zone(rawString: rawValue)!.rawValue

        case .mulligan_state:
            return Mulligan(rawString: rawValue)!.rawValue

        case .playstate:
            return PlayState(rawString: rawValue)!.rawValue

        case .cardtype:
            return CardType(rawString: rawValue)!.rawValue

        case .tag_class:
            return TagClass(rawString: rawValue)!.rawValue

        case .state:
            return State(rawString: rawValue)!.rawValue
            
        case .step:
            return Step(rawString: rawValue)!.rawValue

        default:
            if let value = Int(rawValue) {
                return value
            }
            return 0
        }
    }

    func determinePlayers(game: Game, playerId: Int, isOpponentId: Bool = true) {
        if isOpponentId {
            game.entities.map { $0.1 }
                .firstWhere { $0[.player_id] == 1 }?.isPlayer = playerId != 1
            game.entities.map { $0.1 }
                .firstWhere { $0[.player_id] == 2 }?.isPlayer = playerId == 1

            game.player.id = playerId % 2 + 1
            game.opponent.id = playerId
        } else {
            game.entities.map { $0.1 }
                .firstWhere { $0[.player_id] == 1 }?.isPlayer = playerId == 1
            game.entities.map { $0.1 }
                .firstWhere { $0[.player_id] == 2 }?.isPlayer = playerId != 1

            game.player.id = playerId
            game.opponent.id = playerId % 2 + 1
        }

        Log.info?.message("Setting player id: \(game.player.id), opponent id: \(game.opponent.id)")
        if game.wasInProgress {
            /*let playerName = game.getStoredPlayerName(game.player.id)
            if !String.isNullOrEmpty(playerName) {
                game.player.name = playerName
            }
            let opponentName = game.getStoredPlayerName(game.opponent.id)
            if !String.isNullOrEmpty(opponentName) {
                game.opponent.name = opponentName
            }*/
        }

        game.determinedPlayers = game.playerEntity != nil
    }
}

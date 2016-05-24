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

    static let ParseEntityIDRegex = "id=(\\d+)"
    static let ParseEntityZonePosRegex = "zonePos=(\\d+)"
    static let ParseEntityPlayerRegex = "player=(\\d+)"
    static let ParseEntityNameRegex = "name=(\\w+)"
    static let ParseEntityZoneRegex = "zone=(\\w+)"
    static let ParseEntityCardIDRegex = "cardId=(\\w+)"
    static let ParseEntityTypeRegex = "type=(\\w+)"

    private var creationTagActionQueue = [
        (tag: GameTag, game: Game, id: Int, value: Int, prevValue: Int)
        ]()
    private var tagChangeAction = TagChangeActions()

    func tagChange(game: Game, _ rawTag: String, _ id: Int,
                   _ rawValue: String, _ isCreationTag: Bool = false) {
        if let tag = GameTag(rawString: rawTag) {
            let value = self.parseTag(tag, rawValue)
            tagChange(game, tag, id, value, isCreationTag)
        } else {
            print("Can't parse \(rawTag) -> \(rawValue)")
        }
    }

    func tagChange(game: Game, _ tag: GameTag, _ id: Int,
                   _ value: Int, _ isCreationTag: Bool = false) {
        if game.lastId != id {
            if let proposedKeyPoint = game.proposedKeyPoint {
                ReplayMaker.generate(proposedKeyPoint.type,
                                     proposedKeyPoint.id,
                                     proposedKeyPoint.player, game)
                game.proposedKeyPoint = nil
            }
        }
        game.lastId = id

        if id > game.maxId {
            game.maxId = id
        }

        if game.entities[id] == .None {
            game.entities[id] = Entity(id)
        }

        if !game.determinedPlayers {
            if let entity = game.entities[id]
                where tag == .CONTROLLER && entity.isInHand && String.isNullOrEmpty(entity.cardId) {
                determinePlayers(game, value)
            }
        }

        if let entity = game.entities[id] {
            let prevValue = entity.getTag(tag)
            entity.setTag(tag, value)
            //print("Set tag \(tag) with value \(value) to entity \(id)")

            if isCreationTag {
                creationTagActionQueue.append((tag, game, id, value, prevValue))
            } else {
                tagChangeAction.callAction(tag, game, id, value, prevValue)
            }
        }
    }

    func invokeQueuedActions(game: Game) {
        while creationTagActionQueue.count > 0 {
            let act = creationTagActionQueue.removeFirst()
            tagChangeAction.callAction(act.tag, game, act.id, act.value, act.prevValue)

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
        if entity.match(self.dynamicType.ParseEntityIDRegex) {
            if let match = entity.matches(self.dynamicType.ParseEntityIDRegex).first {
                id = Int(match.value)
            }
        }
        if entity.match(self.dynamicType.ParseEntityZonePosRegex) {
            if let match = entity.matches(self.dynamicType.ParseEntityZonePosRegex).first {
                zonePos = Int(match.value)
            }
        }
        if entity.match(self.dynamicType.ParseEntityPlayerRegex) {
            if let match = entity.matches(self.dynamicType.ParseEntityPlayerRegex).first {
                player = Int(match.value)
            }
        }

        var name: String?, zone: String?, cardId: String?, type: String?
        if entity.match(self.dynamicType.ParseEntityNameRegex) {
            if let match = entity.matches(self.dynamicType.ParseEntityNameRegex).first {
                name = match.value
            }
        }
        if entity.match(self.dynamicType.ParseEntityZoneRegex) {
            if let match = entity.matches(self.dynamicType.ParseEntityZoneRegex).first {
                zone = match.value
            }
        }
        if entity.match(self.dynamicType.ParseEntityCardIDRegex) {
            if let match = entity.matches(self.dynamicType.ParseEntityCardIDRegex).first {
                cardId = match.value
            }
        }
        if entity.match(self.dynamicType.ParseEntityTypeRegex) {
            if let match = entity.matches(self.dynamicType.ParseEntityTypeRegex).first {
                type = match.value
            }
        }

        return (id, zonePos, player, name, zone, cardId, type)
    }

    // check if the entity is a raw entity
    func isEntity(rawEntity: String) -> Bool {
        let entity = parseEntity(rawEntity)
        let a: [AnyObject?] = [entity.id, entity.zonePos, entity.player,
                               entity.name, entity.zone, entity.cardId, entity.type]
        return a.any {$0 != nil}
    }

    func parseTag(tag: GameTag, _ rawValue: String) -> Int {
        switch tag {
        case .ZONE:
            return Zone(rawString: rawValue)!.rawValue

        case .MULLIGAN_STATE:
            return Mulligan(rawString: rawValue)!.rawValue

        case .PLAYSTATE:
            return PlayState(rawString: rawValue)!.rawValue

        case .CARDTYPE:
            return CardType(rawString: rawValue)!.rawValue

        case .CLASS:
            return TagClass(rawString: rawValue)!.rawValue

        case .STATE:
            return State(rawString: rawValue)!.rawValue

        default:
            if let value = Int(rawValue) {
                return value
            }
            return 0
        }
    }

    func determinePlayers(game: Game, _ playerId: Int, _ isOpponentId: Bool = true) {
        if isOpponentId {
            game.entities.map { $0.1 }
                .firstWhere { $0.getTag(.PLAYER_ID) == 1 }?.setPlayer(playerId != 1)
            game.entities.map { $0.1 }
                .firstWhere { $0.getTag(.PLAYER_ID) == 2 }?.setPlayer(playerId == 1)

            game.player.id = playerId % 2 + 1
            game.opponent.id = playerId
        } else {
            game.entities.map { $0.1 }
                .firstWhere { $0.getTag(.PLAYER_ID) == 1 }?.setPlayer(playerId == 1)
            game.entities.map { $0.1 }
                .firstWhere { $0.getTag(.PLAYER_ID) == 2 }?.setPlayer(playerId != 1)

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

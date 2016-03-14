/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

class TagChangeHandler {

    let ParseEntityIDRegex = "id=(\\d+)"
    let ParseEntityZonePosRegex = "zonePos=(\\d+)"
    let ParseEntityPlayerRegex = "player=(\\d+)"
    let ParseEntityNameRegex = "name=(\\d+)"
    let ParseEntityZoneRegex = "zone=(\\d+)"
    let ParseEntityCardIDRegex = "cardId=(\\d+)"
    let ParseEntityTypeRegex = "type=(\\d+)"

    private var creationTagActionQueue: [() -> ()] = []
    private var tagChangeAction = TagChangeActions()

    func tagChange(game: Game, _ rawTag: String, _ id: Int, _ rawValue: String, _ isCreationTag: Bool = false) {
        if let tag = GameTag(rawString: rawTag) {
            let value = self.parseTag(tag, rawValue)
            tagChange(game, tag, id, value, isCreationTag)
        }
    }

    func tagChange(game: Game, _ tag: GameTag, _ id: Int, _ value: Int, _ isCreationTag: Bool = false) {
        if game.lastId != id {
            if let proposedKeyPoint = game.proposedKeyPoint {
                ReplayMaker.generate(proposedKeyPoint.type, proposedKeyPoint.id, proposedKeyPoint.player, game)
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
            if let entity = game.entities[id] where tag == .CONTROLLER && entity.isInHand && String.isNullOrEmpty(entity.cardId) {
                determinePlayers(game, value)
            }
        }

        if let entity = game.entities[id] {
            let prevValue = entity.getTag(tag)
            entity.setTag(tag, value)

            if isCreationTag {
                if let action = tagChangeAction.findAction(tag, game, id, value, prevValue) {
                    creationTagActionQueue.append(action)
                }
            }
            else {
                tagChangeAction.findAction(tag, game, id, value, prevValue)?()
            }
        }
    }

    func invokeQueuedActions() {
        while creationTagActionQueue.count > 0 {
            let act = creationTagActionQueue.removeFirst()
            act()
        }
    }

    func clearQueuedActions() {
        creationTagActionQueue.removeAll()
    }

    // parse an entity
    func parseEntity(entity: String) -> (id: Int?, zonePos: Int?, player: Int?, name: String?, zone: String?, cardId: String?, type: String?) {
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
        let entity = parseEntity(rawEntity)
        return entity.id != nil || entity.zonePos != nil || entity.player != nil || entity.name != nil || entity.zone != nil || entity.cardId != nil || entity.type != nil
    }

    func parseTag(tag: GameTag, _ rawValue: String) -> Int {
        switch (tag) {
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

        default:
            if let value = Int(rawValue) {
                return value
            }
            return 0
        }
    }

    func determinePlayers(game: Game, _ playerId: Int, _ isOpponentId: Bool = true) {
        if isOpponentId {
            game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 1 }?.setPlayer(playerId != 1)
            game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 2 }?.setPlayer(playerId == 1)

            game.player.id = playerId % 2 + 1
            game.opponent.id = playerId
        }
        else {
            game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 1 }?.setPlayer(playerId == 1)
            game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 2 }?.setPlayer(playerId != 1)

            game.player.id = playerId
            game.opponent.id = playerId % 2 + 1
        }

        game.determinedPlayers = game.playerEntity != nil
    }
}

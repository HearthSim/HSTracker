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

    private var creationTagActionQueue: [() -> ()] = []
    private var tagChangeAction = TagChangeActions()

    func tagChange(rawTag: String, _ id: Int, _ rawValue: String, _ isCreationTag: Bool = false) {
        var _tag: GameTag? = GameTag(rawString: rawTag)

        if _tag == nil {
            DDLogInfo("tag not found -> rawTag \(rawTag)")
            if let num = Int(rawTag) {
                if let tag = GameTag(rawValue: num) {
                    DDLogInfo("tag not found -> rawTag \(num)")
                    _tag = tag
                }
            }
        }
        if let tag = _tag {
            let value = self.parseTag(tag, rawValue)
            tagChange(tag, id, value, isCreationTag)
        }
    }

    func tagChange(tag: GameTag, _ id: Int, _ value: Int, _ isCreationTag: Bool = false) {
        let game = Game.instance
        if game.lastId != id {
        }
        game.lastId = id

        if id > game.maxId {
            game.maxId = id
        }

        if game.entities[id] == nil {
            game.entities[id] = Entity(id)
        }

        if !game.determinedPlayers {
            if let entity = game.entities[id] {
                if tag == .CONTROLLER && entity.isInHand && String.isNullOrEmpty(entity.cardId) {
                    determinePlayers(value)
                }
            }
        }

        let prevValue = game.entities[id]!.getTag(tag)
        game.entities[id]!.setTag(tag, value)

        if isCreationTag {
            if let action = tagChangeAction.findAction(tag, game, id, value, prevValue) {
                creationTagActionQueue.append(action)
            }
        }
        else {
            tagChangeAction.findAction(tag, game, id, value, prevValue)?()
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
        if entity.isMatch(PowerGameStateHandler.ParseEntityIDRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityIDRegex)
            id = Int(match.groups[1].value)
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityZonePosRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityZonePosRegex)
            zonePos = Int(match.groups[1].value)
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityPlayerRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityPlayerRegex)
            player = Int(match.groups[1].value)
        }

        var name: String?, zone: String?, cardId: String?, type: String?
        if entity.isMatch(PowerGameStateHandler.ParseEntityNameRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityNameRegex)
            name = match.groups[1].value
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityZoneRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityZoneRegex)
            zone = match.groups[1].value
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityCardIDRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityCardIDRegex)
            cardId = match.groups[1].value
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityTypeRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityTypeRegex)
            type = match.groups[1].value
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

    func determinePlayers(playerId: Int, _ isOpponentId: Bool = true) {
        let game = Game.instance
        if isOpponentId {
            game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 1 }?.isPlayer = (playerId != 1)
            game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 2 }?.isPlayer = (playerId == 1)

            game.player.id = playerId % 2 + 1
            game.opponent.id = playerId
        }
        else {
            game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 1 }?.isPlayer = (playerId == 1)
            game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 2 }?.isPlayer = (playerId != 1)

            game.player.id = playerId
            game.opponent.id = playerId % 2 + 1
        }
        game.determinedPlayers = game.playerEntity != nil
    }
}

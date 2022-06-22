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

class TagChangeHandler {

    let ParseEntityIDRegex = Regex("id=(\\d+)")
    let ParseEntityZonePosRegex = Regex("zonePos=(\\d+)")
    let ParseEntityPlayerRegex = Regex("player=(\\d+)")
    let ParseEntityNameRegex = Regex("name=(\\w+)")
    let ParseEntityZoneRegex = Regex("zone=(\\w+)")
    let ParseEntityCardIDRegex = Regex("cardId=(\\w+)")
    let ParseEntityTypeRegex = Regex("type=(\\w+)")

    private var creationTagActionQueue: [(id: Int, action: (() -> Void))] = []
    private var tagChangeAction = TagChangeActions()
    
    func setPowerGameStateParser(parser: PowerGameStateParser) {
        tagChangeAction.setPowerGameStateParser(parser: parser)
    }

    func tagChange(eventHandler: PowerEventHandler, rawTag: String, id: Int,
                   rawValue: String, isCreationTag: Bool = false) {
        if let tag = GameTag(rawString: rawTag) {
            let value = self.parseTag(tag: tag, rawValue: rawValue)
            tagChange(eventHandler: eventHandler, tag: tag, id: id, value: value,
                      isCreationTag: isCreationTag)
        } else {
            //logger.warning("Can't parse \(rawTag) -> \(rawValue)")
        }
    }

    func tagChange(eventHandler: PowerEventHandler, tag: GameTag, id: Int,
                   value: Int, isCreationTag: Bool = false) {
        if eventHandler.entities[id] == .none {
            eventHandler.entities[id] = Entity(id: id)
        }
        
        eventHandler.lastId = id

        if let entity = eventHandler.entities[id] {
            let prevValue = entity[tag]
            entity[tag] = value

            if isCreationTag {
                if let action = tagChangeAction.findAction(eventHandler: eventHandler,
                                                        tag: tag,
                                                        id: id,
                                                        value: value,
                                                        prevValue: prevValue) {
                    entity.info.hasOutstandingTagChanges = true
                    creationTagActionQueue.append((id: id, action: action))
                }
            } else {
                tagChangeAction.findAction(eventHandler: eventHandler, tag: tag,
                                           id: id, value: value,
                                           prevValue: prevValue)?()
            }
        }
    }

    func invokeQueuedActions(eventHandler: PowerEventHandler) {
        while creationTagActionQueue.count > 0 {
            let action = creationTagActionQueue.removeFirst()
            action.action()

            if creationTagActionQueue.all({ $0.id != action.id }) && eventHandler.entities[action.id] != nil {
                eventHandler.entities[action.id]!.info.hasOutstandingTagChanges = false
            }
        }
    }

    func clearQueuedActions() {
        if creationTagActionQueue.count > 0 {
            logger.warning("Clearing tagActionQueue with \(creationTagActionQueue.count)"
                + " elements in it")
        }
        creationTagActionQueue.removeAll()
    }

    struct LogEntity {
        var id: Int?
        var zonePos: Int?
        var player: Int?
        var name: String?
        var zone: String?
        var cardId: String?
        var type: String?

        func isValid() -> Bool {
            let a: [Any?] = [id, zonePos, player, name, zone, cardId, type]
            return a.any { $0 != nil }
        }
    }

    // parse an entity
    func parseEntity(entity: String) -> LogEntity {
        var id: Int?, zonePos: Int?, player: Int?
        var name: String?, zone: String?, cardId: String?, type: String?

        if ParseEntityIDRegex.match(entity) {
            if let match = ParseEntityIDRegex.matches(entity).first {
                id = Int(match.value)
            }
        }
        if ParseEntityZonePosRegex.match(entity) {
            if let match = ParseEntityZonePosRegex.matches(entity).first {
                zonePos = Int(match.value)
            }
        }
        if ParseEntityPlayerRegex.match(entity) {
            if let match = ParseEntityPlayerRegex.matches(entity).first {
                player = Int(match.value)
            }
        }
        if ParseEntityNameRegex.match(entity) {
            if let match = ParseEntityNameRegex.matches(entity).first {
                name = match.value
            }
        }
        if ParseEntityZoneRegex.match(entity) {
            if let match = ParseEntityZoneRegex.matches(entity).first {
                zone = match.value
            }
        }
        if ParseEntityCardIDRegex.match(entity) {
            if let match = ParseEntityCardIDRegex.matches(entity).first {
                cardId = match.value
            }
        }
        if ParseEntityTypeRegex.match(entity) {
            if let match = ParseEntityTypeRegex.matches(entity).first {
                type = match.value
            }
        }

        return LogEntity(id: id, zonePos: zonePos, player: player,
                         name: name, zone: zone, cardId: cardId, type: type)
    }

    // check if the entity is a raw entity
    func isEntity(rawEntity: String) -> Bool {
        return parseEntity(entity: rawEntity).isValid()
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

        case .class:
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
}

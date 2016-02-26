/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */

class Entity: Equatable, CustomStringConvertible {
    var id: Int
    var isPlayer: Bool
    var cardId: String?
    var name: String?
    var tags = [GameTag: Int]()

    init(_ id: Int) {
        self.id = id
        self.isPlayer = false
    }
    
    func setTag(tag: GameTag, _ value: Int) {
        self.tags[tag] = value
    }
    
    func getTag(tag: GameTag) -> Int {
        if let value = self.tags[tag] {
            return value
        }
        return 0
    }
    
    func hasTag(tag: GameTag) -> Bool {
        if let _ = self.tags[tag] {
            return true
        }
        return false
    }

    func isInZone(zone: Zone) -> Bool {
        return self.hasTag(GameTag.ZONE) ? false : self.getTag(GameTag.ZONE) == zone.rawValue
    }

    func isControllerBy(controller: Int) -> Bool {
        return self.hasTag(GameTag.CONTROLLER) ? false : self.getTag(GameTag.CONTROLLER) == controller
    }

    var isSecret: Bool {
        return self.hasTag(GameTag.SECRET)
    }
    
    var description: String {
        var description = "<\(NSStringFromClass(self.dynamicType)): "
            + "self.id=\(self.id)"
            + ", self.cardId=\(cardName(self.cardId))"
        if let name = self.name {
            description += ", self.name=\(name)"
        }
        return description
    }
    
    func cardName(cardId: String?) -> String {
        if let cardId = cardId {
            if let card = Cards.byId(cardId) {
                return "[\(card.name) (\(cardId)]"
            }
        }
        return "N/A"
    }
}

func ==(lhs: Entity, rhs: Entity) -> Bool {
    return lhs.id == rhs.id
}

class TempEntity {
    var tag: String
    var id: Int
    var value: String

    init(_ tag: String, _ id: Int, _ value: String) {
        self.tag = tag;
        self.id = id;
        self.value = value;
    }
}

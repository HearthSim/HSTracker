/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */

class Entity: Hashable, CustomStringConvertible {
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

    func setPlayer(isPlayer: Bool) {
        self.isPlayer = isPlayer
    }

    var isActiveDeathrattle: Bool { return hasTag(.DEATHRATTLE) && getTag(.DEATHRATTLE) == 1 }

    var isCurrentPlayer: Bool { return hasTag(GameTag.CURRENT_PLAYER) }

    func isInZone(zone: Zone) -> Bool {
        return hasTag(.ZONE) ? getTag(.ZONE) == zone.rawValue : false
    }

    func isControlledBy(controller: Int) -> Bool {
        return self.hasTag(.CONTROLLER) ? self.getTag(.CONTROLLER) == controller : false
    }

    var isSecret: Bool { return hasTag(.SECRET) }

    var isSpell: Bool { return getTag(.CARDTYPE) == CardType.SPELL.rawValue }

    var isOpponent: Bool { return !isPlayer && hasTag(.PLAYER_ID) }

    var isMinion: Bool { return hasTag(.CARDTYPE) && getTag(.CARDTYPE) == CardType.MINION.rawValue }

    var isWeapon: Bool { return hasTag(.CARDTYPE) && getTag(.CARDTYPE) == CardType.WEAPON.rawValue }

    var isHero: Bool { return Cards.isHero(cardId) }

    var isHeroPower: Bool { return getTag(.CARDTYPE) == CardType.HERO_POWER.rawValue }

    var isInHand: Bool { return isInZone(.HAND) }

    var isInPlay: Bool { return isInZone(.PLAY) }

    var isInGraveyard: Bool { return isInZone(.GRAVEYARD) }

    var description: String {
        var description = "<\(NSStringFromClass(self.dynamicType)): "
            + "id=\(self.id)"
            + ", cardId=\(cardName(self.cardId))"
        if let name = self.name {
            description += ", name=\(name)"
        }
        description += ">"
        return description
    }

    func cardName(cardId: String?) -> String {
        if let cardId = cardId, let card = Cards.byId(cardId) {
            return "[\(card.name) (\(cardId))]"
        }
        return "N/A"
    }

    var hashValue: Int {
        return id.hashValue
    }

    func copy() -> Entity {
        let e = Entity(self.id)
        e.isPlayer = self.isPlayer
        e.cardId = self.cardId
        e.name = self.name
        self.tags.forEach({ e.tags[$0.0] = $0.1 })

        return e
    }
}
func == (lhs: Entity, rhs: Entity) -> Bool {
    return lhs.id == rhs.id
}

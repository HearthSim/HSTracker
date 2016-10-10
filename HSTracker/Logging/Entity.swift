/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */

import Foundation
import Wrap

class Entity {
    var id: Int
    var isPlayer = false
    var cardId = ""
    var name: String?
    lazy var tags = [GameTag: Int]()
    lazy var info: EntityInfo = { return EntityInfo(entity: self) }()

    init() {
        self.id = -1
    }

    init(id: Int) {
        self.id = id
    }

    func setTag(tag: GameTag, value: Int) {
        self.tags[tag] = value
    }

    func getTag(tag: GameTag) -> Int {
        if let value = self.tags[tag] {
            return value
        }
        return 0
    }

    func hasTag(tag: GameTag) -> Bool {
        return getTag(tag) > 0
    }

    func setPlayer(isPlayer: Bool) {
        self.isPlayer = isPlayer
    }

    var isActiveDeathrattle: Bool { return hasTag(.DEATHRATTLE) && getTag(.DEATHRATTLE) == 1 }

    var isCurrentPlayer: Bool { return hasTag(.CURRENT_PLAYER) }

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
    var isInDeck: Bool { return isInZone(.DECK) }
    var isInPlay: Bool { return isInZone(.PLAY) }
    var isInGraveyard: Bool { return isInZone(.GRAVEYARD) }
    var isInSetAside: Bool { return isInZone(.SETASIDE) }
    var isInSecret: Bool { return isInZone(.SECRET) }

    var health: Int { return getTag(.HEALTH) - getTag(.DAMAGE) }
    var attack: Int { return getTag(.ATK) }

    var hasCardId: Bool { return !String.isNullOrEmpty(cardId) }

    private var _cachedCard: Card?
    var card: Card {
        if let card = _cachedCard {
            return card
        } else if let card = Cards.by(cardId: cardId) {
            return card
        }
        return Card()
    }

    func setCardCount(count: Int) { card.count = count }

    func copy() -> Entity {
        let e = Entity(id: id)
        e.isPlayer = isPlayer
        e.cardId = cardId
        e.name = name
        tags.forEach({ e.tags[$0.0] = $0.1 })
        e.info.discarded = info.discarded
        e.info.returned = info.returned
        e.info.mulliganed = info.mulliganed
        e.info.created = info.created
        e.info.hasOutstandingTagChanges = info.hasOutstandingTagChanges
        e.info.originalController = info.originalController
        e.info.hidden = info.hidden
        e.info.turn = info.turn

        return e
    }
}
func == (lhs: Entity, rhs: Entity) -> Bool {
    return lhs.id == rhs.id
}

extension Entity: Hashable {
    var hashValue: Int {
        return id.hashValue
    }
}

extension Entity: CustomStringConvertible {
    var description: String {
        let cardName: String
        if let card = Cards.any(byId: cardId) {
            cardName = card.name
        } else {
            cardName = ""
        }
        let hide = info.hidden && (isInHand || isInDeck)
        return "[Entity: id=\(id), cardId=\(hide ? "" : cardId), "
            + "cardName=\(hide ? "" : cardName), "
            + "name=\(hide ? "" : name), "
            + "zonePos=\(getTag(.ZONE_POSITION)), info=\(info)]"
    }
}

extension Entity: WrapCustomizable {
    func keyForWrappingPropertyNamed(propertyName: String) -> String? {
        if ["_cachedCard", "card", "description"].contains(propertyName) {
            return nil
        }
        
        return propertyName.capitalizedString
    }
}

class EntityInfo {
    private var _entity: Entity
    var discarded = false
    var returned = false
    var mulliganed = false
    var stolen: Bool {
        return originalController > 0 && originalController != _entity.getTag(.CONTROLLER)
    }
    var created = false
    var hasOutstandingTagChanges = false
    var originalController = 0
    var hidden = false
    var turn = 0
    var costReduction = 0
    var originalZone: Zone?
    var createdInDeck: Bool { return originalZone == .DECK }
    var createdInHand: Bool { return originalZone == .HAND }

    init(entity: Entity) {
        _entity = entity
    }

    var cardMark: CardMark {
        if hidden {
            return .None
        }

        if _entity.cardId == CardIds.NonCollectible.Neutral.TheCoin || _entity.cardId ==
            CardIds.NonCollectible.Neutral.TradePrinceGallywix_GallywixsCoinToken {
            return .Coin
        }
        if returned {
            return .Returned
        }
        if created || stolen {
            return .Created
        }
        if mulliganed {
            return .Mulliganed
        }
        return .None
    }
}

extension EntityInfo: CustomStringConvertible {
    var description: String {
        var description = "[EntityInfo: "
            + "turn=\(turn)"
        
        if cardMark != .None {
            description += ", cardMark=\(cardMark)"
        }
        if discarded {
            description += ", discarded=true"
        }
        if created {
            description += ", created=true"
        }
        if returned {
            description += ", returned=true"
        }
        if stolen {
            description += ", stolen=true"
        }
        if mulliganed {
            description += ", mulliganed=true"
        }
        description += "]"
        
        return description
    }
}

extension EntityInfo: WrapCustomizable {
    func keyForWrappingPropertyNamed(propertyName: String) -> String? {
        if ["_entity", "description"].contains(propertyName) {
            return nil
        }
        
        return propertyName.capitalizedString
    }
}

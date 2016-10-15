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

    var isActiveDeathrattle: Bool { return hasTag(.deathrattle) && getTag(.deathrattle) == 1 }

    var isCurrentPlayer: Bool { return hasTag(.current_player) }

    func isInZone(zone: Zone) -> Bool {
        return hasTag(.zone) ? getTag(.zone) == zone.rawValue : false
    }

    func isControlledBy(controller: Int) -> Bool {
        return self.hasTag(.controller) ? self.getTag(.controller) == controller : false
    }

    var isSecret: Bool { return hasTag(.secret) }
    var isSpell: Bool { return getTag(.cardtype) == CardType.spell.rawValue }
    var isOpponent: Bool { return !isPlayer && hasTag(.player_id) }
    var isMinion: Bool { return hasTag(.cardtype) && getTag(.cardtype) == CardType.minion.rawValue }
    var isWeapon: Bool { return hasTag(.cardtype) && getTag(.cardtype) == CardType.weapon.rawValue }
    var isHero: Bool { return Cards.isHero(cardId) }
    var isHeroPower: Bool { return getTag(.cardtype) == CardType.hero_power.rawValue }

    var isInHand: Bool { return isInZone(.hand) }
    var isInDeck: Bool { return isInZone(.deck) }
    var isInPlay: Bool { return isInZone(.play) }
    var isInGraveyard: Bool { return isInZone(.graveyard) }
    var isInSetAside: Bool { return isInZone(.setaside) }
    var isInSecret: Bool { return isInZone(.secret) }

    var health: Int { return getTag(.health) - getTag(.damage) }
    var attack: Int { return getTag(.atk) }

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
            + "zonePos=\(getTag(.zone_position)), info=\(info)]"
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
        return originalController > 0 && originalController != _entity.getTag(.controller)
    }
    var created = false
    var hasOutstandingTagChanges = false
    var originalController = 0
    var hidden = false
    var turn = 0
    var costReduction = 0
    var originalZone: Zone?
    var createdInDeck: Bool { return originalZone == .deck }
    var createdInHand: Bool { return originalZone == .hand }

    init(entity: Entity) {
        _entity = entity
    }

    var cardMark: CardMark {
        if hidden {
            return .none
        }

        if _entity.cardId == CardIds.NonCollectible.Neutral.TheCoin || _entity.cardId ==
            CardIds.NonCollectible.Neutral.TradePrinceGallywix_GallywixsCoinToken {
            return .coin
        }
        if returned {
            return .returned
        }
        if created || stolen {
            return .created
        }
        if mulliganed {
            return .mulliganed
        }
        return .none
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

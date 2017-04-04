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
    var isPlayer: Bool {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return false
        }
        return self[.player_id] == game.player.id
    }
    var cardId = ""
    var name: String?
    var tags: [GameTag: Int] = [:]
    lazy var info: EntityInfo = { [unowned self] in
        return EntityInfo(entity: self) }()

    init() {
        self.id = -1
    }

    init(id: Int) {
        self.id = id
    }

    subscript(tag: GameTag) -> Int {
        set {
            tags[tag] = newValue
        }
        get {
            guard let value = tags[tag] else {
                return 0
            }
            return value
        }
    }

    func has(tag: GameTag) -> Bool {
        return self[tag] > 0
    }

    var isActiveDeathrattle: Bool {
        return has(tag: .deathrattle) && self[.deathrattle] == 1
    }

    var isCurrentPlayer: Bool {
        return has(tag: .current_player)
    }

    func isInZone(zone: Zone) -> Bool {
        return has(tag: .zone) ? self[.zone] == zone.rawValue : false
    }

    func isControlled(by controller: Int) -> Bool {
        return self.has(tag: .controller) ? self[.controller] == controller : false
    }

    var isSecret: Bool {
        return has(tag: .secret)
    }
    var isSpell: Bool {
        return self[.cardtype] == CardType.spell.rawValue
    }
    var isOpponent: Bool {
        return !isPlayer && has(tag: .player_id)
    }
    var isMinion: Bool {
        return has(tag: .cardtype) && self[.cardtype] == CardType.minion.rawValue
    }
    var isWeapon: Bool {
        return has(tag: .cardtype) && self[.cardtype] == CardType.weapon.rawValue
    }
    var isHero: Bool {
        return self[.cardtype] == CardType.hero.rawValue
    }
    var isHeroPower: Bool {
        return self[.cardtype] == CardType.hero_power.rawValue
    }

    var isInHand: Bool {
        return isInZone(zone: .hand)
    }
    var isInDeck: Bool {
        return isInZone(zone: .deck)
    }
    var isInPlay: Bool {
        return isInZone(zone: .play)
    }
    var isInGraveyard: Bool {
        return isInZone(zone: .graveyard)
    }
    var isInSetAside: Bool {
        return isInZone(zone: .setaside)
    }
    var isInSecret: Bool {
        return isInZone(zone: .secret)
    }

    var health: Int {
        return self[.health] - self[.damage]
    }
    var attack: Int {
        return self[.atk]
    }

    var hasCardId: Bool {
        return !String.isNullOrEmpty(cardId)
    }

    private var _cachedCard: Card?
    var card: Card {
        if let card = _cachedCard {
            return card
        } else if let card = Cards.by(cardId: cardId) {
            return card
        }
        return Card()
    }

    func set(cardCount count: Int) {
        card.count = count
    }
}

extension Entity: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let e = Entity(id: id)
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

extension Entity: Hashable {
    var hashValue: Int {
        return id.hashValue
    }

    static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Entity: CustomStringConvertible {
    var description: String {
        let cardName = Cards.any(byId: cardId)?.name ?? ""
        let tags = self.tags.map {
            "\($0.0)=\($0.1)"
        }.joined(separator: ",")
        let hide = info.hidden && (isInHand || isInDeck)
        return "[Entity: id=\(id), cardId=\(hide ? "" : cardId), "
                + "cardName=\(hide ? "" : cardName), "
                + "name=\(String(describing: hide ? "" : name)), "
                + "tags=(\(tags)), "
                + "info=\(info)]"
    }
}

extension Entity: WrapCustomizable {
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        if ["_cachedCard", "card", "description"].contains(propertyName) {
            return nil
        }

        return propertyName.capitalized
    }
}

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
	
    var cardId = ""
    var name: String?
    var tags: [GameTag: Int] = [:]
    /*
     * tags is accessed from the reader thread as well as from the main thread.
     * There are some crashes in HockeyApp on access to tags so we're trying to play it safe here.
     * There are still a few cases where this is used illegally. Ideally, we should make tags private to enforce
     * locking the semaphore every time.
     */
    static let semaphore = DispatchSemaphore(value: 1)
	
    lazy var info: EntityInfo = { [unowned(unsafe) self] in
        return EntityInfo(entity: self) }()

    init() {
        self.id = -1
    }

    init(id: Int) {
        self.id = id
    }

    subscript(tag: GameTag) -> Int {
        set {
            Entity.semaphore.wait()
            tags[tag] = newValue
            Entity.semaphore.signal()
        }
        get {
            Entity.semaphore.wait()
            guard let value = tags[tag] else {
                Entity.semaphore.signal()
                return 0
            }
            Entity.semaphore.signal()
            return value
        }
    }

    func has(tag: GameTag) -> Bool {
        return self[tag] > 0
    }
	
	func isPlayer(eventHandler: PowerEventHandler) -> Bool {
		return self[.player_id] == eventHandler.player.id
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
    var isQuest: Bool {
        return has(tag: .quest)
    }
    var isSpell: Bool {
        return self[.cardtype] == CardType.spell.rawValue
    }
	func isOpponent(eventHandler: PowerEventHandler) -> Bool {
		return !isPlayer(eventHandler: eventHandler) && has(tag: .player_id)
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
    var isPlayableHero: Bool {
        return isHero && card.set != .core && card.set != .hero_skins && card.collectible
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
        return !cardId.isBlank
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
        Entity.semaphore.wait()
        let tags = self.tags.map {
            "\($0.0)=\($0.1)"
        }.joined(separator: ",")
        Entity.semaphore.signal()
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

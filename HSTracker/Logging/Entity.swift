/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */

class Entity: Hashable, CustomStringConvertible, Dictable {
    var id: Int
    var isPlayer: Bool = false
    var cardId: String = ""
    var name: String?
    lazy var tags = [GameTag: Int]()
    lazy var info: EntityInfo = { return EntityInfo(self) }()
    
    init() {
        self.id = -1
    }
    
    init(_ id: Int) {
        self.id = id
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
    
    var hasCardId: Bool { return !String.isNullOrEmpty(cardId) }
    
    private var _cachedCard: Card?
    var card: Card {
        if let card = _cachedCard {
            return card
        }
        else if let card = Cards.byId(cardId) {
            return card
        }
        return Card()
    }
    
    func setCardCount(count: Int) { card.count = count }
    
    var description: String {
        let card = Cards.anyById(cardId)
        let cardName = card != nil ? card!.name : ""
        let hide = info.hidden && (isInHand || isInDeck)
        return "[Entity: id=\(id), cardId=\(hide ? "" : cardId), cardName=\(hide ? "" : cardName), zonePos=\(getTag(.ZONE_POSITION)), info=\(info)]"
    }

    var hashValue: Int {
        return id.hashValue
    }
    
    func copy() -> Entity {
        let e = Entity(id)
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
    
    func toDict() -> [String : AnyObject] {
        var tags = [Int: Int]()
        self.tags.forEach({ tags[$0.0.rawValue] = $0.1 })
        return [
            "id": self.id,
            "isPlayer": self.isPlayer,
            "cardId": self.cardId,
            "name": self.name != nil ? self.name! : "",
            "tags": tags
        ]
    }
}
func == (lhs: Entity, rhs: Entity) -> Bool {
    return lhs.id == rhs.id
}

class EntityInfo : CustomStringConvertible {
    private var _entity:Entity
    var discarded = false
    var returned = false
    var mulliganed = false
    var stolen: Bool { return originalController > 0 && originalController != _entity.getTag(.CONTROLLER) }
    var created: Bool = false
    var hasOutstandingTagChanges: Bool = false
    var originalController: Int = 0
    var hidden = false
    var turn: Int = 0
    
    init(_ entity: Entity) {
        _entity = entity
    }
    
    var cardMark: CardMark {
        if hidden {
            return .None
        }
        
        if _entity.cardId == CardIds.NonCollectible.Neutral.TheCoin || _entity.cardId == CardIds.NonCollectible.Neutral.GallywixsCoinToken {
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
   
    var description: String {
        var description = "[EntityInfo: "
            + ", turn=\(turn)"
        
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

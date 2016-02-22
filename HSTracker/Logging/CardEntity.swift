/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */

class CardEntity: Equatable, CustomStringConvertible {

    var cardId: String?
    var entity: Entity?

    var turn: Int {
        willSet(newTurn) {
            prevTurn = self.turn
        }
    }
    var prevTurn = -1
    var cardMark: CardMark = .None
    var discarded: Bool = false

    var inHand: Bool {
        get {
            return entity != nil && entity!.getTag(GameTag.ZONE) == Zone.HAND.rawValue
        }
    }
    var inDeck: Bool {
        get {
            return entity != nil && entity!.getTag(GameTag.ZONE) == Zone.DECK.rawValue
        }
    }
    var unkown: Bool {
        get {
            return cardId == nil || cardId!.isEmpty && entity == nil
        }
    }
    var created: Bool = false

    init(cardId: String? = nil, entity: Entity? = nil) {
        if let entity = entity {
            if let cardId = entity.cardId {
                self.cardId = cardId
            }
        } else if let cardId = cardId {
            self.cardId = cardId
        }
        self.entity = entity
        self.turn = -1
        self.cardMark = entity?.id > 68 ? .Created : .None
    }

    func reset() {
        self.cardMark = .None
        self.created = false
        self.cardId = nil
    }

    func zonePosComparison(other: CardEntity) -> Bool {
        let v1 = self.entity != nil ? entity!.getTag(GameTag.ZONE_POSITION) : 10
        let v2 = other.entity != nil ? other.entity!.getTag(GameTag.ZONE_POSITION) : 10
        return v1 < v2
    }

    func update(entity: Entity?) {
        if entity == nil {
            return
        }
        if self.entity == nil {
            self.entity = entity
        }
        if self.cardId == nil || self.cardId!.isEmpty {
            self.cardId = entity!.cardId
        }
    }

    var description: String {
        var description = "<\(NSStringFromClass(self.dynamicType)): "
            + "self.entity=\(self.entity)"
            + ", self.cardId=\(cardName(self.cardId))"
            + ", self.turn=\(self.turn)"
    
        if let entity = self.entity {
            description += ", self.zonePos=\(entity.getTag(GameTag.ZONE_POSITION))"
        }
        if self.cardMark != CardMark.None {
            description += ", self.cardMark=\(self.cardMark)"
        }
        if self.discarded {
            description += ", self.discarded=true"
        }
        if self.created {
            description += ", self.created=true"
        }
        description += ">"

        return description
    }

    func cardName(cardId: String?) -> String {
        if let cardId = cardId {
            if let card = Card.byId(cardId) {
                return "[\(card.name) (\(cardId)]"
            }
        }
        return "N/A"
    }
}

func ==(lhs: CardEntity, rhs: CardEntity) -> Bool {
    if lhs.entity == nil && rhs.entity != nil || lhs.entity != nil && rhs.entity == nil {
        return false
    }
    
    if lhs.entity == nil && rhs.entity == nil {
        let lhsEntity = lhs.entity!
        let rhsEntity = rhs.entity!
        
        return lhsEntity.cardId == nil && rhsEntity.cardId != nil || lhsEntity.cardId != nil && rhsEntity.cardId == nil
    }
    else {
        return lhs.cardId == rhs.cardId
    }
}


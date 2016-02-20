/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */

class CardEntity: Equatable {

    var cardId: String?
    var entity: Entity?

    var turn: Int {
        set {
            prevTurn = turn
            self.turn = newValue
        }
        get {
            return self.turn
        }
    }
    var prevTurn = -1
    var cardMark: CardMark = .None
    var discarded: Bool = false

    var inHand: Bool {
        get {
            return entity != nil && entity![GameTag.ZONE] == Zone.HAND.rawValue
        }
    }
    var inDeck: Bool {
        get {
            return entity != nil && entity![GameTag.ZONE] == Zone.DECK.rawValue
        }
    }
    var unkown: Bool {
        get {
            return cardId == nil || cardId!.isEmpty && entity == nil
        }
    }
    var created: Bool = false

    init(cardId: String? = nil, entity: Entity? = nil) {
        self.cardId = cardId == nil && entity != nil ? entity!.cardId : cardId!
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
        let v1 = (self.entity != nil && entity![GameTag.ZONE_POSITION] != nil) ? entity![GameTag.ZONE_POSITION]! : 10
        let v2 = (other.entity != nil && other.entity![GameTag.ZONE_POSITION] != nil) ? other.entity![GameTag.ZONE_POSITION]! : 10
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


    /*func description() -> String
    {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.entity=%@", self.entity];
    [description appendFormat:@", self.cardId=%@", [self cardName:self.cardId]];
    [description appendFormat:@", self.turn=%li", self.turn];
    if (self.entity) {
    [description appendFormat:@", self.zonePos=%li", [self.entity getTag:EGameTag_ZONE_POSITION]];
    }
    if (self.cardMark != ECardMark_None) {
    [description appendFormat:@", self.cardMark=%li", (NSInteger) self.cardMark];
    }
    if (self.discarded) {
    [description appendString:@", self.discarded=true"];
    }
    if (self.created) {
    [description appendString:@", self.created=true"];
    }
    [description appendString:@">"];
    return description;
    }*/

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


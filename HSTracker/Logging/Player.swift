/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */

import Foundation

class DynamicEntity : Hashable {
    var cardId: String
    var hidden, created, discarded: Bool
    var cardMark: CardMark

    init(cardId: String, hidden: Bool = false, created: Bool = false,
        cardMark: CardMark = CardMark.None, discarded: Bool = false) {
            self.cardId = cardId
            self.hidden = hidden
            self.created = created
            self.discarded = discarded
            self.cardMark = cardMark
    }

    var hashValue: Int {
        return cardId.hashValue ^
        hidden.hashValue ^
        created.hashValue ^
        discarded.hashValue ^
        cardMark.hashValue
    }
}
func == (lhs: DynamicEntity, rhs: DynamicEntity) -> Bool {
    return lhs.cardId == rhs.cardId &&
    lhs.hidden == rhs.hidden &&
    lhs.created == lhs.created &&
    lhs.discarded == rhs.discarded &&
    lhs.cardMark == rhs.cardMark
}

class Player {
    var revealedCards = [CardEntity]()
    var hand = [CardEntity]()
    var board = [CardEntity]()
    var deck = [CardEntity]()
    var graveyard = [CardEntity]()
    var secrets = [CardEntity]()
    var removed = [CardEntity]()
    var drawnCardIds = [String]()
    var drawnCardIdsTotal = [String]()
    var createdInHandCardIds = [String]()
    var hightlightedCards = [String]()
    var isLocalPlayer: Bool
    var id: Int?
    var playerClass: Card?
    var name: String?
    var tracker: Tracker?
    var goingFirst: Bool = false
    var fatigue: Int = 0
    // @property(nonatomic) BOOL drawnCardsMatchDeck;

    let DeckSize = 30

    init(_ local: Bool) {
        self.isLocalPlayer = local
        reset()
    }

    var hasCoin: Bool {
        return hand.any { $0.cardId == "GAME_005" || $0.entity?.cardId == "GAME_005" }
    }

    var handCount: Int {
        return self.hand.count
    }

    var deckCount: Int {
        return self.deck.count
    }

    func drawnCards() -> [Card] {
        return drawnCardIds.filter { !String.isNullOrEmpty($0) }
            .groupBy { (s: String) in s }
            .map { g -> (Card?) in
                if let card = Cards.byId(g.key) {
                    card.count = g.items.count
                    return card
                } else {
                    return nil
                }
        }
            .filter { $0 != nil }
            .map { $0! }
    }

    func displayReveleadCards() -> [Card] {
        return revealedCards.filter { !String.isNullOrEmpty($0.cardId) }
            .map { (ce: CardEntity) -> (DynamicEntity) in
                DynamicEntity(cardId: ce.cardId!,
                    hidden: ce.inHand || ce.inDeck,
                    created: ce.created,
                    discarded: ce.discarded && Settings.instance.highlightDiscarded)
        }
            .groupBy { (d: DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.jousted = g.key.hidden
                    card.isCreated = g.key.created
                    card.wasDiscarded = g.key.discarded
                    return card
                } else {
                    return nil
                }
        }
            .filter { $0 != nil }
            .map { $0! }
            .sortCardList()
    }

    func displayCards() -> [Card] {
        let settings = Settings.instance
        let drawnCards = self.drawnCards()
        DDLogVerbose("drawnCards: \(drawnCards)")

        var createdInHand = [Card]()
        if settings.showPlayerGet {
            createdInHand = createdInHandCardIds.filter { !$0.isEmpty }
                .groupBy { (s: String) in s }
                .map { g -> Card? in
                    if let card = Cards.byId(g.key) {
                        card.count = g.items.count
                        card.isCreated = true
                        card.highlightInHand = self.hand.any { $0.cardId == card.cardId }
                        return card
                    } else {
                        return nil
                    }
            }
                .filter { $0 != nil }
                .map { $0! }
        }
        DDLogVerbose("createdInHand: \(createdInHand)")

        guard let _ = Game.instance.activeDeck else {
            return (drawnCards + createdInHand).sortCardList()
        }

        var stillInDeck = deck.filter { !String.isNullOrEmpty($0.cardId) }
            .map {
                DynamicEntity(cardId: $0.cardId!,
                    cardMark: $0.cardMark,
                    discarded: $0.discarded)
        }
            .groupBy { (d: DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.isCreated = g.key.cardMark == CardMark.Created
                    card.highlightDraw = self.hightlightedCards.contains(g.key.cardId)
                    card.highlightInHand = self.hand.any { $0.cardId == g.key.cardId }
                    return card
                } else {
                    return nil
                }
        }
            .filter { $0 != nil }
            .map { $0! }
        DDLogVerbose("stillInDeck: \(stillInDeck)")

        if settings.removeCardsFromDeck {
            if settings.highlightLastDrawn {
                let drawHighlight = Game.instance.activeDeck!.sortedCards.filter { (card: Card) in
                    self.hightlightedCards.contains(card.cardId) && stillInDeck.all { (c: Card) in c.cardId != card.cardId }
                }
                    .map { card -> Card in
                        let c: Card = card.copy()
                        c.count = 0
                        c.highlightDraw = true
                        return c
                }
                DDLogVerbose("drawHighLight: \(drawHighlight)")
                stillInDeck += drawHighlight
            }

            if settings.highlightCardsInHand {
                let inHand = Game.instance.activeDeck!.sortedCards.filter { (card: Card) in
                    stillInDeck.all { (c: Card) in c.cardId != card.cardId } && self.hand.any { (ce: CardEntity) in card.cardId == ce.cardId }
                }
                    .map { card -> Card in
                        let c: Card = card.copy()
                        c.count = 0
                        c.highlightInHand = true
                        let count = self.deck.filter { !String.isNullOrEmpty($0.cardId) }
                            .groupBy { (ce: CardEntity) -> String in ce.cardId! }
                            .map { g -> Int in g.items.count }
                            .maxElement()
                        if let count = count where self.isLocalPlayer && c.cardId == CardIds.Collectible.Neutral.RenoJackson && count <= 1 {
                            c.highlightFrame = true
                        }

                        return c
                }
                DDLogVerbose("inHand: \(inHand)")
                stillInDeck += inHand
            }
            return stillInDeck.sortCardList()
        }

        let notInDeck = Game.instance.activeDeck!.sortedCards.filter { (card: Card) in
            self.deck.all { (c: CardEntity) in c.cardId != card.cardId }
        }
            .map { card -> Card in
                let c: Card = card.copy()
                c.count = 0
                c.highlightDraw = self.hightlightedCards.contains(c.cardId)
                if self.hand.any({ $0.cardId == c.cardId }) {
                    card.highlightInHand = true
                    let count = self.deck.filter { !String.isNullOrEmpty($0.cardId) }
                        .groupBy { (ce: CardEntity) -> String in ce.cardId! }
                        .map { g -> Int in g.items.count }
                        .maxElement()
                    if let count = count where self.isLocalPlayer && c.cardId == CardIds.Collectible.Neutral.RenoJackson && count <= 1 {
                        c.highlightFrame = true
                    }
                }
                return c
        }
        DDLogVerbose("notInDeck: \(notInDeck)")
        stillInDeck += notInDeck + createdInHand
        return stillInDeck.sortCardList()
    }

    func reset() {
        self.id = nil
        self.name = ""
        self.playerClass = nil
        self.goingFirst = false
        self.fatigue = 0
        // self.drawnCardsMatchDeck = true;
        self.hand = []
        self.board = []
        self.deck = []
        self.graveyard = []
        self.secrets = []
        self.drawnCardIds = []
        self.drawnCardIdsTotal = []
        self.revealedCards = []
        self.createdInHandCardIds = []
        self.hightlightedCards = []
        self.removed = []

        for _ in 0 ..< DeckSize {
            self.deck.append(CardEntity())
        }
    }

    func gameStart() {
    }

    func gameEnd() {
    }

    var debugName: String {
        return self.isLocalPlayer ? "Player" : "Opponent"
    }

    func createInDeck(entity: Entity, _ turn: Int) {
        var cardEntity: CardEntity

        let created = turn > 1

        if self.isLocalPlayer {
            cardEntity = CardEntity(cardId: nil, entity: entity)
            cardEntity.turn = turn
            cardEntity.created = created
            self.deck.append(cardEntity)

            let ce = CardEntity(cardId: nil, entity: entity)
            ce.turn = turn
            ce.created = created
            self.revealedCards.append(ce)
        } else {
            self.deck.append(CardEntity())
            self.revealDeckCard(entity.cardId!, turn, created)
            cardEntity = CardEntity(cardId: entity.cardId, entity: nil)
            cardEntity.turn = turn
            cardEntity.created = created
            self.revealedCards.append(cardEntity)
        }
        DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
    }

    func revealDeckCard(cardId: String, _ turn: Int, _ created: Bool = false) {
        if let cardEntity = deck.firstWhere({ $0.unknown }) {
            cardEntity.cardId = cardId
            cardEntity.turn = turn
            if created {
                cardEntity.created = true
            }
        }
    }

    func createInHand(entity: Entity?, _ turn: Int) {
        let cardEntity = CardEntity(cardId: nil, entity: entity)
        cardEntity.turn = turn
        cardEntity.created = true
        self.hand.append(cardEntity)

        if let entity = entity, let cardId = entity.cardId where self.isLocalPlayer {
            self.createdInHandCardIds.append(cardId)
        }

        DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
    }

    func boardToDeck(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.board, &self.deck, turn) {
            updateRevealedEntity(cardEntity, turn)

            if let cardId = entity.cardId where !String.isNullOrEmpty(cardId) && self.drawnCardIds.contains(cardId) {
                if let index = self.drawnCardIds.indexOf(cardId) {
                    self.drawnCardIds.removeAtIndex(index)
                }
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func play(entity: Entity, _ turn: Int) {
        var destination = entity.isSecret ? self.secrets : self.board
        if let cardEntity = moveCardEntity(entity, &hand, &destination, turn) {
            if entity.getTag(GameTag.CARDTYPE) == CardType.TOKEN.rawValue {
                cardEntity.created = true
            }
            updateRevealedEntity(cardEntity, turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func handDiscard(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.hand, &self.graveyard, turn) {
            updateRevealedEntity(cardEntity, turn, true)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretPlayedFromDeck(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.deck, &self.secrets, turn) {
            updateRevealedEntity(cardEntity, turn)
            if let cardId = entity.cardId where !String.isNullOrEmpty(cardId) {
                self.drawnCardIds.append(cardId)
                self.drawnCardIdsTotal.append(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretPlayedFromHand(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.hand, &self.secrets, turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func mulligan(entity: Entity) {
        if let cardEntity = moveCardEntity(entity, &self.hand, &self.deck, 0) {

            // new cards are drawn first
            if let newCard = hand.firstWhere({ $0.entity?.getTag(GameTag.ZONE_POSITION) == entity.getTag(GameTag.ZONE_POSITION) }) {
                newCard.mulliganed = true
            }
            if let cardId = entity.cardId where !String.isNullOrEmpty(cardId) && drawnCardIds.contains(cardId) {
                drawnCardIds.remove(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func draw(entity: Entity, _ turn: Int) {
        if let ce = moveCardEntity(entity, &self.deck, &self.hand, turn) {

            if self.isLocalPlayer {
                if let cardId = entity.cardId {
                    highlight(cardId)
                }
            } else {
                ce.reset()
            }

            if !String.isNullOrEmpty(entity.cardId) && ce.cardMark != CardMark.Created && ce.cardMark != CardMark.Returned && !ce.created {
                self.drawnCardIds.append(entity.cardId!)
                self.drawnCardIdsTotal.append(entity.cardId!)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(ce)")
        }
    }

    func highlight(cardId: String) {
        hightlightedCards.append(cardId)
        Game.instance.playerTracker?.update()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            NSThread.sleepForTimeInterval(3)
            self.hightlightedCards.removeFirst()
            dispatch_async(dispatch_get_main_queue()) {
                Game.instance.playerTracker?.update()
            }
        }
    }

    func removeFromDeck(entity: Entity, _ turn: Int) {
        if let revealed = revealedCards.firstWhere({ $0.entity == entity }) {
            self.revealedCards.remove(revealed)
        }
        if let cardEntity = moveCardEntity(entity, &self.deck, &self.removed, turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func deckDiscard(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.deck, &self.graveyard, turn) {
            updateRevealedEntity(cardEntity, turn, true)

            if let cardId = entity.cardId where !String.isNullOrEmpty(cardId) && cardEntity.cardMark != CardMark.Created && cardEntity.cardMark != CardMark.Returned {
                /*if(self.isLocalPlayer && !CardMatchesActiveDeck(entity.CardId)) {
                 DrawnCardsMatchDeck = false;
                 }*/
                self.drawnCardIds.append(cardId)
                self.drawnCardIdsTotal.append(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func deckToPlay(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.deck, &self.board, turn) {
            updateRevealedEntity(cardEntity, turn)

            if let cardId = entity.cardId where !String.isNullOrEmpty(cardId) && cardEntity.cardMark != CardMark.Created && cardEntity.cardMark != CardMark.Returned {
                /*if(self.isLocalPlayer && !CardMatchesActiveDeck(entity.CardId)) {
                 DrawnCardsMatchDeck = false;
                 }*/
                self.drawnCardIds.append(cardId)
                self.drawnCardIdsTotal.append(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func playToGraveyard(entity: Entity, _ cardId: String?, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.board, &self.graveyard, turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func joustReveal(entity: Entity, _ turn: Int) {
        if self.deck.filter({ $0.inDeck }).all({ $0.cardId != entity.cardId }) {
            revealDeckCard(entity.cardId!, turn)
            let ce = CardEntity(cardId: entity.cardId, entity: nil)
            ce.turn = turn
            revealedCards.append(ce)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(ce)")
        }
    }

    func createInPlay(entity: Entity, _ turn: Int) {
        let cardEntity = CardEntity(cardId: nil, entity: entity)
        cardEntity.turn = turn
        board.append(cardEntity)
        DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
    }

    func stolenByOpponent(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.board, &self.removed, turn) {
            updateRevealedEntity(cardEntity, turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func stolenFromOpponent(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.removed, &self.board, turn) {
            cardEntity.stolen = true
            updateRevealedEntity(cardEntity, turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func boardToHand(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.board, &self.hand, turn) {
            cardEntity.returned = true
            updateRevealedEntity(cardEntity, turn, nil, CardMark.Returned)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretTriggered(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, &self.secrets, &self.graveyard, turn) {
            updateRevealedEntity(cardEntity, turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func updateRevealedEntity(entity: CardEntity, _ turn: Int, _ discarded: Bool? = nil, _ cardMark: CardMark? = nil) {
        var cardEntity = revealedCards.firstWhere { $0.entity == entity.entity ||
            ($0.cardId == entity.cardId && $0.entity == nil && $0.turn <= entity.prevTurn) }

        if let cardEntity = cardEntity {
            cardEntity.update(entity.entity)
        } else {
            cardEntity = CardEntity(cardId: nil, entity: entity.entity)
            cardEntity!.turn = turn
            cardEntity!.created = entity.created
            cardEntity!.discarded = entity.discarded
            let cardType = CardType(rawValue: entity.entity!.getTag(.CARDTYPE))
            if cardType != .HERO && cardType != .ENCHANTMENT && cardType != .HERO_POWER && cardType != .PLAYER {
                self.revealedCards.append(entity)
            }
        }

        if let discarded = discarded {
            cardEntity!.discarded = discarded
        }
    }

    func moveCardEntity(entity: Entity, inout _ from: [CardEntity], inout _ to: [CardEntity], _
        turn: Int) -> CardEntity? {
            var cardEntity = getEntityFromCollection(from, entity)
            if let _cardEntity = cardEntity {
                from.remove(_cardEntity)
            } else {
                cardEntity = from.firstWhere { String.isNullOrEmpty($0.cardId) && $0.entity == nil }
                if let _cardEntity = cardEntity {
                    from.remove(_cardEntity)
                    _cardEntity.update(entity)
                } else {
                    cardEntity = CardEntity(cardId: nil, entity: entity)
                    cardEntity!.turn = turn
                }
            }

            if let _cardEntity = cardEntity {
                _cardEntity.turn = turn
                to.append(_cardEntity)
                to.sortInPlace(CardEntity.zonePosComparison)
            }
            return cardEntity
    }

    func getEntityFromCollection(array: [CardEntity], _ entity: Entity) -> CardEntity? {
        let cardEntity = array.firstWhere { $0.entity == entity }
            ?? array.firstWhere { !String.isNullOrEmpty($0.cardId) && $0.cardId == entity.cardId }
            ?? array.firstWhere { String.isNullOrEmpty($0.cardId) && $0.entity == nil }

        cardEntity?.update(entity)
        return cardEntity
    }

    func updateZonePos(entity: Entity, _ zone: Zone, _ turn: Int) {
        switch zone {
        case .HAND:
            updateCardEntity(entity)
            hand.sortInPlace(CardEntity.zonePosComparison)
            if !isLocalPlayer && turn == 0 && hand.count == 5 && hand[4].entity?.id > 67 {
                hand[4].cardId = CardIds.NonCollectible.Neutral.TheCoin
                hand[4].created = true
                deck.append(CardEntity())
                DDLogVerbose("Coin \(hand[4])")
            }

        case .PLAY:
            updateCardEntity(entity)
            board.sortInPlace(CardEntity.zonePosComparison)

        default: break
        }
    }

    func updateCardEntity(entity: Entity)
    {
        if let cardEntity = getEntityFromCollection(hand, entity) {
            cardEntity.entity = entity
        }
    }
}

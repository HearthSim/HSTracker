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

class DynamicEntity {
    var cardId: String
    var stolen, hidden, created, isInHand, discarded: Bool
    var cardMark: CardMark
    var entity: Entity?
    var extraInfo: (any ICardExtraInfo)?

    init(cardId: String, hidden: Bool = false, created: Bool = false,
         cardMark: CardMark = .none, discarded: Bool = false,
         extraInfo: (any ICardExtraInfo)? = nil,
         stolen: Bool = false, isInHand: Bool = false, entity: Entity? = nil) {
        self.cardId = cardId
        self.hidden = hidden
        self.created = created
        self.discarded = discarded
        self.cardMark = cardMark
        self.stolen = stolen
        self.isInHand = isInHand
        self.entity = entity
    }
}

extension DynamicEntity: Hashable {
    func hash(into hasher: inout Hasher) {
        cardId.hash(into: &hasher)
        hidden.hash(into: &hasher)
        created.hash(into: &hasher)
        discarded.hash(into: &hasher)
        stolen.hash(into: &hasher)
        cardMark.hash(into: &hasher)
        isInHand.hash(into: &hasher)
    }

    static func == (lhs: DynamicEntity, rhs: DynamicEntity) -> Bool {
        return lhs.cardId == rhs.cardId &&
            lhs.hidden == rhs.hidden &&
            lhs.created == rhs.created &&
            lhs.discarded == rhs.discarded &&
            lhs.cardMark == rhs.cardMark &&
            lhs.stolen == rhs.stolen &&
            lhs.isInHand == rhs.isInHand
    }
}

class DeckState {
    fileprivate(set) var remainingInDeck: [Card]
    fileprivate(set) var removedFromDeck: [Card]
    fileprivate(set) var remainingInSideboards: [String: [Card]]?
    fileprivate(set) var removedFromSideboards: [String: [Card]]?

    init(remainingInDeck: [Card], removedFromDeck: [Card], remainingInSideboards: [String: [Card]]? = nil, removedFromSideboards: [String: [Card]]? = nil) {
        self.removedFromDeck = removedFromDeck
        self.remainingInDeck = remainingInDeck
        self.remainingInSideboards = remainingInSideboards
        self.removedFromSideboards = removedFromSideboards
    }
}

class PredictedCard {
    var cardId: String
    var turn: Int
    var isCreated: Bool

    init(cardId: String, turn: Int, isCreated: Bool = false) {
        self.cardId = cardId
        self.turn = turn
        self.isCreated = isCreated
    }
}

extension PredictedCard: Hashable {
    func hash(into hasher: inout Hasher) {
        cardId.hash(into: &hasher)
        turn.hash(into: &hasher)
    }

    static func == (lhs: PredictedCard, rhs: PredictedCard) -> Bool {
        return lhs.cardId == rhs.cardId && lhs.turn == rhs.turn
    }
}

final class Player {
    var originalClass: CardClass?
    var currentClass: CardClass?
    var playerClassId: String?
    var isLocalPlayer: Bool
    var id = -1
    var fatigue = 0
    var heroPowerCount = 0
    var spellsPlayedCount: Int {
        return spellsPlayedCards.count
    }
    var spellsPlayedCards = [Entity]()
    var spellsPlayedInFriendlyCharacters = [Entity]()
    var spellsPlayedInOpponentCharacters = [Entity]()
    var cardsPlayedThisMatch = [Entity]()
    var cardsPlayedThisTurn = [Entity]()
    fileprivate(set) var cardsPlayedLastTurn = [Entity]()
    fileprivate(set) var launchedStarships = SynchronizedArray<String?>()
    fileprivate(set) var startingHand = [Entity]()
    var isPlayingWhizbang = false
    fileprivate(set) var deathrattlesPlayedCount = 0
    private let game: Game
    var lastDrawnCardId: String?
    var libramReductionCount: Int = 0
    var abyssalCurseCount: Int = 0
    var pogoHopperPlayedCount = 0
    var playedSpellSchools = Set<SpellSchool>()
    var lastDiedMinionCard: Entity? {
        return deadMinionsCards.last
    }
    var deadMinionsCards = [Entity]()
    var secretsTriggeredCards = [Entity]()

    var hasCoin: Bool {
        return hand.any { $0.isTheCoin }
    }

    var handCount: Int {
        return hand.filter({ $0.isControlled(by: self.id) }).count
    }

    /** Number of cards still in the deck */
    var deckCount: Int {
        return deck.filter({ $0.isControlled(by: self.id) }).count
    }
    
    var offeredEntityIds = [Int]()
    
    var offeredEntities: [Entity] {
        return playerEntities.filter { x in offeredEntityIds.contains(x.id) }
    }

    var playerEntities: [Entity] {
        return game.entities.values.filter({
            return !$0.info.hasOutstandingTagChanges && $0.isControlled(by: self.id)
        })
    }

    var revealedEntities: [Entity] {
        return game.entities.values
            .filter({
                return !$0.info.hasOutstandingTagChanges
                    && ($0.isControlled(by: self.id) || $0.info.originalController == self.id)
            }).filter({ $0.hasCardId }).filter({ x in
                // Souleater's Scythe causes entites to be created in the graveyard.
                // We need to not reveal this card for the opponent and only reveal
                // it for the player after mulligan.
                if x.info.inGraveyardAtStartOfGame && x.isInGraveyard {
                    if isLocalPlayer {
                        return game.isMulliganDone()
                    }
                    return false
                }
                return true
            })
    }

    var hand: [Entity] { return playerEntities.filter({ $0.isInHand }) }
    var board: [Entity] { return playerEntities.filter({ $0.isInPlay }) }
    var deck: [Entity] { return playerEntities.filter({ $0.isInDeck }) }
    var graveyard: [Entity] { return playerEntities.filter({ $0.isInGraveyard }) }
    var secrets: [Entity] { return playerEntities.filter({ $0.isInSecret && $0.isSecret }) }
    var quests: [Entity] { return playerEntities.filter({ $0.isInSecret && $0.isQuest }) }
    var trinkets: [Entity] { return board.filter({ x in x.isBattlegroundsTrinket}) }
    var questRewards: [Entity] { return board.filter({ $0.isBgsQuestReward }) }
    var objectives: [Entity] { return playerEntities.filter({ x in x.isInSecret && x.isObjective })}
    var setAside: [Entity] { return playerEntities.filter({ $0.isInSetAside }) }
    static var knownOpponentDeck: [Card]?
    var entity: Entity? {
        return game.entities.values.filter({ $0[.player_id] == self.id }).first
    }

    fileprivate(set) lazy var inDeckPredictions = [PredictedCard]()
    var hero: Entity? {
        return board.first { x in x.isHero }
    }
    
    private let pastHPLock = UnfairLock()
    var pastHeroPowers = Set<String>()

    var name: String?
    var tracker: Tracker?
    var drawnCardsMatchDeck = true

	init(local: Bool, game: Game) {
		self.game = game
        isLocalPlayer = local
        reset()
    }

    func reset() {
        id = -1
        name = ""
        originalClass = nil
        currentClass = nil
        fatigue = 0
        spellsPlayedCards.removeAll()
        spellsPlayedInFriendlyCharacters.removeAll()
        spellsPlayedInOpponentCharacters.removeAll()
        cardsPlayedThisTurn.removeAll()
        cardsPlayedLastTurn.removeAll()
        cardsPlayedThisMatch.removeAll()
        launchedStarships.removeAll()
        startingHand.removeAll()
        secretsTriggeredCards.removeAll()
        deadMinionsCards.removeAll()
        deathrattlesPlayedCount = 0
        heroPowerCount = 0
        offeredEntityIds.removeAll()

        inDeckPredictions.removeAll()
        cardsPlayedThisTurn.removeAll()
        cardsPlayedThisMatch.removeAll()
        
        lastDrawnCardId = nil
        libramReductionCount = 0
        abyssalCurseCount = 0
        pogoHopperPlayedCount = 0
        pastHPLock.around {
            pastHeroPowers.removeAll()
        }
        playedSpellSchools.removeAll()
        isPlayingWhizbang = false
    }
    
    var currentMana: Int {
        return self.maxMana - (entity?[.resources_used] ?? 0)
    }
    
    var maxMana: Int {
        return (entity?[.resources] ?? 0) + (entity?[.temp_resources] ?? 0)
    }

    var displayRevealedCards: [Card] {
        return revealedEntities.filter({ x in
            return !x.info.created
                && x.isPlayableCard
                && (!x.isInDeck || (x.info.stolen && x.info.originalController == self.id))
        })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                    hidden: (e.isInHand || e.isInDeck),
                    created: e.info.created ||
                        (e.info.stolen && e.info.originalController != self.id),
                    discarded: e.info.discarded && Settings.highlightDiscarded)
            })
            .group { (d: DynamicEntity) in d }
            .compactMap { g -> Card? in
                if let card = Cards.by(cardId: g.key.cardId) {
                    card.count = g.value.count
                    card.jousted = g.key.hidden
                    card.isCreated = g.key.created
                    card.wasDiscarded = g.key.discarded
                    return card
                } else {
                    return nil
                }
            }
            .sortCardList()
    }

    func getPredictedCardsInDeck(hidden: Bool) -> [Card] {
        return inDeckPredictions.compactMap { g -> Card? in
            if let card = Cards.by(cardId: g.cardId) {
                if hidden {
                    card.jousted = true
                }
                if g.isCreated {
                    card.isCreated = true
                    card.count = 1
                }
                return card
            } else {
                return nil
            }
        }
    }

    var knownCardsInDeck: [Card] {
        return deck.filter({ $0.hasCardId })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                              created: e.info.created || e.info.stolen,
                              extraInfo: e.info.extraInfo)
            })
            .group { (d: DynamicEntity) in d }
            .compactMap { g -> Card? in
                if let card = Cards.by(cardId: g.key.cardId) {
                    card.count = g.value.count
                    card.isCreated = g.key.created
                    card.jousted = true
                    card.extraInfo = g.key.extraInfo?.copy() as? (any ICardExtraInfo)
                    return card
                } else {
                    return nil
                }
            }
    }

    var revealedCards: [Card] {
        return revealedEntities.filter({ x in
            let created = x.info.created
            let type = (x.isMinion || x.isSpell || x.isWeapon || x.isHero)
            let zone = ((!x.isInDeck
                && (!x.info.stolen || x.info.originalController == self.id))
                || (x.info.stolen && x.info.originalController == self.id))

            return (!created || x.info.originalEntityWasCreated == false) && type && zone
        })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                    stolen: e.info.stolen && e.info.originalController != self.id,
                    entity: e)
            })
            .group { (d: DynamicEntity) in d }
            .compactMap { g -> Card? in
                if let card = Cards.by(cardId: g.key.cardId) {
                    card.count = g.value.count
                    card.isCreated = g.key.stolen
                    card.highlightInHand = g.value.any({
                        $0.isInHand && $0.entity!.isControlled(by: self.id)
                    })
                    return card
                } else {
                    return nil
                }
            }
    }

    var createdCardsInHand: [Card] {
        return hand.filter { ($0.info.created || $0.info.stolen) }
            .group { (e: Entity) in e.cardId }
            .compactMap { g -> Card? in
                if let card = Cards.by(cardId: g.key) {
                    card.count = g.value.count
                    card.isCreated = true
                    card.highlightInHand = true
                    return card
                } else {
                    return nil
                }
            }
    }

    func getHighlightedCardsInHand(cardsInDeck: [Card]) -> [Card] {
		
        guard let deck = game.currentDeck else { return [] }

        return deck.cards.filter({ (c) -> Bool in
            cardsInDeck.all({ $0.id != c.id }) && hand.any({ $0.cardId == c.id })
        })
            .compactMap {
                let card = $0.copy()
                card.count = 0
                card.highlightInHand = true
                return card
        }
    }

    var playerCardList: [Card] {
        let createdInHand = Settings.showPlayerGet ? createdCardsInHand : [Card]()
        if game.currentDeck == nil {
            return (revealedCards + createdInHand
                + knownCardsInDeck + getPredictedCardsInDeck(hidden: true)).sortCardList()
        }
        let sorting = game.isMulliganDone() ? CardListSorting.cost : CardListSorting.mulliganWr
        let deckState = getDeckState()
        let inDeck = deckState.remainingInDeck
        let notInDeck = deckState.removedFromDeck.filter({ x in inDeck.all({ x.id != $0.id }) })
        let predictedInDeck = getPredictedCardsInDeck(hidden: false).filter({ x in inDeck.all { c in x.id != c.id } })
        if !Settings.removeCardsFromDeck {
            return annotateCards(cards: (inDeck + predictedInDeck + notInDeck + createdInHand)).sortCardList(sorting)
        }
        if Settings.highlightCardsInHand {
            return annotateCards(cards: (inDeck + predictedInDeck + getHighlightedCardsInHand(cardsInDeck: inDeck)
                + createdInHand)).sortCardList(sorting)
        }
        return annotateCards(cards: (inDeck + predictedInDeck + createdInHand)).sortCardList(sorting)
    }
    
    private func annotateCards(cards: [Card]) -> [Card] {
        // Override Zilliax 3000 cost
        let cards = Helper.resolveZilliax3000(cards, playerSideboardsDict)
        guard let mulliganCardStats else {
            return cards
        }
        // Attach Mulligan Card Data
        return cards.compactMap { card in
            let dbfId = card.deckbuildingCard.dbfId
            guard let cardStats = mulliganCardStats.first(where: { x in x.dbf_id == dbfId }) else {
                return card
            }
            let newCard = card.copy()
            if let openingHandWinrate = cardStats.opening_hand_winrate {
                let cardWinRates = CardWinrates()
                cardWinRates.mulliganWinRate = openingHandWinrate
                cardWinRates.baseWinrate = cardStats.baseWinRate
                newCard.cardWinRates = cardWinRates
            }
            newCard.isMulliganOption = hand.any { x in x.card.dbfId == dbfId }
            return newCard
        }
    }
    
    var playerSideboardsDict: [Sideboard] {
        return getPlayerSideboards(Settings.removeCardsFromDeck)
    }
    
    private func getPlayerSideboards(_ removeNotInSideboard: Bool) -> [Sideboard] {
        let deckState = getDeckState()
        var sideboardsDict = [String: [Card]]()
        if let sideboards = deckState.remainingInSideboards {
            for sideboard in sideboards {
                sideboardsDict[sideboard.key] = sideboard.value
            }
        }
        
        if let sideboards = deckState.removedFromSideboards {
            for sideboard in sideboards {
                var currentSideboard = sideboardsDict[sideboard.key]
                if currentSideboard != nil {
                    currentSideboard?.append(contentsOf: sideboard.value)
                } else {
                    sideboardsDict[sideboard.key] = sideboard.value
                }
            }
        }
        var sideboards = [Sideboard]()
        for sideboard in sideboardsDict {
            sideboards.append(Sideboard(ownerCardId: sideboard.key, cards: sideboard.value))
        }
        return sideboards
    }

    var opponentCardList: [Card] {
        if Player.knownOpponentDeck == nil {
            return (revealedEntities.filter({ (e: Entity) in
                !(e.info.guessedCardState == GuessedCardState.none && e.info.hidden)
                && (e.isPlayableCard || !e.has(tag: .cardtype))
                && !e.isInCosmetic
                && (e[.creator] == 1
                    || ((!e.info.created || (Settings.showOpponentCreated
                                             && (e.info.createdInDeck || e.info.createdInHand)))
                        && e.info.originalController == self.id)
                    || e.isInHand || e.isInDeck)
                && !CardIds.hiddenCardidPrefixes.any({ y in e.cardId.starts(with: y) })
                && !entityIsRemovedFromGamePassive(entity: e)
                && !(e.info.created && e.isInSetAside &&
                     (e.info.guessedCardState != GuessedCardState.guessed
                        // Plagues go to setaside when they are drawn. We only want to keep tracking of the ones that are still in the deck,
                        // so we hide them here
                        || (e.info.guessedCardState == .guessed &&
                            (e.cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_FrostPlagueToken ||
                             e.cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_BloodPlagueToken ||
                             e.cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_UnholyPlagueToken ||
                             e.cardId == CardIds.NonCollectible.Neutral.Incindius_EruptionToken ||
                             e.cardId == CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken)
                           )
                        )
                     )
            }).map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.info.wasTransformed ? e.info.originalCardId ?? e.cardId : e.cardId,
                              hidden: (e.isInHand || e.isInDeck || (e.isInSetAside && e.info.guessedCardState == GuessedCardState.guessed)) && e.isControlled(by: self.id),
                              created: e.info.created ||
                              (e.info.stolen && e.info.originalController != self.id),
                              discarded: e.info.discarded && Settings.highlightDiscarded,
                              extraInfo: e.info.extraInfo
                )
            }).group { (d: DynamicEntity) in d }
                .compactMap { g -> Card? in
                    if let card = Cards.by(cardId: g.key.cardId) {
                        card.count = g.value.count
                        card.jousted = g.key.hidden
                        card.isCreated = g.key.created
                        card.wasDiscarded = g.key.discarded
                        card.extraInfo = g.key.extraInfo?.copy() as? (any ICardExtraInfo)
                        return card
                    } else {
                        return nil
                    }
                } + getPredictedCardsInDeck(hidden: true)).sortCardList()
        }

        let createdInHand = Settings.showPlayerGet ? createdCardsInHand : [Card]()
        let deckState = getOpponentDeckState()
        let inDeck = deckState.remainingInDeck
        let notInDeck = deckState.removedFromDeck.filter { x in inDeck.all { c in x.id != c.id } }
        let predictedInDeck = getPredictedCardsInDeck(hidden: false).filter { x in inDeck.all { c in x.id != c.id } }
        if !Settings.removeCardsFromDeck {
            return (inDeck + predictedInDeck + notInDeck + createdInHand).sortCardList()
        }
        if Settings.highlightCardsInHand {
            return (inDeck + predictedInDeck + getHighlightedCardsInHand(cardsInDeck: inDeck) + createdInHand).sortCardList()
        }
        return (inDeck + predictedInDeck + createdInHand).sortCardList()
    }

    private func entityIsRemovedFromGamePassive(entity: Entity) -> Bool {
        return entity.has(tag: GameTag.dungeon_passive_buff) && entity[GameTag.zone] == Zone.removedfromgame.rawValue
    }
    
    fileprivate func getDeckState() -> DeckState {
        var createdCardsInDeck: [Card] = deck.filter({
            $0.hasCardId && ($0.info.created || $0.info.stolen)
        })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                              created: e.info.created || e.info.stolen,
                              discarded: e.info.discarded, 
                              extraInfo: e.info.extraInfo
                )
            })
            .group { (d: DynamicEntity) in d }
            .compactMap { g -> Card? in
                if let card = Cards.by(cardId: g.key.cardId) {
                    card.count = g.value.count
                    card.isCreated = g.key.created
                    card.highlightInHand = hand.any({ $0.cardId == g.key.cardId })
                    card.extraInfo = g.key.extraInfo?.copy() as? (any ICardExtraInfo)
                    return card
                } else {
                    return nil
                }
            }
        
        if let hero, hero[.demon_portal_deck] != 0 {
            createdCardsInDeck = [Card]()
        }
        var originalCardsInDeckIds: [String] = []
        if let deck = game.currentDeck {
            originalCardsInDeckIds = deck.cards.flatMap {
                Array(repeating: $0.id, count: $0.count)
                }
                .map({ $0 })
        }

        let revealedNotInDeck = revealedEntities.filter {
            (!$0.info.created || $0.info.originalEntityWasCreated == false)
                && $0.isPlayableCard
                && (!$0.isInDeck || $0.info.stolen)
                && $0.info.originalController == self.id
                && !$0.info.hidden
        }

        let originalSideboards = game.currentDeck?.sideboards
        
        var removedFromDeckIds = [String]()
        let zilliaxCosmetic = originalSideboards?.first { s in s.ownerCardId == CardIds.Collectible.Neutral.ZilliaxDeluxe3000 }?.cards.first { c in c.zilliaxCustomizableCosmeticModule }
        revealedNotInDeck.forEach({ e in
            let cardId = e.cardId
            if cardId.isEmpty {
                return
            }
            if cardId == zilliaxCosmetic?.id {
                originalCardsInDeckIds.remove(CardIds.Collectible.Neutral.ZilliaxDeluxe3000)
            }
            originalCardsInDeckIds.remove(cardId)
            if !e.info.stolen || e.info.originalController == self.id {
                removedFromDeckIds.append(cardId)
            }
        })
        
        func toRemaingCard(_ g: (key: String, value: [String])) -> Card? {
            if let card = Cards.by(cardId: g.key) {
                card.count = g.value.count
                if hand.any({ $0.cardId == card.id }) {
                    card.highlightInHand = true
                }
                return card
            } else {
                return nil
            }
        }
        
        func toRemovedCard(_ g: (key: String, value: [String])) -> Card? {
            if let card = Cards.by(cardId: g.key) {
                card.count = 0
                if hand.any({ e in e.cardId == card.id }) {
                    card.highlightInHand = true
                }
                return card
            } else {
                return nil
            }
        }

        let remainingInDeck: [Card] = Helper.resolveZilliax3000(createdCardsInDeck + (originalCardsInDeckIds
            .group { (c: String) in c }
            .compactMap { g -> Card? in
                toRemaingCard(g)
            }), originalSideboards ?? [Sideboard]())

        let removedFromDeck = removedFromDeckIds.group { (c: String) in c }
            .compactMap({ g -> Card? in
                toRemovedCard(g)
            })
        
        let removedFromSideboardIds = revealedEntities.filter { x in x.hasCardId
            && x.isPlayableCard
            && x.info.originalController == id
            && x.info.originalZone == .hand && x.info.hidden == false
            && x[.copied_from_entity_id] > 0
            && revealedEntities.first { c in
                c.id == x[.copied_from_entity_id] &&
                c.isInSetAside && x.info.createdInDeck == true
            } != nil
        }.compactMap { x in x.cardId }
        var remainingInSideboard = [String: [Card]]()
        var removedFromSideboard = [String: [Card]]()
        
        if let originalSideboards {
            for sideboard in originalSideboards {
                var remainingSideboardCards = [Card]()
                var removedSideboardCards = [Card]()
                for c in sideboard.cards {
                    guard let card = Cards.by(cardId: c.id) else {
                        continue
                    }
                    card.count = c.count - removedFromSideboardIds.filter { cardId in cardId == c.id }.count
                    card.isCreated = false // Intentionally do not set cards as created to avoid gift icon
                    card.highlightInHand = hand.any { ce in ce.cardId == card.id }
                    if c.count > 0 {
                        remainingSideboardCards.append(card)
                    } else {
                        removedSideboardCards.append(card)
                    }
                }
                remainingInSideboard[sideboard.ownerCardId] = remainingSideboardCards
                removedFromSideboard[sideboard.ownerCardId] = removedSideboardCards
            }
        }

        return DeckState(remainingInDeck: remainingInDeck, removedFromDeck: removedFromDeck, remainingInSideboards: remainingInSideboard, removedFromSideboards: removedFromSideboard)
    }
    
    private func getOpponentDeckState() -> DeckState {
        let createdCardsInDeck: [Card] = revealedEntities.filter({
            $0.info.originalController == self.id && $0.isInDeck && $0.hasCardId && ($0.info.created || $0.info.stolen) && !$0.info.hidden
        })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                              created: e.info.created || e.info.stolen,
                              discarded: e.info.discarded,
                              extraInfo: e.info.extraInfo
                )
            })
            .group { (d: DynamicEntity) in d }
            .compactMap { g -> Card? in
                if let card = Cards.by(cardId: g.key.cardId) {
                    card.count = g.value.count
                    card.isCreated = g.key.created
                    card.highlightInHand = hand.any({ $0.cardId == g.key.cardId })
                    card.extraInfo =  g.key.extraInfo?.copy() as? (any ICardExtraInfo)
                    return card
                } else {
                    return nil
                }
            }

        var originalCardsInDeck: [String] = []
        if let deck = Player.knownOpponentDeck {
            originalCardsInDeck = deck.flatMap {
                Array(repeating: $0.id, count: $0.count)
                }
                .map({ $0 })
        }

        let revealedNotInDeck = revealedEntities.filter {
            (!$0.info.created || $0.info.originalEntityWasCreated == false)
                && $0.isPlayableCard
                && !$0.isInCosmetic
                && (!$0.isInDeck || $0.info.stolen)
                && $0.info.originalController == self.id
                && !$0.info.hidden
        }

        var removedFromDeck = [String]()
        revealedNotInDeck.forEach({
            originalCardsInDeck.remove($0.cardId)
            if !$0.info.stolen || $0.info.originalController == self.id {
                removedFromDeck.append($0.cardId)
            }
        })

        let cardsInDeck: [Card] = createdCardsInDeck + (originalCardsInDeck
            .group { (c: String) in c }
            .compactMap { g -> Card? in
                if let card = Cards.by(cardId: g.key) {
                    card.count = g.value.count
                    if hand.any({ $0.cardId == g.key }) {
                        card.highlightInHand = true
                    }
                    return card
                } else {
                    return nil
                }
            })

        let cardsNotInDeck = removedFromDeck.group { (c: String) in c }
            .compactMap({ g -> Card? in
                if let card = Cards.by(cardId: g.key) {
                    card.count = 0
                    if hand.any({ e in e.cardId == g.key }) {
                        card.highlightInHand = true
                    }
                    return card
                } else {
                    return nil
                }
            })

        return DeckState(remainingInDeck: cardsInDeck, removedFromDeck: cardsNotInDeck)
    }

    fileprivate var debugName: String {
        return isLocalPlayer ? "Player" : "Opponent"
    }

    func createInDeck(entity: Entity, turn: Int) {
        if entity.info.discarded {
            entity.info.discarded = false
            entity.info.created = false
        } else {
            entity.info.created = entity.info.created || turn > 1
        }
        entity.info.turn = turn
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func createInHand(entity: Entity, turn: Int) {
        entity.info.created = true
        entity.info.turn = turn
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }
    
    func createInSetAside(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }
    
    func handToDeck(entity: Entity, turn: Int) {
        entity.info.turn = turn
        entity.info.returned = true
        entity.info.drawerId = nil
        entity.info.hidden = true
        if entity.cardId != CardIds.NonCollectible.Neutral.PhotographerFizzle_FizzlesSnapshotToken && entity.cardId != CardIds.NonCollectible.Priest.Repackage_RepackagedBoxToken && !CardUtils.isStarship(entity.cardId) {
            entity.info.storedCardIds.removeAll()
        }
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func boardToDeck(entity: Entity, turn: Int) {
        entity.info.turn = turn
        entity.info.returned = true
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func play(entity: Entity, turn: Int) {
        if !isLocalPlayer {
            updateKnownEntitesInDeck(cardId: entity.cardId, turn: turn)
        }

        if let cardType = CardType(rawValue: entity[.cardtype]) {
            switch cardType {
            case .token: entity.info.created = true
            case .spell: 
                if !entity.cardId.isBlank {
                    spellsPlayedCards.append(entity)
                    if entity.has(tag: .card_target), let target = game.entities[entity[.card_target]] {
                        if target.isControlled(by: id) {
                            spellsPlayedInFriendlyCharacters.append(entity)
                        } else if target.isControlled(by: game.opponent.id) {
                            spellsPlayedInOpponentCharacters.append(entity)
                        }
                    }
                    let activeMistahVistahs = playerEntities.filter { e in e.cardId == CardIds.NonCollectible.Druid.MistahVistah_ScenicVistaToken && (e.isInZone(zone: Zone.play) || e.isInZone(zone: Zone.secret)) }

                    if activeMistahVistahs.count > 0 {
                        for mistahVistah in activeMistahVistahs {
                            mistahVistah.info.storedCardIds.append(entity.cardId)
                        }
                    }
                }
                if entity.has(tag: .spell_school), let spellSchool = SpellSchool(rawValue: entity[.spell_school]) {
                    playedSpellSchools.insert(spellSchool)
                }
            case .minion:
                if entity.cardId == CardIds.Collectible.Rogue.PogoHopper {
                    pogoHopperPlayedCount += 1
                }
            default: break
            }
        }
        entity.info.hidden = false
        entity.info.turn = turn
        entity.info.turnPlayed = game.gameEntity?[.turn]
        entity.info.costReduction = 0
        if entity.cardId != CardIds.NonCollectible.Neutral.PhotographerFizzle_FizzlesSnapshotToken && entity.cardId != CardIds.NonCollectible.Priest.Repackage_RepackagedBoxToken &&  !CardUtils.isStarship(entity.cardId) {
            entity.info.storedCardIds.removeAll()
        }
        if !entity.cardId.isBlank {
            cardsPlayedThisTurn.append(entity)
            cardsPlayedThisMatch.append(entity)
        }
        
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func handDiscard(entity: Entity, turn: Int) {
        if !isLocalPlayer {
            updateKnownEntitesInDeck(cardId: entity.cardId, turn: entity.info.turn)
        }
        entity.info.turn = turn
        entity.info.discarded = true
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func secretPlayedFromDeck(entity: Entity, turn: Int) {
        updateKnownEntitesInDeck(cardId: entity.cardId)
        entity.info.turn = turn
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func secretPlayedFromHand(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if !entity.cardId.isBlank {
            spellsPlayedCards.append(entity)
        }
        if entity.has(tag: .spell_school), let spellSchool = SpellSchool(rawValue: entity[.spell_school]) {
            playedSpellSchools.insert(spellSchool)
        }
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func questPlayedFromHand(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if !entity.cardId.isBlank {
            spellsPlayedCards.append(entity)
        }
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func mulligan(entity: Entity) {
        startingHand.remove(entity)
        
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func draw(entity: Entity, turn: Int) {
        if isLocalPlayer {
            updateKnownEntitesInDeck(cardId: entity.cardId)
        } else {
            if game.opponentEntity?[.mulligan_state] == Mulligan.dealing.rawValue {
                entity.info.mulliganed = true
            }
            entity.info.hidden = true
        }
        entity.info.turn = turn
        lastDrawnCardId = entity.cardId
        
        if turn == 0 {
            startingHand.append(entity)
        }
        
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func removeFromDeck(entity: Entity, turn: Int) {
        // Do not check for KnownCardIds here, this is how jousted cards get removed from the deck
        entity.info.turn = turn
        entity.info.discarded = true
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func removeFromPlay(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func deckDiscard(entity: Entity, turn: Int) {
        updateKnownEntitesInDeck(cardId: entity.cardId)
        entity.info.turn = turn
        entity.info.discarded = true
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }
    
    func onTurnStart() {
        cardsPlayedLastTurn = cardsPlayedThisTurn
        cardsPlayedThisTurn.removeAll()
    }
    
    func onTurnEnd() {
        cardsPlayedLastTurn = cardsPlayedThisTurn
        cardsPlayedThisTurn.removeAll()
    }
    
    // Used when a card goes from Hand to Play Zone without being played by the player.
    // (e.g. Dirty Rat, Summon when Drawn)
    func handToPlay(entity: Entity, turn: Int) {
        if !entity.cardId.isEmpty {
            updateKnownEntitesInDeck(cardId: entity.cardId)
        }
        entity.info.hidden = false
        entity.info.turn = turn
        entity.info.costReduction = 0
    }

    func deckToPlay(entity: Entity, turn: Int) {
        updateKnownEntitesInDeck(cardId: entity.cardId)
        entity.info.hidden = false
        entity.info.turn = turn
        entity.info.costReduction = 0
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }
    
    func sigilPlayedFromHand(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if !entity.cardId.isBlank {
            spellsPlayedCards.append(entity)
        }
        if entity.has(tag: .spell_school), let spellSchool = SpellSchool(rawValue: entity[.spell_school]) {
            playedSpellSchools.insert(spellSchool)
        }
    }
    
    func objectivePlayedFromHand(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if !entity.cardId.isBlank {
            spellsPlayedCards.append(entity)
        }
        if entity.has(tag: .spell_school), let spellSchool = SpellSchool(rawValue: entity[.spell_school]) {
            playedSpellSchools.insert(spellSchool)
        }
    }

    func playToGraveyard(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if entity.isMinion && entity.has(tag: .deathrattle) {
            deathrattlesPlayedCount += 1
        }
        
        if entity.isMinion {
            deadMinionsCards.append(entity)
        }
        
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func joustReveal(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if let card = inDeckPredictions.first(where: { $0.cardId == entity.cardId }) {
            card.turn = turn
        } else if entity.cardId != CardIds.NonCollectible.Neutral.ProGamer_Rock && entity.cardId != CardIds.NonCollectible.Neutral.ProGamer_Paper && entity.cardId != CardIds.NonCollectible.Neutral.ProGamer_Scissors {
            inDeckPredictions.append(PredictedCard(cardId: entity.cardId, turn: turn))
        }
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func createInPlay(entity: Entity, turn: Int) {
        entity.info.created = true
        entity.info.turn = turn
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
        if entity.isHeroPower {
            heroPowerChanged(entity: entity)
        }
    }

    func createInSecret(entity: Entity, turn: Int, creatorId: Int? = nil) {
        entity.info.created = true
        entity.info.turn = turn
        entity.info.creatorId = creatorId
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func stolenByOpponent(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func stolenFromOpponent(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func boardToHand(entity: Entity, turn: Int) {
        entity.info.turn = turn
        entity.info.returned = true
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }

    func secretTriggered(entity: Entity, turn: Int) {
        if !entity.cardId.isBlank {
            secretsTriggeredCards.append(entity)
        }
    }
    
    func opponentSecretTriggered(entity: Entity, turn: Int) {
        entity.info.turn = turn
        game.secretsManager?.secretTriggered(entity: entity)
        if Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }
    
    func heroPower(turn: Int) {
        heroPowerCount += 1
    }

    private func updateKnownEntitesInDeck(cardId: String?, turn: Int = Int.max) {
        if let card = inDeckPredictions.first(where: { $0.cardId == cardId && turn >= $0.turn }) {
            inDeckPredictions.remove(card)
        }
    }
    
    func predictUniqueCardInDeck(cardId: String, isCreated: Bool) {
        if inDeckPredictions.all({ x in x.cardId != cardId }) {
            inDeckPredictions.append(PredictedCard(cardId: cardId, turn: 0, isCreated: isCreated))
        }
    }
    
    func updateLibramReduction(change: Int) {
        libramReductionCount += change
    }
    
    func updateAbyssalCurse(value: Int) {
        abyssalCurseCount = value > 0 ? value : abyssalCurseCount + 1
    }
    
    func shuffleDeck() {
        for card in deck {
            card.info.deckIndex = 0
        }
    }
    
    func heroPowerChanged(entity: Entity) {
        if !isLocalPlayer {
            return
        }
        let id = entity.info.latestCardId
        if id == "" {
            return
        }
        let added = pastHPLock.around {
            pastHeroPowers.update(with: id)
        }
        if added != nil  && Settings.fullGameLog {
            logger.info("\(debugName) \(#function) \(entity)")
        }
    }
    
    private var _mulliganCardStats: [SingleCardStats]?
    var mulliganCardStats: [SingleCardStats]? {
        get {
            return _mulliganCardStats
        }
        set {
            _mulliganCardStats = newValue
            AppDelegate.instance().coreManager.game.updatePlayerTracker(reset: true)
        }
    }
}

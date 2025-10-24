//
//  SecretsManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/10/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class SecretsManager {
    let avengeDelay: Double = 50.0 / 1000.0
    let multipleSecretResolveDelay = 750.0 / 1000.0
    private var _avengeDeathRattleCount = 0
    private var _awaitingAvenge = false
    private var _lastStartOfTurnCheck = 0
    private var _lastStartOfTurnDamageCheck = 0
    private var _lastStartOfTurnMinionCheck = 0
    
    private var entititesInHandOnMinionsPlayed: Set<Entity>  = Set<Entity>()
    
    private var game: Game
    private let _availableSecrets: AvailableSecretsProvider
    private let _relatedCardsManager: RelatedCardsManager
    private(set) var secrets = SynchronizedArray<Secret>()
    private var _triggeredSecrets = SynchronizedArray<Entity>()
    private var opponentTookDamageDuringTurns = SynchronizedArray<Int>()
    private var entityDamageDealtHistory = SynchronizedDictionary<Int, SynchronizedDictionary<Int, Int>>()
    
    private var _lastPlayedMinionId: Int = 0
    private var savedSecrets = SynchronizedArray<MultiIdCard>()
    
    var onChanged: (([Card]) -> Void)?
    
    init(game: Game, availableSecrets: AvailableSecretsProvider, relatedCardsManager: RelatedCardsManager) {
        self.game = game
        self._availableSecrets = availableSecrets
        self._relatedCardsManager = relatedCardsManager
    }
    
    private var freeSpaceOnBoard: Bool { return game.opponentBoardCount < 7 }
    private var freeSpaceInHand: Bool { return game.opponentHandCount < 10 }
    private var handleAction: Bool { return hasActiveSecrets }
    private var isAnyMinionInOpponentsHand: Bool { return entititesInHandOnMinionsPlayed.first(where: { entity in entity.isMinion }) != nil }
    
    private var hasActiveSecrets: Bool {
        return secrets.count > 0
    }
    
    private func saveSecret(secret: MultiIdCard) {
        if !secrets.any({ (s) -> Bool in
            s.isExcluded(cardId: secret)
        }) {
            savedSecrets.append(secret)
        }
    }
    
    func exclude(cardId: MultiIdCard, invokeCallback: Bool = true) {
        secrets.forEach {
            $0.exclude(cardId: cardId)
        }
        
        if invokeCallback {
            onChanged?(getSecretList())
        }
    }
    
    func exclude(cardIds: [MultiIdCard]) {
        cardIds.enumerated().forEach {
            exclude(cardId: $1, invokeCallback: $0 == cardIds.count - 1)
        }
    }
    
    func reset() {
        _avengeDeathRattleCount = 0
        _awaitingAvenge = false
        _lastStartOfTurnCheck = 0
        _lastStartOfTurnDamageCheck = 0
        _lastStartOfTurnMinionCheck = 0
        opponentTookDamageDuringTurns.removeAll()
        entititesInHandOnMinionsPlayed.removeAll()
        secrets.removeAll()
    }
    
    @discardableResult
    func newSecret(entity: Entity) -> Bool {
        if !entity.isSecret || !entity.has(tag: .class) {
            return false
        }
        
        if entity.hasCardId {
            if let secretMultiIdCard = CardIds.Secrets.getSecretMultiIdCard(entity.cardId) {
                exclude(cardId: secretMultiIdCard, invokeCallback: false)
            }
        }
        do {
            let secret = try Secret(entity: entity)
            secrets.append(secret)
            logger.info("new secret : \(entity)")
            onNewSecret(secret: secret)
            onChanged?(getSecretList())
            return true
        } catch {
            logger.error("\(error)")
            return false
        }
    }
    
    @discardableResult
    func removeSecret(entity: Entity) -> Bool {
        guard let secret = secrets.first(where: { $0.entity.id == entity.id }) else {
            logger.info("Secret not found \(entity)")
            return false
        }
        
        handleFastCombat(entity: entity)
        secrets.remove(secret)
        if secret.entity.hasCardId {
            if let secretMultiIdCard = CardIds.Secrets.getSecretMultiIdCard(secret.entity.cardId) {
                exclude(cardId: secretMultiIdCard, invokeCallback: false)
                savedSecrets.remove(secretMultiIdCard)
            }
        }
        onChanged?(getSecretList())
        return true
    }
    
    func toggle(cardId: String) {
        let mcid = MultiIdCard(cardId)
        let excluded = secrets.any { $0.isExcluded(cardId: mcid) }
        if excluded {
            secrets.forEach { $0.include(cardId: mcid) }
        } else {
            exclude(cardId: mcid, invokeCallback: false)
        }
    }
    
    func getAvailableSecrets(gameMode: GameType, format: FormatType) -> Set<String> {
        if let byType = _availableSecrets.byType {
            if let gameModeSecrets = byType["\(gameMode)".uppercased()] {
                return gameModeSecrets
            }
            if let formatSecrets = byType["\(format)".uppercased()] {
                return formatSecrets
            }
        }
        // Fallback in case query isn't available
        return switch format {
        case .ft_standard:
            Set<String>(CardIds.Secrets.All.filter { x in x.isStandard }.map { x in x.ids[0] })
        default:
            Set<String>(CardIds.Secrets.All.filter { x in x.isWild }.map { x in x.ids[0] })
        }
    }
    
    func getCreatedBySecretsByCreator(gameMode: GameType, format: FormatType) -> [String: Set<String>]? {
        if gameMode != .gt_arena && gameMode != .gt_underground_arena {
            return nil
        }
        
        if let createdByTypeByCretor = _availableSecrets.createdByTypeByCreator, let res = createdByTypeByCretor["\(gameMode)"] {
            return res
        }
        return nil
    }

    func getSecretList() -> [Card] {
        let gameMode = game.currentGameType
        let format = game.currentFormatType
        
        let deckSecrets = getSecretsFromDeck(gameMode, format)
        let createdSecretsList = getSecretsCreatedBy(gameMode, format)
        
        return createdSecretsList.concatCardList(deckSecrets)
    }
    
    private func getSecretsFromDeck(_ gameMode: GameType, _ format: FormatType) -> [Card] {
        let gameModeHasCardLimit = switch gameMode {
        case .gt_casual, .gt_ranked, .gt_vs_friend, .gt_vs_ai:
            true
        default:
            false
        }
        
        let opponentEntities = game.opponent.revealedEntities.filter {
            $0.id < 68 && $0.isSecret && $0.hasCardId
        }
        
        let createdSecrets = secrets
            .filter { $0.entity.info.created }
            .flatMap { $0.excluded }
            .filter { !$0.value }
            .map { $0.key }
            .unique()
        
        let availableSecrets = getAvailableSecrets(gameMode: gameMode, format: format)
        
        let secretsFromDeck = secrets.filter { s in !s.entity.info.created }
        
        let filteredSecretsFromDeck = getFilteredSecretsByDrawer(secretsFromDeck, availableSecrets)
        
        let hasPlayedTwoOf: ((_ card: MultiIdCard) -> Bool) = { card in
            opponentEntities.filter { card == $0.cardId && !$0.info.created }.count >= 2
        }
        let adjustCount: ((_ card: MultiIdCard, _ count: Int) -> Int) = { card, count in
            gameModeHasCardLimit && hasPlayedTwoOf(card) && !createdSecrets.contains(card) ? 0 : count
        }
        
        let cards = filteredSecretsFromDeck
            .group { m in m }
            .compactMap { group in
                if let multiIdCard = CardIds.Secrets.getSecretMultiIdCard(group.key.ids[0]) {
                    return QuantifiedMultiIdCard(baseCard: group.key, count: adjustCount(multiIdCard, group.value.count))
                } else {
                    return QuantifiedMultiIdCard(baseCard: group.key, count: 0)
                }
            }
                
        return SecretsManager.quantifiedCardsToCards(cards, format)
    }
    
    private func getSecretsCreatedBy(_ gameMode: GameType, _ format: FormatType) -> [Card] {
        let createdBySecrets = secrets.filter { $0.entity.info.created }
        
        let availableSecrets = getAvailableSecrets(gameMode: gameMode, format: format)
        
        if gameMode == .gt_arena || gameMode == .gt_underground_arena {
            let secrets = getArenaCreatedSecrets(createdBySecrets, availableSecrets, gameMode, format)
            return secrets
        }
        
        let filteredSecrets = getFilteredSecretsByDrawer(createdBySecrets, availableSecrets)
        
        let quantified = filteredSecrets
            .group { m in m }
            .compactMap { g in
                if CardIds.Secrets.getSecretMultiIdCard(g.key.ids[0]) != nil {
                    return QuantifiedMultiIdCard(baseCard: g.key, count: g.value.count)
                } else {
                    return QuantifiedMultiIdCard(baseCard: g.key, count: 0)
                }
            }
            .filter { x in x.ids.any { availableSecrets.contains($0) }}
        
        return SecretsManager.quantifiedCardsToCards(quantified, format)
    }
    
    private func getArenaCreatedSecrets(_ createdBySecrets: [Secret], _ availableSecrets: Set<String>, _ gameMode: GameType, _ format: FormatType) -> [Card] {
        var secretsCreated = [MultiIdCard]()
        if let availableCreatedBy = getCreatedBySecretsByCreator(gameMode: gameMode, format: format) {
            let creators = createdBySecrets.compactMap { s in (s, game.opponent.revealedEntities.first { e in e.id == s.entity.info.getCreatorId()})}
            for (secret, creator) in creators {
                let drawer = game.opponent.revealedEntities.first { e in e.id == secret.entity.info.getDrawerId() }
                
                if let drawer, let spellSchoolTutor = _relatedCardsManager.getSpellSchoolTutor(drawer.cardId) {
                    if let creator, let creatableSecrets = availableCreatedBy[creator.cardId] {
                        let secrets = SecretsManager.getFilteredSecretsByDrawerFromSingleSecret(secret, spellSchoolTutor, creatableSecrets)
                        secretsCreated.append(contentsOf: secrets)
                    } else {
                        let secrets = SecretsManager.getFilteredSecretsByDrawerFromSingleSecret(secret, spellSchoolTutor, availableSecrets)
                        secretsCreated.append(contentsOf: secrets)
                    }
                } else {
                    if let creator, let creatableSecrets = availableCreatedBy[creator.cardId] {
                        let secrets = secret.excluded.filter { x in x.key.ids.any { creatableSecrets.contains($0) }}
                        secretsCreated.append(contentsOf: secrets.filter { x in !x.value }.compactMap { x in x.key })
                    } else {
                        let secrets = secret.excluded.filter { x in x.key.ids.any { availableSecrets.contains($0) }}
                        secretsCreated.append(contentsOf: secrets.filter { x in !x.value }.compactMap { x in x.key })
                    }
                }
            }
            
            let quantified = secretsCreated
                .group { m in m }
                .compactMap { g in
                    if CardIds.Secrets.getSecretMultiIdCard(g.key.ids[0]) != nil {
                        return QuantifiedMultiIdCard(baseCard: g.key, count: g.value.count)
                    } else {
                        return QuantifiedMultiIdCard(baseCard: g.key, count: 0)
                    }
                }
            return SecretsManager.quantifiedCardsToCards(quantified, format)
        }
        
        let filteredSecrets = getFilteredSecretsByDrawer(createdBySecrets, availableSecrets)
        
        let quantifiedSecrets = filteredSecrets
            .group { x in x }
            .compactMap { g in
                if CardIds.Secrets.getSecretMultiIdCard(g.key.ids[0]) != nil {
                    return QuantifiedMultiIdCard(baseCard: g.key, count: g.value.count)
                } else {
                    return QuantifiedMultiIdCard(baseCard: g.key, count: 0)
                }
            }
        
        return SecretsManager.quantifiedCardsToCards(quantifiedSecrets, format)
    }
    
    private func getFilteredSecretsByDrawer(_ allSecrets: [Secret], _ availableSecrets: Set<String>) -> [MultiIdCard] {
        let secretAndDrawSource = allSecrets.compactMap { s in
            (s, game.opponent.revealedEntities.first { e in e.id == s.entity.info.getDrawerId() })
        }

        var filteredSecrets = [MultiIdCard]()
        for (secret, drawSource) in secretAndDrawSource {
            if let drawSource, let spellSchoolTutor = _relatedCardsManager.getSpellSchoolTutor(drawSource.cardId) {
                filteredSecrets.append(contentsOf: SecretsManager.getFilteredSecretsByDrawerFromSingleSecret(secret, spellSchoolTutor, availableSecrets))
            } else {
                let secrets = secret.excluded.filter { x in x.key.ids.any { availableSecrets.contains($0) } }
                filteredSecrets.append(contentsOf: secrets.filter { x in !x.value }.compactMap { x in x.key })
            }
        }

        return filteredSecrets
    }

    private static func getFilteredSecretsByDrawerFromSingleSecret(_ secret: Secret, _ spellSchoolTutor: ISpellSchoolTutor, _ availableSecrets: Set<String>) ->  [MultiIdCard] {
        let spellSchools = spellSchoolTutor.tutoredSpellSchools
        return secret.excluded
            .filter { x in x.key.ids.any { availableSecrets.contains($0) && !x.value }}
            .compactMap { x in Card(id: x.key.ids[0]) }
            .filter { c in spellSchools.contains(c.spellSchool.rawValue) }
            .compactMap { c in CardIds.Secrets.getSecretMultiIdCard(c.id) }
    }
    
    private static func quantifiedCardsToCards(_ quantified: [QuantifiedMultiIdCard], _ format: FormatType) -> [Card] {
        return quantified.compactMap { x in
            if let card = x.getCardForFormat(format: format) {
                card.count = x.count
                return card
            }
            return nil
        }
    }

    func handleAttack(attacker: Entity, defender: Entity, fastOnly: Bool = false) {
        guard handleAction else { return }

        if attacker[.controller] == defender[.controller] {
            return
        }

        var exclude: [MultiIdCard] = []
        
        if freeSpaceOnBoard {
            exclude.append(CardIds.Secrets.Paladin.NobleSacrifice)
        }
        
        if !attacker.isHero {
            exclude.append(CardIds.Secrets.Paladin.JudgementofJustice)
        }

        if defender.isHero {
            if !fastOnly && attacker.health >= 1 {
                if freeSpaceOnBoard {
                    exclude.append(CardIds.Secrets.Hunter.BearTrap)
                }

                if game.entities.values.first(where: { x in
                    x.isInPlay && (x.isHero || x.isMinion) && !x.has(tag: .immune) && x != attacker && x != defender
                    }) != nil {
                    exclude.append(CardIds.Secrets.Hunter.Misdirection)
                }

                if attacker.isMinion {
                    if game.playerMinionCount > 1 {
                        exclude.append(CardIds.Secrets.Rogue.SuddenBetrayal)
                    }

                    exclude.append(CardIds.Secrets.Mage.FlameWard)
                    exclude.append(CardIds.Secrets.Hunter.FreezingTrap)
                    exclude.append(CardIds.Secrets.Mage.Vaporize)
                    if freeSpaceOnBoard {
                        exclude.append(CardIds.Secrets.Rogue.ShadowClone)
                    }
                }
            }

            if freeSpaceOnBoard {
                exclude.append(CardIds.Secrets.Hunter.WanderingMonster)
                if attacker.isMinion {
                    exclude.append(CardIds.Secrets.Mage.VengefulVisage)
                }
            }

            exclude.append(CardIds.Secrets.Mage.IceBarrier)
            exclude.append(CardIds.Secrets.Hunter.ExplosiveTrap)
        } else {
            exclude.append(CardIds.Secrets.Rogue.Bamboozle)
            exclude.append(CardIds.Secrets.Hunter.BaitAndSwitch)
            if !defender.has(tag: .divine_shield) {
                exclude.append(CardIds.Secrets.Paladin.AutodefenseMatrix)
            }
            
            if freeSpaceOnBoard {
                exclude.append(CardIds.Secrets.Mage.SplittingImage)
                exclude.append(CardIds.Secrets.Hunter.PackTactics)
                exclude.append(CardIds.Secrets.Hunter.SnakeTrap)
                exclude.append(CardIds.Secrets.Hunter.VenomstrikeTrap)
                //I think most of the secrets here could (and maybe should) check for this, but this one definitley does because of Hysteria.
                if game.playerEntity?.isCurrentPlayer ?? false {
                    exclude.append(CardIds.Secrets.Mage.OasisAlly)
                }
            }

            if attacker.isMinion {
                exclude.append(CardIds.Secrets.Hunter.FreezingTrap)
            }
        }
        self.exclude(cardIds: exclude)
    }

    func handleFastCombat(entity: Entity) {
        guard handleAction else { return }

        if !entity.hasCardId || game.proposedAttacker == 0 || game.proposedDefender == 0 {
            return
        }
        guard let multiIdCard = CardIds.Secrets.getSecretMultiIdCard(entity.cardId) else {
            return
        }
        if !CardIds.Secrets.fastCombat.contains(multiIdCard) {
            return
        }
        if let attacker = game.entities[game.proposedAttacker],
            let defender = game.entities[game.proposedDefender] {
            handleAttack(attacker: attacker, defender: defender, fastOnly: true)
        }
    }

    func handleMinionPlayed(entity: Entity) {
        guard handleAction else { return }

        var exclude: [MultiIdCard] = []
        
        _lastPlayedMinionId = entity.id

        if !entity.has(tag: .dormant) {
            saveSecret(secret: CardIds.Secrets.Hunter.BargainBin)
            exclude.append(CardIds.Secrets.Hunter.BargainBin)
            saveSecret(secret: CardIds.Secrets.Hunter.Snipe)
            exclude.append(CardIds.Secrets.Hunter.Snipe)
            saveSecret(secret: CardIds.Secrets.Mage.ExplosiveRunes)
            exclude.append(CardIds.Secrets.Mage.ExplosiveRunes)
            saveSecret(secret: CardIds.Secrets.Mage.Objection)
            exclude.append(CardIds.Secrets.Mage.Objection)
            saveSecret(secret: CardIds.Secrets.Mage.PotionOfPolymorph)
            exclude.append(CardIds.Secrets.Mage.PotionOfPolymorph)
            saveSecret(secret: CardIds.Secrets.Paladin.Repentance)
            exclude.append(CardIds.Secrets.Paladin.Repentance)
        }

        if freeSpaceOnBoard {
            saveSecret(secret: CardIds.Secrets.Mage.MirrorEntity)
            exclude.append(CardIds.Secrets.Mage.MirrorEntity)
            saveSecret(secret: CardIds.Secrets.Rogue.Ambush)
            exclude.append(CardIds.Secrets.Rogue.Ambush)
            saveSecret(secret: CardIds.Secrets.Hunter.Zombeeees)
            exclude.append(CardIds.Secrets.Hunter.Zombeeees)
        }

        if freeSpaceInHand {
            exclude.append(CardIds.Secrets.Mage.FrozenClone)
        }
        exclude.append(CardIds.Secrets.Rogue.Kidnap)

        //Hidden cache will only trigger if the opponent has a minion in hand.
        //We might not know this for certain - requires additional tracking logic.
        let cardsInOpponentsHand = game.entities.values.filter({ e in
            e.isInHand && e.isControlled(by: game.opponent.id)
        }).compactMap({ e in e })
        for cardInOpponentsHand in cardsInOpponentsHand {
            entititesInHandOnMinionsPlayed.insert(cardInOpponentsHand)
        }

        if isAnyMinionInOpponentsHand {
            exclude.append(CardIds.Secrets.Hunter.HiddenCache)
        }

        self.exclude(cardIds: exclude)
    }

    func handleOpponentMinionDeath(entity: Entity) {
        guard handleAction else { return }

        var exclude: [MultiIdCard] = []
        if freeSpaceInHand {
            exclude.append(CardIds.Secrets.Mage.Duplicate)
            exclude.append(CardIds.Secrets.Paladin.GetawayKodo)
            exclude.append(CardIds.Secrets.Rogue.CheatDeath)
        }
        
        if let opponent_minions_died = game.opponentEntity?[.num_friendly_minions_that_died_this_turn], opponent_minions_died >= 1 {
            exclude.append(CardIds.Secrets.Paladin.HandOfSalvation)
        }

        var numDeathrattleMinions = 0
        if entity.isActiveDeathrattle {
            if let count = CardIds.DeathrattleSummonCardIds[entity.cardId] {
                numDeathrattleMinions = count
            } else if entity.cardId == CardIds.Collectible.Neutral.Stalagg
                && game.opponent.graveyard.any({ $0.cardId == CardIds.Collectible.Neutral.Feugen })
                || entity.cardId == CardIds.Collectible.Neutral.Feugen
                && game.opponent.graveyard.any({ $0.cardId == CardIds.Collectible.Neutral.Stalagg }) {
                numDeathrattleMinions = 1
            }

            if game.entities.values.any({ $0.cardId == CardIds.NonCollectible.Druid.SouloftheForest_SoulOfTheForestEnchantment
                && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }
            if game.entities.values.any({ $0.cardId == CardIds.NonCollectible.Shaman.AncestralSpirit_AncestralSpiritEnchantment
                && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }
        }

        if let opponentEntity = game.opponentEntity,
            opponentEntity.has(tag: .extra_deathrattles) {
            numDeathrattleMinions *= opponentEntity[.extra_deathrattles] + 1
        }

        handleAvengeAsync(deathRattleCount: numDeathrattleMinions)

        // redemption never triggers if a deathrattle effect fills up the board
        // effigy can trigger ahead of the deathrattle effect, but only if effigy was played before the deathrattle minion
        if game.opponentBoardCount < 7 - numDeathrattleMinions {
            exclude.append(CardIds.Secrets.Paladin.Redemption)
        }

        // TODO: break ties when Effigy + Deathrattle played on the same turn
        exclude.append(CardIds.Secrets.Mage.Effigy)
        exclude.append(CardIds.Secrets.Hunter.EmergencyManeuvers)

        self.exclude(cardIds: exclude)
    }
    
    func handlePlayerMinionDeath(entity: Entity) {
        if entity.id == _lastPlayedMinionId && savedSecrets.count > 0 {
            savedSecrets.forEach { savedSecret in
                secrets.forEach { secret in
                    secret.include(cardId: savedSecret)
                }
            }
            
            onChanged?(getSecretList())
        }
    }

    func handleAvengeAsync(deathRattleCount: Int) {
        guard handleAction else { return }

        if _awaitingAvenge {
            return
        }
        
        DispatchQueue.global().async {
            self._awaitingAvenge = true
            self._avengeDeathRattleCount += deathRattleCount
            if self.game.opponentMinionCount != 0 {
                Thread.sleep(forTimeInterval: self.avengeDelay)
                if self.game.opponentMinionCount - self._avengeDeathRattleCount > 0 {
                    self.exclude(cardId: CardIds.Secrets.Paladin.Avenge)
                }
            }
            self._avengeDeathRattleCount = 0
            self._awaitingAvenge = false
        }
    }

    func handleOpponentDamage(entity: Entity, damage: Int) {
        guard handleAction else { return }

        if entity.isHero && entity.isControlled(by: game.opponent.id) {
            if !entity.has(tag: GameTag.immune) {
                exclude(cardId: CardIds.Secrets.Paladin.EyeForAnEye)
                exclude(cardId: CardIds.Secrets.Rogue.Evasion)
                opponentTookDamageDuringTurns.append(game.turnNumber())
            }
        }
        
        if damage >= 3 && entity.isMinion && entity.isControlled(by: game.opponent.id) && entity[.zone] != Zone.graveyard.rawValue {
            exclude(cardId: CardIds.Secrets.Paladin.Reckoning)
        }
    }
    
    func handleEntityLostArmor(entity: Entity, value: Int) {
        if value <= 0 {
            return
        }
        
        if entity.isHero && entity.isControlled(by: game.opponent.id) {
            if !entity.has(tag: .immune) {
                opponentTookDamageDuringTurns.append(game.turnNumber())
            }
        }
    }

    func handleTurnsInPlayChange(entity: Entity, turn: Int) {
        guard handleAction else { return }

        let isCurrentPlayer = game.opponentEntity?.isCurrentPlayer ?? false
        
        if isCurrentPlayer && (turn > _lastStartOfTurnCheck) {
            _lastStartOfTurnCheck = turn
            exclude(cardId: CardIds.Secrets.Rogue.Perjury)
            if game.opponentMinionCount >= 1 && freeSpaceOnBoard {
                exclude(cardId: CardIds.Secrets.Mage.SummoningWard)
            }
        }
        
        if isCurrentPlayer && (turn > _lastStartOfTurnMinionCheck) {
            if entity.isMinion && entity.isControlled(by: game.opponent.id) {
                _lastStartOfTurnMinionCheck = turn
                exclude(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
                if game.opponentMinionCount >= 2 && freeSpaceOnBoard {
                    exclude(cardId: CardIds.Secrets.Hunter.OpenTheCages)
                }
            }
        }
        if isCurrentPlayer && (turn > _lastStartOfTurnDamageCheck) {
            _lastStartOfTurnDamageCheck = turn
            let turnToCheck = turn - (game.playerEntity?.has(tag: .first_player) ?? false ? 0 : 1)
            if !opponentTookDamageDuringTurns.contains(turnToCheck) {
                exclude(cardId: CardIds.Secrets.Mage.RiggedFaireGame)
            }
        }
    }
    
    func handlePlayerTurnStart() {
        savedSecrets.removeAll()
    }
    
    func handleOpponentTurnStart() {
        if game.player.cardsPlayedThisTurn.count > 0 {
            exclude(cardId: CardIds.Secrets.Rogue.Plagiarize)
        }
    }
    
    func handlePlayerTurnEnded(mana: Int) {
        if mana == 0 {
            exclude(cardId: CardIds.Secrets.Hunter.HiddenMeaning)
        }
    }
    
    func handlePlayerManaRemaining(mana: Int) {
        if mana == 0 && freeSpaceInHand {
            exclude(cardId: CardIds.Secrets.Rogue.DoubleCross)
        }
    }
    
    func secretTriggered(entity: Entity) {
        _triggeredSecrets.append(entity)
    }

    func handleCardPlayed(entity: Entity, parentCardId: String) {
        guard handleAction else { return }
        
        savedSecrets.removeAll()

        var exclude: [MultiIdCard] = []
        
        if let player = game.playerEntity, player.has(tag: .num_cards_played_this_turn) && (player[.num_cards_played_this_turn] >= 3) {
            exclude.append(CardIds.Secrets.Hunter.MotionDenied)
            if freeSpaceOnBoard {
                exclude.append(CardIds.Secrets.Hunter.RatTrap)
                exclude.append(CardIds.Secrets.Paladin.GallopingSavior)
            }
            
            if freeSpaceInHand {
                exclude.append(CardIds.Secrets.Paladin.HiddenWisdom)
            }
        }
        
        if entity[.num_turns_in_hand] == 1 {
            if freeSpaceInHand {
                exclude.append(CardIds.Secrets.Mage.AzeriteVein)
            }
        }
        
        if entity.isSpell {
            if parentCardId == CardIds.Collectible.Rogue.SparkjoyCheat {
                return
            }
            _triggeredSecrets.removeAll()
            if game.opponentSecretCount > 1 {
                usleep(useconds_t(1000 * multipleSecretResolveDelay))
            }
            // Counterspell/Ice trap order may matter in rare edge cases where both are in play.
            // This is currently not handled.
            exclude.append(CardIds.Secrets.Mage.Counterspell)
            
            if _triggeredSecrets.any({ x in CardIds.Secrets.Mage.Counterspell == x.cardId }) {
                self.exclude(cardIds: [CardIds.Secrets.Mage.Counterspell])
                return
            }
            
            exclude.append(CardIds.Secrets.Hunter.IceTrap)
            if _triggeredSecrets.any({ x in CardIds.Secrets.Hunter.IceTrap == x.cardId }) {
                self.exclude(cardIds: [CardIds.Secrets.Hunter.IceTrap])
                return
            }
            
            exclude.append(CardIds.Secrets.Hunter.BargainBin)

            exclude.append(CardIds.Secrets.Paladin.OhMyYogg)
            
            if game.opponentMinionCount > 0 {
                exclude.append(CardIds.Secrets.Paladin.NeverSurrender)
            }

            if game.opponentHandCount < 10 {
                exclude.append(CardIds.Secrets.Rogue.DirtyTricks)
                exclude.append(CardIds.Secrets.Mage.ManaBind)
            }

            if freeSpaceOnBoard {
                // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                Thread.sleep(forTimeInterval: 0.2)
                if let target = game.entities[entity[.card_target]],
                    entity.has(tag: .card_target),
                    target.isMinion {
                    exclude.append(CardIds.Secrets.Mage.Spellbender)
                }
                exclude.append(CardIds.Secrets.Hunter.CatTrick)
                exclude.append(CardIds.Secrets.Mage.NetherwindPortal)
                exclude.append(CardIds.Secrets.Rogue.StickySituation)
            }

            if game.playerMinionCount > 0 {
                exclude.append(CardIds.Secrets.Hunter.PressurePlate)
            }
        } else if entity.isMinion && game.playerMinionCount > 3 {
            exclude.append(CardIds.Secrets.Paladin.SacredTrial)
        }
        
        if entity.isWeapon {
            exclude.append(CardIds.Secrets.Hunter.BargainBin)
        }
        self.exclude(cardIds: exclude)
    }
    
    func onNewSecret(secret: Secret) {
        if secret.entity[GameTag.class] == CardClass.allCases.firstIndex(of: .hunter) {
            entititesInHandOnMinionsPlayed.removeAll()
        }
    }
    
    func handleCardDrawn(entity: Entity) {
        guard handleAction else { return }

        var exclude: [MultiIdCard] = []
        if let playerEntity = game.playerEntity, playerEntity[.num_cards_drawn_this_turn] >= 1 {
            exclude.append(CardIds.Secrets.Rogue.Shenanigans)
        }
        
        self.exclude(cardIds: exclude)
    }

    func handleHeroPower() {
        guard handleAction else { return }
        exclude(cardId: CardIds.Secrets.Hunter.DartTrap)
    }
    
    func onEntityRevealedAsMinion(entity: Entity) {
        if entititesInHandOnMinionsPlayed.contains(entity) && entity.isMinion {
            exclude(cardId: CardIds.Secrets.Hunter.HiddenCache)
        }
    }
    
    func onNewBlock() {
        entityDamageDealtHistory.removeAll()
    }
    
    func entityDamage(dealer: Entity, target: Entity, damage: Int) {
        DispatchQueue.global().async { [self] in
            if target.isHero && target.isControlled(by: game.opponent.id) {
                if !target.has(tag: .immune) {
                    exclude(cardId: CardIds.Secrets.Paladin.EyeForAnEye)
                    exclude(cardId: CardIds.Secrets.Rogue.Evasion)
                    opponentTookDamageDuringTurns.append(game.turnNumber())
                }
            }
            if dealer.isMinion && dealer.isControlled(by: game.player.id) {
                if let dict = entityDamageDealtHistory[dealer.id] {
                    if let hist = dict[target.id] {
                        dict[target.id] = hist + damage
                    } else {
                        dict[target.id] = damage
                    }
                } else {
                    let dict = SynchronizedDictionary<Int, Int>()
                    entityDamageDealtHistory[dealer.id] = dict
                    dict[target.id] = damage
                }
                let damageDealt = entityDamageDealtHistory[dealer.id]?[target.id] ?? 0
                Thread.sleep(forTimeInterval: 0.1)
                //We check both heaolth and zone because sometimes after the await the dealer's health will revert to that of the original card.
                if damageDealt >= 3 && dealer.health > 0 && dealer[.zone] != Zone.graveyard.rawValue {
                    exclude(cardId: CardIds.Secrets.Paladin.Reckoning)
                }
            }
        }
    }
}

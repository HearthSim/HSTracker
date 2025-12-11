/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import Foundation

enum DeckLocation: Int {
    case unknown, top, bottom
}

class PowerGameStateParser: LogEventParser {
    static let TransferStudentToken = CardIds.Collectible.Neutral.TransferStudent + "t"
    
    final let BlockStartRegex = Regex(".*BLOCK_START.*BlockType=(\\w+).*id=(\\d*).*(cardId=(\\w*)).*player=(\\d*).*EffectCardId=(.*)\\sEffectIndex=.*Target=(.+).*SubOption=([^\\s]*)(?:\\sTriggerKeyword=\\w+)?")
    final let CardIdRegex = Regex("cardId=(\\w+)")
    final let CreationRegex = Regex("FULL_ENTITY - Updating.*id=(\\d+).*zone=(\\w+).*CardID=(\\w*)")
    final let CreationTagRegex = Regex("tag=(\\w+) value=(\\w+)")
    final let GameEntityRegex = Regex("GameEntity EntityID=(\\d+)")
    final let PlayerEntityRegex = Regex("Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)")
    final let PlayerIDRegex = Regex("\\[hi\\=(\\d+)\\slo=(\\d+)")
    final let PlayerNameRegex = Regex("id=(\\d) Player=(.+) TaskList=(\\d)")
    final let TagChangeRegex = Regex("TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)")
    final let UpdatingEntityRegex = Regex("(SHOW_ENTITY|CHANGE_ENTITY) - Updating Entity=(.+) CardID=(\\w*)")
    final let HideEntityRegex = Regex("HIDE_ENTITY\\ -\\ .* id=(?<id>(\\d+))")
    final let ShuffleRegex = Regex("SHUFFLE_DECK\\ PlayerID=(?<id>(\\d+))")
    final let SubSpellStartRegex = Regex("SUB_SPELL_START - SpellPrefabGUID=(.*) Source=(\\d+)")
    final let MetaInfoRegex = Regex("Info\\[\\d+\\]\\s*=\\s*(?:.*\\bid=(\\d+).*]|\\b(\\d+)\\b)")
    var tagChangeHandler = TagChangeHandler()
    var currentEntity: Entity?
    var gameStateIsInsideMetaDataHistoryTarget = false

	private let eventHandler: PowerEventHandler

	init(with eventHandler: PowerEventHandler) {
		self.eventHandler = eventHandler
        self.tagChangeHandler.setPowerGameStateParser(parser: self)
	}

    // MARK: - Entities

    private var currentEntityId = 0

    func resetCurrentEntity() {
        currentEntityId = 0
    }
    func set(currentEntity id: Int) {
        currentEntityId = id
    }

    // MARK: - blocks
    func blockStart(type: String?, cardId: String?, target: String?, trigger: String?) {
        maxBlockId += 1
        let blockId = maxBlockId
        currentBlock = currentBlock?.createChild(blockId: blockId, type: type, cardId: cardId, target: target, trigger: trigger) ?? Block(parent: nil, id: blockId, type: type, cardId: cardId, target: target, trigger: trigger)
        AppDelegate.instance().coreManager.game.secretsManager?.onNewBlock()
    }

    func blockEnd() {
        currentBlock = currentBlock?.parent
        if let entity = eventHandler.entities[currentEntityId] {
            entity.info.hasOutstandingTagChanges = false
        }
    }

    private var maxBlockId: Int = 0
    var currentBlock: Block?
    
    func getCurrentBlock() -> Block? {
        return self.currentBlock
    }

    // MARK: - line handling

    func handle(logLine: LogLine) {
        var creationTag = false
        var isInsideMetaDataHistoryTarget = false

        // current game
        if GameEntityRegex.match(logLine.line) {
            if let match = GameEntityRegex.matches(logLine.line).first,
                let id = Int(match.value) {
                //print("**** GameEntityRegex id:'\(id)'")
                if eventHandler.entities[id] == nil {
                    let entity = Entity(id: id)
                    entity.name = "GameEntity"
                    eventHandler.add(entity: entity)
                }

                set(currentEntity: id)

                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
                return
            }
        }

        // players
        else if PlayerEntityRegex.match(logLine.line) {
            let matches = PlayerEntityRegex.matches(logLine.line)
            if let id = Int(matches[0].value) {
                if eventHandler.entities[id] == nil {
                    let entity = Entity(id: id)
                    eventHandler.add(entity: entity)
                }
                
                set(currentEntity: id)
                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
            }
            return
        } else if TagChangeRegex.match(logLine.line) {
            let matches = TagChangeRegex.matches(logLine.line)
            guard matches.count == 3 else {
                Influx.sendSingleEvent(eventName: "TagChangeRegex_unexpected_matches", withProperties: ["logline": logLine.line, "matches": "\(matches.count)"])
                return
            }
            let rawEntity = matches[0].value
                .replacingOccurrences(of: "UNKNOWN ENTITY ", with: "")
            let tag = matches[1].value
            let value = matches[2].value

            if rawEntity.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity: rawEntity) {
                let entity = tagChangeHandler.parseEntity(entity: rawEntity)
                if let id = entity.id {
                    tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag, id: id, rawValue: value)
                }
            } else if let id = Int(rawEntity) {
                tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag, id: id, rawValue: value)
            } else {
                var entity = eventHandler.entities.values
                    .first { $0.name == rawEntity }

                if let entity = entity {
                    tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag,
                                               id: entity.id, rawValue: value)
                } else {
                    let players = eventHandler.entities.values
                        .filter { $0.has(tag: .player_id) }.sorted(by: { $0.id < $1.id })
                        .take(2)
                    let unnamedPlayers = players.filter { $0.name.isBlank }
                    let unknownHumanPlayer = players
                        .first { $0.name == "UNKNOWN HUMAN PLAYER" }

                    if unnamedPlayers.count == 0 && unknownHumanPlayer != nil {
                        entity = unknownHumanPlayer
                    }

                    //while the id is unknown, store in tmp entities
                    var tmpEntity = eventHandler.tmpEntities.first { $0.name == rawEntity }
                    if tmpEntity == nil {
                        let tmp = Entity(id: eventHandler.tmpEntities.count + 1)
                        tmp.name = rawEntity
                        eventHandler.tmpEntities.append(tmp)
                        tmpEntity = tmp
                    }

                    if let _tag = GameTag(rawString: tag) {
                        let tagValue = tagChangeHandler.parseTag(tag: _tag, rawValue: value)

                        if unnamedPlayers.count == 1 {
                            entity = unnamedPlayers.first
                        } else if unnamedPlayers.count == 2 &&
                            _tag == .current_player && tagValue == 0 {
                            entity = eventHandler.entities.values
                                .first { $0.has(tag: .current_player) }
                        } else if _tag == .hero_entity {
                            if let bob = players.first(where: { x in x.has(tag: .bacon_dummy_player) }) {
                                entity = bob
                            }
                        }

                        if let entity = entity, let tmpEntity = tmpEntity {
                            entity.name = tmpEntity.name
                            tmpEntity.tags.forEach({ (gameTag, val) in
                                tagChangeHandler.tagChange(eventHandler: eventHandler,
                                    tag: gameTag, id: entity.id,
                                    value: val)
                            })
                            eventHandler.tmpEntities.remove(tmpEntity)
                            tagChangeHandler.tagChange(eventHandler: eventHandler,
                                                       rawTag: tag,
                                                       id: entity.id,
                                                       rawValue: value)
                        }

                        if let tmpEntity = tmpEntity, eventHandler.tmpEntities.contains(tmpEntity) {
                            tmpEntity[_tag] = tagValue
                            let player: Player? = eventHandler.player.name == tmpEntity.name
                                ? eventHandler.player
                                : (eventHandler.opponent.name == tmpEntity.name ? eventHandler.opponent : nil)

                            if let _player = player,
                                let playerEntity = eventHandler.entities.values
                                    .first(where: { $0[.player_id] == _player.id }) {
                                playerEntity.name = tmpEntity.name
                                tmpEntity.tags.forEach({ gameTag, val in
                                    tagChangeHandler.tagChange(eventHandler: eventHandler,
                                                               tag: gameTag,
                                                               id: playerEntity.id,
                                                               value: val)
                                })
                                eventHandler.tmpEntities.remove(tmpEntity)
                            }
                        }
                    }
                }
            }
        } else if CreationRegex.match(logLine.line) {
            let matches = CreationRegex.matches(logLine.line)
            guard let id = Int(matches[0].value) else {
                logger.error("Failed to convert id to integer: Log line was $(logLine.line)")
                return
            }
            guard let zone = Zone(rawString: matches[1].value) else { return }
            var guessedCardId = false
            var guessedLocation = DeckLocation.unknown
            var cardId: String? = ensureValidCardID(cardId: matches[2].value)
            var copyOfCardId: String?
            var entityInfo: EntityInfo?

            if eventHandler.entities[id] == nil {
                if cardId.isBlank && zone != .setaside {
                    if let blockId = currentBlock?.id,
                       let known = eventHandler.knownCardIds[blockId]?.first {
                        cardId = known.0
                        copyOfCardId = known.2
                        entityInfo = known.3
                        if !cardId.isBlank {
                            guessedLocation = known.1
                            logger.verbose("Found data for entity=\(id): CardId=\(cardId ?? ""), location=\(guessedLocation)")
                            guessedCardId = true
                        }
                        if eventHandler.knownCardIds[blockId]?.count ?? 0 > 0 {
                            eventHandler.knownCardIds[blockId]?.removeFirst()
                        } else {
                            Influx.sendSingleEvent(eventName: "PowerGameStateParser_knownCardIds_failed",
                                                   withProperties: ["blockId": "\(blockId)",
                                                                    "known": "\(known)",
                                                                    "logLine": logLine.line ])
                        }
                    } else if currentBlock?.cardId == CardIds.NonCollectible.Neutral.MarintheManager_TolinsGobletToken || currentBlock?.cardId == CardIds.NonCollectible.Neutral.TolinsGobletHeroic {
                        cardId = ""
                        let lastCardDrawnId = eventHandler.opponent.hand.sorted(by: { $0.zonePosition > $1.zonePosition }).first?.id ?? -1
                        let lastCardDrawnEntity = eventHandler.entities[lastCardDrawnId]
                        copyOfCardId = lastCardDrawnEntity?.info.copyOfCardId ?? "\(lastCardDrawnId)"
                    }
                }

                let entity = Entity(id: id)
                entity.cardId = cardId ?? ""
                if let entityInfo {
                    entity.info.forged = entityInfo.forged
                    entity.info.costReduction = entityInfo.costReduction
                    entity.info.extraInfo = entityInfo.extraInfo
                    entity.info.storedCardIds = entityInfo.storedCardIds
                }
                if guessedCardId {
                    entity.info.guessedCardState = GuessedCardState.guessed
                }
                if guessedLocation != .unknown {
                    eventHandler.dredgeCounter += 1
                    let newIndex = eventHandler.dredgeCounter
                    let sign = guessedLocation == .top ? 1 : -1
                    entity.info.deckIndex = sign * newIndex
                }
                if let cid = cardId {
                    entity.cardId = cid
                }
                entity.info.copyOfCardId = copyOfCardId
                eventHandler.entities[id] = entity
                
                if let currentBlock, zone == .deck {
                    currentBlock.entitiesCreatedInDeck.append((entity: entity, ids: Set<Int>()))
                }
                
                if let currentBlock = currentBlock, entity.cardId.uppercased().contains("HERO") {
                    currentBlock.hasFullEntityHeroPackets = true
                }
            }

            set(currentEntity: id)
            if eventHandler.determinedPlayers() {
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
            }
            eventHandler.currentEntityHasCardId = !cardId.isBlank
            eventHandler.currentEntityZone = zone
            
            // For tourists, a different entity of the Tourist card is created by the TouristEnchantment, and that entity is REMOVEDFROMGAME.
            // we can predict, then, that there is a real entity of that cardId on the opponents deck.
            if zone == Zone.removedfromgame, let currentBlock, let cardId {
                if let actionStartingEntity = eventHandler.entities[currentBlock.sourceEntityId] {
                    if actionStartingEntity.cardId == CardIds.NonCollectible.Neutral.TouristVfxEnchantmentEnchantment && actionStartingEntity.isControlled(by: eventHandler.opponent.id) && eventHandler.opponent.revealedCards.all({ c in c.id != cardId }) {
                        eventHandler.opponent.predictUniqueCardInDeck(cardId: cardId, isCreated: false)
                        AppDelegate.instance().coreManager.game.updateTrackers()
                    }
                }

            }
            return
        } else if UpdatingEntityRegex.match(logLine.line) {
            let matches = UpdatingEntityRegex.matches(logLine.line)
            let type = matches[0].value
            let rawEntity = matches[1].value
            let cardId = ensureValidCardID(cardId: matches[2].value)
            var entityId: Int?

            if rawEntity.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity: rawEntity) {
                let entity = tagChangeHandler.parseEntity(entity: rawEntity)
                entityId = entity.id
            } else if let _entityId = Int(rawEntity) {
                entityId = _entityId
            }

            if let entityId = entityId {
                if eventHandler.entities[entityId] == nil {
                    let entity = Entity(id: entityId)
                    eventHandler.entities[entityId] = entity
                }
                let entity = eventHandler.entities[entityId]!
                let oldCardId = entity.cardId
                if entity.cardId.isBlank ||
                    // placeholders and Fantastic Treasure (Marin's hero power)
                    entity.has(tag: .bacon_is_magic_item_discover) ||
                    // Souvenir Stand
                    entity.has(tag: .bacon_trinket) ||
                    // Heroes during Battlegrounds reroll
                    entity.has(tag: .bacon_hero_can_be_drafted) ||
                    entity.has(tag: .bacon_skin) {
                    entity.cardId = cardId
                }
                entity.info.latestCardId = cardId
                if type == "SHOW_ENTITY" {
                    if entity.info.guessedCardState != GuessedCardState.none {
                        entity.info.guessedCardState = GuessedCardState.revealed
                    }
                    if (AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.hideShowEntities ?? false && !(entity.info.revealedOnHistory) && !(entity.has(tag: .displayed_creator))) || entity.cardId == CardIds.NonCollectible.Rogue.GaronaHalforcen_KingLlaneToken {
                        entity.info.hidden = true
                    } else {
                        entity.info.hidden = false
                    }
                    if entity.info.deckIndex < 0, let currentBlock = currentBlock, currentBlock.sourceEntityId != 0 {
                        if let source = eventHandler.entities[currentBlock.sourceEntityId], source.hasDredge {
                            eventHandler.dredgeCounter += 1
                            let newIndex = eventHandler.dredgeCounter
                            entity.info.deckIndex = newIndex
                            logger.info("Dredge Top: \(entity.description)")
                            eventHandler.handlePlayerDredge()
                        }
                    }
                    
                    if entity.cardId == CardIds.NonCollectible.Neutral.PhotographerFizzle_FizzlesSnapshotToken
                       && currentBlock?.cardId == CardIds.Collectible.Neutral.PhotographerFizzle {
                        if entity.isControlled(by: eventHandler.player.id) {
                            entity.info.storedCardIds.append(contentsOf: eventHandler.player.hand.sorted(by: { $0.zonePosition < $1.zonePosition }).compactMap { e in e.card.id })
                        } else if entity.isControlled(by: eventHandler.opponent.id) {
                            entity.info.storedCardIds.append(contentsOf: eventHandler.opponent.hand.sorted(by: { $0.zonePosition < $1.zonePosition }).compactMap { e in
                                if e.hasCardId && !e.info.hidden {
                                    return e.card.id
                                }
                                return String(e.id)
                            })
                            entity.info.guessedCardState = .guessed
                        }
                    }
                    
                    if currentBlock?.cardId == CardIds.Collectible.Shaman.Triangulate && !(entity.cardId.isBlank) {
                        if entity.isControlled(by: eventHandler.player.id) {
                            addKnownCardId(eventHandler: eventHandler, cardId: entity.cardId, count: 3, info: entity.info)
                        } else if entity.isControlled(by: eventHandler.opponent.id) {
                            eventHandler.triangulatePlayed = true
                        }
                    }
                    
                    if currentBlock?.cardId == CardIds.Collectible.Priest.Repackage && entity.cardId == CardIds.NonCollectible.Priest.Repackage_RepackagedBoxToken {
                        entity.info.storedCardIds.append(contentsOf: eventHandler.minionsInPlay.array())
                        
                        if entity.isControlled(by: eventHandler.opponent.id) {
                            entity.info.guessedCardState = .guessed
                        }
                    }
                }

                let fizzleSnapshots = eventHandler.opponent.playerEntities.filter { e in e.cardId == CardIds.NonCollectible.Neutral.PhotographerFizzle_FizzlesSnapshotToken }

                for fizzle in fizzleSnapshots where fizzle.info.storedCardIds.contains(String(entity.id)) {
                    if let index = fizzle.info.storedCardIds.firstIndex(of: String(entity.id)) {
                        fizzle.info.storedCardIds[index] = entity.card.id
                    }
                }

                handleCopiedCard(eventHandler: eventHandler, entity: entity)

                if type == "CHANGE_ENTITY" {
                    let entity = eventHandler.entities[entityId]!
                    if entity.info.originalEntityWasCreated == nil {
                        entity.info.originalEntityWasCreated = entity.info.created
                    }
                    if entity[.transformed_from_card] == 46706 {
                        eventHandler.chameleosReveal = (entityId, cardId)
                    }
                    // Battlegrounds hero reroll
                    if entity.isHero && entity.isControlled(by: eventHandler.player.id) && (eventHandler.gameEntity?[.step] ?? Step.invalid.rawValue) <= Step.begin_mulligan.rawValue {
                        eventHandler.handleBattlegroundsHeroReroll(entity: entity, oldCardId: oldCardId)
                    }
                }
                
                set(currentEntity: entityId)
                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
            }

            if eventHandler.joustReveals > 0 {
                if let currentEntity = eventHandler.entities[entityId!] {
                    if currentEntity.isControlled(by: eventHandler.opponent.id) {
                        eventHandler.opponentJoust(entity: currentEntity, cardId: cardId,
                                           turn: eventHandler.turnNumber())
                    } else if currentEntity.isControlled(by: eventHandler.player.id) {
                        eventHandler.playerJoust(entity: currentEntity, cardId: cardId,
                                         turn: eventHandler.turnNumber())
                    }
                }
            }
            return
        } else if CreationTagRegex.match(logLine.line)
            && !logLine.line.contains("HIDE_ENTITY") {
            let matches = CreationTagRegex.matches(logLine.line)
            let tag = matches[0].value
            let value = matches[1].value
            tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag, id: currentEntityId,
                                       rawValue: value, isCreationTag: true)
            creationTag = true
            if eventHandler.triangulatePlayed, let tag = GameTag(rawString: tag) {
                if tag == GameTag.linked_entity {
                    addKnownCardId(eventHandler: eventHandler, cardId: "", count: 3, copyOfCardId: value)
                    eventHandler.triangulatePlayed = false
                } else if tag == GameTag.casts_when_drawn && Int(value) == 1, let gameEntity =
                            eventHandler.entities[currentEntityId] {
                    let cardId = gameEntity.cardId
                    if !cardId.isEmpty {
                        removeKnownCardId(eventHandler: eventHandler, count: 3)
                        addKnownCardId(eventHandler: eventHandler, cardId: cardId, count: 3, info: gameEntity.info)
                    }
                    eventHandler.triangulatePlayed = false
                }
            }
        } else if logLine.line.contains("HIDE_ENTITY") {
            let match = HideEntityRegex.matches(logLine.line)
            if match.count > 0 {
                let id = Int(match[0].value) ?? -1
                if let entity = eventHandler.entities[id] {
                    if entity.info.guessedCardState == GuessedCardState.revealed {
                        entity.info.guessedCardState = GuessedCardState.guessed
                    }
                    if currentBlock?.cardId == CardIds.Collectible.Neutral.KingTogwaggle
                        || currentBlock?.cardId == CardIds.NonCollectible.Neutral.KingTogwaggle_KingsRansomToken {
                        entity.info.hidden = true
                    }
                    // Plagues are flagged here due to the following info leak:
                    // 1. Plagues are created in the opponent's deck
                    // 2. SHOW_ENTITY followed by HIDE_ENTITY
                    // 3. Later on the card may enter hand in a way where it doesn't trigger (e.g. due to Sir Finley)
                    // 4. When the hand updates, we exclude the card because the entity is now in the hand (this is the info leak).
                    // By setting a GuessedCardState here we prevent the card from appearing as drawn.
                    if entity.cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_FrostPlagueToken || entity.cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_BloodPlagueToken || entity.cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_UnholyPlagueToken {
                        entity.info.guessedCardState = GuessedCardState.guessed
                    }
                    if let blockId = currentBlock?.id, let known = eventHandler.knownCardIds[blockId]?.first {
                        if entity.cardId == known.0 && known.1 != .unknown {
                            logger.info("Setting DeckLocation=\(known.1) for \(entity.description)")
                            eventHandler.dredgeCounter += 1
                            let newIndex = eventHandler.dredgeCounter
                            let sign = known.1 == .top ? 1 : -1
                            entity.info.deckIndex = sign * newIndex
                        }
                    }
                 }
            }
        } else if ShuffleRegex.match(logLine.line) {
            let match = ShuffleRegex.matches(logLine.line)
            let playerId = Int(match[0].value)
            if playerId == eventHandler.player.id {
                eventHandler.player.shuffleDeck()
                eventHandler.handlePlayerDredge()
            }
        } else if logLine.line.contains("META_DATA - Meta=OVERRIDE_HISTORY") {
            AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.hideShowEntities = true
        } else if logLine.line.contains("META_DATA - Meta=HISTORY_TARGET") {
            gameStateIsInsideMetaDataHistoryTarget = true
            isInsideMetaDataHistoryTarget = true
        } else if MetaInfoRegex.match(logLine.line) {
            if gameStateIsInsideMetaDataHistoryTarget {
                let match = MetaInfoRegex.matches(logLine.line)
                if let entityId = Int(match.count > 1 ? match[1].value : match[0].value), let entity = eventHandler.entities[entityId] {
                    entity.info.hidden = false
                }
                isInsideMetaDataHistoryTarget = true
            }
        } else if SubSpellStartRegex.match(logLine.line) {
            let match = SubSpellStartRegex.matches(logLine.line)
            if let sourceId = Int(match[1].value) {
                if let entity = eventHandler.entities[sourceId] {
                    if entity.cardId == CardIds.Collectible.Druid.BottomlessToyChest {
                        let lastCardDrawnId = eventHandler.opponent.hand.sorted(by: { $0.zonePosition > $1.zonePosition}).first?.id ?? -1
                        let lastCardDrawnEntity = eventHandler.entities[lastCardDrawnId]
                        let copyOfCardId = lastCardDrawnEntity?.info.copyOfCardId ?? "\(lastCardDrawnId)"
                        addKnownCardId(eventHandler: eventHandler, cardId: "", copyOfCardId: copyOfCardId)
                    }
                }
            } else {
                logger.info("Invalid source id: \(match[1].value)")
            }
        }
        gameStateIsInsideMetaDataHistoryTarget = isInsideMetaDataHistoryTarget
        if logLine.line.contains("End Spectator") && eventHandler.isInMenu {
            eventHandler.gameEnded = true
            eventHandler.gameEnd()
        } else if logLine.line.contains("BLOCK_START") {
            let matches = BlockStartRegex.matches(logLine.line)
            var blockType: String?
            if matches.count > 0 {
                blockType = matches[0].value
            }
            var cardId: String?
            if matches.count > 3 {
                cardId = matches[3].value
            }
            let target = getTargetCardId(matches: matches)
            var correspondPlayer: Int?
            if matches.count > 4 {
                if let v = Int(matches[4].value) {
                    correspondPlayer = v
                }
            }
            var triggerKeyword: String?
            if matches.count > 5 {
                triggerKeyword = matches[5].value
            }
            
            blockStart(type: blockType, cardId: cardId, target: target, trigger: triggerKeyword)

            if matches.count > 0 && (blockType == "TRIGGER" || blockType == "POWER") {
                let player = eventHandler.entities.values
                    .first { $0.has(tag: .player_id) && $0[.player_id] == eventHandler.player.id }
                let opponent = eventHandler.entities.values
                    .first { $0.has(tag: .player_id) && $0[.player_id] == eventHandler.opponent.id }

                guard let actionStartingEntityId = Int(matches[1].value) else {
                    Influx.sendSingleEvent(eventName: "PowerGameStateParser_invalid_action_entity_id", withProperties: ["line": logLine.line])
                    return
                }
                currentBlock?.sourceEntityId = actionStartingEntityId

                var actionStartingCardId: String? = matches[3].value
                var actionStartingEntity: Entity?

                if !actionStartingCardId.isBlank {
                    actionStartingEntity = eventHandler.entities[actionStartingEntityId]
                    if let actionEntity = actionStartingEntity {
                        actionStartingCardId = actionEntity.cardId
                    }
                }

                if actionStartingCardId.isBlank {
                    return
                }
                
                if actionStartingCardId == CardIds.Collectible.Shaman.Shudderwock {
                    let effectCardId = matches.count > 5 ? matches[5] : nil
                    if let cardId = effectCardId {
                        actionStartingCardId = cardId.value
                    }
                }
                
                if actionStartingCardId == CardIds.NonCollectible.Rogue.ValeeratheHollow_ShadowReflectionToken {
                    actionStartingCardId = cardId
                }
                
                if blockType == "TRIGGER" {
                    if let actionStartingCardId = actionStartingCardId {
                        
                        switch actionStartingCardId {
                        case CardIds.Collectible.Neutral.SphereOfSapience:
                            // These are tricky to implement correctly, so
                            // until the are, we will just reset the state
                            // known about the top/bottom of the deck
                            if actionStartingEntity?.isControlled(by: player?.id ?? 0) ?? false {
                                eventHandler.handlePlayerUnknownCardAddedToDeck()
                            }
                        case CardIds.Collectible.Rogue.TradePrinceGallywix:
                            if let entity = eventHandler.entities[eventHandler.lastCardPlayed] {
                                let cardId = entity.cardId
                                addKnownCardId(eventHandler: eventHandler, cardId: cardId)
                            }
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .TradePrinceGallywix_GallywixsCoinToken)
                        case CardIds.Collectible.Shaman.WhiteEyes:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Shaman
                                            .WhiteEyes_TheStormGuardianToken)
                        case CardIds.Collectible.Hunter.RaptorHatchling:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Hunter
                                            .RaptorHatchling_RaptorPatriarchToken)
                        case CardIds.Collectible.Warrior.DirehornHatchling:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warrior
                                            .DirehornHatchling_DirehornMatriarchToken)
                        case CardIds.Collectible.Mage.FrozenClone, CardIds.Collectible.Mage.FrozenCloneCore:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target,
                                           count: 2)
                        case CardIds.Collectible.Shaman.Moorabi, CardIds.Collectible.Shaman.MoorabiCorePlaceholder, CardIds.Collectible.Rogue.SonyaShadowdancer:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target)
                        case CardIds.Collectible.Neutral.HoardingDragon:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCoinBasic, count: 2)
                        case CardIds.Collectible.Priest.GildedGargoyle:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Druid.AstralTiger:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Druid.AstralTiger)
                        case CardIds.Collectible.Rogue.Kingsbane:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Rogue.Kingsbane)
                        case CardIds.Collectible.Neutral.WeaselTunneler:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Neutral.WeaselTunneler)
                        case CardIds.Collectible.Neutral.SparkDrill:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SparkDrill_SparkToken, count: 2)
                        case CardIds.NonCollectible.Neutral.HakkartheSoulflayer_CorruptedBloodToken:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.HakkartheSoulflayer_CorruptedBloodToken, count: 2)
                        //TODO: Gral, the Shark?
                        case CardIds.Collectible.Paladin.ImmortalPrelate:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Paladin.ImmortalPrelate)
                        case CardIds.Collectible.Neutral.Explodineer, CardIds.Collectible.Warrior.Wrenchcalibur:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken)
                        case CardIds.Collectible.Priest.SpiritOfTheDead:
                            if correspondPlayer == eventHandler.player.id, let cardId = eventHandler.player.lastDiedMinionCard?.cardId {
                                addKnownCardId(eventHandler: eventHandler, cardId: cardId)
                            } else if correspondPlayer == eventHandler.opponent.id, let cardId = eventHandler.opponent.lastDiedMinionCard?.cardId {
                                addKnownCardId(eventHandler: eventHandler, cardId: cardId)
                            }
                        case CardIds.Collectible.Druid.SecureTheDeck:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.Claw, count: 3)
                        case CardIds.Collectible.Rogue.Waxadred:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.Waxadred_WaxadredsCandleToken)
                        case CardIds.Collectible.Neutral.BadLuckAlbatross:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.BadLuckAlbatross_AlbatrossToken, count: 2)
                        case CardIds.Collectible.Priest.ReliquaryOfSouls:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Priest.ReliquaryofSouls_ReliquaryPrimeToken)
                        case CardIds.Collectible.Mage.AstromancerSolarian:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.AstromancerSolarian_SolarianPrimeToken)
                        case CardIds.Collectible.Warlock.KanrethadEbonlocke:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.KanrethadEbonlocke_KanrethadPrimeToken)
                        case CardIds.Collectible.Paladin.MurgurMurgurgle:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Paladin.MurgurMurgurgle_MurgurglePrimeToken)
                        case CardIds.Collectible.Rogue.Akama:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.Akama_AkamaPrimeToken)
                        case CardIds.Collectible.Druid.ArchsporeMsshifn:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Druid.ArchsporeMsshifn_MsshifnPrimeToken)
                        case CardIds.Collectible.Shaman.LadyVashj:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Shaman.LadyVashj_VashjPrimeToken)
                        case CardIds.Collectible.Hunter.ZixorApexPredator:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Hunter.ZixorApexPredator_ZixorPrimeToken)
                        case CardIds.Collectible.Warrior.KargathBladefist:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warrior.KargathBladefist_KargathPrimeToken)
                        case CardIds.Collectible.Neutral.SneakyDelinquent:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.SneakyDelinquent_SpectralDelinquentToken)
                        case CardIds.Collectible.Neutral.FishyFlyer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.FishyFlyer_SpectralFlyerToken)
                        case CardIds.Collectible.Neutral.SmugSenior:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.SmugSenior_SpectralSeniorToken)
                        case CardIds.Collectible.Rogue.Plagiarize, CardIds.Collectible.Rogue.PlagiarizeCore:
                            if let actionEntity = actionStartingEntity {
                                if let player = actionEntity.isControlled(by: eventHandler.player.id) ? eventHandler.opponent : eventHandler.player {
                                    for card in player.cardsPlayedThisTurn {
                                        addKnownCardId(eventHandler: eventHandler, cardId: card.cardId)
                                    }
                                }
                            }
                        case CardIds.Collectible.Rogue.EfficientOctoBot:
                            if let actionEntity = actionStartingEntity, actionEntity.isControlled(by: eventHandler.opponent.id) {
                                eventHandler.handleOpponentHandCostReduction(value: 1)
                            }
                        case CardIds.Collectible.Neutral.KeymasterAlabaster:
                            // The player controlled side of this is handled by TagChangeActions.OnCardCopy
                            if let actionEntity = actionStartingEntity, actionEntity.isControlled(by: eventHandler.opponent.id) && eventHandler.player.lastDrawnCardId != nil {
                                addKnownCardId(eventHandler: eventHandler, cardId: eventHandler.player.lastDrawnCardId)
                            }
                        case CardIds.Collectible.Neutral.EducatedElekk:
                            if let actionEntity = actionStartingEntity {
                                if actionEntity.isInGraveyard {
                                    for card in actionEntity.info.storedCardIds {
                                        addKnownCardId(eventHandler: eventHandler, cardId: card)
                                    }
                                } else if let lastPlayedEntity = eventHandler.entities[eventHandler.lastCardPlayed] {
                                        actionEntity.info.storedCardIds.append(lastPlayedEntity.cardId)
                                }
                            }
                        case CardIds.Collectible.Shaman.DiligentNotetaker:
                            if let lastPlayedEntity1 = eventHandler.entities[eventHandler.lastCardPlayed] {
                                addKnownCardId(eventHandler: eventHandler, cardId: lastPlayedEntity1.cardId)
                            }
                        case CardIds.Collectible.Neutral.CthunTheShattered:
                            // The pieces are created in random order. So we can not assign predicted ids to entities the way we usually do.
                            if let actionStartingEntity = actionStartingEntity {
                                if let player = actionStartingEntity.isControlled(by: eventHandler.player.id) ? eventHandler.player : eventHandler.opponent {
                                    player.predictUniqueCardInDeck(cardId: CardIds.NonCollectible.Neutral.CThuntheShattered_EyeOfCthunToken, isCreated: true)
                                    player.predictUniqueCardInDeck(cardId: CardIds.NonCollectible.Neutral.CThuntheShattered_BodyOfCthunToken, isCreated: true)
                                    player.predictUniqueCardInDeck(cardId: CardIds.NonCollectible.Neutral.CThuntheShattered_MawOfCthunToken, isCreated: true)
                                    player.predictUniqueCardInDeck(cardId: CardIds.NonCollectible.Neutral.CThuntheShattered_HeartOfCthunToken, isCreated: true)
                                }
                            }
                        case CardIds.Collectible.Priest.MidaPureLight:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Priest.MidaPureLight_FragmentOfMidaToken)
                        case CardIds.Collectible.Warlock.CurseOfAgony:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.CurseofAgony_AgonyToken, count: 3)
                        case CardIds.Collectible.Neutral.AzsharanSentinel:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.AzsharanSentinel_SunkenSentinelToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Warrior.AzsharanTrident:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warrior.AzsharanTrident_SunkenTridentToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Hunter.AzsharanSaber:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Hunter.AzsharanSaber_SunkenSaberToken, count: 1, location: .bottom)
                        case CardIds.Collectible.DemonHunter.AzsharanDefector:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.DemonHunter.AzsharanDefector_SunkenDefectorToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Druid.Bottomfeeder:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.Bottomfeeder, count: 1, location: .bottom)
                        case CardIds.Collectible.Shaman.PiranhaPoacher:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.PiranhaSwarmer)
                        case CardIds.Collectible.Paladin.SinfulSousChef:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Paladin.SilverHandRecruitLegacyToken, count: 2)
                        case CardIds.Collectible.Neutral.RivendareWarrider:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.RivendareWarrider_BlaumeauxFamineriderToken)
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.RivendareWarrider_KorthazzDeathriderToken)
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.RivendareWarrider_ZeliekConquestriderToken)
                        case CardIds.NonCollectible.Deathknight.Helya_PlightOfTheDeadEnchantment:
                            if eventHandler.lastPlagueDrawn.count > 0, let lastPlagueDrawn = eventHandler.lastPlagueDrawn.pop() {
                                addKnownCardId(eventHandler: eventHandler, cardId: lastPlagueDrawn)
                            }
                        case CardIds.Collectible.Rogue.TombPillager, CardIds.Collectible.Rogue.TombPillagerPLACEHOLDER_202204, CardIds.Collectible.Rogue.TombPillagerWONDERS:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic, count: 2)
                        case CardIds.Collectible.Rogue.LoanShark:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic, count: 2)
                        case CardIds.Collectible.Rogue.CoppertailSnoop:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Warlock.DisposalAssistant:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TramMechanic_BarrelOfSludgeToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Warlock.SludgeOnWheels:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TramMechanic_BarrelOfSludgeToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Neutral.AdaptiveAmalgam:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.AdaptiveAmalgam, count: 1)
                        case CardIds.Collectible.DemonHunter.PatchesThePilot:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.DemonHunter.PatchesthePilot_ParachuteToken, count: 6)
                        case CardIds.Collectible.Neutral.WhelpWrangler:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TaketotheSkies_HappyWhelpToken)
                        case CardIds.Collectible.Hunter.RangerGilly:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Hunter.RangerGilly_IslandCrocoliskToken)
                        case CardIds.Collectible.Neutral.MiracleSalesman:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.MiracleSalesman_SnakeOilToken)
                        case CardIds.Collectible.Hunter.Starshooter:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Hunter.ArcaneShotCore)
                        case CardIds.Collectible.Priest.PuppetTheatre:
                            if let target {
                                addKnownCardId(eventHandler: eventHandler, cardId: target)
                            }
                        case CardIds.Collectible.Paladin.LifesavingAura:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Paladin.Grillmaster_SunscreenToken)
                        case CardIds.Collectible.Rogue.MetalDetector:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.NonCollectible.Rogue.GaronaHalforcen_KingLlaneToken:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.GaronaHalforcen_KingLlaneToken)
                        case CardIds.NonCollectible.Paladin.LibramofDivinity_LibramOfDivinityEnchantment:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Paladin.LibramOfDivinity)
                        case CardIds.NonCollectible.Neutral.Corpsicle_CorpsicleEnchantment:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Deathknight.Corpsicle)
                        case CardIds.Collectible.Mage.CommanderSivara, CardIds.Collectible.Neutral.TidepoolPupil:
                            if let cardId = currentBlock?.parent?.cardId, Cards.by(cardId: cardId)?.type == .spell, let actionStartingEntity {
                                let maxCards = 3
                                if actionStartingEntity.info.storedCardIds.count < maxCards {
                                    actionStartingEntity.info.storedCardIds.append(cardId)
                                }
                            }
                        case CardIds.Collectible.Neutral.AugmentedElekk:
                            if let currentBlock, currentBlock.parent != nil {
                                if let index = currentBlock.parent?.entitiesCreatedInDeck.lastIndex(where: { x in !x.ids.contains(currentBlock.sourceEntityId)}) {
                                    let value = currentBlock.parent?.entitiesCreatedInDeck[index]
                                    if let entity = value?.entity, let ids = value?.ids {
                                        if !entity.cardId.isBlank {
                                            currentBlock.parent?.entitiesCreatedInDeck.remove(at: index)
                                            var ids = Set<Int>(ids)
                                            ids.insert(currentBlock.sourceEntityId)
                                            currentBlock.parent?.entitiesCreatedInDeck.insert((entity: entity, ids: ids), at: index)
                                        }
                                    }
                                }
                            }
                        case CardIds.Collectible.Neutral.Meadowstrider:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.Meadowstrider, count: 1, location: DeckLocation.bottom)
                        case CardIds.Collectible.Paladin.IdoOfTheThreshfleet:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Paladin.IdooftheThreshfleet_CallTheThreshfleetToken)
                        case CardIds.Collectible.Hunter.RangariScout:
                            // discover options often are copies of other entities
                            // when they are discovered, they are still not created on game.Entities
                            // here we check if they are a copy of other entity, if they are we use the original entity id
                            let chosenId = eventHandler.lastEntityChosenOnDiscover
                            let chosenEntity = eventHandler.entities[chosenId]
                            let isCopiedEntity = chosenEntity?[.copied_from_entity_id] ?? 0 > 0
                            eventHandler.lastEntityChosenOnDiscover = isCopiedEntity ? chosenEntity?[.copied_from_entity_id] ?? chosenId : chosenId

                            addKnownCardId(eventHandler: eventHandler, cardId: "", copyOfCardId: "\(eventHandler.lastEntityChosenOnDiscover)")
                        default: break
                        }
                    }
                    if triggerKeyword == "SECRET" {
                        if let actionStartingEntity {
                            if actionStartingEntity.isControlled(by: eventHandler.player.id) {
                                eventHandler.playerSecretTrigger(entity: actionStartingEntity, cardId: cardId, turn: eventHandler.turnNumber(), otherId: actionStartingEntityId)
                            } else {
                                eventHandler.opponentSecretTrigger(entity: actionStartingEntity, cardId: cardId, turn: eventHandler.turnNumber(), otherId: actionStartingEntityId)
                            }
                        }
                    }
                } else { // type == "POWER"
                    if let actionStartingCardId = actionStartingCardId {
                        switch actionStartingCardId {
                        case CardIds.Collectible.DemonHunter.SightlessWatcherCore,
                            CardIds.Collectible.DemonHunter.SightlessWatcherLegacy,
                            CardIds.Collectible.Neutral.AmbassadorFaelin:
                            // These are tricky to implement correctly, so
                            // until the are, we will just reset the state
                            // known about the top/bottom of the deck
                            if actionStartingEntity?.isControlled(by: player?.id ?? 0) ?? false {
                                eventHandler.handlePlayerUnknownCardAddedToDeck()
                            }
                        case CardIds.Collectible.Rogue.GangUp,
                             CardIds.Collectible.Hunter.DireFrenzy,
                             CardIds.Collectible.Rogue.LabRecruiter:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target,
                                           count: 3)
                        case CardIds.Collectible.Rogue.BeneathTheGrounds:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Rogue
                                            .BeneaththeGrounds_NerubianAmbushToken,
                                           count: 3)
                        case CardIds.Collectible.Warrior.IronJuggernaut:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warrior
                                            .IronJuggernaut_BurrowingMineToken)
                        case CardIds.Collectible.Druid.Recycle,
                             CardIds.Collectible.Mage.ManicSoulcaster,
                             CardIds.Collectible.Neutral.ZolaTheGorgon,
                             CardIds.Collectible.Neutral.ZolaTheGorgon1810,
                             CardIds.Collectible.Druid.Splintergraft,
                             //CardIds.Collectible.Priest.HolyWater: -- TODO
                             CardIds.Collectible.Neutral.BalefulBanker,
                             CardIds.Collectible.Neutral.DollmasterDorian,
                             CardIds.Collectible.Priest.Seance,
                             CardIds.Collectible.Druid.MarkOfTheSpikeshell,
                             CardIds.Collectible.Neutral.DragonBreeder,
                             CardIds.Collectible.Shaman.ColdStorage,
                             CardIds.Collectible.Priest.PowerChordSynchronize,
                             CardIds.Collectible.Rogue.Shadowcaster:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target)
                        case CardIds.Collectible.Mage.ForgottenTorch:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Mage
                                            .ForgottenTorch_RoaringTorchToken)
                        case CardIds.Collectible.Warlock.CurseOfRafaam:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warlock
                                            .CurseofRafaam_CursedToken)
                        case CardIds.Collectible.Neutral.AncientShade:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .AncientShade_AncientCurseToken)
                        case CardIds.Collectible.Priest.ExcavatedEvil:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Priest.ExcavatedEvil)
                        case CardIds.Collectible.Neutral.EliseStarseeker,
                             CardIds.Collectible.Neutral.EliseStarseeker1810:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .EliseStarseeker_MapToTheGoldenMonkeyToken)
                        case CardIds.NonCollectible.Neutral
                            .EliseStarseeker_MapToTheGoldenMonkeyToken:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .EliseStarseeker_GoldenMonkeyToken)
                        case CardIds.Collectible.Neutral.Doomcaller:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.Cthun)
                        case CardIds.Collectible.Druid.JadeIdol, CardIds.NonCollectible.Druid.JadeIdol_JadeStash:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Druid.JadeIdol,
                                           count: 3)
                        case CardIds.NonCollectible.Hunter.TheMarshQueen_QueenCarnassaToken:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Hunter
                                            .TheMarshQueen_CarnassasBroodToken,
                                           count: 20)
                        case CardIds.Collectible.Neutral.EliseTheTrailblazer:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .ElisetheTrailblazer_UngoroPackToken)
                        case CardIds.Collectible.Mage.GhastlyConjurer, CardIds.Collectible.Mage.GhastlyConjurerCorePlaceholder:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Mage.MirrorImage)
                        case CardIds.Collectible.Druid.ThorngrowthSentries:
                            addKnownCardId(eventHandler: eventHandler, cardId:
                                            CardIds.NonCollectible.Druid.ThorngrowthSentries_ThornguardTurtleToken,
                                           count: 2)
                        case CardIds.Collectible.Mage.DeckOfWonders:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Mage.DeckofWondersScrollOfWonderToken, count: 5)
                        case CardIds.Collectible.Neutral.TheDarkness:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheDarknessDarknessCandleToken, count: 3)
                        case CardIds.Collectible.Rogue.FaldoreiStrider, CardIds.Collectible.Rogue.FaldoreiStriderInvalid:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Rogue.FaldoreiStrider_SpiderAmbushEnchantment, count: 3)
                        case CardIds.Collectible.Neutral.KingTogwaggle:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.KingTogwaggle_KingsRansomToken)
                        case CardIds.NonCollectible.Neutral.TheCandle:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCandle)
                        case CardIds.NonCollectible.Neutral.CoinPouchGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SackOfCoinsGILNEAS)
                        case CardIds.NonCollectible.Neutral.SackOfCoinsGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.HeftySackOfCoinsGILNEAS)
                        case CardIds.NonCollectible.Neutral.CreepyCurioGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.HauntedCurioGILNEAS)
                        case CardIds.NonCollectible.Neutral.HauntedCurioGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.CursedCurioGILNEAS)
                        case CardIds.NonCollectible.Neutral.OldMilitiaHornGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.MilitiaHornGILNEAS)
                        case CardIds.NonCollectible.Neutral.MilitiaHornGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.VeteransMilitiaHornGILNEAS)
                        case CardIds.NonCollectible.Neutral.SurlyMobGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.AngryMobGILNEAS)
                        case CardIds.NonCollectible.Neutral.AngryMobGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.CrazedMobGILNEAS)
                        case CardIds.Collectible.Neutral.SparkEngine:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SparkDrill_SparkToken)
                        case CardIds.Collectible.Priest.ExtraArms:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Priest.ExtraArms_MoreArmsToken)
                        case CardIds.Collectible.Neutral.SeaforiumBomber,
                             CardIds.Collectible.Warrior.ClockworkGoblin:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken)
                        case CardIds.Collectible.Rogue.Wanted:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        //TODO: Hex Lord Malacrass
                        //TODO: Krag'wa, the Frog
                        case CardIds.Collectible.Hunter.HalazziTheLynx:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Hunter.Springpaw_LynxToken, count: 10)
                        case CardIds.Collectible.Neutral.BananaVendor:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.BananaBuffoon_BananasToken, count: 4)
                        case CardIds.Collectible.Neutral.BananaBuffoon:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.BananaBuffoon_BananasToken, count: 2)
                        case CardIds.Collectible.Neutral.BootyBayBookie:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Neutral.PortalKeeper, CardIds.Collectible.Neutral.PortalOverfiend:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.PortalKeeper_FelhoundPortalToken)
                        case CardIds.Collectible.Rogue.TogwagglesScheme:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target)
                        case CardIds.Collectible.Paladin.SandwaspQueen:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Paladin.SandwaspQueen_SandwaspToken,
                                           count: 2)
                        case CardIds.Collectible.Rogue.ShadowOfDeath:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Rogue.ShadowofDeath_ShadowToken,
                                           count: 3)
                        case CardIds.Collectible.Warlock.Impbalming:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warlock.Impbalming_WorthlessImpToken,
                                           count: 3)
                        case CardIds.Collectible.Druid.YseraUnleashed:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Druid.YseraUnleashed_DreamPortalToken, count: 7)
                        case CardIds.Collectible.Rogue.BloodsailFlybooter:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.BloodsailFlybooter_SkyPirateToken, count: 2)
                        case CardIds.Collectible.Rogue.UmbralSkulker:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic, count: 3)
                        case CardIds.Collectible.Neutral.Sathrovarr:
                            addKnownCardId(eventHandler: eventHandler, cardId: target, count: 3)
                        case CardIds.Collectible.Warlock.SchoolSpirits, CardIds.Collectible.Warlock.SoulShear, CardIds.Collectible.Warlock.SpiritJailer, CardIds.Collectible.DemonHunter.Marrowslicer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.SchoolSpirits_SoulFragmentToken, count: 2)
                        case CardIds.Collectible.Mage.ConfectionCyclone:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.ConfectionCyclone_SugarElementalToken, count: 2)
                        case CardIds.Collectible.Druid.KiriChosenOfElune:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.LunarEclipse)
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.SolarEclipse)
                        case CardIds.Collectible.Druid.KiriChosenOfEluneCore:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.LunarEclipseCore)
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.SolarEclipseCore)
                        case CardIds.NonCollectible.Neutral.CThuntheShattered_EyeOfCthunToken,
                             CardIds.NonCollectible.Neutral.CThuntheShattered_HeartOfCthunToken,
                             CardIds.NonCollectible.Neutral.CThuntheShattered_BodyOfCthunToken,
                             CardIds.NonCollectible.Neutral.CThuntheShattered_MawOfCthunToken:
                            // A new copy of C'Thun is created in the last of these POWER blocks.
                            // This currently leads to a duplicate copy of C'Thun showing up in the
                            // opponents deck list, but it will have to do for now.
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.CthunTheShattered)
                        case CardIds.Collectible.Hunter.SunscaleRaptor:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Hunter.SunscaleRaptor)
                        case CardIds.Collectible.Neutral.Mankrik:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.Mankrik_OlgraMankriksWifeToken)
                        case CardIds.Collectible.Neutral.ShadowHunterVoljin:
                            addKnownCardId(eventHandler: eventHandler, cardId: target)
                        case CardIds.Collectible.Paladin.AldorAttendant:
                            if let ent = actionStartingEntity {
                                if ent.isControlled(by: eventHandler.player.id) {
                                    eventHandler.handlePlayerLibramReduction(change: 1)
                                } else {
                                    eventHandler.handleOpponentLibramReduction(change: 1)
                                }
                            }
                        case CardIds.Collectible.Paladin.AldorTruthseeker:
                            if let ent = actionStartingEntity {
                                if ent.isControlled(by: eventHandler.player.id) {
                                    eventHandler.handlePlayerLibramReduction(change: 2)
                                } else {
                                    eventHandler.handleOpponentLibramReduction(change: 2)
                                }
                            }
                        case CardIds.Collectible.Druid.VibrantSquirrel:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Druid.VibrantSquirrel_AcornToken, count: 4)
                        case CardIds.Collectible.Mage.FirstFlame:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage
                                            .FirstFlame_SecondFlameToken)
                        case CardIds.Collectible.Rogue.Garrote:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.Garrote_BleedToken, count: 3)
                        case CardIds.Collectible.Neutral.MailboxDancer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Neutral.NorthshireFarmer:
                            addKnownCardId(eventHandler: eventHandler, cardId: target, count: 3)
                        case CardIds.Collectible.Rogue.LoanShark:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Warlock.SeedsOfDestruction:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.DreadlichTamsin_FelRiftToken, count: 3)
                        case CardIds.Collectible.Mage.BuildASnowman:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.BuildaSnowman_BuildASnowbruteToken)
                        case CardIds.Collectible.Warrior.Scrapsmith:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warrior.Scrapsmith_ScrappyGruntToken)
                        case CardIds.Collectible.Neutral.RamCommander:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.RamCommander_BattleRamToken)
                        case CardIds.Collectible.Warlock.DraggedBelow,
                            CardIds.Collectible.Warlock.SirakessCultist:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.SirakessCultist_AbyssalCurseToken, count: 1)
                        case CardIds.Collectible.Neutral.SchoolTeacher:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.SchoolTeacher_NagalingToken, count: 1)
                        case CardIds.Collectible.Warlock.AzsharanScavenger:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.AzsharanScavenger_SunkenScavengerToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Priest.AzsharanRitual:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Priest.AzsharanRitual_SunkenRitualToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Shaman.AzsharanScroll:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Shaman.AzsharanScroll_SunkenScrollToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Paladin.AzsharanMooncatcher:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Paladin.AzsharanMooncatcher_SunkenMooncatcherToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Rogue.AzsharanVessel:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.AzsharanVessel_SunkenVesselToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Shaman.Schooling:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.PiranhaSwarmer, count: 3) // is this the correct token? There are 4 different ones
                        case CardIds.Collectible.Druid.AzsharanGardens:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Druid.AzsharanGardens_SunkenGardensToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Mage.AzsharanSweeper:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.AzsharanSweeper_SunkenSweeperToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Rogue.BootstrapSunkeneer:
                            if target != nil {
                                addKnownCardId(eventHandler: eventHandler, cardId: target, count: 1, location: .bottom)
                            }
                        case CardIds.Collectible.Mage.FrozenTouch:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.FrozenTouch_FrozenTouchToken)
                        case CardIds.Collectible.Mage.ArcaneWyrm:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Mage.ArcaneBolt)
                        case CardIds.Collectible.Priest.SisterSvalna:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Priest.SisterSvalna_VisionOfDarknessToken)
                        case CardIds.Collectible.Neutral.PozzikAudioEngineer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.PozzikAudioEngineer_AudioBotToken, count: 2)
                        case CardIds.NonCollectible.Neutral.KingMukla_BananasToken:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.KingMukla_BananasToken, count: 10)
                        case CardIds.Collectible.Shaman.SaxophoneSoloist:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Shaman.SaxophoneSoloist)
                        case CardIds.Collectible.Paladin.TheCountess:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Paladin.TheCountess_LegendaryInvitationToken)
                        case CardIds.Collectible.Neutral.LicensedAdventurer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Mage.SteamSurger:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Mage.FlameGeyser)
                        case CardIds.Collectible.Warrior.BoombossThogrun:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warrior.BoombossThogrun_TNTToken, count: 3)
                        case CardIds.NonCollectible.Neutral.KoboldMiner_PouchOfCoinsToken:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic, count: 2)
                        case CardIds.Collectible.Rogue.DartThrow:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Rogue.BountyWrangler:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Neutral.GreedyPartner:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Neutral.SnakeOilSeller:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.MiracleSalesman_SnakeOilToken, count: 2)
                        case CardIds.Collectible.Warlock.DisposalAssistant:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TramMechanic_BarrelOfSludgeToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Warlock.MassProduction:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Warlock.MassProduction, count: 2)
                        case CardIds.Collectible.Warrior.SafetyExpert:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken, count: 3)
                        case CardIds.Collectible.Neutral.Incindius:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.Incindius_EruptionToken, count: 5)
                        case CardIds.Collectible.Neutral.Mixologist:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.Mixologist_MixologistsSpecialToken)
                        case CardIds.Collectible.Neutral.CelestialProjectionist:
                            if let target {
                                addKnownCardId(eventHandler: eventHandler, cardId: target)
                            }
                        case CardIds.Collectible.Neutral.Gorgonzormu:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.Gorgonzormu_DeliciousCheeseToken)
                        case CardIds.Collectible.Rogue.TentacleGrip:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.ChaoticTendril)
                        case CardIds.Collectible.Rogue.DigForTreasure:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Rogue.OhManager:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Neutral.CarryOnGrub:
                            // TODO Token2 if only one card is left
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.CarryOnGrub_CarryOnSuitcaseToken1)
                        case CardIds.Collectible.Warrior.TheRyecleaver:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warrior.TheRyecleaver_SliceOfBreadToken)
                        case CardIds.NonCollectible.Neutral.PhotographerFizzle_FizzlesSnapshotToken:
                            for card in actionStartingEntity?.info.storedCardIds ?? [String]() {
                                // When the opponent plays the "Fizzle" card, a snapshot of the game state is captured.
                                // Some cards are revealed, providing their exact cardId, while others we only know the entityId.
                                // We handle these cases differently based on the information available:
                                //
                                // 1. If the revealed identifier is a number, it represents an entityId
                                //    In this case, we link the created card to the existing entity.
                                //
                                // 2. If the revealed identifier is not a number, it represents a cardId
                                //    Here, we create a new card using the known cardId.
                                if Int(card) != nil {
                                    addKnownCardId(eventHandler: eventHandler, cardId: "", copyOfCardId: card)
                                } else {
                                    addKnownCardId(eventHandler: eventHandler, cardId: card)
                                }
                            }
                        case CardIds.NonCollectible.Priest.Repackage_RepackagedBoxToken:
                            for card in actionStartingEntity?.info.storedCardIds ?? [String]() {
                                addKnownCardId(eventHandler: eventHandler, cardId: card)
                            }
                        case CardIds.Collectible.DemonHunter.XortothBreakerOfStars:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.DemonHunter.XortothBreakerofStars_StarOfOriginationToken)
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.DemonHunter.XortothBreakerofStars_StarOfConclusionToken)
                        case CardIds.Collectible.Neutral.MarinTheManager:
                            if actionStartingEntity?.isControlled(by: eventHandler.opponent.id) == true {
                                for id in [
                                    CardIds.NonCollectible.Neutral.MarintheManager_TolinsGobletToken,
                                    CardIds.NonCollectible.Neutral.MarintheManager_GoldenKoboldToken,
                                    CardIds.NonCollectible.Neutral.MarintheManager_WondrousWandToken,
                                    CardIds.NonCollectible.Neutral.MarintheManager_ZarogsCrownToken
                                ] {
                                    eventHandler.opponent.predictUniqueCardInDeck(cardId: id, isCreated: true)
                                }
                            }
                        case CardIds.Collectible.Rogue.Talgath:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Rogue.BackstabCore)
                        case CardIds.Collectible.Neutral.AstralVigilant:
                            if let last = eventHandler.opponent.cardsPlayedThisMatch
                                .compactMap({ entity in CardUtils.getProcessedCardFromEntity(entity, eventHandler.opponent) })
                                .filter({ card in card.mechanics.count > 0 && card.isDraenei() })
                                .compactMap({ card in card.id }).last {
                                addKnownCardId(eventHandler: eventHandler, cardId: last)
                            }
                        case CardIds.Collectible.Mage.StellarBalance:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.MoonfireCorePlaceholder)
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.Starfire)
                        case CardIds.Collectible.Mage.SpiritGatherer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.WispTokenEMERALD_DREAM)
                        case CardIds.NonCollectible.Warrior.EntertheLostCity_LatorviusGazeOfTheCityToken:
                            if actionStartingEntity?.isControlled(by: eventHandler.opponent.id) ?? false {
                                for id in [ CardIds.NonCollectible.Druid.JungleGiants_BarnabusTheStomperToken,
                                            CardIds.NonCollectible.Hunter.TheMarshQueen_QueenCarnassaToken,
                                            CardIds.NonCollectible.Mage.OpentheWaygate_TimeWarpToken,
                                            CardIds.NonCollectible.Paladin.TheLastKaleidosaur_GalvadonToken,
                                            CardIds.NonCollectible.Priest.AwakentheMakers_AmaraWardenOfHopeToken,
                                            CardIds.NonCollectible.Rogue.TheCavernsBelow_CrystalCoreToken,
                                            CardIds.NonCollectible.Shaman.UnitetheMurlocs_MegafinToken,
                                            CardIds.NonCollectible.Warlock.LakkariSacrifice_NetherPortalToken1,
                                            CardIds.NonCollectible.Warrior.FirePlumesHeart_SulfurasToken ] {
                                    eventHandler.opponent.predictUniqueCardInDeck(cardId: id, isCreated: true)
                                }
                            }
                        default:
                            if let card = Cards.any(byId: actionStartingCardId) {
                                if (player != nil && player![.current_player] == 1
                                    && !eventHandler.playerUsedHeroPower)
                                    || (opponent != nil && opponent![.current_player] == 1
                                        && !eventHandler.opponentUsedHeroPower) {
                                    if card.type == .hero_power {
                                        if player != nil && player![.current_player] == 1 {
                                            eventHandler.playerHeroPower(cardId: actionStartingCardId,
                                                                 turn: eventHandler.turnNumber())
                                            eventHandler.playerUsedHeroPower = true
                                        } else if opponent != nil {
                                            eventHandler.opponentHeroPower(cardId: actionStartingCardId,
                                                                   turn: eventHandler.turnNumber())
                                            eventHandler.opponentUsedHeroPower = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if logLine.line.contains("BlockType=JOUST") {
                eventHandler.joustReveals = 2
            } else if logLine.line.contains("BlockType=REVEAL_CARD") {
                eventHandler.joustReveals = 1
            } else if eventHandler.gameTriggerCount == 0
                && logLine.line.contains("BLOCK_START BlockType=TRIGGER Entity=GameEntity") {
                eventHandler.gameTriggerCount += 1
            }
        } else if logLine.line.contains("CREATE_GAME") {
            tagChangeHandler.clearQueuedActions()

            // indicate game start
            maxBlockId = 0
            currentBlock = nil
            resetCurrentEntity()
//            eventHandler.gameStart(at: logLine.time)
        } else if logLine.line.contains("BLOCK_END") {
            if eventHandler.gameTriggerCount < 10 && (eventHandler.gameEntity?.has(tag: .turn) ?? false) {
                eventHandler.gameTriggerCount += 10
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                eventHandler.setupDone = true
            }
            
            if let currentBlock = currentBlock, currentBlock.type == "JOUST" || currentBlock.type == "REVEAL_CARD" {
                //make sure there are no more queued actions that might depend on JoustReveals
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                eventHandler.joustReveals = 0
            }
            
            if let currentBlock = currentBlock, let chameleosReveal = eventHandler.chameleosReveal,
                let chameleos = eventHandler.entities[chameleosReveal.0], currentBlock.type == "TRIGGER"
                && (currentBlock.cardId == CardIds.NonCollectible.Neutral.Chameleos_ShiftingEnchantment
                    || currentBlock.cardId == CardIds.Collectible.Priest.Chameleos) && chameleos.has(tag: .shifting) {
                eventHandler.handleChameleosReveal(cardId: chameleosReveal.1)
            }
            
            eventHandler.chameleosReveal = nil
            
            let abyssalCurseCreators = [ CardIds.Collectible.Warlock.DraggedBelow, CardIds.Collectible.Warlock.SirakessCultist, CardIds.Collectible.Warlock.AbyssalWave, CardIds.Collectible.Warlock.Zaqul ]
            if currentBlock?.type == "POWER" && abyssalCurseCreators.contains(currentBlock?.cardId ?? "") {
                if let sourceEntity = eventHandler.entities.values.first(where: { x in x.id == currentBlock!.sourceEntityId }) {
                    let abyssalCurse = eventHandler.entities.values.last(where: { x in x[.creator] == sourceEntity.id })
                    let nextDamage = abyssalCurse?[.tag_script_data_num_1] ?? 0
                    
                    if sourceEntity.isControlled(by: eventHandler.player.id) {
                        eventHandler.handleOpponentAbyssalCurse(value: nextDamage)
                    } else {
                        eventHandler.handlePlayerAbyssalCurse(value: nextDamage)
                    }
                }
            }
            
            // Handle Choral Mrrrglr enchantment in Battlegrounds
            // Check at BLOCK_END because the enchantment is updated DURING the block, not at BLOCK_START
            if eventHandler.currentGameMode == GameMode.battlegrounds, let currentBlock, currentBlock.type == "TRIGGER" {
                if currentBlock.cardId == CardIds.NonCollectible.Neutral.ChoralMrrrglr, let choralEntity = eventHandler.entities[currentBlock.sourceEntityId], choralEntity.isControlled(by: eventHandler.opponent.id) {
                    // Find the Chorus enchantment that was CHANGED in this block and attached to Choral
                    // The enchantment is created inside the TRIGGER block, so it exists in game.Entities by BLOCK_END
                    if let chorusEnchantment = eventHandler.entities.values
                        .first(where: { e in e.cardId == CardIds.NonCollectible.Neutral.ChoralMrrrglr_ChorusEnchantment &&
                            e[GameTag.attached] == choralEntity.id &&
                            e[GameTag.creator] == choralEntity.id }) {
                        BobsBuddyInvoker.instance(gameId: eventHandler.gameId, turn: eventHandler.turnNumber())?.updateMinionEnchantment(chorusEnchantment, choralEntity.id, false)
                    }
                }
                if currentBlock.cardId == CardIds.NonCollectible.Neutral.TimewarpedNelliesShipToken1 && currentBlock.triggerKeyword == "DEATHRATTLE" {
                    if let nelliesEntity = eventHandler.entities[currentBlock.sourceEntityId] {
                        let summonedEntities = eventHandler.entities.values.filter { e in e[GameTag.cardtype] == CardType.minion.rawValue && e[.creator] == nelliesEntity[.creator] && e[.zone] == Zone.play.rawValue }.compactMap { x in x.card.dbfId }
                        if summonedEntities.count > 0 {
                            BobsBuddyInvoker.instance(gameId: eventHandler.gameId, turn: eventHandler.turnNumber())?.updateNelliesShipEnchantment(summonedEntities, nelliesEntity.id, nelliesEntity.isControlled(by: eventHandler.player.id))
                        }
                    }
                }
            }
            blockEnd()
        }

        if eventHandler.isInMenu { return }

        if !creationTag && eventHandler.determinedPlayers() {
            tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
        }
        if !creationTag {
            resetCurrentEntity()
        }
    }
    
    private func handleCopiedCard(eventHandler: PowerEventHandler, entity: Entity) {
        let copiesOfCard = eventHandler.opponent.playerEntities.filter { e in e.info.copyOfCardId == String(entity.id) }

        for copy in copiesOfCard {
            copy.cardId = entity.cardId
            copy.info.guessedCardState = .guessed
        }

        if entity.info.copyOfCardId != nil {
            let matchingEntities = eventHandler.opponent.playerEntities.filter({ e in String(e.id) == entity.info.copyOfCardId || e.info.copyOfCardId == entity.info.copyOfCardId })

            for matchingEntity in matchingEntities {
                if matchingEntity.id == entity.id { continue }
                matchingEntity.cardId = entity.cardId
                matchingEntity.info.hidden = false
                matchingEntity.info.copyOfCardId = "\(entity.id)"
                matchingEntity.info.guessedCardState = .guessed
            }
        }
    }
    
    private func ensureValidCardID(cardId: String) -> String {
        if cardId.starts(with: PowerGameStateParser.TransferStudentToken) && !cardId.hasSuffix("e") {
            return CardIds.Collectible.Neutral.TransferStudent
        }
        if let overrideId = CardIds.upgradeOverrides[cardId] {
            return overrideId
        }
        return cardId
    }

    private func getTargetCardId(matches: [Match]) -> String? {
        if matches.count < 7 {
            return nil
        }
        let target = matches[6].value.trim()
        guard target.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity: target) else {
            return nil
        }
        guard CardIdRegex.match(target) else { return nil }

        let cardIdMatch = CardIdRegex.matches(target)
        return cardIdMatch.first?.value.trim()
    }
    
    private func removeKnownCardId(eventHandler: PowerEventHandler, count: Int = 1) {
        guard let currentBlock else {
            return
        }
        let blockId = currentBlock.id
        for _ in 0 ..< count {
            if !eventHandler.knownCardIds.containsKey(blockId) {
                break
            }
            if let count = eventHandler.knownCardIds[blockId]?.count, count > 0 {
                eventHandler.knownCardIds[blockId]?.removeLast()
            }
        }
    }

    private func addKnownCardId(eventHandler: PowerEventHandler, cardId: String?, count: Int = 1, location: DeckLocation = .unknown, copyOfCardId: String? = nil, info: EntityInfo? = nil) {
        guard let cardId = cardId else { return }

        if let blockId = currentBlock?.id {
            for _ in 0 ..< count {
                if eventHandler.knownCardIds[blockId] == nil {
                    eventHandler.knownCardIds[blockId] = []
                }

                eventHandler.knownCardIds[blockId]?.append((cardId, location, copyOfCardId, info))
            }
        }
    }

    private func reset() {
        tagChangeHandler.clearQueuedActions()
    }
}

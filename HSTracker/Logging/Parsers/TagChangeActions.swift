//
//  TagChanceActions.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct TagChangeActions {
    //We have to remove cards moved from deck -> graveyard when this is the parent block due to a data leak introduced by blizzard to the classic format.
    static let ClassicTrackingCardId = CardIds.Collectible.Hunter.TrackingVanilla

    var powerGameStateParser: PowerGameStateParser?

    mutating func setPowerGameStateParser(parser: PowerGameStateParser) {
        self.powerGameStateParser = parser
    }
    
    func findAction(eventHandler: PowerEventHandler, tag: GameTag, id: Int, value: Int, prevValue: Int) -> (() -> Void)? {
        if tag == .bacon_card_dbid_reward {
            logger.debug("Tag change of reward: \(id): \(prevValue) -> \(value)")
        }
        return {
            switch tag {
            case .zone: 
                self.zoneChange(eventHandler: eventHandler, id: id, value: value, prevValue: prevValue)
            case .playstate: 
                self.playstateChange(eventHandler: eventHandler, id: id, value: value)
            case .gametag_3479:
                self.bgsConcededChange(eventHandler: eventHandler, id: id, value: value)
            case .cardtype:
                self.cardTypeChange(eventHandler: eventHandler, id: id, value: value)
            case .defending: 
                self.defendingChange(eventHandler: eventHandler, id: id, value: value)
            case .attacking: 
                self.attackingChange(eventHandler: eventHandler, id: id, value: value)
            case .proposed_defender: 
                self.proposedDefenderChange(eventHandler: eventHandler, value: value)
            case .proposed_attacker:
                self.proposedAttackerChange(eventHandler: eventHandler, value: value)
            case .predamage:
                self.predamageChange(eventHandler: eventHandler, id: id, value: value)
            case .num_turns_in_play:
                self.numTurnsInPlayChange(eventHandler: eventHandler, id: id, value: value)
            case .controller:
                self.controllerChange(eventHandler: eventHandler, id: id, prevValue: prevValue, value: value)
            case .fatigue:
                self.fatigueChange(eventHandler: eventHandler, value: value, id: id)
            case .step:
                self.stepChange(eventHandler: eventHandler, value: value)
            case .turn:
                self.turnChange(eventHandler: eventHandler)
            case .state:
                self.stateChange(eventHandler: eventHandler, value: value)
            case .transformed_from_card:
                self.transformedFromCardChange(eventHandler: eventHandler, id: id, value: value)
            case .creator, .displayed_creator:
                self.creatorChanged(eventHandler: eventHandler, id: id, value: value)
            case .whizbang_deck_id:
                self.whizbangDeckIdChange(eventHandler: eventHandler, id: id, value: value)
            case .mulligan_state:
                self.mulliganStateChange(eventHandler: eventHandler, id: id, value: value)
            case .copied_from_entity_id:
                self.onCardCopy(eventHandler: eventHandler, id: id, value: value)
            case .linked_entity:
                self.linkedEntity(eventHandler: eventHandler, id: id, value: value)
            case .tag_script_data_num_1:
                self.tagScriptDataNum1(eventHandler: eventHandler, id: id, value: value)
            case .reborn:
                self.rebornChange(eventHandler: eventHandler, id: id, value: value)
            case .damage:
                self.damageChange(eventHandler: eventHandler, id: id, value: value, previous: prevValue)
            case .armor:
                self.armorChange(eventHandler: eventHandler, id: id, value: value, previous: prevValue)
            case .forge_revealed:
                self.onForgeRevealed(eventHandler: eventHandler, id: id, value: value, previous: prevValue)
            case .revealed:
                self.onRevealed(eventHandler: eventHandler, id: id, value: value, previous: prevValue)
            case .parent_card:
                self.onParentCardChange(eventHandler: eventHandler, id: id, value: value, previous: prevValue)
            case .cant_play:
                self.cantPlayChange(eventHandler: eventHandler, id: id, value: value, previous: prevValue)
            case .lettuce_ability_tile_visual_all_visible, .lettuce_ability_tile_visual_self_only, .fake_zone, .fake_zone_position:
                eventHandler.handleMercenariesStateChange()
            case .player_tech_level:
                self.playerTechLevel(eventHandler: eventHandler, id: id, value: value, previous: prevValue)
            case .player_triples:
                self.playerTriples(eventHandler: eventHandler, id: id, value: value, previous: prevValue)
            case .immolatestage:
                self.onImmolateStage(eventHandler: eventHandler, id: id, value: value)
            case .resources_used:
                self.onResourcesUsedChange(eventHandler: eventHandler, id: id, value: value)
            case .quest_reward_database_id:
                eventHandler.handleQuestRewardDatabaseId(id: id, value: value)
            case .bacon_player_num_hero_buddies_gained:
                self.playerBuddiesGained(eventHandler: eventHandler, id: id, value: value)
            case .bacon_hero_heropower_quest_reward_database_id:
                self.playerHeroPowerQuestRewardDatabaseId(eventHandler: eventHandler, id: id, value: value)
            case .bacon_hero_heropower_quest_reward_completed:
                self.playerHeroPowerQuestRewardCompleted(eventHandler: eventHandler, id: id, value: value)
            case .bacon_hero_quest_reward_database_id:
                self.playerHeroQuestRewardDatabaseId(eventHandler: eventHandler, id: id, value: value)
            case .bacon_hero_quest_reward_completed:
                self.playerHeroQuestRewardCompleted(eventHandler: eventHandler, id: id, value: value)
            case .gametag_2022:
                self.onBattlegroundsSetupChange(eventHandler: eventHandler, value: value, prevValue: prevValue)
            case .gametag_3533:
                self.onBattlegroundsCombatSetupChange(eventHandler: eventHandler, value: value, prevValue: prevValue )
            case .hero_entity:
                self.onHeroEntityChange(eventHandler: eventHandler, playerEntityId: id, heroEntityId: value)
            case .next_opponent_player_id:
                self.onNextOpponentPlayerId(eventHandler: eventHandler, id: id, value: value)
            default:
                break
            }
            if let game = eventHandler as? Game {
                game.counterManager.handleTagChange(tag: tag, id: id, value: value, prevValue: prevValue)
            }
        }
    }
    
    private func onBattlegroundsSetupChange(eventHandler: PowerEventHandler, value: Int, prevValue: Int) {
        if prevValue == 1 && value == 0 {
            eventHandler.isBattlegroundsCombatPhase = true
            if eventHandler.isBattlegroundsSoloMatch() {
                BobsBuddyInvoker.instance(gameId: eventHandler.gameId, turn: eventHandler.turnNumber())?.startCombat()
            }
        }
    }
    
    private func onBattlegroundsCombatSetupChange(eventHandler: PowerEventHandler, value: Int, prevValue: Int) {
        if prevValue == 0 && value == 1 {
            eventHandler.duosResetHeroTracking()
        }

        if prevValue == 1 && value == 0 {
            eventHandler.isBattlegroundsCombatPhase = false
            if !eventHandler.isBattlegroundsDuosMatch() || eventHandler.duosWasOpponentHeroModified {
                eventHandler.snapshotBattlegroundsBoardState()
            }
            if eventHandler.isBattlegroundsDuosMatch() {
                BobsBuddyInvoker.instance(gameId: eventHandler.gameId, turn: eventHandler.turnNumber())?.startCombat()
            }
        }
    }

    private func onHeroEntityChange(eventHandler: PowerEventHandler, playerEntityId: Int, heroEntityId: Int) {
        if eventHandler.isBattlegroundsDuosMatch() {
            if playerEntityId == eventHandler.playerEntity?.id {
                eventHandler.duosSetHeroModified(true)
            } else if playerEntityId == eventHandler.opponentEntity?.id {
                eventHandler.duosSetHeroModified(false)
            }
        } else if eventHandler.isTraditionalHearthstoneMatch {
            if let entity = eventHandler.entities[heroEntityId] {
                let hero = Cards.by(cardId: entity.cardId)
                
                guard let heroName = hero?.getClasses().first else {
                    return
                }
                
                if playerEntityId == eventHandler.playerEntity?.id {
                    eventHandler.player.currentClass = heroName
                } else if playerEntityId == eventHandler.opponentEntity?.id {
                    eventHandler.opponent.currentClass = heroName
                }
            }
        }
    }

    private func onResourcesUsedChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        guard let playerEntity = eventHandler.playerEntity else {
            return
        }
        if id != playerEntity.id {
            return
        }
        let available = playerEntity[.resources] + playerEntity[.temp_resources]
        AppDelegate.instance().coreManager.game.secretsManager?.handlePlayerManaRemaining(mana: max(0, available - value))
    }
    
    private func rebornChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if eventHandler.currentGameMode != GameMode.battlegrounds {
            return
        }
        if value != 1 {
            return
        }
    }
    
    private func tagScriptDataNum1(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if eventHandler.currentGameMode != .battlegrounds {
            return
        }
        let block = powerGameStateParser?.getCurrentBlock()
        
        if block == nil || block?.type != "TRIGGER" || block?.cardId != CardIds.NonCollectible.Neutral.Baconshop8playerenchantTavernBrawl || value != 1 {
            return
        }
        if let entity = eventHandler.entities[id] {
            if !entity.isHeroPower || entity.isControlled(by: eventHandler.player.id) {
                return
            }
            if entity.cardId != entity.info.latestCardId {
                logger.warning("CardId Mismatch \(entity.cardId) vs \(entity.info.latestCardId)")
            }
        }
    }
    
    private func onCardCopy(eventHandler: PowerEventHandler, id: Int, value: Int) {

        guard let entity = eventHandler.entities[id] else {
            return
        }

        if eventHandler.currentGameMode == .battlegrounds && AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.cardId == CardIds.NonCollectible.Neutral.TavishStormpike_LockAndLoad &&
            entity[.controller] == eventHandler.opponent.id && entity.isInZone(zone: .play) {
            BobsBuddyInvoker.instance(gameId: eventHandler.gameId, turn: eventHandler.turnNumber())?.updateOpponentHeroPower(attachedEntity: entity)
        }
        
        guard let targetEntity = eventHandler.entities[value] else {
            return
        }
        
        onDredge(eventHandler: eventHandler, entity: entity, target: targetEntity)
        
        if entity.isControlled(by: eventHandler.opponent.id) {
            return
        }
        
        if entity[.creator_dbid] == CardIds.suspiciousMysteryDbfId {
            // Card was created by Suspicious Alchemist/Usher/Pirate
            return
        }

        if targetEntity.cardId == "" {
            targetEntity.cardId = entity.info.latestCardId
            targetEntity.info.guessedCardState = GuessedCardState.guessed

            if entity[.creator_dbid] == CardIds.keyMasterAlabasterDbfId {
                targetEntity.info.hidden = false
            }

            eventHandler.handleCardCopy()
        }
    }
    
    private func linkedEntity(eventHandler: PowerEventHandler, id: Int, value: Int) {
        guard let entity = eventHandler.entities[id] else {
            return
        }
        guard let targetEntity = eventHandler.entities[value] else {
            return
        }
        
        let currentBlock = AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock
        // Eyes in the Sky
        if let currentBlock, currentBlock.type == "POWER", let actionStartingEntity = eventHandler.entities[currentBlock.sourceEntityId], actionStartingEntity.cardId == CardIds.Collectible.Rogue.EyesInTheSky, let linkingEntity = eventHandler.entities[id], let linkedEntity = eventHandler.entities[value], !linkedEntity.cardId.isEmpty && linkedEntity.cardId.isEmpty {
            linkedEntity.cardId = linkingEntity.cardId
            linkedEntity.info.guessedCardState = .guessed
            
            AppDelegate.instance().coreManager.game.updateTrackers()
        }
        
        // prevents dark gift leaking the card
        if currentBlock?.parent?.cardId == CardIds.Collectible.Neutral.NightmareLordXavius && entity.cardId == CardIds.NonCollectible.Neutral.TreacherousTormentor_DarkGiftToken && entity.isControlled(by: eventHandler.opponent.id) {
            targetEntity.info.revealedOnHistory = false
            targetEntity.info.hidden = true
            return
        }
        onDredge(eventHandler: eventHandler, entity: entity, target: targetEntity)
    }
    
    static let _canCastDredge = [ CardIds.Collectible.Druid.ConvokeTheSpirits,
                                  CardIds.Collectible.Mage.PuzzleBoxOfYoggSaron ]
    
    private func onDredge(eventHandler: PowerEventHandler, entity: Entity, target: Entity) {
        guard entity[.linked_entity] == target.id && entity[.copied_from_entity_id] == target.id && entity.isControlled(by: eventHandler.player.id) else {
            return
        }
        guard entity.isInZone(zone: .setaside) || entity.isInZone(zone: .deck) else {
            return
        }
        let source = entity[.creator]
        guard source != 0, let sourceEntity = eventHandler.entities[source], sourceEntity.hasDredge else {
            return
        }
        guard let currentBlock = powerGameStateParser?.getCurrentBlock() else {
            return
        }
        if currentBlock.dredgeCounter == 0 {
            eventHandler.dredgeCounter += 3
        }
        if TagChangeActions._canCastDredge.contains(currentBlock.parent?.cardId ?? "") {
            // Dredge effect was automatically cast by another card. Not revealed to the player.
            return
        }
        let index = eventHandler.dredgeCounter - currentBlock.dredgeCounter
        currentBlock.dredgeCounter += 1
        target.info.deckIndex = -index
        
        logger.info("Dredge Bottom: \(target.description)")
        
        eventHandler.handlePlayerDredge()
    }
    
    private func mulliganStateChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value == 0 {
            return
        }
        guard let entity = eventHandler.entities[id] else {
            return
        }

        if entity.isPlayer(eventHandler: eventHandler) && Mulligan.done.rawValue == value {
            if #available(macOS 10.15, *) {
                Task.detached {
                    await eventHandler.handlePlayerMulliganDone()
                }
            }
        }
    }
    
    private func whizbangDeckIdChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value == 0 {
            return
        }
        guard let entity = eventHandler.entities[id] else {
            return
        }
        if entity.isControlled(by: eventHandler.player.id) {
            eventHandler.player.isPlayingWhizbang = true
        } else if entity.isControlled(by: eventHandler.opponent.id) {
            eventHandler.opponent.isPlayingWhizbang = true
        }
        if !entity.isPlayer(eventHandler: eventHandler) {
            return
        }
        if Settings.autoDeckDetection {
            _ = AppDelegate.instance().coreManager.autoSelectTemplateDeckByDeckId(deckId: value)
        }
    }
    
    private func creatorChanged(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value == 0 {
            return
        }
        
        if let entity = eventHandler.entities[id] {
            let displayedCreatorId = entity[.displayed_creator]
            if displayedCreatorId == id {
                // Some cards (e.g. Direhorn Hatchling) wrongfully set DISPLAYED_CREATOR
                // on themselves instead of the created entity.
                return
            }
            if let displayedCreator = eventHandler.entities[displayedCreatorId] {
                // For some reason Far Sight sets DISPLAYED_CREATOR on the entity
                if displayedCreator.cardId == CardIds.Collectible.Shaman.FarSight || displayedCreator.cardId == CardIds.Collectible.Shaman.FarSightCore ||  displayedCreator.cardId == CardIds.Collectible.Shaman.FarSightVanilla {
                    return
                }
            }

            let creatorId = entity[.creator]
            if creatorId == id {
                // Same precaution as for Direhorn Hatching above.
                return
            }
            if creatorId == eventHandler.gameEntity?.id {
                return
            }
            // All cards created by Whizbang have a creator tag set
            if let creator = eventHandler.entities[creatorId] {
                if creator.cardId == CardIds.Collectible.Neutral.WhizbangTheWonderful {
                    return
                }
                let controller = creator[.controller]
                let usingWhizbang = controller == eventHandler.player.id && eventHandler.player.isPlayingWhizbang || controller == eventHandler.opponent.id && eventHandler.opponent.isPlayingWhizbang
                if usingWhizbang && creator.isInSetAside {
                    return
                }
            }
            entity.info.created = true
        }
    }
    private func transformedFromCardChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value == 0 { return }
        guard let entity = eventHandler.entities[id] else { return }

        entity.info.set(originalCardId: value)
    }

    private func stateChange(eventHandler: PowerEventHandler, value: Int) {
        if value != State.complete.rawValue {
            return
        }
        eventHandler.gameEnd()
        eventHandler.gameEnded = true
    }

    private func turnChange(eventHandler: PowerEventHandler) {
        guard eventHandler.setupDone && eventHandler.playerEntity != nil else { return }
        guard let playerEntity = eventHandler.playerEntity else { return }

        if playerEntity.has(tag: .current_player) {
            eventHandler.playerUsedHeroPower = false
        } else {
            eventHandler.opponentUsedHeroPower = false
        }
    }

    private func stepChange(eventHandler: PowerEventHandler, value: Int) {
        if value == Step.begin_mulligan.rawValue {
            eventHandler.handleBeginMulligan()
        }
        eventHandler.handleMercenariesStateChange()
        if let playerEntity = eventHandler.playerEntity, playerEntity.has(tag: .current_player) && value == Step.main_cleanup.rawValue {
            let remainingMana = playerEntity[.resources] + playerEntity[.temp_resources] - playerEntity[.resources_used]
            
            AppDelegate.instance().coreManager.game.secretsManager?.handlePlayerTurnEnded(mana: remainingMana)
        }
        guard !eventHandler.setupDone && eventHandler.entities.first?.1.name == "GameEntity" else { return }

        logger.info("Game was already in progress.")
        eventHandler.wasInProgress = true
    }

    private func defendingChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        guard let entity = eventHandler.entities[id] else { return }
        eventHandler.defending(entity: value == 1 ? entity : nil)
    }

    private func attackingChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        guard let entity = eventHandler.entities[id] else { return }
        eventHandler.attacking(entity: value == 1 ? entity : nil)
    }

    private func proposedDefenderChange(eventHandler: PowerEventHandler, value: Int) {
        eventHandler.proposedDefenderEntityId = value
    }

    private func proposedAttackerChange(eventHandler: PowerEventHandler, value: Int) {
        eventHandler.proposedAttackerEntityId = value
        if value <= 0 {
            return
        }
        guard let entity = eventHandler.entities[value] else {
            return
        }
        if entity.isHero {
            logger.debug("Saw hero attack from \(entity.cardId)")

            if eventHandler.isBattlegroundsDuosMatch() {
                _ = BobsBuddyInvoker.instance(gameId: eventHandler.gameId, turn: eventHandler.turnNumber())?.maybeRunDuosPartialCombat()
            }
        }
        eventHandler.handleProposedAttackerChange(entity: entity)
    }

    private func predamageChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = eventHandler.entities[id] else { return }
        
        eventHandler.entityPredamage(entity: entity, damage: value)
    }
    
    private func armorChange(eventHandler: PowerEventHandler, id: Int, value: Int, previous: Int) {
        if value <= 0 {
            return
        }
        
        if let entity = eventHandler.entities[id] {
            //We do prevValue - value because armor gets smaller as you lose it and damage gets bigger as you lose life.
            eventHandler.handleEntityLostArmor(entity: entity, value: previous - value)
        }
    }
    
    private func onForgeRevealed(eventHandler: PowerEventHandler, id: Int, value: Int, previous: Int) {
        guard let entity = eventHandler.entities[id] else {
            return
        }
        
        if entity.isControlled(by: eventHandler.opponent.id) && entity.isInZone(zone: .hand) {
            entity.info.forged = true
            entity.info.hidden = false
        }
    }
    
    private func onRevealed(eventHandler: PowerEventHandler, id: Int, value: Int, previous: Int) {
        guard let entity = eventHandler.entities[id] else {
            return
        }
    
        let isStartOfTheGameEffect = powerGameStateParser?.currentBlock?.triggerKeyword == "START_OF_GAME_KEYWORK"
        entity.info.hidden = isStartOfTheGameEffect
        
        if isStartOfTheGameEffect {
            entity.info.guessedCardState = .revealed
            
            AppDelegate.instance().coreManager.game.updateTrackers()
        }
    }
    
    private func cantPlayChange(eventHandler: PowerEventHandler, id: Int, value: Int, previous: Int) {
        guard let entity = eventHandler.entities[id] else {
            return
        }
        
        let player = entity.isControlled(by: eventHandler.player.id) ? eventHandler.player : eventHandler.opponent
        player?.cardsPlayedThisMatch.remove(entity)
        player?.cardsPlayedThisTurn.remove(entity)
        player?.spellsPlayedCards.remove(entity)
        player?.spellsPlayedInFriendlyCharacters.remove(entity)
        player?.spellsPlayedInOpponentCharacters.remove(entity)
    }
    
    private func onParentCardChange(eventHandler: PowerEventHandler, id: Int, value: Int, previous: Int) {
        guard let entity = eventHandler.entities[id] else {
            return
        }

        // when a starship is launched it sets the value to 0
        // otherwise it sets to the parent starship id
        if let parentEntity = eventHandler.entities[value] {
            if !entity.cardId.isBlank {
                parentEntity.info.storedCardIds.append(entity.cardId)
            }
        } else {
            let currentBlock = powerGameStateParser?.getCurrentBlock()

            // every piece sets the parent to 0, we only need to get 1 of them
            if eventHandler.starshipLaunchBlockIds.contains(currentBlock?.id) {
                return
            }

            if currentBlock?.type != "POWER" ||
                !(CardUtils.isStarship(currentBlock?.cardId ?? "") || currentBlock?.cardId == CardIds.Collectible.Neutral.TheExodar) {
                return
            }

            guard let starshipToken = eventHandler.entities[previous] else {
                return
            }

            let player: Player! = entity.isControlled(by: eventHandler.player.id) ? eventHandler.player : eventHandler.opponent
            eventHandler.starshipLaunchBlockIds.append(currentBlock?.id)
            player.launchedStarships.append(starshipToken.cardId)

            let excludedPieces = [
                CardIds.NonCollectible.Neutral.LaunchStarship,
                CardIds.NonCollectible.Neutral.AbortLaunch
            ]

            let starshipPieces = starshipToken.info.storedCardIds.filter { cardId in !excludedPieces.contains(cardId) }
            player.launchedStarships.append(contentsOf: starshipPieces)
            return
        }
    }
    
    private func damageChange(eventHandler: PowerEventHandler, id: Int, value: Int, previous: Int) {
        if value <= 0 {
            return
        }
        if let entity = eventHandler.entities[id], let dealer = eventHandler.entities[entity[.last_affected_by]] {
            eventHandler.entityDamage(dealer: dealer, entity: entity, damage: value - previous)
        }
    }
    
    private func numTurnsInPlayChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = eventHandler.entities[id] else { return }
        
        eventHandler.turnsInPlayChange(entity: entity, turn: eventHandler.turnNumber())
    }

    private func fatigueChange(eventHandler: PowerEventHandler, value: Int, id: Int) {
        guard let entity = eventHandler.entities[id] else { return }
        
        let controller = entity[.controller]
        if controller == eventHandler.player.id {
            eventHandler.playerFatigue(value: value)
        } else if controller == eventHandler.opponent.id {
            eventHandler.opponentFatigue(value: value)
        }
    }

    private func controllerChange(eventHandler: PowerEventHandler, id: Int, prevValue: Int, value: Int) {
        guard let entity = eventHandler.entities[id] else { return }
        if prevValue <= 0 {
            entity.info.originalController = value
            return
        }
        
        if entity.has(tag: .player_id) { return }
        
        if value == eventHandler.player.id {
            if entity.isInZone(zone: .secret) {
                eventHandler.opponentStolen(entity: entity, cardId: entity.info.latestCardId, turn: eventHandler.turnNumber())
            } else if entity.isInZone(zone: .play) {
                eventHandler.opponentStolen(entity: entity, cardId: entity.info.latestCardId, turn: eventHandler.turnNumber())
            }
        } else if value == eventHandler.opponent.id {
            if entity.isInZone(zone: .secret) {
                eventHandler.playerStolen(entity: entity, cardId: entity.info.latestCardId, turn: eventHandler.turnNumber())
            } else if entity.isInZone(zone: .play) {
                eventHandler.playerStolen(entity: entity, cardId: entity.info.latestCardId, turn: eventHandler.turnNumber())
            }
        }
    }

    private func cardTypeChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value == CardType.hero.rawValue {
            setHeroAsync(eventHandler: eventHandler, id: id)
        } else if value == CardType.minion.rawValue {
            minionRevealed(eventHandler: eventHandler, id: id)
        }
    }
    
    private func bgsConcededChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value == 1 {
            eventHandler.concede()
        }
    }

    private func playstateChange(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value == PlayState.conceded.rawValue {
            eventHandler.concede()
        }

        if eventHandler.gameEnded { return }

        guard let entity = eventHandler.entities[id], entity.isPlayer(eventHandler: eventHandler) else {
            return
        }

        if let value = PlayState(rawValue: value) {
            switch value {
            case .won:
                eventHandler.win()
            case .lost:
                eventHandler.loss()
            case .tied:
                eventHandler.tied()
            default: break
            }
        }
    }

    private func zoneChange(eventHandler: PowerEventHandler, id: Int, value: Int, prevValue: Int) {
        guard id > 3 else { return }
        guard let entity = eventHandler.entities[id] else { return }
        
        if entity.info.originalZone == nil {
            if prevValue != Zone.invalid.rawValue && prevValue != Zone.setaside.rawValue {
                entity.info.originalZone = Zone(rawValue: prevValue)
            } else if value != Zone.invalid.rawValue && value != Zone.setaside.rawValue {
                entity.info.originalZone = Zone(rawValue: value)
            }
        }
        
        let controller = entity[.controller]
        guard let zoneValue = Zone(rawValue: prevValue) else {
            return
        }
        
        switch zoneValue {
        case .deck:
            zoneChangeFromDeck(eventHandler: eventHandler, id: id, value: value,
                               prevValue: prevValue,
                               controller: controller,
                               cardId: entity.info.latestCardId)
            
        case .hand:
            zoneChangeFromHand(eventHandler: eventHandler, id: id, value: value,
                               prevValue: prevValue, controller: controller,
                               cardId: entity.info.latestCardId)
            
        case .play:
            zoneChangeFromPlay(eventHandler: eventHandler, id: id, value: value,
                               prevValue: prevValue, controller: controller,
                               cardId: entity.info.latestCardId)
            
        case .secret:
            zoneChangeFromSecret(eventHandler: eventHandler, id: id, value: value,
                                 prevValue: prevValue, controller: controller,
                                 cardId: entity.info.latestCardId)
            
        case .invalid:
            if !eventHandler.setupDone && value == Zone.graveyard.rawValue {
                // Souleater's Scythe causes entites to be created in the graveyard.
                // We need to not reveal this card for the opponent and only reveal
                // it for the player after mulligan.
                entity.info.inGraveyardAtStartOfGame = true
            }
            let maxId = getMaxHeroPowerId(eventHandler: eventHandler)
            if !eventHandler.setupDone
                && (id <= maxId || eventHandler.gameEntity?[.step] == Step.invalid.rawValue
                    && entity[.zone_position] < 5) {
                entity.info.originalZone = .deck
                simulateZoneChangesFromDeck(eventHandler: eventHandler, id: id, value: value,
                                            cardId: entity.info.latestCardId, maxId: maxId)
            } else {
                zoneChangeFromOther(eventHandler: eventHandler, id: id, rawValue: value,
                                    prevValue: prevValue, controller: controller,
                                    cardId: entity.info.latestCardId)
            }
        case .setaside:
            if value == Zone.play.rawValue && controller == eventHandler.opponent.id && eventHandler.currentGameMode == .battlegrounds {
                let copiedFrom = entity[.copied_from_entity_id]
                if copiedFrom > 0, let source = eventHandler.entities[copiedFrom], source.isInHand && !source.hasCardId {
                    BobsBuddyInvoker.instance(gameId: eventHandler.gameId, turn: eventHandler.turnNumber())?.updateOpponentHand(entity: source, copy: entity)
                }
            }
            zoneChangeFromOther(eventHandler: eventHandler, id: id, rawValue: value, prevValue: prevValue, controller: controller, cardId: entity.info.latestCardId)

        case .graveyard, .removedfromgame:
            zoneChangeFromOther(eventHandler: eventHandler, id: id, rawValue: value, prevValue: prevValue,
                                controller: controller, cardId: entity.info.latestCardId)
        default:
            break
        }
        
        if value == Zone.play.rawValue {
            if let e = eventHandler.entities[id], e.isMinion {
                eventHandler.minionsInPlay.append(e.cardId)
                
                if let minions = eventHandler.minionsInPlayByPlayer[e[.controller]] {
                    minions.append(e.cardId)
                } else {
                    let arr = SynchronizedArray<String>()
                    arr.append(e.cardId)
                    eventHandler.minionsInPlayByPlayer[e[.controller]] = arr
                }
            }
        }
    }

    // The last heropower is created after the last hero, therefore +1
    private func getMaxHeroPowerId(eventHandler: PowerEventHandler) -> Int {
        return max(eventHandler.playerEntity?[.hero_entity] ?? 66,
                   eventHandler.opponentEntity?[.hero_entity] ?? 66) + 1
    }

    private func simulateZoneChangesFromDeck(eventHandler: PowerEventHandler, id: Int,
                                             value: Int, cardId: String?, maxId: Int) {
        if value == Zone.deck.rawValue {
            return
        }
        
        guard let entity = eventHandler.entities[id] else { return }
                
        if value == Zone.setaside.rawValue {
            entity.info.created = true
            return
        }
        
        if entity.isHero && !entity.isPlayableHero || entity.isHeroPower
            || entity.has(tag: .player_id) || entity[.cardtype] == CardType.game.rawValue
            || entity.has(tag: .creator) {
            return
        }
        
        zoneChangeFromDeck(eventHandler: eventHandler, id: id, value: Zone.hand.rawValue,
                           prevValue: Zone.deck.rawValue,
                           controller: entity[.controller], cardId: cardId)
        if value == Zone.hand.rawValue {
            return
        }
        zoneChangeFromHand(eventHandler: eventHandler, id: id, value: Zone.play.rawValue,
                           prevValue: Zone.hand.rawValue,
                           controller: entity[.controller], cardId: cardId)
        if value == Zone.play.rawValue {
            return
        }
        zoneChangeFromPlay(eventHandler: eventHandler, id: id, value: value, prevValue: Zone.play.rawValue,
                           controller: entity[.controller], cardId: cardId)
    }

    private func zoneChangeFromOther(eventHandler: PowerEventHandler, id: Int, rawValue: Int,
                                     prevValue: Int, controller: Int, cardId: String?) {
        guard let value = Zone(rawValue: rawValue) else {
            return
        }
        guard let entity = eventHandler.entities[id] else { return }

        let currentBlockCardId = powerGameStateParser?.getCurrentBlock()?.cardId ?? ""
        if entity.info.originalZone == .deck  && rawValue != Zone.deck.rawValue {
            // This entity was moved from DECK to SETASIDE to HAND, e.g. by Tracking
            entity.info.discarded = false
            zoneChangeFromDeck(eventHandler: eventHandler, id: id, value: rawValue, prevValue: prevValue,
                               controller: controller, cardId: cardId)
            return
        }
        entity.info.created = true
        
        switch value {
        case .play:
            if controller == eventHandler.player.id && cardId != "" {
                eventHandler.playerCreateInPlay(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            }
            if controller == eventHandler.opponent.id {
                eventHandler.opponentCreateInPlay(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            }
            
        case .deck:
            if controller == eventHandler.player.id && cardId != "" {
                if currentBlockCardId == CardIds.Collectible.Neutral.Overplanner {
                    eventHandler.dredgeCounter += 1
                    let newIndex = eventHandler.dredgeCounter
                    entity.info.deckIndex = newIndex
                }
                
                if eventHandler.joustReveals > 0 {
                    break
                }
                eventHandler.playerGetToDeck(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            }
            if controller == eventHandler.opponent.id {
                
                if eventHandler.joustReveals > 0 {
                    break
                }
                eventHandler.opponentGetToDeck(entity: entity, turn: eventHandler.turnNumber())
            }
            
        case .hand:
            if controller == eventHandler.player.id {
                eventHandler.playerGet(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentGet(entity: entity, turn: eventHandler.turnNumber(), id: id)
            }
            
        case .secret:
            if controller == eventHandler.player.id && cardId != "" {
                if let prevZone = Zone(rawValue: prevValue) {
                    eventHandler.playerSecretPlayed(entity: entity, cardId: cardId,
                                                    turn: eventHandler.turnNumber(), fromZone: prevZone, parentCardId: currentBlockCardId)
                }
            } else if controller == eventHandler.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    eventHandler.opponentSecretPlayed(entity: entity, cardId: cardId, from: -1,
                                              turn: eventHandler.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                    if powerGameStateParser?.getCurrentBlock()?.cardId == CardIds.Collectible.Neutral.GrandArchivist
                       && powerGameStateParser?.getCurrentBlock()?.entityDiscardedByArchivist != nil {
                        powerGameStateParser?.getCurrentBlock()?.entityDiscardedByArchivist?.cardId = entity.info.latestCardId
                    }
                }
            }
            
        case .setaside:
            if controller == eventHandler.player.id {
                eventHandler.playerCreateInSetAside(entity: entity, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentCreateInSetAside(entity: entity, turn: eventHandler.turnNumber())
                let currentBlock = powerGameStateParser?.currentBlock
                if currentBlock?.cardId == CardIds.Collectible.Neutral.GrandArchivist && currentBlock?.entityDiscardedByArchivist?.cardId != nil {
                    currentBlock?.entityDiscardedByArchivist?.cardId = entity.info.latestCardId
                }
            }
            
        default:
            break
        }
    }

    private func zoneChangeFromSecret(eventHandler: PowerEventHandler, id: Int, value: Int,
                                      prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value) else {
            return
        }
        guard eventHandler.entities[id] != nil else {
            return
        }
        
        switch zoneValue {
        case .secret, .graveyard:
            if controller == eventHandler.opponent.id {
                guard let entity = eventHandler.entities[id], let game = eventHandler as? Game else {
                    return
                }
                game.secretsManager?.removeSecret(entity: entity)
                game.updateTrackers()
            }
            
        case .setaside:
            if controller == eventHandler.opponent.id {
                guard let entity = eventHandler.entities[id] else {
                    return
                }
                eventHandler.handleOpponentSecretRemove(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            }
            
        default:
            break
        }
    }

    private func zoneChangeFromPlay(eventHandler: PowerEventHandler, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value) else {
            return
        }
        guard let entity = eventHandler.entities[id] else {
            return
        }

        switch zoneValue {
        case .hand:
            if controller == eventHandler.player.id && cardId != "" {
                eventHandler.playerBackToHand(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentPlayToHand(entity: entity, cardId: cardId,
                                        turn: eventHandler.turnNumber(), id: id)
            }
            
        case .deck:
            if controller == eventHandler.player.id && cardId != "" {
                eventHandler.playerPlayToDeck(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentPlayToDeck(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            }
            
        case .graveyard:
            if controller == eventHandler.player.id && cardId != "" {
                eventHandler.playerPlayToGraveyard(entity: entity, cardId: cardId, turn: eventHandler.turnNumber(), playersTurn: eventHandler.playerEntity?.isCurrentPlayer ?? false)
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentPlayToGraveyard(entity: entity, cardId: cardId,
                                                     turn: eventHandler.turnNumber(),
                                                     playersTurn: eventHandler.playerEntity?.isCurrentPlayer ?? false)
            }
            
        case .removedfromgame, .setaside:
            if controller == eventHandler.player.id {
                eventHandler.playerRemoveFromPlay(entity: entity, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentRemoveFromPlay(entity: entity, turn: eventHandler.turnNumber())
            }
            
        case .play:
            break
            
        default:
            break
        }
    }

    private func zoneChangeFromHand(eventHandler: PowerEventHandler, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value) else {
            return
        }
        guard let entity = eventHandler.entities[id] else {
            return
        }

        let currentBlockCardId = powerGameStateParser?.getCurrentBlock()?.cardId ?? ""
        let currentBlockType = powerGameStateParser?.getCurrentBlock()?.type ?? ""

        // When a card is moved from hand it is not relevant if it was mulliganed.
        // If not cleared, we may display mulliganed mark to cards if they return to hand.
        entity.info.mulliganed = false
        switch zoneValue {
        case .play where currentBlockType == "PLAY":
            eventHandler.lastCardPlayed = id
            if controller == eventHandler.player.id {
                if cardId != "" {
                    eventHandler.playerPlay(entity: entity, cardId: cardId, turn: eventHandler.turnNumber(), parentCardId: currentBlockCardId)
                }
                var magnetic = false
                if entity.isMinion {
                    if entity.has(tag: .modular) && (eventHandler.playerEntity?.isCurrentPlayer ?? false) {
                        let pos = entity[.zone_position]
                        let neighbour = eventHandler.player?.board.first { x in x[.zone_position] == pos + 1 }
                        magnetic = neighbour?.card.race == .mechanical
                    }
                    if !magnetic {
                        eventHandler.playerMinionPlayed(entity: entity)
                    }
                }
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentPlay(entity: entity, cardId: cardId, from: entity[.zone_position],
                                  turn: eventHandler.turnNumber())
            }
            
        case .play where currentBlockType != "PLAY":
            if controller == eventHandler.player.id {
                eventHandler.handlePlayerHandToPlay(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.handleOpponentHandToPlay(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            }
            
        case .removedfromgame, .setaside, .graveyard:
            if controller == eventHandler.player.id && cardId != "" {
                eventHandler.playerHandDiscard(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentHandDiscard(entity: entity, cardId: cardId,
                                         from: entity[.zone_position],
                                         turn: eventHandler.turnNumber())
            }
            
        case .secret:
            if controller == eventHandler.player.id && cardId != "" {
                if let prevZone = Zone(rawValue: prevValue) {
                    eventHandler.playerSecretPlayed(entity: entity, cardId: cardId,
                                                    turn: eventHandler.turnNumber(), fromZone: prevZone, parentCardId: currentBlockCardId)
                }
            } else if controller == eventHandler.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    eventHandler.opponentSecretPlayed(entity: entity, cardId: cardId,
                                              from: entity[.zone_position],
                                              turn: eventHandler.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                }
            }
            
        case .deck:
            if controller == eventHandler.player.id && cardId != "" {
                if eventHandler.playerEntity?[.mulligan_state] ?? 0 == Mulligan.done.rawValue {
                    eventHandler.handlePlayerHandToDeck(entity: entity, cardId: cardId)
                } else {
                    eventHandler.playerMulligan(entity: entity, cardId: cardId)
                }
            } else if controller == eventHandler.opponent.id {
                if cardId != "" {
                    eventHandler.opponentHandToDeck(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
                }
                if eventHandler.opponentEntity?[.mulligan_state] ?? 0 == Mulligan.dealing.rawValue {
                    eventHandler.opponentMulligan(entity: entity, from: entity[.zone_position])
                }
            }
            
        default:
            break
        }
    }

    private func zoneChangeFromDeck(eventHandler: PowerEventHandler, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value) else {
            return
        }
        guard let entity = eventHandler.entities[id] else {
            return
        }
        
        entity.info.deckIndex = 0
        
        let currentBlockCardId = powerGameStateParser?.getCurrentBlock()?.cardId ?? ""

        switch zoneValue {
        case .hand:
            if let cardId, cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_FrostPlagueToken || cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_BloodPlagueToken || cardId == CardIds.NonCollectible.Deathknight.DistressedKvaldir_UnholyPlagueToken {
                eventHandler.lastPlagueDrawn.push(cardId)
            }
            if controller == eventHandler.player.id && cardId != "" {
                eventHandler.playerDraw(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                let drawerCardId = currentBlockCardId
                var drawerId: Int?
                if drawerCardId != "" && (powerGameStateParser?.currentBlock?.parent == nil ||  !(powerGameStateParser?.currentBlock?.parent?.isTradeableAction ?? false)) {
                    drawerId = eventHandler.entities.first { (_, value) in value.cardId == drawerCardId }?.1.id
                }
                eventHandler.opponentDraw(entity: entity, turn: eventHandler.turnNumber(), cardId: cardId ?? "", drawerId: drawerId)
            }
            
        case .setaside, .removedfromgame:
            if !eventHandler.setupDone {
                entity.info.created = true
                return
            }
            if controller == eventHandler.player.id {
                if eventHandler.joustReveals > 0 {
                    eventHandler.joustReveals -= 1
                    break
                }
                eventHandler.playerRemoveFromDeck(entity: entity, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                if eventHandler.joustReveals > 0 {
                    eventHandler.joustReveals -= 1
                    break
                }
                if currentBlockCardId == CardIds.Collectible.Neutral.GrandArchivist {
                    powerGameStateParser?.getCurrentBlock()?.entityDiscardedByArchivist = entity
                }
                eventHandler.opponentRemoveFromDeck(entity: entity, turn: eventHandler.turnNumber())
            }
            
        case .graveyard:
            if currentBlockCardId != "" {
                if currentBlockCardId == TagChangeActions.ClassicTrackingCardId {
                    entity.info.hidden = true
                    entity[.zone] = Zone.deck.rawValue
                }
            }
            if controller == eventHandler.player.id && cardId != "" {
                eventHandler.playerDeckDiscard(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentDeckDiscard(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            }
            
        case .play:
            if controller == eventHandler.player.id {
                eventHandler.playerDeckToPlay(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            } else if controller == eventHandler.opponent.id {
                eventHandler.opponentDeckToPlay(entity: entity, cardId: cardId, turn: eventHandler.turnNumber())
            }
            
        case .secret:
            if controller == eventHandler.player.id && cardId != "" {
                if let prevZone = Zone(rawValue: prevValue) {
                    eventHandler.playerSecretPlayed(entity: entity, cardId: cardId,
                                                    turn: eventHandler.turnNumber(), fromZone: prevZone, parentCardId: currentBlockCardId)
                }
            } else if controller == eventHandler.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    eventHandler.opponentSecretPlayed(entity: entity, cardId: cardId,
                                              from: -1, turn: eventHandler.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                }
            }
            
        default:
            break
        }
    }

    // TODO: this is essentially blocking the global queue!
    private func setHeroAsync(eventHandler: PowerEventHandler, id: Int) {
        DispatchQueue.global().async {
            logger.info("Found hero with id \(id) ")
            if eventHandler.playerEntity == nil {
                logger.info("Waiting for playerEntity")
                while eventHandler.playerEntity == nil {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                logger.info("Found PlayerEntity")
            }

            if eventHandler.player.originalClass == nil, let playerEntity = eventHandler.playerEntity, id == playerEntity[.hero_entity] {
                guard let entity = eventHandler.entities[id] else { return }
                if entity.cardId != entity.info.latestCardId {
                    logger.warning("CardId Mismatch \(entity.cardId) vs \(entity.info.latestCardId)")
                }
                eventHandler.set(playerHero: entity.cardId)
                return
            }

            if eventHandler.opponentEntity == nil {
                logger.info("Waiting for opponentEntity")
                while eventHandler.opponentEntity == nil {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                logger.info("Found OpponentEntity")
            }
            if eventHandler.opponent.originalClass == nil, let opponentEntity = eventHandler.opponentEntity, id == opponentEntity[.hero_entity] {
                guard let entity = eventHandler.entities[id] else { return }

                if entity.cardId != entity.info.latestCardId {
                    logger.warning("CardId Mismatch \(entity.cardId) vs \(entity.info.latestCardId)")
                }
                eventHandler.set(opponentHero: entity.cardId)
                return
            }
        }
    }
    
    private func minionRevealed(eventHandler: PowerEventHandler, id: Int) {
        if let entity = eventHandler.entities[id] {
            AppDelegate.instance().coreManager.game.secretsManager?.onEntityRevealedAsMinion(entity: entity)
        }
    }
    
    private func onImmolateStage(eventHandler: PowerEventHandler, id: Int, value: Int) {
        let game = AppDelegate.instance().coreManager.game
        
        if value == 4, let entity = game.entities[id], entity.cardId != CardIds.NonCollectible.Neutral.TheCoinBasic {
            entity.clearCardId()
        }
    }
    
    private func onNextOpponentPlayerId(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if id != eventHandler.playerEntity?.id {
            return
        }
        OpponentDeadForTracker.setNextOpponentPlayerId(value)
    }

    private func playerTechLevel(eventHandler: PowerEventHandler, id: Int, value: Int, previous: Int) {
        if value != 0 && value > previous {
            if let entity = eventHandler.entities[id] {
                eventHandler.handlePlayerTechLevel(entity: entity, techLevel: value)
            }
        }
    }
    
    private func playerTriples(eventHandler: PowerEventHandler, id: Int, value: Int, previous: Int) {
        if value != 0 && value > previous {
            if let entity = eventHandler.entities[id] {
                eventHandler.handlePlayerTriples(entity: entity, triples: value - previous)
            }
        }
    }

    private func playerBuddiesGained(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value != 0 {
            if let entity = eventHandler.entities[id] {
                eventHandler.handlePlayerBuddiesGained(entity: entity, num: value)
            }
        }
    }
    
    private func playerHeroPowerQuestRewardDatabaseId(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value != 0 {
            if let entity = eventHandler.entities[id] {
                eventHandler.handlePlayerHeroPowerQuestRewardDatabaseId(entity: entity, num: value)
            }
        }
    }
    
    private func playerHeroPowerQuestRewardCompleted(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value != 0 {
            if let entity = eventHandler.entities[id] {
                eventHandler.handlePlayerHeroPowerQuestRewardCompleted(entity: entity, num: value)
            }
        }
    }
    
    private func playerHeroQuestRewardDatabaseId(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value != 0 {
            if let entity = eventHandler.entities[id] {
                eventHandler.handlePlayerHeroQuestRewardDatabaseId(entity: entity, num: value)
            }
        }
    }
    
    private func playerHeroQuestRewardCompleted(eventHandler: PowerEventHandler, id: Int, value: Int) {
        if value != 0 {
            if let entity = eventHandler.entities[id] {
                eventHandler.handlePlayerHeroQuestRewardCompleted(entity: entity, num: value)
            }
        }
    }
    
}

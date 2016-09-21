//
//  TagChanceActions.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct TagChangeActions {

    func callAction(game: Game, tag: GameTag, id: Int, value: Int, prevValue: Int) {
        switch tag {
        case .ZONE: self.zoneChange(game, id: id, value: value, prevValue: prevValue)
        case .PLAYSTATE: self.playstateChange(game, id: id, value: value)
        case .CARDTYPE: self.cardTypeChange(game, id: id, value: value)
        case .LAST_CARD_PLAYED: self.lastCardPlayedChange(game, value: value)
        case .DEFENDING: self.defendingChange(game, id: id, value: value)
        case .ATTACKING: self.attackingChange(game, id: id, value: value)
        case .PROPOSED_DEFENDER: self.proposedDefenderChange(game, value: value)
        case .PROPOSED_ATTACKER: self.proposedAttackerChange(game, value: value)
        case .NUM_MINIONS_PLAYED_THIS_TURN: self.numMinionsPlayedThisTurnChange(game, value: value)
        case .PREDAMAGE: self.predamageChange(game, id: id, value: value)
        case .NUM_TURNS_IN_PLAY: self.numTurnsInPlayChange(game, id: id, value: value)
        case .NUM_ATTACKS_THIS_TURN: self.numAttacksThisTurnChange(game, id: id, value: value)
        case .ZONE_POSITION: self.zonePositionChange(game, id: id)
        case .CARD_TARGET: self.cardTargetChange(game, id: id, value: value)
        case .EQUIPPED_WEAPON: self.equippedWeaponChange(game, id: id, value: value)
        case .EXHAUSTED: self.exhaustedChange(game, id: id, value: value)
        case .CONTROLLER: self.controllerChange(game, id: id, prevValue: prevValue, value: value)
        case .FATIGUE: self.fatigueChange(game, value: value, id: id)
        case .STEP: self.stepChange(game)
        case .TURN: self.turnChange(game)
        case .STATE: self.stateChange(game, value: value)
        default: break
        }
    }

    private func lastCardPlayedChange(game: Game, value: Int) {
        game.lastCardPlayed = value
    }

    private func defendingChange(game: Game, id: Int, value: Int) {
        guard let entity = game.entities[id] else { return }
        game.defendingEntity(value == 1 ? entity : nil)
    }

    private func attackingChange(game: Game, id: Int, value: Int) {
        guard let entity = game.entities[id] else { return }
        game.attackingEntity(value == 1 ? entity : nil)
    }

    private func proposedDefenderChange(game: Game, value: Int) {
        game.opponentSecrets?.proposedDefenderEntityId = value
    }

    private func proposedAttackerChange(game: Game, value: Int) {
        game.opponentSecrets?.proposedAttackerEntityId = value
    }

    private func numMinionsPlayedThisTurnChange(game: Game, value: Int) {
        guard value > 0 else { return }
        guard let playerEntity = game.playerEntity else { return }
        
        if playerEntity.isCurrentPlayer {
            game.playerMinionPlayed()
        }
    }

    private func predamageChange(game: Game, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let playerEntity = game.playerEntity, entity = game.entities[id] else { return }
        
        if playerEntity.isCurrentPlayer {
            game.opponentDamage(entity)
        }
    }

    private func numTurnsInPlayChange(game: Game, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = game.entities[id] else { return }
        
        game.turnsInPlayChange(entity, turn: game.turnNumber())
    }

    private func fatigueChange(game: Game, value: Int, id: Int) {
        guard let entity = game.entities[id] else { return }
        
        let controller = entity.getTag(.CONTROLLER)
        if controller == game.player.id {
            game.playerFatigue(value)
        } else if controller == game.opponent.id {
            game.opponentFatigue(value)
        }
    }

    private func controllerChange(game: Game, id: Int, prevValue: Int, value: Int) {
        guard let entity = game.entities[id] else { return }
        if prevValue <= 0 {
            entity.info.originalController = value
            return
        }
        
        guard !entity.hasTag(.PLAYER_ID) else { return }
        
        if value == game.player.id {
            if entity.isInZone(.SECRET) {
                game.opponentStolen(entity, cardId: entity.cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.SecretStolen, id: id, player: .Player)
            } else if entity.isInZone(.PLAY) {
                game.opponentStolen(entity, cardId: entity.cardId, turn: game.turnNumber())
            }
        } else if value == game.opponent.id {
            if entity.isInZone(.SECRET) {
                game.playerStolen(entity, cardId: entity.cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.SecretStolen, id: id, player: .Player)
            } else if entity.isInZone(.PLAY) {
                game.playerStolen(entity, cardId: entity.cardId, turn: game.turnNumber())
            }
        }
    }

    private func exhaustedChange(game: Game, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = game.entities[id] else { return }
        guard entity.getTag(.CARDTYPE) == CardType.HERO_POWER.rawValue else { return }
        
        let controller = entity.getTag(.CONTROLLER)
        if controller == game.player.id {
            game.proposeKeyPoint(.HeroPower, id: id, player: .Player)
        } else if controller == game.opponent.id {
            game.proposeKeyPoint(.HeroPower, id: id, player: .Opponent)
        }
    }

    private func equippedWeaponChange(game: Game, id: Int, value: Int) {
        guard value == 0 else { return }
        guard let entity = game.entities[id] else { return }
        
        let controller = entity.getTag(.CONTROLLER)
        if controller == game.player.id {
            game.proposeKeyPoint(.WeaponDestroyed, id: id, player: .Player)
        } else if controller == game.opponent.id {
            game.proposeKeyPoint(.WeaponDestroyed, id: id, player: .Opponent)
        }
    }

    private func cardTargetChange(game: Game, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = game.entities[id] else { return }
        
        let controller = entity.getTag(.CONTROLLER)
        if controller == game.player.id {
            game.proposeKeyPoint(.PlaySpell, id: id, player: .Player)
        } else if controller == game.opponent.id {
            game.proposeKeyPoint(.PlaySpell, id: id, player: .Opponent)
        }
    }

    private func zonePositionChange(game: Game, id: Int) {
        guard let entity = game.entities[id] else { return }
        
        let zone = entity.getTag(.ZONE)
        let controller = entity.getTag(.CONTROLLER)
        if zone == Zone.HAND.rawValue {
            if controller == game.player.id {
                ReplayMaker.generate(.HandPos, id: id, player: .Player, game: game)
            } else if controller == game.opponent.id {
                ReplayMaker.generate(.HandPos, id: id, player: .Opponent, game: game)
            }
        } else if zone == Zone.PLAY.rawValue {
            if controller == game.player.id {
                ReplayMaker.generate(.BoardPos, id: id, player: .Player, game: game)
            } else if controller == game.opponent.id {
                ReplayMaker.generate(.BoardPos, id: id, player: .Opponent, game: game)
            }
        }
    }

    private func numAttacksThisTurnChange(game: Game, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = game.entities[id] else { return }
        
        let controller = entity.getTag(.CONTROLLER)
        if controller == game.player.id {
            game.proposeKeyPoint(.Attack, id: id, player: .Player)
        } else if controller == game.opponent.id {
            game.proposeKeyPoint(.Attack, id: id, player: .Opponent)
        }
    }

    private func stateChange(game: Game, value: Int) {
        if value != State.COMPLETE.rawValue {
            return
        }
        game.gameEnd()
        game.gameEnded = true
    }

    private func turnChange(game: Game) {
        guard game.setupDone && game.playerEntity != nil else { return }
        guard let playerEntity = game.playerEntity else { return }

        let activePlayer: PlayerType = playerEntity.hasTag(.CURRENT_PLAYER) ? .Player : .Opponent
        
        if activePlayer == .Player {
            game.playerUsedHeroPower = false
        } else {
            game.opponentUsedHeroPower = false
        }
    }

    private func stepChange(game: Game) {
        guard !game.setupDone && game.entities.first?.1.name == "GameEntity" else { return }

        Log.info?.message("Game was already in progress.")
        // game.wasInProgress = true
    }

    private func cardTypeChange(game: Game, id: Int, value: Int) {
        if value == CardType.HERO.rawValue {
            setHeroAsync(game, id: id)
        }
    }

    private func playstateChange(game: Game, id: Int, value: Int) {
        if value == PlayState.CONCEDED.rawValue {
            game.concede()
        }

        guard !game.gameEnded else { return }

        if let entity = game.entities[id] where !entity.isPlayer {
            return
        }

        if let value = PlayState(rawValue: value) {
            switch value {
            case .WON:
                game.gameEndKeyPoint(true, id: id)
                game.win()
            case .LOST:
                game.gameEndKeyPoint(false, id: id)
                game.loss()
            case .TIED:
                game.gameEndKeyPoint(false, id: id)
                game.tied()
            default: break
            }
        }
    }

    private func zoneChange(game: Game, id: Int, value: Int, prevValue: Int) {
        guard id > 3 else { return }
        guard let entity = game.entities[id] else { return }
        
        if entity.info.originalZone == nil {
            if prevValue != Zone.INVALID.rawValue && prevValue != Zone.SETASIDE.rawValue {
                entity.info.originalZone = Zone(rawValue: prevValue)
            } else if value != Zone.INVALID.rawValue && value != Zone.SETASIDE.rawValue {
                entity.info.originalZone = Zone(rawValue: value)
            }
        }
        
        let controller = entity.getTag(.CONTROLLER)
        guard let zoneValue = Zone(rawValue: prevValue) else { return }
        
        switch zoneValue {
        case .DECK:
            zoneChangeFromDeck(game, id: id, value: value,
                               prevValue: prevValue,
                               controller: controller,
                               cardId: entity.cardId)
            
        case .HAND:
            zoneChangeFromHand(game, id: id, value: value,
                               prevValue: prevValue, controller: controller,
                               cardId: entity.cardId)
            
        case .PLAY:
            zoneChangeFromPlay(game, id: id, value: value,
                               prevValue: prevValue, controller: controller,
                               cardId: entity.cardId)
            
        case .SECRET:
            zoneChangeFromSecret(game, id: id, value: value,
                                 prevValue: prevValue, controller: controller,
                                 cardId: entity.cardId)
            
        case .INVALID:
            let maxId = getMaxHeroPowerId(game)
            if !game.setupDone
                && (id <= maxId || game.gameEntity?.getTag(.STEP) == Step.INVALID.rawValue
                    && entity.getTag(.ZONE_POSITION) < 5) {
                entity.info.originalZone = .DECK
                simulateZoneChangesFromDeck(game, id: id, value: value,
                                            cardId: entity.cardId, maxId: maxId)
            } else {
                zoneChangeFromOther(game, id: id, rawValue: value,
                                    prevValue: prevValue, controller: controller,
                                    cardId: entity.cardId)
            }
            
        case .GRAVEYARD, .SETASIDE, .REMOVEDFROMGAME:
            zoneChangeFromOther(game, id: id, rawValue: value, prevValue: prevValue,
                                controller: controller, cardId: entity.cardId)
        }
    }

    // The last heropower is created after the last hero, therefore +1
    private func getMaxHeroPowerId(game: Game) -> Int {
        return max(game.playerEntity?.getTag(.HERO_ENTITY) ?? 66,
                   game.opponentEntity?.getTag(.HERO_ENTITY) ?? 66) + 1
    }

    private func simulateZoneChangesFromDeck(game: Game, id: Int,
                                             value: Int, cardId: String?, maxId: Int) {
        if value == Zone.DECK.rawValue {
            return
        }
        
        guard let entity = game.entities[id] else { return }
        
        if value == Zone.SETASIDE.rawValue {
            entity.info.created = true
            return
        }
        
        if entity.isHero || entity.isHeroPower || entity.hasTag(.PLAYER_ID)
            || entity.getTag(.CARDTYPE) == CardType.GAME.rawValue || entity.hasTag(.CREATOR) {
            return
        }
        
        zoneChangeFromDeck(game, id: id, value: Zone.HAND.rawValue,
                           prevValue: Zone.DECK.rawValue,
                           controller: entity.getTag(.CONTROLLER), cardId: cardId)
        if value == Zone.HAND.rawValue {
            return
        }
        zoneChangeFromHand(game, id: id, value: Zone.PLAY.rawValue,
                           prevValue: Zone.HAND.rawValue,
                           controller: entity.getTag(.CONTROLLER), cardId: cardId)
        if value == Zone.PLAY.rawValue {
            return
        }
        zoneChangeFromPlay(game, id: id, value: value, prevValue: Zone.PLAY.rawValue,
                           controller: entity.getTag(.CONTROLLER), cardId: cardId)
    }

    private func zoneChangeFromOther(game: Game, id: Int, rawValue: Int,
                                     prevValue: Int, controller: Int, cardId: String?) {
        guard let value = Zone(rawValue: rawValue), entity = game.entities[id] else { return }

        if entity.info.originalZone == .DECK  && rawValue != Zone.DECK.rawValue {
            // This entity was moved from DECK to SETASIDE to HAND, e.g. by Tracking
            entity.info.discarded = false
            zoneChangeFromDeck(game, id: id, value: rawValue, prevValue: prevValue,
                               controller: controller, cardId: cardId)
            return
        }
        entity.info.created = true
        
        switch value {
        case .PLAY:
            if controller == game.player.id {
                game.playerCreateInPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.Summon, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentCreateInPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.Summon, id: id, player: .Opponent)
            }
            
        case .DECK:
            if controller == game.player.id {
                if game.joustReveals > 0 {
                    break
                }
                game.playerGetToDeck(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.CreateToDeck, id: id, player: .Player)
            }
            if controller == game.opponent.id {
                
                if game.joustReveals > 0 {
                    break
                }
                game.opponentGetToDeck(entity, turn: game.turnNumber())
                game.proposeKeyPoint(.CreateToDeck, id: id, player: .Opponent)
            }
            
        case .HAND:
            if controller == game.player.id {
                game.playerGet(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.Obtain, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentGet(entity, turn: game.turnNumber(), id: id)
                game.proposeKeyPoint(.Obtain, id: id, player: .Opponent)
            }
            
        case .SECRET:
            if controller == game.player.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.playerSecretPlayed(entity, cardId: cardId,
                                            turn: game.turnNumber(), fromZone: prevZone)
                }
                game.proposeKeyPoint(.SecretPlayed, id: id, player: .Player)
            } else if controller == game.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.opponentSecretPlayed(entity, cardId: cardId, from: -1,
                                              turn: game.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                }
                game.proposeKeyPoint(.SecretPlayed, id: id, player: .Opponent)
            }
            
        case .SETASIDE:
            if controller == game.player.id {
                game.playerCreateInSetAside(entity, turn: game.turnNumber())
            } else if controller == game.opponent.id {
                game.opponentCreateInSetAside(entity, turn: game.turnNumber())
            }
            
        default:
            // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
            break
        }
    }

    private func zoneChangeFromSecret(game: Game, id: Int, value: Int,
                                      prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value), entity = game.entities[id] else { return }
        
        switch zoneValue {
        case .SECRET, .GRAVEYARD:
            if controller == game.player.id {
                game.proposeKeyPoint(.SecretTriggered, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentSecretTrigger(entity, cardId: cardId,
                                           turn: game.turnNumber(), otherId: id)
                game.proposeKeyPoint(.SecretTriggered, id: id, player: .Opponent)
            }
            
        default:
            // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
            break
        }
    }

    private func zoneChangeFromPlay(game: Game, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value), entity = game.entities[id] else { return }
        
        switch zoneValue {
        case .HAND:
            if controller == game.player.id {
                game.playerBackToHand(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.PlayToHand, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentPlayToHand(entity, cardId: cardId, turn: game.turnNumber(), id: id)
                game.proposeKeyPoint(.PlayToHand, id: id, player: .Opponent)
            }
            
        case .DECK:
            if controller == game.player.id {
                game.playerPlayToDeck(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.PlayToDeck, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentPlayToDeck(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.PlayToDeck, id: id, player: .Opponent)
            }
            
        case .GRAVEYARD:
            if controller == game.player.id {
                game.playerPlayToGraveyard(entity, cardId: cardId, turn: game.turnNumber())
                if entity.hasTag(.HEALTH) {
                    game.proposeKeyPoint(.Death, id: id, player: .Player)
                }
            } else if controller == game.opponent.id {
                if let playerEntity = game.playerEntity {
                    game.opponentPlayToGraveyard(entity, cardId: cardId,
                                                 turn: game.turnNumber(),
                                                 playersTurn: playerEntity.isCurrentPlayer)
                }
                if entity.hasTag(.HEALTH) {
                    game.proposeKeyPoint(.Death, id: id, player: .Opponent)
                }
            }
            
        case .REMOVEDFROMGAME, .SETASIDE:
            if controller == game.player.id {
                game.playerRemoveFromPlay(entity, turn: game.turnNumber())
            } else if controller == game.opponent.id {
                game.opponentRemoveFromPlay(entity, turn: game.turnNumber())
            }
            
        case .PLAY:
            break
            
        default:
            // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
            break
        }
    }

    private func zoneChangeFromHand(game: Game, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value), entity = game.entities[id] else { return }
        
        switch zoneValue {
        case .PLAY:
            if controller == game.player.id {
                game.playerPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.Play, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentPlay(entity, cardId: cardId, from: entity.getTag(.ZONE_POSITION),
                                  turn: game.turnNumber())
                game.proposeKeyPoint(.Play, id: id, player: .Opponent)
            }
            
        case .REMOVEDFROMGAME, .SETASIDE, .GRAVEYARD:
            if controller == game.player.id {
                game.playerHandDiscard(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.HandDiscard, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentHandDiscard(entity, cardId: cardId,
                                         from: entity.getTag(.ZONE_POSITION),
                                         turn: game.turnNumber())
                game.proposeKeyPoint(.HandDiscard, id: id, player: .Opponent)
            }
            
        case .SECRET:
            if controller == game.player.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.playerSecretPlayed(entity, cardId: cardId,
                                            turn: game.turnNumber(), fromZone: prevZone)
                }
                game.proposeKeyPoint(.SecretPlayed, id: id, player: .Player)
            } else if controller == game.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.opponentSecretPlayed(entity, cardId: cardId,
                                              from: entity.getTag(.ZONE_POSITION),
                                              turn: game.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                }
                game.proposeKeyPoint(.SecretPlayed, id: id, player: .Opponent)
            }
            
        case .DECK:
            if controller == game.player.id {
                game.playerMulligan(entity, cardId: cardId)
                game.proposeKeyPoint(.Mulligan, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentMulligan(entity, from: entity.getTag(.ZONE_POSITION))
                game.proposeKeyPoint(.Mulligan, id: id, player: .Opponent)
            }
            
        default:
            // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
            break
        }
    }

    private func zoneChangeFromDeck(game: Game, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value), entity = game.entities[id] else { return }
        
        switch zoneValue {
        case .HAND:
            if controller == game.player.id {
                game.playerDraw(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.Draw, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentDraw(entity, turn: game.turnNumber())
                game.proposeKeyPoint(.Draw, id: id, player: .Opponent)
            }
            
        case .SETASIDE, .REMOVEDFROMGAME:
            if !game.setupDone {
                entity.info.created = true
                return
            }
            if controller == game.player.id {
                if game.joustReveals > 0 {
                    game.joustReveals -= 1
                    break
                }
                game.playerRemoveFromDeck(entity, turn: game.turnNumber())
            } else if controller == game.opponent.id {
                if game.joustReveals > 0 {
                    game.joustReveals -= 1
                    break
                }
                game.opponentRemoveFromDeck(entity, turn: game.turnNumber())
            }
            
        case .GRAVEYARD:
            if controller == game.player.id {
                game.playerDeckDiscard(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.DeckDiscard, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentDeckDiscard(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.DeckDiscard, id: id, player: .Opponent)
            }
            
        case .PLAY:
            if controller == game.player.id {
                game.playerDeckToPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.DeckDiscard, id: id, player: .Player)
            } else if controller == game.opponent.id {
                game.opponentDeckToPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.DeckDiscard, id: id, player: .Opponent)
            }
            
        case .SECRET:
            if controller == game.player.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.playerSecretPlayed(entity, cardId: cardId,
                                            turn: game.turnNumber(), fromZone: prevZone)
                }
                game.proposeKeyPoint(.SecretPlayed, id: id, player: .Player)
            } else if controller == game.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.opponentSecretPlayed(entity, cardId: cardId,
                                              from: -1, turn: game.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                }
                game.proposeKeyPoint(.SecretPlayed, id: id, player: .Opponent)
            }
            
        default:
            // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
            break
        }
    }

    private func setHeroAsync(game: Game, id: Int) {
        Log.info?.message("Found hero with id \(id) ")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if game.playerEntity == nil {
                Log.info?.message("Waiting for playerEntity")
                while game.playerEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
            }

            if let playerEntity = game.playerEntity,
                entity = game.entities[id] {
                // swiftlint:disable line_length
                Log.info?.message("playerEntity found playerClass : \(game.player.playerClass), \(id) -> \(playerEntity.getTag(.HERO_ENTITY)) -> \(entity) ")
                // swiftlint:enable line_length
                if game.player.playerClass == nil && id == playerEntity.getTag(.HERO_ENTITY) {
                    let cardId = entity.cardId
                    dispatch_async(dispatch_get_main_queue()) {
                        game.setPlayerHero(cardId)
                    }
                    return
                }
            }

            if game.opponentEntity == nil {
                Log.info?.message("Waiting for opponentEntity")
                while game.opponentEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
            }
            if let opponentEntity = game.opponentEntity,
                entity = game.entities[id] {
                // swiftlint:disable line_length
                Log.info?.message("opponentEntity found playerClass : \(game.opponent.playerClass), \(id) -> \(opponentEntity.getTag(.HERO_ENTITY)) -> \(entity) ")
                // swiftlint:enable line_length

                if game.opponent.playerClass == nil
                    && id == opponentEntity.getTag(.HERO_ENTITY) {
                    let cardId = entity.cardId
                    dispatch_async(dispatch_get_main_queue()) {
                        game.setOpponentHero(cardId)
                    }
                    return
                }
            }
        }
    }
}

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
        case .zone: self.zoneChange(game, id: id, value: value, prevValue: prevValue)
        case .playstate: self.playstateChange(game, id: id, value: value)
        case .cardtype: self.cardTypeChange(game, id: id, value: value)
        case .last_card_played: self.lastCardPlayedChange(game, value: value)
        case .defending: self.defendingChange(game, id: id, value: value)
        case .attacking: self.attackingChange(game, id: id, value: value)
        case .proposed_defender: self.proposedDefenderChange(game, value: value)
        case .proposed_attacker: self.proposedAttackerChange(game, value: value)
        case .num_minions_played_this_turn: self.numMinionsPlayedThisTurnChange(game, value: value)
        case .predamage: self.predamageChange(game, id: id, value: value)
        case .num_turns_in_play: self.numTurnsInPlayChange(game, id: id, value: value)
        case .num_attacks_this_turn: self.numAttacksThisTurnChange(game, id: id, value: value)
        case .zone_position: self.zonePositionChange(game, id: id)
        case .card_target: self.cardTargetChange(game, id: id, value: value)
        case .equipped_weapon: self.equippedWeaponChange(game, id: id, value: value)
        case .exhausted: self.exhaustedChange(game, id: id, value: value)
        case .controller: self.controllerChange(game, id: id, prevValue: prevValue, value: value)
        case .fatigue: self.fatigueChange(game, value: value, id: id)
        case .step: self.stepChange(game)
        case .turn: self.turnChange(game)
        case .state: self.stateChange(game, value: value)
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
        guard let playerEntity = game.playerEntity, let entity = game.entities[id] else { return }
        
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
        
        let controller = entity[.controller]
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
        
        guard !entity.has(tag: .player_id) else { return }
        
        if value == game.player.id {
            if entity.isInZone(.secret) {
                game.opponentStolen(entity, cardId: entity.cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.secretStolen, id: id, player: .player)
            } else if entity.isInZone(.play) {
                game.opponentStolen(entity, cardId: entity.cardId, turn: game.turnNumber())
            }
        } else if value == game.opponent.id {
            if entity.isInZone(.secret) {
                game.playerStolen(entity, cardId: entity.cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.secretStolen, id: id, player: .player)
            } else if entity.isInZone(.play) {
                game.playerStolen(entity, cardId: entity.cardId, turn: game.turnNumber())
            }
        }
    }

    private func exhaustedChange(game: Game, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = game.entities[id] else { return }
        guard entity[.cardtype] == CardType.hero_power.rawValue else { return }
        
        let controller = entity[.controller]
        if controller == game.player.id {
            game.proposeKeyPoint(.heroPower, id: id, player: .player)
        } else if controller == game.opponent.id {
            game.proposeKeyPoint(.heroPower, id: id, player: .opponent)
        }
    }

    private func equippedWeaponChange(game: Game, id: Int, value: Int) {
        guard value == 0 else { return }
        guard let entity = game.entities[id] else { return }
        
        let controller = entity[.controller]
        if controller == game.player.id {
            game.proposeKeyPoint(.weaponDestroyed, id: id, player: .player)
        } else if controller == game.opponent.id {
            game.proposeKeyPoint(.weaponDestroyed, id: id, player: .opponent)
        }
    }

    private func cardTargetChange(game: Game, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = game.entities[id] else { return }
        
        let controller = entity[.controller]
        if controller == game.player.id {
            game.proposeKeyPoint(.playSpell, id: id, player: .player)
        } else if controller == game.opponent.id {
            game.proposeKeyPoint(.playSpell, id: id, player: .opponent)
        }
    }

    private func zonePositionChange(game: Game, id: Int) {
        guard let entity = game.entities[id] else { return }
        
        let zone = entity[.zone]
        let controller = entity[.controller]
        if zone == Zone.hand.rawValue {
            if controller == game.player.id {
                ReplayMaker.generate(.handPos, id: id, player: .player, game: game)
            } else if controller == game.opponent.id {
                ReplayMaker.generate(.handPos, id: id, player: .opponent, game: game)
            }
        } else if zone == Zone.play.rawValue {
            if controller == game.player.id {
                ReplayMaker.generate(.boardPos, id: id, player: .player, game: game)
            } else if controller == game.opponent.id {
                ReplayMaker.generate(.boardPos, id: id, player: .opponent, game: game)
            }
        }
    }

    private func numAttacksThisTurnChange(game: Game, id: Int, value: Int) {
        guard value > 0 else { return }
        guard let entity = game.entities[id] else { return }
        
        let controller = entity[.controller]
        if controller == game.player.id {
            game.proposeKeyPoint(.attack, id: id, player: .player)
        } else if controller == game.opponent.id {
            game.proposeKeyPoint(.attack, id: id, player: .opponent)
        }
    }

    private func stateChange(game: Game, value: Int) {
        if value != State.complete.rawValue {
            return
        }
        game.gameEnd()
        game.gameEnded = true
    }

    private func turnChange(game: Game) {
        guard game.setupDone && game.playerEntity != nil else { return }
        guard let playerEntity = game.playerEntity else { return }

        let activePlayer: PlayerType = playerEntity.has(tag: .current_player) ? .player : .opponent
        
        if activePlayer == .player {
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
        if value == CardType.hero.rawValue {
            setHeroAsync(game, id: id)
        }
    }

    private func playstateChange(game: Game, id: Int, value: Int) {
        if value == PlayState.conceded.rawValue {
            game.concede()
        }

        guard !game.gameEnded else { return }

        if let entity = game.entities[id] where !entity.isPlayer {
            return
        }

        if let value = PlayState(rawValue: value) {
            switch value {
            case .won:
                game.gameEndKeyPoint(true, id: id)
                game.win()
            case .lost:
                game.gameEndKeyPoint(false, id: id)
                game.loss()
            case .tied:
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
            if prevValue != Zone.invalid.rawValue && prevValue != Zone.setaside.rawValue {
                entity.info.originalZone = Zone(rawValue: prevValue)
            } else if value != Zone.invalid.rawValue && value != Zone.setaside.rawValue {
                entity.info.originalZone = Zone(rawValue: value)
            }
        }
        
        let controller = entity[.controller]
        guard let zoneValue = Zone(rawValue: prevValue) else { return }
        
        switch zoneValue {
        case .deck:
            zoneChangeFromDeck(game, id: id, value: value,
                               prevValue: prevValue,
                               controller: controller,
                               cardId: entity.cardId)
            
        case .hand:
            zoneChangeFromHand(game, id: id, value: value,
                               prevValue: prevValue, controller: controller,
                               cardId: entity.cardId)
            
        case .play:
            zoneChangeFromPlay(game, id: id, value: value,
                               prevValue: prevValue, controller: controller,
                               cardId: entity.cardId)
            
        case .secret:
            zoneChangeFromSecret(game, id: id, value: value,
                                 prevValue: prevValue, controller: controller,
                                 cardId: entity.cardId)
            
        case .invalid:
            let maxId = getMaxHeroPowerId(game)
            if !game.setupDone
                && (id <= maxId || game.gameEntity?[.step] == Step.invalid.rawValue
                    && entity[.zone_position] < 5) {
                entity.info.originalZone = .deck
                simulateZoneChangesFromDeck(game, id: id, value: value,
                                            cardId: entity.cardId, maxId: maxId)
            } else {
                zoneChangeFromOther(game, id: id, rawValue: value,
                                    prevValue: prevValue, controller: controller,
                                    cardId: entity.cardId)
            }
            
        case .graveyard, .setaside, .removedfromgame:
            zoneChangeFromOther(game, id: id, rawValue: value, prevValue: prevValue,
                                controller: controller, cardId: entity.cardId)
        }
    }

    // The last heropower is created after the last hero, therefore +1
    private func getMaxHeroPowerId(game: Game) -> Int {
        return max(game.playerEntity?[.hero_entity] ?? 66,
                   game.opponentEntity?[.hero_entity] ?? 66) + 1
    }

    private func simulateZoneChangesFromDeck(game: Game, id: Int,
                                             value: Int, cardId: String?, maxId: Int) {
        if value == Zone.deck.rawValue {
            return
        }
        
        guard let entity = game.entities[id] else { return }
        
        if value == Zone.setaside.rawValue {
            entity.info.created = true
            return
        }
        
        if entity.isHero || entity.isHeroPower || entity.has(tag: .player_id)
            || entity[.cardtype] == CardType.game.rawValue || entity.has(tag: .creator) {
            return
        }
        
        zoneChangeFromDeck(game, id: id, value: Zone.hand.rawValue,
                           prevValue: Zone.deck.rawValue,
                           controller: entity[.controller], cardId: cardId)
        if value == Zone.hand.rawValue {
            return
        }
        zoneChangeFromHand(game, id: id, value: Zone.play.rawValue,
                           prevValue: Zone.hand.rawValue,
                           controller: entity[.controller], cardId: cardId)
        if value == Zone.play.rawValue {
            return
        }
        zoneChangeFromPlay(game, id: id, value: value, prevValue: Zone.play.rawValue,
                           controller: entity[.controller], cardId: cardId)
    }

    private func zoneChangeFromOther(game: Game, id: Int, rawValue: Int,
                                     prevValue: Int, controller: Int, cardId: String?) {
        guard let value = Zone(rawValue: rawValue), entity = game.entities[id] else { return }

        if entity.info.originalZone == .deck  && rawValue != Zone.deck.rawValue {
            // This entity was moved from DECK to SETASIDE to HAND, e.g. by Tracking
            entity.info.discarded = false
            zoneChangeFromDeck(game, id: id, value: rawValue, prevValue: prevValue,
                               controller: controller, cardId: cardId)
            return
        }
        entity.info.created = true
        
        switch value {
        case .play:
            if controller == game.player.id {
                game.playerCreateInPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.summon, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentCreateInPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.summon, id: id, player: .opponent)
            }
            
        case .deck:
            if controller == game.player.id {
                if game.joustReveals > 0 {
                    break
                }
                game.playerGetToDeck(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.createToDeck, id: id, player: .player)
            } else if controller == game.opponent.id {
                if game.joustReveals > 0 {
                    break
                }
                game.opponentGetToDeck(entity, turn: game.turnNumber())
                game.proposeKeyPoint(.createToDeck, id: id, player: .opponent)
            }
            
        case .hand:
            if controller == game.player.id {
                game.playerGet(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.obtain, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentGet(entity, turn: game.turnNumber(), id: id)
                game.proposeKeyPoint(.obtain, id: id, player: .opponent)
            }
            
        case .secret:
            if controller == game.player.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.playerSecretPlayed(entity, cardId: cardId,
                                            turn: game.turnNumber(), fromZone: prevZone)
                }
                game.proposeKeyPoint(.secretPlayed, id: id, player: .player)
            } else if controller == game.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.opponentSecretPlayed(entity, cardId: cardId, from: -1,
                                              turn: game.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                }
                game.proposeKeyPoint(.secretPlayed, id: id, player: .opponent)
            }
            
        case .setaside:
            if controller == game.player.id {
                game.playerCreateInSetAside(entity, turn: game.turnNumber())
            } else if controller == game.opponent.id {
                game.opponentCreateInSetAside(entity, turn: game.turnNumber())
            }
            
        default:
            break
        }
    }

    private func zoneChangeFromSecret(game: Game, id: Int, value: Int,
                                      prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value), entity = game.entities[id] else { return }
        
        switch zoneValue {
        case .secret, .graveyard:
            if controller == game.player.id {
                game.proposeKeyPoint(.secretTriggered, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentSecretTrigger(entity, cardId: cardId,
                                           turn: game.turnNumber(), otherId: id)
                game.proposeKeyPoint(.secretTriggered, id: id, player: .opponent)
            }
            
        default:
            break
        }
    }

    private func zoneChangeFromPlay(game: Game, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value), entity = game.entities[id] else { return }
        
        switch zoneValue {
        case .hand:
            if controller == game.player.id {
                game.playerBackToHand(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.playToHand, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentPlayToHand(entity, cardId: cardId, turn: game.turnNumber(), id: id)
                game.proposeKeyPoint(.playToHand, id: id, player: .opponent)
            }
            
        case .deck:
            if controller == game.player.id {
                game.playerPlayToDeck(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.playToDeck, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentPlayToDeck(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.playToDeck, id: id, player: .opponent)
            }
            
        case .graveyard:
            if controller == game.player.id {
                game.playerPlayToGraveyard(entity, cardId: cardId, turn: game.turnNumber())
                if entity.has(tag: .health) {
                    game.proposeKeyPoint(.death, id: id, player: .player)
                }
            } else if controller == game.opponent.id {
                if let playerEntity = game.playerEntity {
                    game.opponentPlayToGraveyard(entity, cardId: cardId,
                                                 turn: game.turnNumber(),
                                                 playersTurn: playerEntity.isCurrentPlayer)
                }
                if entity.has(tag: .health) {
                    game.proposeKeyPoint(.death, id: id, player: .opponent)
                }
            }
            
        case .removedfromgame, .setaside:
            if controller == game.player.id {
                game.playerRemoveFromPlay(entity, turn: game.turnNumber())
            } else if controller == game.opponent.id {
                game.opponentRemoveFromPlay(entity, turn: game.turnNumber())
            }
            
        case .play:
            break
            
        default:
            break
        }
    }

    private func zoneChangeFromHand(game: Game, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value), entity = game.entities[id] else { return }
        
        switch zoneValue {
        case .play:
            if controller == game.player.id {
                game.playerPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.play, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentPlay(entity, cardId: cardId, from: entity[.zone_position],
                                  turn: game.turnNumber())
                game.proposeKeyPoint(.play, id: id, player: .opponent)
            }
            
        case .removedfromgame, .setaside, .graveyard:
            if controller == game.player.id {
                game.playerHandDiscard(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.handDiscard, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentHandDiscard(entity, cardId: cardId,
                                         from: entity[.zone_position],
                                         turn: game.turnNumber())
                game.proposeKeyPoint(.handDiscard, id: id, player: .opponent)
            }
            
        case .secret:
            if controller == game.player.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.playerSecretPlayed(entity, cardId: cardId,
                                            turn: game.turnNumber(), fromZone: prevZone)
                }
                game.proposeKeyPoint(.secretPlayed, id: id, player: .player)
            } else if controller == game.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.opponentSecretPlayed(entity, cardId: cardId,
                                              from: entity[.zone_position],
                                              turn: game.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                }
                game.proposeKeyPoint(.secretPlayed, id: id, player: .opponent)
            }
            
        case .deck:
            if controller == game.player.id {
                game.playerMulligan(entity, cardId: cardId)
                game.proposeKeyPoint(.mulligan, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentMulligan(entity, from: entity[.zone_position])
                game.proposeKeyPoint(.mulligan, id: id, player: .opponent)
            }
            
        default:
            break
        }
    }

    private func zoneChangeFromDeck(game: Game, id: Int, value: Int,
                                    prevValue: Int, controller: Int, cardId: String?) {
        guard let zoneValue = Zone(rawValue: value), entity = game.entities[id] else { return }
        
        switch zoneValue {
        case .hand:
            if controller == game.player.id {
                game.playerDraw(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.draw, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentDraw(entity, turn: game.turnNumber())
                game.proposeKeyPoint(.draw, id: id, player: .opponent)
            }
            
        case .setaside, .removedfromgame:
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
            
        case .graveyard:
            if controller == game.player.id {
                game.playerDeckDiscard(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.deckDiscard, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentDeckDiscard(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.deckDiscard, id: id, player: .opponent)
            }
            
        case .play:
            if controller == game.player.id {
                game.playerDeckToPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.deckDiscard, id: id, player: .player)
            } else if controller == game.opponent.id {
                game.opponentDeckToPlay(entity, cardId: cardId, turn: game.turnNumber())
                game.proposeKeyPoint(.deckDiscard, id: id, player: .opponent)
            }
            
        case .secret:
            if controller == game.player.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.playerSecretPlayed(entity, cardId: cardId,
                                            turn: game.turnNumber(), fromZone: prevZone)
                }
                game.proposeKeyPoint(.secretPlayed, id: id, player: .player)
            } else if controller == game.opponent.id {
                if let prevZone = Zone(rawValue: prevValue) {
                    game.opponentSecretPlayed(entity, cardId: cardId,
                                              from: -1, turn: game.turnNumber(),
                                              fromZone: prevZone, otherId: id)
                }
                game.proposeKeyPoint(.secretPlayed, id: id, player: .opponent)
            }
            
        default:
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
                Log.info?.message("playerEntity found playerClass : \(game.player.playerClass), \(id) -> \(playerEntity[.hero_entity]) -> \(entity) ")
                // swiftlint:enable line_length
                if game.player.playerClass == nil && id == playerEntity[.hero_entity] {
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
                Log.info?.message("opponentEntity found playerClass : \(game.opponent.playerClass), \(id) -> \(opponentEntity[.hero_entity]) -> \(entity) ")
                // swiftlint:enable line_length

                if game.opponent.playerClass == nil
                    && id == opponentEntity[.hero_entity] {
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

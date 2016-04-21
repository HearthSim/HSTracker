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

    func callAction(tag: GameTag, _ game: Game, _ id: Int, _ value: Int, _ prevValue: Int) {
        //print("callAction tag:\(tag), id:\(id), value:\(value), prevValue:\(prevValue)")
        switch tag {
        case .ZONE: self.zoneChange(game, id, value, prevValue)
        case .PLAYSTATE: self.playstateChange(game, id, value)
        case .CARDTYPE: self.cardTypeChange(game, id, value)
        case .LAST_CARD_PLAYED: self.lastCardPlayedChange(game, value)
        case .DEFENDING: self.defendingChange(game, id, value)
        case .ATTACKING: self.attackingChange(game, id, value)
        case .PROPOSED_DEFENDER: self.proposedDefenderChange(game, value)
        case .PROPOSED_ATTACKER: self.proposedAttackerChange(game, value)
        case .NUM_MINIONS_PLAYED_THIS_TURN: self.numMinionsPlayedThisTurnChange(game, value)
        case .PREDAMAGE: self.predamageChange(game, id, value)
        case .NUM_TURNS_IN_PLAY: self.numTurnsInPlayChange(game, id, value)
        case .NUM_ATTACKS_THIS_TURN: self.numAttacksThisTurnChange(game, id, value)
        case .ZONE_POSITION: self.zonePositionChange(game, id)
        case .CARD_TARGET: self.cardTargetChange(game, id, value)
        case .EQUIPPED_WEAPON: self.equippedWeaponChange(game, id, value)
        case .EXHAUSTED: self.exhaustedChange(game, id, value)
        case .CONTROLLER: self.controllerChange(game, id, prevValue, value)
        case .FATIGUE: self.fatigueChange(game, value, id)
        case .STEP: self.stepChange(game)
        case .TURN: self.turnChange(game)
        default: break
        }
    }

    private func lastCardPlayedChange(game: Game, _ value: Int) {
        game.lastCardPlayed = value
    }

    private func defendingChange(game: Game, _ id: Int, _ value: Int) {
        game.defendingEntity(value == 1 ? game.entities[id] : nil)
    }

    private func attackingChange(game: Game, _ id: Int, _ value: Int) {
        game.attackingEntity(value == 1 ? game.entities[id] : nil)
    }

    private func proposedDefenderChange(game: Game, _ value: Int) {
        game.opponentSecrets?.proposedDefenderEntityId = value
    }

    private func proposedAttackerChange(game: Game, _ value: Int) {
        game.opponentSecrets?.proposedAttackerEntityId = value
    }

    private func numMinionsPlayedThisTurnChange(game: Game, _ value: Int) {
        guard value > 0 else { return }
        
        if let playerEntity = game.playerEntity where playerEntity.isCurrentPlayer {
            game.playerMinionPlayed()
        }
    }

    private func predamageChange(game: Game, _ id: Int, _ value: Int) {
        guard value > 0 else { return }
        
        if let playerEntity = game.playerEntity, let entity = game.entities[id] where playerEntity.isCurrentPlayer {
            game.opponentDamage(entity)
        }
    }

    private func numTurnsInPlayChange(game: Game, _ id: Int, _ value: Int) {
        guard value > 0 else { return }

        if let opponentEntity = game.opponentEntity, let entity = game.entities[id] where opponentEntity.isCurrentPlayer {
            game.opponentTurnStart(entity)
        }
    }

    private func fatigueChange(game: Game, _ value: Int, _ id: Int) {
        if let entity = game.entities[id] {
            let controller = entity.getTag(.CONTROLLER)
            if controller == game.player.id {
                game.playerFatigue(value)
            }
            else if controller == game.opponent.id {
                game.opponentFatigue(value)
            }
        }
    }

    private func controllerChange(game: Game, _ id: Int, _ prevValue: Int, _ value: Int) {
        if let entity = game.entities[id] {
            if prevValue <= 0 {
                entity.info.originalController = value
                return
            }
            
            guard !entity.hasTag(.PLAYER_ID) else { return }

            if value == game.player.id {
                if entity.isInZone(.SECRET) {
                    game.opponentStolen(entity, entity.cardId, game.turnNumber())
                    game.proposeKeyPoint(.SecretStolen, id, .Player)
                }
                else if entity.isInZone(.PLAY) {
                    game.opponentStolen(entity, entity.cardId, game.turnNumber())
                }
            }
            else if value == game.opponent.id {
                if entity.isInZone(.SECRET) {
                    game.playerStolen(entity, entity.cardId, game.turnNumber())
                    game.proposeKeyPoint(.SecretStolen, id, .Player)
                }
                else if entity.isInZone(.PLAY) {
                    game.playerStolen(entity, entity.cardId, game.turnNumber())
                }
            }
        }
    }

    private func exhaustedChange(game: Game, _ id: Int, _ value: Int) {
        guard value > 0 else { return }

        if let entity = game.entities[id] {
            guard entity.getTag(.CARDTYPE) == CardType.HERO_POWER.rawValue else { return }
            
            let controller = entity.getTag(.CONTROLLER)
            if controller == game.player.id {
                game.proposeKeyPoint(.HeroPower, id, .Player)
            }
            else if controller == game.opponent.id {
                game.proposeKeyPoint(.HeroPower, id, .Opponent)
            }
        }
    }

    private func equippedWeaponChange(game: Game, _ id: Int, _ value: Int) {
        guard value == 0 else { return }
        
        if let entity = game.entities[id] {
            let controller = entity.getTag(.CONTROLLER)
            if controller == game.player.id {
                game.proposeKeyPoint(.WeaponDestroyed, id, .Player)
            }
            else if controller == game.opponent.id {
                game.proposeKeyPoint(.WeaponDestroyed, id, .Opponent)
            }
        }
    }

    private func cardTargetChange(game: Game, _ id: Int, _ value: Int) {
        guard value > 0 else { return }
        
        if let entity = game.entities[id] {
            let controller = entity.getTag(.CONTROLLER)
            if controller == game.player.id {
                game.proposeKeyPoint(.PlaySpell, id, .Player)
            }
            else if controller == game.opponent.id {
                game.proposeKeyPoint(.PlaySpell, id, .Opponent)
            }
        }
    }

    private func zonePositionChange(game: Game, _ id: Int) {
        if let entity = game.entities[id] {
            let zone = entity.getTag(.ZONE)
            let controller = entity.getTag(.CONTROLLER)
            if zone == Zone.HAND.rawValue {
                if controller == game.player.id {
                    ReplayMaker.generate(.HandPos, id, .Player, game)
                }
                else if controller == game.opponent.id {
                    ReplayMaker.generate(.HandPos, id, .Opponent, game)
                }
            }
            else if zone == Zone.PLAY.rawValue
            {
                if controller == game.player.id {
                    ReplayMaker.generate(.BoardPos, id, .Player, game)
                }
                else if controller == game.opponent.id {
                    ReplayMaker.generate(.BoardPos, id, .Opponent, game)
                }
            }
        }
    }

    private func numAttacksThisTurnChange(game: Game, _ id: Int, _ value: Int) {
        guard value > 0 else { return }

        if let entity = game.entities[id] {
            let controller = entity.getTag(.CONTROLLER)
            if controller == game.player.id {
                game.proposeKeyPoint(.Attack, id, .Player)
            }
            else if controller == game.opponent.id {
                game.proposeKeyPoint(.Attack, id, .Opponent)
            }
        }
    }

    private func turnChange(game: Game) {
        guard game.setupDone && game.playerEntity != nil else { return }
        
        if let playerEntity = game.playerEntity {
            let activePlayer: PlayerType = playerEntity.hasTag(.CURRENT_PLAYER) ? .Player : .Opponent
            game.turnStart(activePlayer, game.turnNumber())

            if activePlayer == .Player {
                game.playerUsedHeroPower = false
            }
            else {
                game.opponentUsedHeroPower = false
            }
        }
    }

    private func stepChange(game: Game) {
        guard !game.setupDone && game.entities.first?.1.name == "GameEntity" else { return }

        Log.info?.message("Game was already in progress.")
        // game.wasInProgress = true
    }

    private func cardTypeChange(game: Game, _ id: Int, _ value: Int) {
        if value == CardType.HERO.rawValue {
            setHeroAsync(game, id)
        }
    }

    private func playstateChange(game: Game, _ id: Int, _ value: Int) {
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
                game.gameEndKeyPoint(true, id)
                game.win()
                game.gameEnd()
                game.gameEnded = true

            case .LOST:
                game.gameEndKeyPoint(false, id)
                game.loss()
                game.gameEnd()
                game.gameEnded = true

            case .TIED:
                game.gameEndKeyPoint(false, id)
                game.tied()
                game.gameEnd()

            default: break
            }
        }
    }

    private func zoneChange(game: Game, _ id: Int, _ value: Int, _ prevValue: Int) {
        if let entity = game.entities[id] {
            let controller = entity.getTag(.CONTROLLER)
            if let zoneValue = Zone(rawValue: prevValue) {
                switch zoneValue {
                case .DECK:
                    zoneChangeFromDeck(game, id, value, prevValue, controller, entity.cardId)

                case .HAND:
                    zoneChangeFromHand(game, id, value, prevValue, controller, entity.cardId)

                case .PLAY:
                    zoneChangeFromPlay(game, id, value, prevValue, controller, entity.cardId)

                case .SECRET:
                    zoneChangeFromSecret(game, id, value, prevValue, controller, entity.cardId)

                case .CREATED:
                    let maxId = getMaxHeroPowerId(game)
                    if !game.setupDone && id <= maxId {
                        simulateZoneChangesFromDeck(game, id, value, entity.cardId, maxId)
                    }
                    else {
                        zoneChangeFromOther(game, id, value, prevValue, controller, entity.cardId)
                    }

                case .GRAVEYARD, .SETASIDE, .INVALID, .REMOVEDFROMGAME:
                    zoneChangeFromOther(game, id, value, prevValue, controller, entity.cardId)
                }
            }
        }
    }
    
    // The last heropower is created after the last hero, therefore +1
    private func getMaxHeroPowerId(game: Game) -> Int {
        return max(game.playerEntity?.getTag(.HERO_ENTITY) ?? 66, game.opponentEntity?.getTag(.HERO_ENTITY) ?? 66) + 1
    }

    private func simulateZoneChangesFromDeck(game: Game, _ id: Int, _ value: Int, _ cardId: String?, _ maxId: Int) {
        if value == Zone.DECK.rawValue {
            return
        }
        if let entity = game.entities[id] {
            if value == Zone.SETASIDE.rawValue {
                entity.info.created = true
                return
            }
            
            if entity.isHero || entity.isHeroPower || entity.hasTag(.PLAYER_ID) || entity.getTag(.CARDTYPE) == CardType.GAME.rawValue || entity.hasTag(.CREATOR) {
                return
            }
            
            zoneChangeFromDeck(game, id, Zone.HAND.rawValue, Zone.DECK.rawValue, entity.getTag(.CONTROLLER), cardId)
            if value == Zone.HAND.rawValue {
                return
            }
            zoneChangeFromHand(game, id, Zone.PLAY.rawValue, Zone.HAND.rawValue, entity.getTag(.CONTROLLER), cardId)
            if value == Zone.PLAY.rawValue {
                return
            }
            zoneChangeFromPlay(game, id, value, Zone.PLAY.rawValue, entity.getTag(.CONTROLLER), cardId)
        }
    }

    private func zoneChangeFromOther(game: Game, _ id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        if let value = Zone(rawValue: value), entity = game.entities[id] {
            //print("**** CHANGE \(value), entity \(entity), controller: \(controller), playerId: \(game.player.id), opponentId: \(game.opponent.id)")
            entity.info.created = true
            
            switch value {
            case .PLAY:
                if controller == game.player.id {
                    game.playerCreateInPlay(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.Summon, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentCreateInPlay(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.Summon, id, .Opponent)
                }

            case .DECK:
                if controller == game.player.id {
                    if game.joustReveals > 0 {
                        break
                    }
                    game.playerGetToDeck(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.CreateToDeck, id, .Player)
                }
                if controller == game.opponent.id {

                    if game.joustReveals > 0 {
                        break
                    }
                    game.opponentGetToDeck(entity, game.turnNumber())
                    game.proposeKeyPoint(.CreateToDeck, id, .Opponent)
                }

            case .HAND:
                if controller == game.player.id {
                    game.playerGet(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.Obtain, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentGet(entity, game.turnNumber(), id)
                    game.proposeKeyPoint(.Obtain, id, .Opponent)
                }

            default:
                // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
                break
            }
        }
    }

    private func zoneChangeFromSecret(game: Game, _ id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        if let zoneValue = Zone(rawValue: value), let entity = game.entities[id] {
            switch zoneValue {
            case .SECRET, .GRAVEYARD:
                if controller == game.player.id {
                    game.proposeKeyPoint(.SecretTriggered, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentSecretTrigger(entity, cardId, game.turnNumber(), id)
                    game.proposeKeyPoint(.SecretTriggered, id, .Opponent)
                }

            default:
                // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
                break
            }
        }
    }

    private func zoneChangeFromPlay(game: Game, _ id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        if let zoneValue = Zone(rawValue: value), let entity = game.entities[id] {
            switch zoneValue {
            case .HAND:
                if controller == game.player.id {
                    game.playerBackToHand(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.PlayToHand, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentPlayToHand(entity, cardId, game.turnNumber(), id)
                    game.proposeKeyPoint(.PlayToHand, id, .Opponent)
                }

            case .DECK:
                if controller == game.player.id {
                    game.playerPlayToDeck(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.PlayToDeck, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentPlayToDeck(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.PlayToDeck, id, .Opponent)
                }

            case .GRAVEYARD:
                if controller == game.player.id {
                    game.playerPlayToGraveyard(entity, cardId, game.turnNumber())
                    if entity.hasTag(.HEALTH) {
                        game.proposeKeyPoint(.Death, id, .Player)
                    }
                }
                else if controller == game.opponent.id {
                    if let playerEntity = game.playerEntity {
                        game.opponentPlayToGraveyard(entity, cardId, game.turnNumber(), playerEntity.isCurrentPlayer)
                    }
                    if entity.hasTag(.HEALTH) {
                        game.proposeKeyPoint(.Death, id, .Opponent)
                    }
                }

            case .REMOVEDFROMGAME, .SETASIDE:
                if controller == game.player.id {
                    game.playerRemoveFromPlay(entity, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentRemoveFromPlay(entity, game.turnNumber())
                }

            case .PLAY:
                break

            default:
                // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
                break
            }
        }
    }

    private func zoneChangeFromHand(game: Game, _ id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        if let zoneValue = Zone(rawValue: value), let entity = game.entities[id] {
            switch zoneValue {
            case .PLAY:
                if controller == game.player.id {
                    game.playerPlay(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.Play, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentPlay(entity, cardId, entity.getTag(.ZONE_POSITION), game.turnNumber())
                    game.proposeKeyPoint(.Play, id, .Opponent)
                }

            case .REMOVEDFROMGAME, .SETASIDE, .GRAVEYARD:
                if controller == game.player.id {
                    game.playerHandDiscard(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.HandDiscard, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentHandDiscard(entity, cardId, entity.getTag(.ZONE_POSITION), game.turnNumber())
                    game.proposeKeyPoint(.HandDiscard, id, .Opponent)
                }

            case .SECRET:
                if controller == game.player.id {
                    game.playerSecretPlayed(entity, cardId, game.turnNumber(), false)
                    game.proposeKeyPoint(.SecretPlayed, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentSecretPlayed(entity, cardId, entity.getTag(.ZONE_POSITION), game.turnNumber(), false, id)
                    game.proposeKeyPoint(.SecretPlayed, id, .Opponent)
                }

            case .DECK:
                if controller == game.player.id {
                    game.playerMulligan(entity, cardId)
                    game.proposeKeyPoint(.Mulligan, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentMulligan(entity, entity.getTag(.ZONE_POSITION))
                    game.proposeKeyPoint(.Mulligan, id, .Opponent)
                }

            default:
                // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
                break
            }
        }
    }

    private func zoneChangeFromDeck(game: Game, _ id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        if let zoneValue = Zone(rawValue: value), let entity = game.entities[id] {
            switch zoneValue {
            case .HAND:
                if controller == game.player.id {
                    game.playerDraw(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.Draw, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentDraw(entity, game.turnNumber())
                    game.proposeKeyPoint(.Draw, id, .Opponent)
                }

            case .SETASIDE, .REMOVEDFROMGAME:
                if controller == game.player.id {
                    if game.joustReveals > 0 {
                        game.joustReveals -= 1
                        break
                    }
                    game.playerRemoveFromDeck(entity, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    if game.joustReveals > 0 {
                        game.joustReveals -= 1
                        break
                    }
                    game.opponentRemoveFromDeck(entity, game.turnNumber())
                }

            case .GRAVEYARD:
                if controller == game.player.id {
                    game.playerDeckDiscard(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.DeckDiscard, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentDeckDiscard(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.DeckDiscard, id, .Opponent)
                }

            case .PLAY:
                if controller == game.player.id {
                    game.playerDeckToPlay(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.DeckDiscard, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentDeckToPlay(entity, cardId, game.turnNumber())
                    game.proposeKeyPoint(.DeckDiscard, id, .Opponent)
                }

            case .SECRET:
                if controller == game.player.id {
                    game.playerSecretPlayed(entity, cardId, game.turnNumber(), true)
                    game.proposeKeyPoint(.SecretPlayed, id, .Player)
                }
                else if controller == game.opponent.id {
                    game.opponentSecretPlayed(entity, cardId, -1, game.turnNumber(), true, id)
                    game.proposeKeyPoint(.SecretPlayed, id, .Opponent)
                }

            default:
                // DDLogWarn("unhandled zone change(id = \(id)): \(prevValue) -> \(value) ")
                break
            }
        }
    }

    private func setHeroAsync(game: Game, _ id: Int) {
        Log.info?.message("Found hero with id \(id) ")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if game.playerEntity == nil {
                Log.info?.message("Waiting for playerEntity")
                while game.playerEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
            }

            if let playerEntity = game.playerEntity,
                let entity = game.entities[id] {
                    Log.info?.message("playerEntity found playerClass : \(game.player.playerClass), \(id) -> \(playerEntity.getTag(.HERO_ENTITY)) -> \(entity) ")
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
                let entity = game.entities[id] {
                    Log.info?.message("opponentEntity found playerClass : \(game.opponent.playerClass), \(id) -> \(opponentEntity.getTag(.HERO_ENTITY)) -> \(entity) ")

                    if game.opponent.playerClass == nil && id == opponentEntity.getTag(.HERO_ENTITY) {
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
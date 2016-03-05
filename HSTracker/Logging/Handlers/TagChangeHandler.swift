/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

class TagChangeHandler {

    func tagChange(rawTag: String, _ id: Int, _ rawValue: String, _ recurse: Bool? = false) {
        var _tag: GameTag? = GameTag(rawString: rawTag)

        if _tag == nil {
            DDLogInfo("tag not found -> rawTag \(rawTag)")
            if let num = Int(rawTag) {
                if let tag = GameTag(rawValue: num) {
                    DDLogInfo("tag not found -> rawTag \(num)")
                    _tag = tag
                }
            }
        }
        if let tag = _tag {
            let value = self.parseTag(tag, rawValue)
            tagChange(tag, id, value, recurse)
        }
    }

    func tagChange(tag: GameTag, _ id: Int, _ value: Int, _ recurse: Bool? = false) {
        let game = Game.instance
        if game.lastId != id {
        }
        game.lastId = id

        if id > game.maxId {
            game.maxId = id
        }

        if game.entities[id] == nil {
            game.entities[id] = Entity(id)
        }

        var prevValue = game.entities[id]!.getTag(tag)
        game.entities[id]!.setTag(tag, value)

        if tag == GameTag.CONTROLLER && game.waitController != nil && game.player.id == nil {
            determinePlayers(value)
        }

        let controller: Int = game.entities[id]!.getTag(GameTag.CONTROLLER)
        let cardId = game.entities[id]!.cardId
        // DDLogVerbose("Entity \(id), Controller is \(controller), player is \(game.player.id), opponent is \(game.opponent.id), card \(cardId)")

        switch tag {
        case .ZONE:
            if Zone(rawValue: value) == Zone.HAND || ((Zone(rawValue: value) == Zone.PLAY || Zone(rawValue: value) == Zone.DECK) && game.isMulliganDone())
            && game.waitController == nil {
                if !game.isMulliganDone() {
                    prevValue = Zone.DECK.rawValue
                }
                if controller == 0 {
                    game.entities[id]!.setTag(GameTag.ZONE, prevValue)
                    game.waitController = TempEntity(tag, id, value)
                    return
                }
            }
            zoneChange(id, value, prevValue, controller, cardId)

        case .PLAYSTATE:
            playstateChange(id, value)

        case .CARDTYPE:
            cardTypeChange(id, value)

        case .CURRENT_PLAYER:
            currentPlayerChange(id, value)

        case .LAST_CARD_PLAYED:
            lastCardPlayedChange(value)

        case .DEFENDING:
            defendingChange(id, controller, value)

        case .ATTACKING:
            attackingChange(id, controller, value)

        case .PROPOSED_DEFENDER:
            proposedDefenderChange(value)

        case .PROPOSED_ATTACKER:
            proposedAttackerChange(value)

        case .NUM_MINIONS_PLAYED_THIS_TURN:
            numMinionsPlayedThisTurnChange(value)

        case .PREDAMAGE:
            predamageChange(id, value)

        case .NUM_TURNS_IN_PLAY:
            numTurnsInPlayChange(id, value)

        case .NUM_ATTACKS_THIS_TURN:
            numAttacksThisTurnChange(id, value, controller)

        case .ZONE_POSITION:
            zonePositionChange(id, controller)

        case .CARD_TARGET:
            cardTargetChange(id, value, controller)

        case .EQUIPPED_WEAPON:
            equippedWeaponChange(id, value, controller)

        case .EXHAUSTED:
            exhaustedChange(id, value, controller)

        case .CONTROLLER:
            controllerChange(id, prevValue, value, cardId)

        case .FATIGUE:
            fatigueChange(value, controller)

        default:
            break
        }

        if let _ = recurse, let waitController = game.waitController where recurse == false {
            let tag = waitController.tag
            let id = waitController.id
            let value = waitController.value
            game.waitController = nil

            tagChange(tag, id, value, true)
        }
    }

    // parse an entity
    func parseEntity(entity: String) -> (id: Int?, zonePos: Int?, player: Int?, name: String?, zone: String?, cardId: String?, type: String?) {
        var id: Int?, zonePos: Int?, player: Int?
        if entity.isMatch(PowerGameStateHandler.ParseEntityIDRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityIDRegex)
            id = Int(match.groups[1].value)
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityZonePosRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityZonePosRegex)
            zonePos = Int(match.groups[1].value)
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityPlayerRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityPlayerRegex)
            player = Int(match.groups[1].value)
        }

        var name: String?, zone: String?, cardId: String?, type: String?
        if entity.isMatch(PowerGameStateHandler.ParseEntityNameRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityNameRegex)
            name = match.groups[1].value
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityZoneRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityZoneRegex)
            zone = match.groups[1].value
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityCardIDRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityCardIDRegex)
            cardId = match.groups[1].value
        }
        if entity.isMatch(PowerGameStateHandler.ParseEntityTypeRegex) {
            let match = entity.firstMatchWithDetails(PowerGameStateHandler.ParseEntityTypeRegex)
            type = match.groups[1].value
        }

        return (id, zonePos, player, name, zone, cardId, type)
    }

    // check if the entity is a raw entity
    func isEntity(rawEntity: String) -> Bool {
        let entity = parseEntity(rawEntity)
        return entity.id != nil || entity.zonePos != nil || entity.player != nil || entity.name != nil || entity.zone != nil || entity.cardId != nil || entity.type != nil
    }

    func parseTag(tag: GameTag, _ rawValue: String) -> Int {
        switch (tag) {
        case .ZONE:
            return Zone(rawString: rawValue)!.rawValue

        case .MULLIGAN_STATE:
            return Mulligan(rawString: rawValue)!.rawValue

        case .PLAYSTATE:
            return PlayState(rawString: rawValue)!.rawValue

        case .CARDTYPE:
            return CardType(rawString: rawValue)!.rawValue

        case .CLASS:
            return TagClass(rawString: rawValue)!.rawValue

        default:
            if let value = Int(rawValue) {
                return value
            }
            return 0
        }
    }

    private func determinePlayers(controller: Int) {
        let game = Game.instance
        let p1 = game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 1 }
        let p2 = game.entities.map { $0.1 }.firstWhere { $0.getTag(.PLAYER_ID) == 2 }

        if game.currentEntityHasCardId {
            if let p1 = p1 {
                p1.isPlayer = controller == 1
            }
            if let p2 = p2 {
                p2.isPlayer = controller != 1
            }
            game.player.id = controller
            game.opponent.id = controller % 2 + 1
        }
        else
        {
            if let p1 = p1 {
                p1.isPlayer = controller != 1
            }
            if let p2 = p2 {
                p2.isPlayer = controller == 1
            }

            game.player.id = controller % 2 + 1
            game.opponent.id = controller
        }
    }

    private func lastCardPlayedChange(value: Int) {
        Game.instance.lastCardPlayed = value
    }

    private func defendingChange(id: Int, _ controller: Int, _ value: Int) {
        let game = Game.instance
        if controller == game.opponent.id {
            game.handleDefendingEntity(value == 1 ? game.entities[id] : nil)
        }
    }

    private func attackingChange(id: Int, _ controller: Int, _ value: Int) {
        let game = Game.instance
        if controller == game.player.id {
            game.handleAttackingEntity(value == 1 ? game.entities[id] : nil)
        }
    }

    private func proposedDefenderChange(value: Int) {
        // Game.instance.OpponentSecrets.ProposedDefenderEntityId = value;
    }

    private func proposedAttackerChange(value: Int) {
        // Game.instance.OpponentSecrets.ProposedAttackerEntityId = value
    }

    private func numMinionsPlayedThisTurnChange(value: Int) {
        if value <= 0 {
            return
        }
        /*let game = Game.instance
         if game.PlayerEntity.IsCurrentPlayer() {
         game.PlayerMinionPlayed();
         }*/
    }

    private func predamageChange(id: Int, _ value: Int)
    {
        if value <= 0 {
            return
        }
        /*
         let game = Game.instance
         if game.PlayerEntity.IsCurrentPlayer() {
         game.OpponentDamage(game.Entities[id]);
         }
         */
    }

    private func numTurnsInPlayChange(id: Int, _ value: Int)
    {
        if value <= 0 {
            return
        }
        /*
         let game = Game.instance
         if game.PlayerEntity.IsCurrentPlayer() {
         game.OpponentTurnStart(game.Entities[id]);
         }*/
    }

    private func fatigueChange(value: Int, _ controller: Int) {
        let game = Game.instance

        if controller == game.player.id {
            game.playerFatigue(value)
        }
        else if controller == game.opponent.id {
            game.opponentFatigue(value)
        }
    }

    private func controllerChange(id: Int, _ prevValue: Int, _ value: Int, _ cardId: String?) {
        if prevValue <= 0 {
            return
        }
        let game = Game.instance
        if let entity = game.entities[id] {
            if entity.hasTag(.PLAYER_ID) {
                return
            }

            if value == game.player.id {
                if entity.isInZone(.SECRET) {
                    game.opponentStolen(entity, cardId, game.turnNumber())
                }
                else if entity.isInZone(.PLAY) {
                    game.opponentStolen(entity, cardId, game.turnNumber())
                }
            }
            else if value == game.opponent.id {
                if entity.isInZone(.SECRET) {
                    game.opponentStolen(entity, cardId, game.turnNumber())
                }
                else if entity.isInZone(.PLAY) {
                    game.playerStolen(entity, cardId, game.turnNumber())
                }
            }
        }
    }

    private func exhaustedChange(id: Int, _ value: Int, _ controller: Int) {
        if value <= 0 {
            return
        }
        let game = Game.instance

        if let entity = game.entities[id] where entity.getTag(.CARDTYPE) != CardType.HERO_POWER.rawValue {
            return
        }
        if controller == game.player.id {
            // gameState.ProposeKeyPoint(HeroPower, id, ActivePlayer.Player);
        }
        else if controller == game.opponent.id {
            // gameState.ProposeKeyPoint(HeroPower, id, ActivePlayer.Opponent);
        }
    }

    private func equippedWeaponChange(id: Int, _ value: Int, _ controller: Int) {
        if value != 0 {
            return
        }
        let game = Game.instance
        if controller == game.player.id {
            // gameState.ProposeKeyPoint(WeaponDestroyed, id, ActivePlayer.Player);
        }
        else if controller == game.opponent.id {
            // gameState.ProposeKeyPoint(WeaponDestroyed, id, ActivePlayer.Opponent);
        }
    }

    private func cardTargetChange(id: Int, _ value: Int, _ controller: Int)
    {
        if value <= 0 {
            return
        }
        let game = Game.instance
        if controller == game.player.id {
            // gameState.ProposeKeyPoint(PlaySpell, id, ActivePlayer.Player);
        }
        else if controller == game.opponent.id {
            // gameState.ProposeKeyPoint(PlaySpell, id, ActivePlayer.Opponent);
        }
    }

    private func zonePositionChange(id: Int, _ controller: Int) {
        let game = Game.instance
        if let entity = game.entities[id] {
            let zone = entity.getTag(.ZONE)
            if zone == Zone.HAND.rawValue {
                if controller == game.player.id {
                    game.zonePositionUpdate(.Player, entity, .HAND, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.zonePositionUpdate(.Opponent, entity, .HAND, game.turnNumber())
                }
            }
            else if zone == Zone.PLAY.rawValue
            {
                if controller == game.player.id {
                    game.zonePositionUpdate(.Player, entity, .PLAY, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.zonePositionUpdate(.Opponent, entity, .PLAY, game.turnNumber())
                }
            }
        }
    }

    private func numAttacksThisTurnChange(id: Int, _ value: Int, _ controller: Int) {
        if value > 0 {
            let game = Game.instance
            if controller == game.player.id {
                // gameState.ProposeKeyPoint(Attack, id, ActivePlayer.Player);
            }
            else if controller == game.opponent.id {
                // gameState.ProposeKeyPoint(Attack, id, ActivePlayer.Opponent);
            }
        }
    }

    private func currentPlayerChange(id: Int, _ value: Int) {
        let game = Game.instance
        if let entity = game.entities[id] where value == 1 {
            let activePlayer: PlayerType = entity.isPlayer ? .Player : .Opponent
            game.turnStart(activePlayer, game.turnNumber())
            if activePlayer == .Player {
                game.playerUsedHeroPower = false
            }
            else {
                game.opponentUsedHeroPower = false
            }
        }
    }

    private func cardTypeChange(id: Int, _ value: Int) {
        if value == CardType.HERO.rawValue {
            setHeroAsync(id)
        }
    }

    private func playstateChange(id: Int, _ value: Int) {
        let game = Game.instance
        if value == PlayState.CONCEDED.rawValue {
            game.concede()
        }

        if (game.gameEnded) {
            return
        }

        guard let entity = game.entities[id] where !entity.isPlayer else {
            return
        }

        if let value = PlayState(rawValue: value) {
            switch value {
            case .WON:
                game.win()
                game.gameEnd()
                game.gameEnded = true

            case .LOST:
                game.loss()
                game.gameEnd()
                game.gameEnded = true

            case .TIED:
                game.tied()
                game.gameEnd()

            default: break
            }
        }
    }

    private func zoneChange(id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        if let zoneValue = Zone(rawValue: prevValue) {
            switch zoneValue {
            case .DECK:
                zoneChangeFromDeck(id, value, prevValue, controller, cardId)

            case .HAND:
                zoneChangeFromHand(id, value, prevValue, controller, cardId)

            case .PLAY:
                zoneChangeFromPlay(id, value, prevValue, controller, cardId)

            case .SECRET:
                zoneChangeFromSecret(id, value, prevValue, controller, cardId)

            case .GRAVEYARD,
                    .SETASIDE,
                    .CREATED,
                    .INVALID,
                    .REMOVEDFROMGAME:
                    zoneChangeFromOther(id, value, prevValue, controller, cardId)
            }
        }
    }

    private func zoneChangeFromOther(id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        let game = Game.instance
        if let value = Zone(rawValue: value), let entity = game.entities[id] {
            switch value {
            case .PLAY:
                if controller == game.player.id {
                    game.playerCreateInPlay(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentCreateInPlay(entity, cardId, game.turnNumber())
                }

            case .DECK:
                if controller == game.player.id {
                    if game.joustReveals > 0 {
                        break
                    }
                    game.playerGetToDeck(entity, cardId, game.turnNumber())
                }
                if controller == game.opponent.id {

                    if game.joustReveals > 0 {
                        break
                    }
                    game.opponentGetToDeck(entity, game.turnNumber())
                }

            case .HAND:
                if controller == game.player.id {
                    game.playerGet(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentGet(entity, game.turnNumber(), id)
                }

            default:
                DDLogWarn("unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
            }
        }
    }

    private func zoneChangeFromSecret(id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        let game = Game.instance
        if let zoneValue = Zone(rawValue: value), let entity = game.entities[id] {
            switch zoneValue {
            case .SECRET, .GRAVEYARD:
                if controller == game.player.id {
                }
                else if controller == game.opponent.id {
                    game.opponentSecretTrigger(entity, cardId, game.turnNumber(), id)
                }

            default:
                DDLogWarn("unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
            }
        }
    }

    private func zoneChangeFromPlay(id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        let game = Game.instance

        if let zoneValue = Zone(rawValue: value), let entity = game.entities[id] {
            switch zoneValue {
            case .HAND:
                if controller == game.player.id {
                    game.playerBackToHand(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentPlayToHand(entity, cardId, game.turnNumber(), id)
                }

            case .DECK:
                if controller == game.player.id {
                    game.playerPlayToDeck(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentPlayToDeck(entity, cardId, game.turnNumber())
                }

            case .REMOVEDFROMGAME,
                    .SETASIDE,
                    .GRAVEYARD:
                    if controller == game.player.id {
                        game.playerPlayToGraveyard(entity, cardId, game.turnNumber());
                        /*if let entity = entity where entity.hasTag(.HEALTH) {
                         }*/
                }
                else if controller == game.opponent.id {
                    game.opponentPlayToGraveyard(entity, cardId, game.turnNumber(), game.playerEntity!.isCurrentPlayer)
                    /*if let entity = entity where entity.hasTag(.HEALTH) {
                     }*/
                }

            case .PLAY:
                break

            default:
                DDLogWarn("unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
            }
        }
    }

    private func zoneChangeFromHand(id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        let game = Game.instance

        if let zoneValue = Zone(rawValue: value), let entity = game.entities[id] {
            switch zoneValue {
            case .PLAY:
                if controller == game.player.id {
                    game.playerPlay(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentPlay(entity, cardId, entity.getTag(.ZONE_POSITION), game.turnNumber())
                }

            case .REMOVEDFROMGAME, .SETASIDE, .GRAVEYARD:
                if controller == game.player.id {
                    game.playerHandDiscard(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentHandDiscard(entity, cardId, entity.getTag(.ZONE_POSITION), game.turnNumber());
                }

            case .SECRET:
                if controller == game.player.id {
                    game.playerSecretPlayed(entity, cardId, game.turnNumber(), false)
                }
                else if controller == game.opponent.id {
                    game.opponentSecretPlayed(entity, cardId, entity.getTag(.ZONE_POSITION), game.turnNumber(), false, id)
                }

            case .DECK:
                if controller == game.player.id {
                    game.playerMulligan(entity, cardId)
                }
                else if controller == game.opponent.id {
                    game.opponentMulligan(entity, entity.getTag(.ZONE_POSITION))
                }

            default:
                DDLogWarn("unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
            }
        }
    }

    private func zoneChangeFromDeck(id: Int, _ value: Int, _ prevValue: Int, _ controller: Int, _ cardId: String?) {
        let game = Game.instance

        if let zoneValue = Zone(rawValue: value), let entity = game.entities[id] {
            switch zoneValue {
            case .HAND:
                if controller == game.player.id {
                    game.playerDraw(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    if entity.cardId != nil && !entity.cardId!.isEmpty {
                        entity.cardId = ""
                    }
                    game.opponentDraw(entity, game.turnNumber())
                }

            case .SETASIDE, .REMOVEDFROMGAME:
                if controller == game.player.id {
                    if game.joustReveals > 0 {
                        game.joustReveals--
                        break
                    }
                    game.playerRemoveFromDeck(entity, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    if game.joustReveals > 0 {
                        game.joustReveals--
                        break
                    }
                    game.opponentRemoveFromDeck(entity, game.turnNumber())
                }

            case .GRAVEYARD:
                if controller == game.player.id {
                    game.playerDeckDiscard(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentDeckDiscard(entity, cardId, game.turnNumber())
                }

            case .PLAY:
                if controller == game.player.id {
                    game.playerDeckToPlay(entity, cardId, game.turnNumber())
                }
                else if controller == game.opponent.id {
                    game.opponentDeckToPlay(entity, cardId, game.turnNumber())
                }

            case .SECRET:
                if controller == game.player.id {
                    game.playerSecretPlayed(entity, cardId, game.turnNumber(), true)
                }
                else if controller == game.opponent.id {
                    game.opponentSecretPlayed(entity, cardId, -1, game.turnNumber(), true, id)
                }

            default:
                DDLogWarn("unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
            }
        }
    }

    private func setHeroAsync(id: Int) {
        DDLogVerbose("Found hero with id \(id)")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let game = Game.instance
            if game.playerEntity == nil {
                DDLogVerbose("Waiting for playerEntity")
                while game.playerEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
            }
            if let playerEntity = game.playerEntity {
                if id == playerEntity.getTag(GameTag.HERO_ENTITY) {
                    dispatch_async(dispatch_get_main_queue()) {
                        game.setPlayerHero(game.entities[id]!.cardId!)
                    }
                    return
                }
            }

            if game.opponentEntity == nil {
                DDLogVerbose("Waiting for opponentEntity")
                while game.opponentEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
            }
            if let opponentEntity = game.opponentEntity {
                if id == opponentEntity.getTag(GameTag.HERO_ENTITY) {
                    dispatch_async(dispatch_get_main_queue()) {
                        game.setOpponentHero(game.entities[id]!.cardId!)
                    }
                    return
                }
            }
        }
    }
}

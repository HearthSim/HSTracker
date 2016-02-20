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
    var currentEntityHasCardId: Bool = false
    var playerUsedHeroPower: Bool = false
    var opponentUsedHeroPower: Bool = false

    func tagChange(rawTag: String, id: Int, rawValue: String, recurse: Bool? = false) {
        let game = Game.instance
        if game.entities[id] != nil {
            game.entities[id] = Entity(id)
        }

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
            var prevValue = game.entities[id]![tag]!
            game.entities[id]![tag] = value

            if tag == GameTag.CONTROLLER && game.waitController != nil && game.player.id == NSNotFound {
                var player1: Entity?, player2: Entity?
                for (_, ent) in game.entities {
                    if ent[GameTag.PLAYER_ID] == 1 {
                        player1 = ent
                    } else if ent[GameTag.PLAYER_ID] == 2 {
                        player2 = ent
                    }
                }
                if self.currentEntityHasCardId {
                    if let player1 = player1 {
                        player1.isPlayer = (value == 1)
                    }
                    if let player2 = player2 {
                        player2.isPlayer = (value != 1)
                    }

                    game.player.id = value
                    game.opponent.id = value % 2 + 1
                } else {
                    if let player1 = player1 {
                        player1.isPlayer = (value != 1)
                    }
                    if let player2 = player2 {
                        player2.isPlayer = (value == 1)
                    }

                    game.player.id = value % 2 + 1
                    game.opponent.id = value
                }

                if let player1 = player1 {
                    DDLogInfo("player1 is player : \(player1.isPlayer ? "YES" : "NO")")
                }
                if let player2 = player2 {
                    DDLogInfo("player2 is player : \(player2.isPlayer ? "YES" : "NO")")
                }
            }

            let controller: Int = game.entities[id]![GameTag.CONTROLLER] == nil ? 0 : game.entities[id]![GameTag.CONTROLLER]!
            let cardId = game.entities[id]!.cardId
            //DDLogVerbose("Entity \(id), Controller is \(controller), player is \(game.player.id), opponent is \(game.opponent.id), card \(cardId)")

            if (tag == GameTag.ZONE) {
                if Zone(rawValue: value) == Zone.HAND || ((Zone(rawValue: value) == Zone.PLAY || Zone(rawValue: value) == Zone.DECK) && game.isMulliganDone())
                        && game.waitController == nil {
                    if !game.isMulliganDone() {
                        prevValue = Zone.DECK.rawValue
                    }
                    if controller == 0 {
                        game.entities[id]![GameTag.ZONE] = prevValue
                        game.waitController = TempEntity(rawTag, id, rawValue)
                        return
                    }
                }

                switch Zone(rawValue: prevValue)! {
                case .DECK:
                    switch Zone(rawValue: value)! {
                    case .HAND:
                        if controller == game.player.id {
                            game.playerDraw(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            if let _cardId = game.entities[id]!.cardId where _cardId.isEmpty {
                                game.entities[id]!.cardId = nil
                            }

                            game.opponentDraw(game.entities[id]!, turn: game.turnNumber())
                        }

                    case Zone.REMOVEDFROMGAME,
                         Zone.SETASIDE:
                        if controller == game.player.id {
                            if game.joustReveals > 0 {
                                game.joustReveals -= 1;
                                break
                            }
                            game.playerRemoveFromDeck(game.entities[id]!, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            if game.joustReveals > 0 {
                                game.joustReveals -= 1
                                break
                            }
                            game.opponentRemoveFromDeck(game.entities[id]!, turn: game.turnNumber())
                        }

                    case Zone.GRAVEYARD:
                        if controller == game.player.id {
                            game.playerDeckDiscard(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            game.opponentDeckDiscard(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        }

                    case Zone.PLAY:
                        if controller == game.player.id {
                            game.playerDeckToPlay(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            game.opponentDeckToPlay(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        }

                    case Zone.SECRET:
                        if controller == game.player.id {
                            game.playerSecretPlayed(game.entities[id]!, cardId: cardId, turn: game.turnNumber(), fromDeck: true)
                        } else if controller == game.opponent.id {
                            game.opponentSecretPlayed(game.entities[id]!, cardId: cardId, from: 1, turn: game.turnNumber(), fromDeck: true, id: id)
                        }

                    default:
                        //DDLogVerbose("WARNING - unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
                        break
                    }

                case Zone.HAND:
                    switch Zone(rawValue: value)! {
                    case Zone.PLAY:
                        if controller == game.player.id {
                            game.playerPlay(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            game.opponentPlay(game.entities[id]!, cardId: cardId,
                                    from: game.entities[id]![GameTag.ZONE_POSITION]!, turn: game.turnNumber())
                        }

                    case Zone.REMOVEDFROMGAME,
                         Zone.SETASIDE,
                         Zone.GRAVEYARD:
                        if controller == game.player.id {
                            game.playerHandDiscard(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            game.opponentHandDiscard(game.entities[id]!,
                                    cardId: cardId,
                                    from: game.entities[id]![GameTag.ZONE_POSITION]!,
                                    turn: game.turnNumber())
                        }

                    case Zone.SECRET:
                        if controller == game.player.id {
                            game.playerSecretPlayed(game.entities[id]!, cardId: cardId, turn: game.turnNumber(), fromDeck: false)
                        } else if controller == game.opponent.id {
                            game.opponentSecretPlayed(game.entities[id]!, cardId: cardId,
                                    from: game.entities[id]![GameTag.ZONE_POSITION]!, turn: game.turnNumber(), fromDeck: false, id: id)
                        }

                    case Zone.DECK:
                        if controller == game.player.id {
                            game.playerMulligan(game.entities[id]!, cardId: cardId)
                        } else if controller == game.opponent.id {
                            game.opponentMulligan(game.entities[id]!, from: game.entities[id]![GameTag.ZONE_POSITION]!)
                        }

                    default:
                        //DDLogVerbose("WARNING - unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
                        break
                    }

                case Zone.PLAY:
                    switch Zone(rawValue: value)! {
                    case Zone.HAND:
                        if controller == game.player.id {
                            game.playerBackToHand(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            game.opponentPlayToHand(game.entities[id]!, cardId: cardId, turn: game.turnNumber(), id: id)
                        }

                    case Zone.DECK:
                        if controller == game.player.id {
                            game.playerPlayToDeck(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            game.opponentPlayToDeck(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        }

                    case Zone.REMOVEDFROMGAME,
                         Zone.SETASIDE,
                         Zone.GRAVEYARD:
                        if controller == game.player.id {
                            game.playerPlayToGraveyard(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                            if game.entities[id]![GameTag.HEALTH] != nil {
                            }
                        } else if controller == game.opponent.id {
                            // TODO gameState.GameHandler.HandleOpponentPlayToGraveyard(game.Entities[id], cardId, gameState.GetTurnNumber(), gameState.PlayersTurn());
                            game.opponentPlayToGraveyard(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                            if game.entities[id]![GameTag.HEALTH] != nil {
                            }
                        }

                    default:
                        //DDLogVerbose("WARNING - unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
                        break
                    }

                case Zone.SECRET:
                    switch Zone(rawValue: value)! {
                    case Zone.SECRET,
                         Zone.GRAVEYARD:
                        if controller == game.player.id {
                        } else if controller == game.opponent.id {
                            game.opponentSecretTrigger(game.entities[id]!, cardId: cardId, turn: game.turnNumber(), id: id)
                        }

                    default:
                        //DDLogVerbose("WARNING - unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
                        break
                    }

                case Zone.GRAVEYARD,
                     Zone.SETASIDE,
                     Zone.CREATED,
                     Zone.INVALID,
                     Zone.REMOVEDFROMGAME:
                    switch Zone(rawValue: value)! {
                    case Zone.PLAY:
                        if controller == game.player.id {
                            game.playerCreateInPlay(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            game.opponentCreateInPlay(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        }

                    case Zone.DECK:
                        if controller == game.player.id {
                            if game.joustReveals > 0 {
                                break
                            }
                            game.playerGetToDeck(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            if game.joustReveals > 0 {
                                break
                            }
                            game.opponentGetToDeck(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        }

                    case Zone.HAND:
                        if controller == game.player.id {
                            game.playerGet(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                        } else if controller == game.opponent.id {
                            game.opponentGet(game.entities[id]!, turn: game.turnNumber(), id: id)
                        }

                    default:
                        //DDLogVerbose("WARNING - unhandled zone change (id=\(id)): \(prevValue) -> \(value)")
                        break
                    }
                }
            } else if tag == GameTag.PLAYSTATE {
                if PlayState(rawValue: value)! == PlayState.CONCEDED {
                    game.concede()
                }

                if game.gameStarted {
                    if game.entities[id]!.isPlayer {
                        switch PlayState(rawValue: value)! {
                        case .WON:
                            game.gameStarted = false
                            game.win()
                            game.gameEnd()
                        case .LOST:
                            game.gameStarted = false
                            game.loss()
                            game.gameEnd()
                        case .TIED:
                            game.gameStarted = false
                            game.tied()
                            game.gameEnd()
                        default:
                            break
                        }
                    }
                }
            } else if tag == GameTag.CARDTYPE && CardType(rawValue: value)! == CardType.HERO {
                setHeroAsync(id)
            } else if tag == GameTag.CURRENT_PLAYER && value == 1 {
                // be sure to "reset" cards from tracking
                let player: PlayerType = game.entities[id]!.isPlayer ? .Player : .Opponent
                game.turnStart(player, turn: game.turnNumber())

                if player == .Player {
                    self.playerUsedHeroPower = false
                } else {
                    self.opponentUsedHeroPower = false
                }
            } else if tag == GameTag.LAST_CARD_PLAYED {
                //gameState.LastCardPlayed = value;
            } else if tag == GameTag.DEFENDING {
            } else if tag == GameTag.ATTACKING {
            } else if tag == GameTag.PROPOSED_DEFENDER {
            } else if tag == GameTag.PROPOSED_ATTACKER {
            } else if tag == GameTag.NUM_ATTACKS_THIS_TURN && value > 0 {
            } else if tag == GameTag.PREDAMAGE && value > 0 {
            } else if tag == GameTag.NUM_TURNS_IN_PLAY && value > 0 {
            } else if tag == GameTag.NUM_ATTACKS_THIS_TURN && value > 0 {
            } else if tag == GameTag.ZONE_POSITION {
            } else if tag == GameTag.CARD_TARGET && value > 0 {
            } else if tag == GameTag.EQUIPPED_WEAPON && value == 0 {
            } else if tag == GameTag.EXHAUSTED && value > 0 {
            } else if tag == GameTag.CONTROLLER && prevValue > 0 {
                if value == game.player.id {
                    if game.entities[id]!.isInZone(Zone.SECRET) {
                        game.opponentStolen(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                    } else if game.entities[id]!.isInZone(Zone.PLAY) {
                        game.opponentStolen(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                    }
                } else if value == game.opponent.id {
                    if game.entities[id]!.isInZone(Zone.SECRET) {
                        game.opponentStolen(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                    } else if game.entities[id]!.isInZone(Zone.PLAY) {
                        game.playerStolen(game.entities[id]!, cardId: cardId, turn: game.turnNumber())
                    }
                }
            } else if tag == GameTag.FATIGUE {
                if controller == game.player.id {
                    game.playerFatigue(value)
                } else if controller == game.opponent.id {
                    game.opponentFatigue(value)
                }
            }

            if let _ = recurse {
                if let waitController = game.waitController {
                    tagChange(waitController.tag, id: waitController.id, rawValue: waitController.value, recurse: true)
                    game.waitController = nil
                }
            }
        }
    }

    func setHeroAsync(id: Int) {
        DDLogInfo("Found hero with id \(id)")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let game = Game.instance
            if game.playerEntity == nil {
                DDLogInfo("Waiting for playerEntity")
                while game.playerEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
                DDLogInfo("Found playerEntity")
            }
            if id == game.playerEntity![GameTag.HERO_ENTITY] {
                dispatch_async(dispatch_get_main_queue()) {
                    game.setPlayerHero(game.entities[id]!.cardId!)
                }
                return
            }

            if game.opponentEntity == nil {
                DDLogInfo("Waiting for opponentEntity")
                while game.opponentEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
                DDLogInfo("Found opponentEntity")
            }
            if id == game.opponentEntity![GameTag.HERO_ENTITY] {
                dispatch_async(dispatch_get_main_queue()) {
                    game.setOpponentHero(game.entities[id]!.cardId!)
                }
                return
            }
        }
    }

    // parse an entity
    func parseEntity(entity: String) -> (id:Int?, zonePos:Int?, player:Int?, name:String?, zone:String?, cardId:String?, type:String?) {
        var id: Int?, zonePos: Int?, player: Int?
        if entity.isMatch(NSRegularExpression.rx("id=(\\d+)")) {
            let match = entity.firstMatchWithDetails(NSRegularExpression.rx("id=(\\d+)"))
            id = Int(match.groups[1].value)
        }
        if entity.isMatch(NSRegularExpression.rx("zonePos=(\\d+)")) {
            let match = entity.firstMatchWithDetails(NSRegularExpression.rx("zonePos=(\\d+)"))
            zonePos = Int(match.groups[1].value)
        }
        if entity.isMatch(NSRegularExpression.rx("player=(\\d+)")) {
            let match = entity.firstMatchWithDetails(NSRegularExpression.rx("player=(\\d+)"))
            player = Int(match.groups[1].value)
        }

        var name: String?, zone: String?, cardId: String?, type: String?
        if entity.isMatch(NSRegularExpression.rx("name=(\\d+)")) {
            let match = entity.firstMatchWithDetails(NSRegularExpression.rx("name=(\\d+)"))
            name = match.groups[1].value
        }
        if entity.isMatch(NSRegularExpression.rx("zone=(\\d+)")) {
            let match = entity.firstMatchWithDetails(NSRegularExpression.rx("zone=(\\d+)"))
            zone = match.groups[1].value
        }
        if entity.isMatch(NSRegularExpression.rx("cardId=(\\d+)")) {
            let match = entity.firstMatchWithDetails(NSRegularExpression.rx("cardId=(\\d+)"))
            cardId = match.groups[1].value
        }
        if entity.isMatch(NSRegularExpression.rx("type=(\\d+)")) {
            let match = entity.firstMatchWithDetails(NSRegularExpression.rx("type=(\\d+)"))
            type = match.groups[1].value
        }

        return (id, zonePos, player, name, zone, cardId, type)
    }

    // check if the entity is a raw entity
    func isEntity(entity: String) -> Bool {
        let (id, zonePos, player, name, zone, cardId, type) = parseEntity(entity)
        return id != nil || zonePos != nil || player != nil || name != nil || zone != nil || cardId != nil || type != nil
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
            return Int(rawValue)!
        }
    }
}

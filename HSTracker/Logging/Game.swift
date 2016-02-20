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

enum PlayerType: Int {
    case Player, Opponent
}

class Game {
    var currentTurn: Int = 0
    var currentRank: Int = 0

    var player: Player
    var opponent: Player
    var gameMode: GameMode = .Unknow
    var entities = [Int: Entity]()
    var tmpEntities = [Entity]()
    var joustReveals: Int = 0
    var rankFound: Bool = false
    var awaitingRankedDetection: Bool = true
    var lastAssetUnload: Double = 0
    var waitController: TempEntity?
    var gameStarted: Bool = false
    var gameStartDate: NSDate?
    var gameResult: GameResult = .Unknow
    var gameEndDate: NSDate?
    var waitingForFirstAssetUnload: Bool = true

    static let instance = Game()

    init() {
        player = Player(true)
        opponent = Player(false)
    }

    var playerTracker: Tracker {
        set {
            self.playerTracker = newValue
            self.playerTracker.player = player
        }
        get {
            return self.playerTracker
        }
    }
    var opponentTracker: Tracker {
        set {
            self.opponentTracker = newValue
            self.opponentTracker.player = opponent
        }
        get {
            return self.opponentTracker
        }
    }

    func reset() {
        currentTurn = -1
        entities.removeAll()
        tmpEntities.removeAll()
        joustReveals = 0
        gameMode = GameMode.Unknow
        rankFound = false
        awaitingRankedDetection = false
        lastAssetUnload = -1
        waitController = nil
        gameStarted = false
        gameResult = GameResult.Unknow;
        gameStartDate = nil
        gameEndDate = nil

        player.reset()
        opponent.reset()
    }

    var playerEntity: Entity? {
        for (_, ent) in entities {
            if ent.isPlayer {
                return ent
            }
        }
        return nil
    }

    var opponentEntity: Entity? {
        for (_, ent) in entities {
            if ent[GameTag.PLAYER_ID] != nil && !ent.isPlayer {
                return ent
            }
        }
        return nil
    }

    func gameStart() {
        if gameStarted {
            return
        }
        reset()
        gameStarted = true
        gameStartDate = NSDate()

        DDLogInfo("----- Game Started -----")

        player.gameStart()
        playerTracker.gameStart()
        opponent.gameStart()
        opponentTracker.gameStart()
    }

    func gameEnd() {
        DDLogInfo("----- Game End -----")
        gameStarted = false
        gameEndDate = NSDate()

        //@opponent_cards = opponent_tracker.cards
        handleEndGame()

        player.gameEnd()
        playerTracker.gameEnd()
        opponent.gameEnd()
        opponentTracker.gameEnd()
        // TODO [self.timerHud gameEnd]
    }

    func handleEndGame() {
        if gameMode == GameMode.Unknow {
            detectMode(3) {
                self.handleEndGame()
            }
            return
        }

        if gameMode == GameMode.Ranked && !self.rankFound {
            waitForRank(5) {
                self.handleEndGame()
            }
            return
        }
    }

    func waitForRank(seconds: Double, completion: () -> Void) {
        DDLogInfo("waiting for rank")
        rankFound = false
        let timeout = NSDate().timeIntervalSince1970 + seconds
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while NSDate().timeIntervalSince1970 - self.lastAssetUnload < timeout {
                NSThread.sleepForTimeInterval(0.1)
                if self.rankFound {
                    break
                }
                dispatch_async(dispatch_get_main_queue()) {
                    completion()
                }
            }
        }
    }

    func detectMode(seconds: Double, completion: () -> Void) {
        DDLogInfo("waiting for mode")
        awaitingRankedDetection = true
        rankFound = false
        lastAssetUnload = NSDate().timeIntervalSince1970
        waitingForFirstAssetUnload = true
        let timeout = NSDate().timeIntervalSince1970 + seconds
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while self.waitingForFirstAssetUnload || NSDate().timeIntervalSince1970 - self.lastAssetUnload < timeout {
                NSThread.sleepForTimeInterval(0.1)
                if self.rankFound {
                    break
                }
            }

            dispatch_async(dispatch_get_main_queue()) {
                completion()
            }
        }
    }

    func turnNumber() -> Int {
        if !isMulliganDone() {
            return 0
        }

        if currentTurn == -1 {
            var player: Entity?
            for (_, ent) in entities {
                if ent[GameTag.FIRST_PLAYER] != nil {
                    player = ent
                    break
                }
            }
            if player != nil {
                currentTurn = player![GameTag.CONTROLLER] == self.player.id ? 0 : 1
            }
        }

        var entity: Entity?
        for (_, ent) in entities {
            if ent.name == "GameEntity" {
                entity = ent
                break
            }
        }
        if entity != nil {
            let _turn = currentTurn == -1 ? 0 : currentTurn
            return Int(Double(entity![GameTag.TURN]! + _turn) / 2.0)
        }
        return 0
    }

    func turnStart(player: PlayerType, turn: Int) {
        DDLogInfo("Turn \(turn) start for player \(player.rawValue)")
        //timer_hud.restart(player)
    }

    func concede() {
        DDLogInfo("Game has been conceded :(")
    }


    func win() {
        DDLogInfo("You win ¯\\_(ツ)_/¯")
        gameResult = GameResult.Win
    }

    func loss() {
        DDLogInfo("You lose :(")
        self.gameResult = GameResult.Loss
    }

    func tied() {
        DDLogInfo("You lose :( / game tied:(")
        self.gameResult = GameResult.Tied
    }

    func isMulliganDone() -> Bool {
        var player: Entity?, opponent: Entity?
        for (_, ent) in entities {
            if ent.isPlayer {
                player = ent
            } else if ent[GameTag.PLAYER_ID] != nil && !ent.isPlayer {
                opponent = ent
            }
        }

        if player == nil || opponent == nil {
            return false
        }
        return player![GameTag.MULLIGAN_STATE] != nil && player![GameTag.MULLIGAN_STATE]! == Mulligan.DONE.rawValue
                && opponent![GameTag.MULLIGAN_STATE] != nil && opponent![GameTag.MULLIGAN_STATE]! == Mulligan.DONE.rawValue
    }

    // MARK: - player
    func setPlayerHero(cardId: String) {
        player.playerClass = Card.byId(cardId)
    }

    func setPlayerRank(rank: Int) {
        DDLogInfo("Player rank is \(rank)")
        currentRank = rank
    }

    func setPlayerName(name: String) {
        player.name = name
    }


    func playerGet(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.createInHand(entity, turn: turn)
        playerTracker.update()
        /*if(cardId == "GAME_005" && _game.CurrentGameStats != null)
        {
        _game.CurrentGameStats.Coin = true;
        Logger.WriteLine("Got coin", "GameStats");
        }*/
    }

    func playerBackToHand(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        playerTracker.update()
        player.boardToHand(entity, turn: turn)
    }


    func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.boardToDeck(entity, turn: turn)
        playerTracker.update()
    }

    func playerPlay(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.play(entity, turn: turn)
        playerTracker.update()
    }

    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.handDiscard(entity, turn: turn)
        playerTracker.update()
    }

    func playerSecretPlayed(entity: Entity, cardId: String?, turn: Int, fromDeck: Bool) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        if fromDeck {
            player.secretPlayedFromDeck(entity, turn: turn)
        } else {
            player.secretPlayedFromHand(entity, turn: turn)
        }
        playerTracker.update()
    }

    func playerMulligan(entity: Entity, cardId: String?) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        //TurnTimer.Instance.MulliganDone(ActivePlayer.Player);
        player.mulligan(entity)
        playerTracker.update()
    }

    func playerDraw(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        if cardId == "GAME_005" {
            playerGet(entity, cardId: cardId, turn: turn)
        } else {
            player.draw(entity, turn: turn)
            playerTracker.update()
        }
    }

    func playerRemoveFromDeck(entity: Entity, turn: Int) {
        player.removeFromDeck(entity, turn: turn)
        playerTracker.update()
    }

    func playerDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        player.deckDiscard(entity, turn: turn)
        playerTracker.update()
    }

    func playerDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        player.deckToPlay(entity, turn: turn)
        playerTracker.update()
    }

    func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        player.playToGraveyard(entity, cardId: cardId, turn: turn)
    }

    func playerJoust(entity: Entity, cardId: String?, turn: Int) {
        player.joustReveal(entity, turn: turn)
        playerTracker.update()
    }

    func playerGetToDeck(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.createInDeck(entity, turn: turn)
        playerTracker.update()
    }

    func playerFatigue(value: Int) {
        DDLogInfo("Player get \(value) fatigue")
        player.fatigue = value
    }

    func playerCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        player.createInPlay(entity, turn: turn)
    }

    func playerStolen(entity: Entity, cardId: String?, turn: Int) {
        player.stolenByOpponent(entity, turn: turn)
        opponent.stolenFromOpponent(entity, turn: turn)
    }

    //MARK: - opponent

    func setOpponentHero(cardId: String) {
        opponent.playerClass = Card.byId(cardId)
    }

    func setOpponentName(name: String) {
        opponent.name = name
    }

    func opponentGet(entity: Entity, turn: Int, id: Int) {
        opponent.createInHand(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.boardToHand(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        opponent.boardToDeck(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentPlay(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.play(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentHandDiscard(entity: Entity, cardId: String?, from: Int, turn: Int) {
        // TODO exception ???
        opponent.play(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentSecretPlayed(entity: Entity, cardId: String?, from: Int, turn: Int, fromDeck: Bool, id: Int) {
        if fromDeck {
            opponent.secretPlayedFromDeck(entity, turn: turn)
        } else {
            opponent.secretPlayedFromHand(entity, turn: turn)
        }
    }

    func opponentMulligan(entity: Entity, from: Int) {
        opponent.mulligan(entity)
    }

    func opponentDraw(entity: Entity, turn: Int) {
        opponent.draw(entity, turn: turn)
    }

    func opponentRemoveFromDeck(entity: Entity, turn: Int) {
        opponent.removeFromDeck(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckDiscard(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckToPlay(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentPlayToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        opponent.playToGraveyard(entity, cardId: cardId, turn: turn)
    }

    func opponentJoust(entity: Entity, cardId: String?, turn: Int) {
        opponent.joustReveal(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentGetToDeck(entity: Entity, cardId: String?, turn: Int) {
        opponent.createInDeck(entity, turn: turn)
        opponentTracker.update()
    }

    func opponentSecretTrigger(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.secretTriggered(entity, turn: turn)
    }

    func opponentFatigue(value: Int) {
        opponent.fatigue = value
    }

    func opponentCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.createInPlay(entity, turn: turn)
    }

    func opponentStolen(entity: Entity, cardId: String?, turn: Int) {
        opponent.stolenByOpponent(entity, turn: turn)
        player.stolenFromOpponent(entity, turn: turn)
        if entity.isSecret {
            opponentTracker.update()
        }
    }
}
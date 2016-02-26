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
    var maxId: Int = 0

    var player: Player
    var opponent: Player
    var gameMode: GameMode = .Unknow
    var entities = [Int: Entity]()
    var tmpEntities = [Entity]()
    var knownCardIds = [Int: String]()
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
    var playerTracker: Tracker?
    var opponentTracker: Tracker?
    var lastCardPlayed: Int?
    var activeDeck: Deck?
    var currentEntityId = Int.min
    
    static let instance = Game()

    init() {
        player = Player(true)
        opponent = Player(false)
    }

    func reset() {
        DDLogVerbose("Reseting Game")
        maxId = 0
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
        knownCardIds.removeAll()
        gameStartDate = nil
        gameEndDate = nil

        player.reset()
        opponent.reset()
    }
    
    func setActiveDeck(deck:Deck)
    {
        self.activeDeck = deck
        for card in deck.sortedCards {
            for _ in 0..<card.count {
                DDLogVerbose("adding \(card.cardId)")
                player.revealDeckCard(card.cardId, -1)
            }
        }
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
            if ent.hasTag(GameTag.PLAYER_ID) && !ent.isPlayer {
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
        if let tracker = playerTracker {
            tracker.gameStart()
        }
        opponent.gameStart()
        if let tracker = opponentTracker {
            tracker.gameStart()
        }
    }

    func gameEnd() {
        DDLogInfo("----- Game End -----")
        gameStarted = false
        gameEndDate = NSDate()

        //@opponent_cards = opponent_tracker.cards
        handleEndGame()

        player.gameEnd()
        if let tracker = playerTracker {
            tracker.gameEnd()
        }
        opponent.gameEnd()
        if let tracker = opponentTracker {
            tracker.gameEnd()
        }
        // TODO [self.timerHud gameEnd]
    }
    
    func setPlayerTracker(tracker:Tracker?) {
        self.playerTracker = tracker
        if let playerTracker = self.playerTracker {
            playerTracker.player = self.player
        }
    }
    
    func setOpponentTracker(tracker:Tracker?) {
        self.opponentTracker = tracker
        if let opponentTracker = self.opponentTracker {
            opponentTracker.player = self.opponent
        }
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
                if ent.hasTag(GameTag.FIRST_PLAYER) {
                    player = ent
                    break
                }
            }
            if player != nil {
                currentTurn = player!.getTag(GameTag.CONTROLLER) == self.player.id ? 0 : 1
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
            return Int(Double(entity!.getTag(GameTag.TURN) + _turn) / 2.0)
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
            } else if ent.hasTag(GameTag.PLAYER_ID) && !ent.isPlayer {
                opponent = ent
            }
        }

        if player == nil || opponent == nil {
            return false
        }
        return player!.hasTag(GameTag.MULLIGAN_STATE) && player!.getTag(GameTag.MULLIGAN_STATE) == Mulligan.DONE.rawValue
                && opponent!.hasTag(GameTag.MULLIGAN_STATE) && opponent!.getTag(GameTag.MULLIGAN_STATE) == Mulligan.DONE.rawValue
    }
    
    func handleZonePositionUpdate(playerType:PlayerType, _ entity:Entity, _ zone:Zone, _ turn:Int) {
        if playerType == .Player {
            player.updateZonePos(entity, zone, turn)
        }
        else if playerType == .Opponent {
            opponent.updateZonePos(entity, zone, turn)
        }
    }

    // MARK: - player
    func setPlayerHero(cardId: String) {
        player.playerClass = Cards.byId(cardId)
        if let card = player.playerClass {
            DDLogInfo("player is \(card.name)")
        }
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
        player.createInHand(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
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
        if let tracker = playerTracker {
            tracker.update()
        }
        player.boardToHand(entity, turn)
    }


    func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.boardToDeck(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerPlay(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.play(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.handDiscard(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerSecretPlayed(entity: Entity, cardId: String?, turn: Int, fromDeck: Bool) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        if fromDeck {
            player.secretPlayedFromDeck(entity, turn)
        } else {
            player.secretPlayedFromHand(entity, turn)
        }
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerMulligan(entity: Entity, cardId: String?) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        //TurnTimer.Instance.MulliganDone(ActivePlayer.Player);
        player.mulligan(entity)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerDraw(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        if cardId == "GAME_005" {
            playerGet(entity, cardId: cardId, turn: turn)
        } else {
            player.draw(entity, turn)
            if let tracker = playerTracker {
                tracker.update()
            }
        }
    }

    func playerRemoveFromDeck(entity: Entity, turn: Int) {
        player.removeFromDeck(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        player.deckDiscard(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        player.deckToPlay(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        player.playToGraveyard(entity, cardId, turn)
    }

    func playerJoust(entity: Entity, cardId: String?, turn: Int) {
        player.joustReveal(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerGetToDeck(entity: Entity, cardId: String?, turn: Int) {
        if cardId == nil || cardId!.isEmpty {
            return
        }
        player.createInDeck(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerFatigue(value: Int) {
        DDLogInfo("Player get \(value) fatigue")
        player.fatigue = value
    }

    func playerCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        player.createInPlay(entity, turn)
    }

    func playerStolen(entity: Entity, cardId: String?, turn: Int) {
        player.stolenByOpponent(entity, turn)
        opponent.stolenFromOpponent(entity, turn)
    }

    //MARK: - opponent

    func setOpponentHero(cardId: String) {
        opponent.playerClass = Cards.byId(cardId)
        if let card = opponent.playerClass {
            DDLogInfo("opponent is \(card.name)")
        }
    }

    func setOpponentName(name: String) {
        opponent.name = name
    }

    func opponentGet(entity: Entity, turn: Int, id: Int) {
        opponent.createInHand(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.boardToHand(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        opponent.boardToDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentPlay(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.play(entity, turn)
        DDLogVerbose("player opponent play tracker -> \(opponentTracker)")
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentHandDiscard(entity: Entity, cardId: String?, from: Int, turn: Int) {
        // TODO exception ???
        opponent.play(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentSecretPlayed(entity: Entity, cardId: String?, from: Int, turn: Int, fromDeck: Bool, id: Int) {
        if fromDeck {
            opponent.secretPlayedFromDeck(entity, turn)
        } else {
            opponent.secretPlayedFromHand(entity, turn)
        }
    }

    func opponentMulligan(entity: Entity, from: Int) {
        opponent.mulligan(entity)
    }

    func opponentDraw(entity: Entity, turn: Int) {
        opponent.draw(entity, turn)
    }

    func opponentRemoveFromDeck(entity: Entity, turn: Int) {
        opponent.removeFromDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckDiscard(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckToPlay(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentPlayToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        opponent.playToGraveyard(entity, cardId, turn)
    }

    func opponentJoust(entity: Entity, cardId: String?, turn: Int) {
        opponent.joustReveal(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentGetToDeck(entity: Entity, cardId: String?, turn: Int) {
        opponent.createInDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentSecretTrigger(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.secretTriggered(entity, turn)
    }

    func opponentFatigue(value: Int) {
        opponent.fatigue = value
    }

    func opponentCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.createInPlay(entity, turn)
    }

    func opponentStolen(entity: Entity, cardId: String?, turn: Int) {
        opponent.stolenByOpponent(entity, turn)
        player.stolenFromOpponent(entity, turn)
        if let tracker = opponentTracker where entity.isSecret {
            tracker.update()
        }
    }
}
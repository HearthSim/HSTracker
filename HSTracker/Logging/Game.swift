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
    case Player, Opponent, DeckManager
}

class Game {
    var currentTurn: Int = 0
    var currentRank: Int = 0
    var maxId: Int = 0
    var lastId: Int = 0

    var player: Player
    var opponent: Player
    var currentMode: Mode? = .INVALID
    var previousMode: Mode? = .INVALID
    var currentGameMode: GameMode = .None
    var entities = [Int: Entity]()
    var tmpEntities = [Entity]()
    var knownCardIds = [Int: String]()
    var joustReveals: Int = 0
    var awaitingRankedDetection: Bool = true
    var lastAssetUnload: Double = 0
    var waitController: TempEntity?
    var gameStarted: Bool = false
    var gameEnded: Bool = true
    var gameStartDate: NSDate?
    var gameResult: GameResult = .Unknow
    var gameEndDate: NSDate?
    var waitingForFirstAssetUnload: Bool = true
    var playerTracker: Tracker?
    var opponentTracker: Tracker?
    var lastCardPlayed: Int?
    var activeDeck: Deck?
    var currentEntityId = Int.min
    var currentEntityHasCardId: Bool = false
    var playerUsedHeroPower: Bool = false
    var hasCoin: Bool = false
    var opponentUsedHeroPower: Bool = false

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
        awaitingRankedDetection = false
        lastAssetUnload = -1
        waitController = nil
        gameStarted = false
        gameResult = GameResult.Unknow;
        knownCardIds.removeAll()
        gameStartDate = nil
        gameEndDate = nil
        gameEnded = false

        player.reset()
        opponent.reset()
        if activeDeck != nil {
            activeDeck?.reset()
            setActiveDeck(activeDeck!)
        }
    }

    func hearthstoneIsActive(active: Bool) {
        if let tracker = self.playerTracker {
            changeTracker(tracker, active, SizeHelper.playerTrackerFrame())
        }
        if let tracker = self.opponentTracker {
            changeTracker(tracker, active, SizeHelper.opponentTrackerFrame())
        }
    }

    private func changeTracker(tracker: Tracker, _ active: Bool, _ frame: NSRect?) {
        if active {
            tracker.window?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
            // TODO check for setting
            if let frame = frame {
                tracker.window?.setFrame(frame, display: true)
            }
        }
        else {
            tracker.window?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
    }

    func setActiveDeck(deck: Deck)
    {
        self.activeDeck = deck
        for card in deck.sortedCards {
            for _ in 0 ..< card.count {
                DDLogVerbose("adding \(card.cardId)")
                player.revealDeckCard(card.cardId, -1)
            }
        }
    }

    var playerEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.isPlayer }
    }

    var opponentEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.hasTag(GameTag.PLAYER_ID) && !$0.isPlayer }
    }

    var gameEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.name == "GameEntity" }
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

        // @opponent_cards = opponent_tracker.cards
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

    func setPlayerTracker(tracker: Tracker?) {
        self.playerTracker = tracker
        if let playerTracker = self.playerTracker {
            playerTracker.player = self.player
        }
    }

    func setOpponentTracker(tracker: Tracker?) {
        self.opponentTracker = tracker
        if let opponentTracker = self.opponentTracker {
            opponentTracker.player = self.opponent
        }
    }

    func handleEndGame() {
        if currentGameMode == .None || currentGameMode == .Casual {
            waitForRank(5) {
                self.handleEndGame()
            }
            return
        }

        DDLogInfo("End game : mode=\(currentGameMode), rank=\(currentRank), result=\(gameResult), against=\(opponent.name)(\(opponent.playerClass)), opponent played : \(opponent.displayReveleadCards())")

        if let deck = activeDeck,
            let opponentName = opponent.name,
            let opponentClass = opponent.playerClass?.playerClass {
                let statistic = Statistic()
                statistic.opponentName = opponentName
                statistic.opponentClass = opponentClass
                statistic.gameResult = gameResult
                statistic.hasCoin = hasCoin
                statistic.playerRank = currentRank
                statistic.playerMode = currentGameMode
                deck.addStatistic(statistic)
                deck.save()
        }
    }

    func waitForRank(seconds: Double, completion: () -> Void) {
        DDLogInfo("waiting for rank")
        let timeout = NSDate().timeIntervalSince1970 + seconds
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while NSDate().timeIntervalSince1970 - self.lastAssetUnload < timeout {
                NSThread.sleepForTimeInterval(0.1)
                if self.currentRank != 0 {
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
        // rankFound = false
        lastAssetUnload = NSDate().timeIntervalSince1970
        waitingForFirstAssetUnload = true
        let timeout = NSDate().timeIntervalSince1970 + seconds
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while self.waitingForFirstAssetUnload || NSDate().timeIntervalSince1970 - self.lastAssetUnload < timeout {
                NSThread.sleepForTimeInterval(0.1)
                if self.currentGameMode != .None {
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
        if let gameEntity = self.gameEntity {
            return (gameEntity.getTag(GameTag.TURN) + 1) / 2
        }
        return 0
    }

    func turnStart(player: PlayerType, _ turn: Int) {
        DDLogInfo("Turn \(turn) start for player \(player.rawValue)")
        // timer_hud.restart(player)
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
        gameResult = GameResult.Loss
    }

    func tied() {
        DDLogInfo("You lose :( / game tied:(")
        gameResult = GameResult.Tied
    }

    func isMulliganDone() -> Bool {
        let player = entities.map { $0.1 }.firstWhere { $0.isPlayer }
        let opponent = entities.map { $0.1 }.firstWhere { $0.hasTag(.PLAYER_ID) && !$0.isPlayer }

        if let player = player, let opponent = opponent {
            return player.hasTag(.MULLIGAN_STATE) && player.getTag(.MULLIGAN_STATE) == Mulligan.DONE.rawValue
            && opponent.hasTag(.MULLIGAN_STATE) && opponent.getTag(.MULLIGAN_STATE) == Mulligan.DONE.rawValue
        }
        return false
    }

    func zonePositionUpdate(playerType: PlayerType, _ entity: Entity, _ zone: Zone, _ turn: Int) {
        if playerType == .Player {
            player.updateZonePos(entity, zone, turn)
        }
        else if playerType == .Opponent {
            opponent.updateZonePos(entity, zone, turn)
        }
    }

    // MARK: - player
    func setPlayerHero(cardId: String) {
        if let card = Cards.heroById(cardId) {
            player.playerClass = card
            DDLogInfo("Player class is \(card.name)")
        }
    }

    func setPlayerRank(rank: Int) {
        DDLogInfo("Player rank is \(rank)")
        currentRank = rank
    }

    func setPlayerName(name: String) {
        player.name = name
    }

    func playerGet(entity: Entity, _ cardId: String?, _ turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.createInHand(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
        if cardId == "GAME_005" {
            hasCoin = true
            DDLogInfo("Player got the coin")
        }
    }

    func playerBackToHand(entity: Entity, _ cardId: String?, _ turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        if let tracker = playerTracker {
            tracker.update()
        }
        player.boardToHand(entity, turn)
    }

    func playerPlayToDeck(entity: Entity, _ cardId: String?, _ turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.boardToDeck(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerPlay(entity: Entity, _ cardId: String?, _ turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.play(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerHandDiscard(entity: Entity, _ cardId: String?, _ turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.handDiscard(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerSecretPlayed(entity: Entity, _ cardId: String?, _ turn: Int, _ fromDeck: Bool) {
        if String.isNullOrEmpty(cardId) {
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

    func playerMulligan(entity: Entity, _ cardId: String?) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        // TurnTimer.Instance.MulliganDone(ActivePlayer.Player);
        player.mulligan(entity)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerDraw(entity: Entity, _ cardId: String?, _ turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        if cardId == "GAME_005" {
            playerGet(entity, cardId, turn)
        } else {
            player.draw(entity, turn)
            if let tracker = playerTracker {
                tracker.update()
            }
        }
    }

    func playerRemoveFromDeck(entity: Entity, _ turn: Int) {
        player.removeFromDeck(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerDeckDiscard(entity: Entity, _ cardId: String?, _ turn: Int) {
        player.deckDiscard(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerDeckToPlay(entity: Entity, _ cardId: String?, _ turn: Int) {
        player.deckToPlay(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerPlayToGraveyard(entity: Entity, _ cardId: String?, _ turn: Int) {
        player.playToGraveyard(entity, cardId, turn)
    }

    func playerJoust(entity: Entity, _ cardId: String?, _ turn: Int) {
        player.joustReveal(entity, turn)
        if let tracker = playerTracker {
            tracker.update()
        }
    }

    func playerGetToDeck(entity: Entity, _ cardId: String?, _ turn: Int) {
        if String.isNullOrEmpty(cardId) {
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

    func playerCreateInPlay(entity: Entity, _ cardId: String?, _ turn: Int) {
        player.createInPlay(entity, turn)
    }

    func playerStolen(entity: Entity, _ cardId: String?, _ turn: Int) {
        player.stolenByOpponent(entity, turn)
        opponent.stolenFromOpponent(entity, turn)
    }

    func playerRemoveFromPlay(entity: Entity, _ turn: Int) {
        player.removeFromPlay(entity, turn)
    }

    // MARK: - opponent
    func setOpponentHero(cardId: String) {
        if let card = Cards.heroById(cardId) {
            opponent.playerClass = card
            DDLogInfo("Opponent class is \(card.name)")
        }
    }

    func setOpponentName(name: String) {
        opponent.name = name
    }

    func opponentGet(entity: Entity, _ turn: Int, _ id: Int) {
        opponent.createInHand(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentPlayToHand(entity: Entity, _ cardId: String?, _ turn: Int, _ id: Int) {
        opponent.boardToHand(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentPlayToDeck(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.boardToDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentPlay(entity: Entity, _ cardId: String?, _ from: Int, _ turn: Int) {
        opponent.play(entity, turn)
        DDLogVerbose("player opponent play tracker -> \(opponentTracker)")
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentHandDiscard(entity: Entity, _ cardId: String?, _ from: Int, _ turn: Int) {
        // TODO exception ???
        opponent.play(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentSecretPlayed(entity: Entity, _ cardId: String?, _ from: Int, _ turn: Int, _ fromDeck: Bool, _ id: Int) {
        if fromDeck {
            opponent.secretPlayedFromDeck(entity, turn)
        } else {
            opponent.secretPlayedFromHand(entity, turn)
        }
    }

    func opponentMulligan(entity: Entity, _ from: Int) {
        opponent.mulligan(entity)
    }

    func opponentDraw(entity: Entity, _ turn: Int) {
        opponent.draw(entity, turn)
    }

    func opponentRemoveFromDeck(entity: Entity, _ turn: Int) {
        opponent.removeFromDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentDeckDiscard(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.deckDiscard(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentDeckToPlay(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.deckToPlay(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentPlayToGraveyard(entity: Entity, _ cardId: String?, _ turn: Int, _ playersTurn: Bool) {
        opponent.playToGraveyard(entity, cardId, turn)
        /*if playersTurn && entity.IsMinion {
         opponentMinionDeath(entity, turn)
         }*/
    }

    func opponentJoust(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.joustReveal(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentGetToDeck(entity: Entity, _ turn: Int) {
        opponent.createInDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
    }

    func opponentSecretTrigger(entity: Entity, _ cardId: String?, _ turn: Int, _ id: Int) {
        opponent.secretTriggered(entity, turn)
    }

    func opponentFatigue(value: Int) {
        opponent.fatigue = value
    }

    func opponentCreateInPlay(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.createInPlay(entity, turn)
    }

    func opponentStolen(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.stolenByOpponent(entity, turn)
        player.stolenFromOpponent(entity, turn)
        if let tracker = opponentTracker where entity.isSecret {
            tracker.update()
        }
    }

    func opponentRemoveFromPlay(entity: Entity, _ turn: Int) {
        opponent.removeFromPlay(entity, turn)
    }

    func handleDefendingEntity(entity: Entity?) {
        /*_defendingEntity = entity;
         if(_attackingEntity != null && _defendingEntity != null)
         _game.OpponentSecrets.ZeroFromAttack(_attackingEntity, _defendingEntity);
         */
    }

    func handleAttackingEntity(entity: Entity?) {
        /*_defendingEntity = entity;
         if(_attackingEntity != null && _defendingEntity != null)
         _game.OpponentSecrets.ZeroFromAttack(_attackingEntity, _defendingEntity);
         */
    }
}
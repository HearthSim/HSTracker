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
    case Player, Opponent, DeckManager, Secrets
}

class Game {
    var currentTurn = 0
    var currentRank = 0
    var maxId = 0
    var lastId = 0

    var player: Player
    var opponent: Player
    var currentMode: Mode? = .INVALID
    var previousMode: Mode? = .INVALID
    var currentGameMode: GameMode = .None
    var entities = [Int: Entity]()
    var tmpEntities = [Entity]()
    var knownCardIds = [Int: String]()
    var joustReveals = 0
    var awaitingRankedDetection = true
    var lastAssetUnload: Double = 0
    var gameStarted = false
    var gameEnded = true
    var gameStartDate: NSDate?
    var gameResult: GameResult = .Unknow
    var gameEndDate: NSDate?
    var waitingForFirstAssetUnload = true
    var playerTracker: Tracker?
    var opponentTracker: Tracker?
    var secretTracker: SecretTracker?
    var timerHud: TimerHud?
    var cardHuds: [CardHud]?
    var lastCardPlayed: Int?
    var activeDeck: Deck?
    var currentEntityId = Int.min
    var currentEntityHasCardId = false
    var playerUsedHeroPower = false
    var hasCoin = false
    var currentEntityZone: Zone? = .INVALID
    var opponentUsedHeroPower = false
    var determinedPlayers = false
    var setupDone = false
    var proposedKeyPoint: ReplayKeyPoint?
    var opponentSecrets: OpponentSecrets?
    var defendingEntity: Entity?
    var attackingEntity: Entity?
    private var avengeDeathRattleCount = 0
    var opponentSecretCount = 0
    private var awaitingAvenge = false
    var isInMenu = true
    var endGameStats = false

    static let instance = Game()

    init() {
        player = Player(true)
        opponent = Player(false)
        opponentSecrets = OpponentSecrets(game: self)
    }

    func reset() {
        DDLogVerbose("Reseting Game")
        maxId = 0
        currentTurn = -1
        entities.removeAll()
        tmpEntities.removeAll()
        lastCardPlayed = 0
        joustReveals = 0
        awaitingRankedDetection = false
        lastAssetUnload = -1
        gameStarted = false
        gameResult = .Unknow;
        knownCardIds.removeAll()
        gameStartDate = nil
        gameEndDate = nil
        gameEnded = false
        determinedPlayers = false
        setupDone = false
        currentEntityZone = .INVALID
        currentEntityId = Int.min
        currentEntityHasCardId = false
        playerUsedHeroPower = false
        hasCoin = false
        endGameStats = false

        opponentSecretCount = 0
        opponentSecrets?.clearSecrets()
        secretTracker?.window?.orderOut(self)
        timerHud?.window?.orderOut(self)

        player.reset()
        opponent.reset()

        updateCardHuds()

        if let activeDeck = activeDeck {
            activeDeck.reset()
            addDeckCards()
        }
    }

    var isMinionInPlay: Bool {
        return entities.map { $0.1 }.firstWhere { $0.isInPlay && $0.isMinion } != nil
    }

    var isOpponentMinionInPlay: Bool {
        return entities.map { $0.1 }.firstWhere { $0.isInPlay && $0.isMinion && $0.isControlledBy(self.opponent.id!) } != nil
    }

    var opponentMinionCount: Int { return entities.map { $0.1 }.filter { $0.isInPlay && $0.isMinion && $0.isControlledBy(self.opponent.id!) }.count }

    var playerMinionCount: Int { return entities.map { $0.1 }.filter { $0.isInPlay && $0.isMinion && $0.isControlledBy(self.player.id!) }.count }

    func hearthstoneIsActive(active: Bool) {
        if Settings.instance.autoPositionTrackers {
            if let tracker = self.playerTracker {
                changeTracker(tracker, active, SizeHelper.playerTrackerFrame())
            }
            if let tracker = self.opponentTracker {
                changeTracker(tracker, active, SizeHelper.opponentTrackerFrame())
            }
        }
        if let tracker = self.secretTracker {
            changeTracker(tracker, active, SizeHelper.secretTrackerFrame())
        }
        if let tracker = self.timerHud {
            changeTracker(tracker, active, SizeHelper.timerHudFrame())
        }

        if let cardHuds = cardHuds {
            let count = opponent.handCount
            if count == 0 {
                for hud in cardHuds {
                    hud.window?.orderOut(self)
                }
            }
            else {
                for i in 0 ..< count {
                    if i > cardHuds.count {
                        continue
                    }
                    if let frame = SizeHelper.opponentCardHudFrame(i, count) {
                        cardHuds[i].window?.setFrame(frame, display: true)
                    }
                }
            }
        }
    }

    private func changeTracker(tracker: NSWindowController, _ active: Bool, _ frame: NSRect?) {
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

    func setActiveDeck(deck: Deck) {
        self.activeDeck = deck
        addDeckCards()
        playerTracker?.update()
    }

    func removeActiveDeck() {
        self.activeDeck = nil
        player.resetDeck()
        playerTracker?.update()
    }

    private func addDeckCards() {
        player.resetDeck()
        if let deck = activeDeck {
            for card in deck.sortedCards {
                for _ in 0 ..< card.count {
                    player.revealDeckCard(card.cardId, -1)
                }
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
        isInMenu = false

        DDLogInfo("----- Game Started -----")

        self.playerTracker?.gameStart()
        self.opponentTracker?.gameStart()
        self.timerHud?.showWindow(self)
        TurnTimer.instance.reset()
    }

    func gameEnd() {
        DDLogInfo("----- Game End -----")
        gameStarted = false
        gameEndDate = NSDate()

        // @opponent_cards = opponent_tracker.cards
        handleEndGame()

        self.playerTracker?.gameEnd()
        self.opponentTracker?.gameEnd()
        self.timerHud?.window?.orderOut(self)
        if let cardHuds = cardHuds {
            for i in 0 ... 10 {
                let cardHud = cardHuds[i]
                cardHud.window?.orderOut(self)
            }
        }
        if let secretTracker = self.secretTracker {
            secretTracker.window!.orderOut(self)
        }
    }

    func inMenu() {
        if isInMenu {
            return
        }
        DDLogVerbose("Game is now in menu")
        
        /*if(Config.Instance.RecordReplays && _game.Entities.Count > 0 && !_game.SavedReplay && _game.CurrentGameStats != null
        && _game.CurrentGameStats.ReplayFile == null && RecordCurrentGameMode)
        _game.CurrentGameStats.ReplayFile = ReplayMaker.SaveToDisk(_game.PowerLog);*/
        ReplayMaker.saveToDisk()
        
        isInMenu = true
    }

    func proposeKeyPoint(type: KeyPointType, _ id: Int, _ player: PlayerType) {
        if let proposedKeyPoint = proposedKeyPoint {
            ReplayMaker.generate(proposedKeyPoint.type, proposedKeyPoint.id, proposedKeyPoint.player, self)
        }
        proposedKeyPoint = ReplayKeyPoint(data: nil, type: type, id: id, player: player)
    }

    func gameEndKeyPoint(victory: Bool, _ id: Int) {
        if let proposedKeyPoint = proposedKeyPoint {
            ReplayMaker.generate(proposedKeyPoint.type, proposedKeyPoint.id, proposedKeyPoint.player, self)
            self.proposedKeyPoint = nil
        }
        ReplayMaker.generate(victory ? .Victory : .Defeat, id, .Player, self)
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

    func setSecretTracker(tracker: SecretTracker?) {
        self.secretTracker = tracker
    }

    func setTimerHud(timerHud: TimerHud?) {
        self.timerHud = timerHud
    }

    func setCardHuds(cardHuds: [CardHud]) {
        self.cardHuds = cardHuds
    }

    func handleEndGame() {
        if currentGameMode == .None || currentGameMode == .Casual {
            waitForRank(5) {
                self.handleEndGame()
            }
            return
        }

        if endGameStats {
            return
        }
        endGameStats = true

        let _player = entities.map { $0.1 }.firstWhere { $0.isPlayer }
        if let _player = _player {
            hasCoin = !_player.hasTag(.FIRST_PLAYER)
        }

        DDLogInfo("End game : mode = \(currentGameMode), rank = \(currentRank), result = \(gameResult), against = \(opponent.name)(\(opponent.playerClass)), opponent played : \(opponent.displayReveleadCards()) ")

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
        let timeout = NSDate().timeIntervalSince1970 + seconds
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while NSDate().timeIntervalSince1970 - self.lastAssetUnload < timeout {
                NSThread.sleepForTimeInterval(0.5)
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
            return (gameEntity.getTag(.TURN) + 1) / 2
        }
        return 0
    }

    func turnStart(player: PlayerType, _ turn: Int) {
        DDLogInfo("Turn \(turn) start for player \(player) ")
        TurnTimer.instance.currentActivePlayer = player
        TurnTimer.instance.restart()
    }

    func concede() {
        DDLogInfo("Game has been conceded : (")
    }

    func win() {
        DDLogInfo("You win ¯\\_(ツ) _ / ¯")
        gameResult = GameResult.Win
    }

    func loss() {
        DDLogInfo("You lose : (")
        gameResult = GameResult.Loss
    }

    func tied() {
        DDLogInfo("You lose : ( / game tied: (")
        gameResult = GameResult.Tied
    }

    func isMulliganDone() -> Bool {
        let player = entities.map { $0.1 }.firstWhere { $0.isPlayer }
        let opponent = entities.map { $0.1 }.firstWhere { $0.hasTag(.PLAYER_ID) && !$0.isPlayer }

        if let player = player, let opponent = opponent {
            return player.getTag(.MULLIGAN_STATE) == Mulligan.DONE.rawValue
            && opponent.getTag(.MULLIGAN_STATE) == Mulligan.DONE.rawValue
        }
        return false
    }

    func zonePositionUpdate(playerType: PlayerType, _ entity: Entity, _ zone: Zone, _ turn: Int) {
        if playerType == .Player {
            player.updateZonePos(entity, zone, turn)
        }
        else if playerType == .Opponent {
            opponent.updateZonePos(entity, zone, turn)
            updateCardHuds()
        }
    }

    // MARK: - player
    func setPlayerHero(cardId: String) {
        if let card = Cards.heroById(cardId) {
            player.playerClass = card
            DDLogInfo("Player class is \(card) ")
        }
    }

    func setPlayerRank(rank: Int) {
        DDLogInfo("Player rank is \(rank) ")
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

        secretsOnPlay(entity)
    }

    func secretsOnPlay(entity: Entity) {
        if Settings.instance.autoGrayoutSecrets {
            return
        }

        if entity.isSpell {
            opponentSecrets?.setZero(CardIds.Secrets.Mage.Counterspell)

            if opponentMinionCount < 7 {
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(50 * Double(NSEC_PER_MSEC)))
                let queue = dispatch_get_main_queue()
                dispatch_after(when, queue) {
                    // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                    if entity.hasTag(.CARD_TARGET) && self.entities[entity.getTag(.CARD_TARGET)]!.isMinion {
                        self.opponentSecrets?.setZero(CardIds.Secrets.Mage.Spellbender)
                    }

                    dispatch_async(dispatch_get_main_queue()) {
                        if let secretTracker = self.secretTracker,
                            let opponentSecrets = self.opponentSecrets {
                                secretTracker.setSecrets(opponentSecrets)
                                secretTracker.showWindow(self)
                        }
                    }
                }
            }
        }
        else if entity.isMinion && playerMinionCount > 3 {
            opponentSecrets?.setZero(CardIds.Secrets.Paladin.SacredTrial)
            
            if let secretTracker = self.secretTracker,
                let opponentSecrets = opponentSecrets {
                    secretTracker.setSecrets(opponentSecrets)
                    secretTracker.showWindow(self)
            }
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
            secretsOnPlay(entity)
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

        if entity.isSecret {
            var heroClass: HeroClass?
            var className = "\(entity.getTag(.CLASS)) "
            if !String.isNullOrEmpty(className) {
                className = className.capitalizedString
                heroClass = HeroClass(rawValue: className)
                if heroClass == .None {
                    if let playerClass = opponent.playerClass {
                        heroClass = HeroClass(rawValue: playerClass.playerClass)
                    }
                }
            }
            else {
                if let playerClass = opponent.playerClass {
                    heroClass = HeroClass(rawValue: playerClass.playerClass)
                }
            }
            guard let _ = heroClass else { return }
            opponentSecretCount++
            opponentSecrets?.newSecretPlayed(heroClass!, entity.id, turn)
            if let secretTracker = self.secretTracker,
                let opponentSecrets = opponentSecrets {
                    secretTracker.setSecrets(opponentSecrets)
                    secretTracker.showWindow(self)
            }
        }
    }

    func playerRemoveFromPlay(entity: Entity, _ turn: Int) {
        player.removeFromPlay(entity, turn)
    }

    func playerHeroPower(cardId: String, _ turn: Int) {
        DDLogInfo("Player Hero Power \(cardId) \(turn) ")

        if !Settings.instance.autoGrayoutSecrets {
            return
        }
        opponentSecrets?.setZero(CardIds.Secrets.Hunter.DartTrap)

        if let secretTracker = self.secretTracker,
            let opponentSecrets = opponentSecrets {
                secretTracker.setSecrets(opponentSecrets)
                secretTracker.showWindow(self)
        }
    }

    // MARK: - opponent
    func setOpponentHero(cardId: String) {
        if let card = Cards.heroById(cardId) {
            opponent.playerClass = card
            DDLogInfo("Opponent class is \(card) ")
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
        updateCardHuds()
    }

    func opponentPlayToHand(entity: Entity, _ cardId: String?, _ turn: Int, _ id: Int) {
        opponent.boardToHand(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentPlayToDeck(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.boardToDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentPlay(entity: Entity, _ cardId: String?, _ from: Int, _ turn: Int) {
        opponent.play(entity, turn)
        DDLogVerbose("player opponent play tracker -> \(opponentTracker) ")
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentHandDiscard(entity: Entity, _ cardId: String?, _ from: Int, _ turn: Int) {
        opponent.play(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentSecretPlayed(entity: Entity, _ cardId: String?, _ from: Int, _ turn: Int, _ fromDeck: Bool, _ otherId: Int) {
        opponentSecretCount++

        if fromDeck {
            opponent.secretPlayedFromDeck(entity, turn)
        } else {
            opponent.secretPlayedFromHand(entity, turn)
        }
        updateCardHuds()

        var heroClass: HeroClass?
        var className = "\(entity.getTag(.CLASS))"
        if !String.isNullOrEmpty(className) {
            className = className.capitalizedString
            heroClass = HeroClass(rawValue: className)
            if heroClass == .None {
                if let playerClass = opponent.playerClass {
                    heroClass = HeroClass(rawValue: playerClass.playerClass.capitalizedString)
                }
            }
        }
        else {
            if let playerClass = opponent.playerClass {
                heroClass = HeroClass(rawValue: playerClass.playerClass.capitalizedString)
            }
        }
        DDLogVerbose("Secret played by \(entity.getTag(.CLASS)) -> \(heroClass) -> \(opponent.playerClass)")
        guard let _ = heroClass else { return }

        opponentSecrets?.newSecretPlayed(heroClass!, otherId, turn)
        if let secretTracker = self.secretTracker,
            let opponentSecrets = opponentSecrets {
                secretTracker.setSecrets(opponentSecrets)
                secretTracker.showWindow(self)
        }
    }

    func opponentMulligan(entity: Entity, _ from: Int) {
        opponent.mulligan(entity)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentDraw(entity: Entity, _ turn: Int) {
        opponent.draw(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentRemoveFromDeck(entity: Entity, _ turn: Int) {
        opponent.removeFromDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentDeckDiscard(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.deckDiscard(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentDeckToPlay(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.deckToPlay(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentPlayToGraveyard(entity: Entity, _ cardId: String?, _ turn: Int, _ playersTurn: Bool) {
        opponent.playToGraveyard(entity, cardId, turn)
        if playersTurn && entity.isMinion {
            opponentMinionDeath(entity, turn)
        }
        updateCardHuds()
    }

    func opponentJoust(entity: Entity, _ cardId: String?, _ turn: Int) {
        opponent.joustReveal(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentGetToDeck(entity: Entity, _ turn: Int) {
        opponent.createInDeck(entity, turn)
        if let tracker = opponentTracker {
            tracker.update()
        }
        updateCardHuds()
    }

    func opponentSecretTrigger(entity: Entity, _ cardId: String?, _ turn: Int, _ otherId: Int) {
        opponent.secretTriggered(entity, turn)

        opponentSecretCount--
        opponentSecrets?.secretRemoved(otherId, cardId!)
        if opponentSecretCount <= 0 {
            if let secretTracker = self.secretTracker {
                secretTracker.window!.orderOut(self)
            }
        } else {
            if Settings.instance.autoGrayoutSecrets {
                opponentSecrets?.setZero(cardId!)
            }
            if let secretTracker = self.secretTracker,
                let opponentSecrets = opponentSecrets {
                    secretTracker.setSecrets(opponentSecrets)
                    secretTracker.showWindow(self)
            }
        }
        updateCardHuds()
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

        if entity.isSecret {
            opponentSecretCount--
            opponentSecrets?.secretRemoved(entity.id, cardId!)
            if opponentSecretCount <= 0 {
                if let secretTracker = self.secretTracker,
                    let opponentSecrets = opponentSecrets {
                        secretTracker.setSecrets(opponentSecrets)
                        secretTracker.window!.orderOut(self)
                }
            } else {
                if Settings.instance.autoGrayoutSecrets {
                    opponentSecrets?.setZero(cardId!)
                }
                if let secretTracker = self.secretTracker,
                    let opponentSecrets = opponentSecrets {
                        secretTracker.setSecrets(opponentSecrets)
                        secretTracker.showWindow(self)
                }
            }

            if let tracker = opponentTracker {
                tracker.update()
            }
        }
    }

    func opponentRemoveFromPlay(entity: Entity, _ turn: Int) {
        player.removeFromPlay(entity, turn)
    }

    func opponentHeroPower(cardId: String, _ turn: Int) {
        DDLogInfo("Opponent Hero Power \(cardId) \(turn) ")
    }

    // MARK: - game actions
    func defendingEntity(entity: Entity?) {
        self.defendingEntity = entity
        if let attackingEntity = self.attackingEntity, let defendingEntity = self.defendingEntity {
            opponentSecrets?.zeroFromAttack(attackingEntity, defendingEntity)
        }
    }

    func attackingEntity(entity: Entity?) {
        self.attackingEntity = entity
        if let attackingEntity = self.attackingEntity, let defendingEntity = self.defendingEntity {
            opponentSecrets?.zeroFromAttack(attackingEntity, defendingEntity)
        }
    }

    func playerMinionPlayed() {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        opponentSecrets?.setZero(CardIds.Secrets.Hunter.Snipe)
        opponentSecrets?.setZero(CardIds.Secrets.Mage.MirrorEntity)
        opponentSecrets?.setZero(CardIds.Secrets.Paladin.Repentance)

        if let secretTracker = self.secretTracker,
            let opponentSecrets = opponentSecrets {
                secretTracker.setSecrets(opponentSecrets)
                secretTracker.showWindow(self)
        }
    }

    func opponentMinionDeath(entity: Entity, _ turn: Int) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        if opponent.handCount < 10 {
            opponentSecrets?.setZero(CardIds.Secrets.Mage.Duplicate)
        }

        var numDeathrattleMinions = 0
        if entity.isActiveDeathrattle {
            if let count = CardIds.DeathrattleSummonCardIds[entity.cardId!] {
                numDeathrattleMinions = count
            }
            else {
                if entity.cardId == CardIds.Collectible.Neutral.Stalagg && opponent.graveyard.any({ $0.cardId == CardIds.Collectible.Neutral.Feugen })
                || entity.cardId == CardIds.Collectible.Neutral.Feugen && opponent.graveyard.any({ $0.cardId == CardIds.Collectible.Neutral.Stalagg }) {
                    numDeathrattleMinions = 1
                }
            }

            if entities.map({ $0.1 }).any({ $0.cardId == CardIds.NonCollectible.Druid.SoulOfTheForestEnchantment && $0.getTag(.ATTACHED) == entity.id }) {
                numDeathrattleMinions++
            }

            if entities.map({ $0.1 }).any({ $0.cardId == CardIds.NonCollectible.Shaman.AncestralSpiritEnchantment && $0.getTag(.ATTACHED) == entity.id }) {
                numDeathrattleMinions++
            }

            if let opponentEntity = opponentEntity where opponentEntity.hasTag(.EXTRA_DEATHRATTLES) {
                numDeathrattleMinions *= (opponentEntity.getTag(.EXTRA_DEATHRATTLES) + 1)
            }

            avengeAsync(numDeathrattleMinions)

            // redemption never triggers if a deathrattle effect fills up the board
            // effigy can trigger ahead of the deathrattle effect, but only if effigy was played before the deathrattle minion
            if opponentMinionCount < 7 - numDeathrattleMinions {
                opponentSecrets?.setZero(CardIds.Secrets.Paladin.Redemption)
                opponentSecrets?.setZero(CardIds.Secrets.Mage.Effigy)
            }
            else {
                // TODO need to properly break ties when effigy + deathrattle played in same turn
                let minionTurnPlayed = turn - entity.getTag(.NUM_TURNS_IN_PLAY)
                var secretOffset: Int = 0
                if let secret = opponentSecrets!.secrets.firstWhere({ $0.turnPlayed >= minionTurnPlayed }) {
                    secretOffset = opponentSecrets!.secrets.indexOf(secret)!
                }
                opponentSecrets?.setZeroOlder(CardIds.Secrets.Mage.Effigy, secretOffset)
            }
        }
        if let secretTracker = self.secretTracker,
            let opponentSecrets = opponentSecrets {
                secretTracker.setSecrets(opponentSecrets)
                secretTracker.showWindow(self)
        }
    }

    func avengeAsync(deathRattleCount: Int) {
        avengeDeathRattleCount += deathRattleCount
        if awaitingAvenge {
            return
        }
        awaitingAvenge = true
        if opponentMinionCount != 0 {
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(50 * Double(NSEC_PER_MSEC)))
            let queue = dispatch_get_main_queue()
            dispatch_after(when, queue) {
                if self.opponentMinionCount - self.avengeDeathRattleCount > 0 {
                    self.opponentSecrets?.setZero(CardIds.Secrets.Paladin.Avenge)
                    dispatch_async(dispatch_get_main_queue()) {
                        if let secretTracker = self.secretTracker,
                            let opponentSecrets = self.opponentSecrets {
                                secretTracker.setSecrets(opponentSecrets)
                                secretTracker.showWindow(self)
                        }
                        
                        self.awaitingAvenge = false
                        self.avengeDeathRattleCount = 0
                    }
                }
            }
        }
    }

    func opponentDamage(entity: Entity) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }
        if !entity.isHero || !entity.isControlledBy(opponent.id!) {
            return
        }
        opponentSecrets?.setZero(CardIds.Secrets.Paladin.EyeForAnEye)
        if let secretTracker = self.secretTracker,
            let opponentSecrets = opponentSecrets {
                secretTracker.setSecrets(opponentSecrets)
                secretTracker.showWindow(self)
        }
    }

    func opponentTurnStart(entity: Entity) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }
        if !entity.isMinion {
            return
        }
        opponentSecrets?.setZero(CardIds.Secrets.Paladin.CompetitiveSpirit)
        if let secretTracker = self.secretTracker,
            let opponentSecrets = opponentSecrets {
                secretTracker.setSecrets(opponentSecrets)
                secretTracker.showWindow(self)
        }
    }

    func updateCardHuds() {
        let opponentHandCount = opponent.handCount
        DDLogVerbose("updateCardHuds : \(opponentHandCount)")
        guard let _ = cardHuds else { return }

        if let cardHuds = cardHuds {
            for i in 0 ... 10 {
                if i > cardHuds.count || cardHuds[i] == .None {
                    continue
                }
                let cardHud = cardHuds[i]
                if i < opponentHandCount {
                    cardHud.setEntity(opponent.hand[i])
                    cardHud.showWindow(self)
                    if let frame = SizeHelper.opponentCardHudFrame(i, opponentHandCount) {
                        cardHud.window?.setFrame(frame, display: true)
                    }
                }
                else {
                    cardHud.window?.orderOut(self)
                }
            }
        }
    }
}
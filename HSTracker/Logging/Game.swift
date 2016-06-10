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
import CleanroomLogger

enum PlayerType: Int {
    case Player, Opponent, DeckManager, Secrets, CardList, Hero
}
enum NotificationType {
    case GameStart, TurnStart, OpponentConcede
}

class Game {
    // MARK: - vars
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
    var gameEnded = true {
        didSet {
            updateOpponentTracker(true)
        }
    }
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
    var currentEntityId = 0
    var currentEntityHasCardId = false
    var playerUsedHeroPower = false
    var hasCoin = false
    var currentEntityZone: Zone = .INVALID
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
    var wasInProgress = false
    var hasBeenConceded = false

    var victoryScreenShow = false
    var playerUpdateRequests = 0
    var opponentUpdateRequests = 0
    var lastCardsUpdateRequest = NSDate.distantPast().timeIntervalSince1970

    var playerEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.isPlayer }
    }

    var opponentEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.hasTag(GameTag.PLAYER_ID) && !$0.isPlayer }
    }

    var gameEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.name == "GameEntity" }
    }

    var isMinionInPlay: Bool {
        return entities.map { $0.1 }.firstWhere { $0.isInPlay && $0.isMinion } != nil
    }

    var isOpponentMinionInPlay: Bool {
        return entities.map { $0.1 }
            .firstWhere { $0.isInPlay && $0.isMinion
                && $0.isControlledBy(self.opponent.id) } != nil
    }

    var opponentMinionCount: Int {
        return entities.map { $0.1 }
            .filter { $0.isInPlay && $0.isMinion
                && $0.isControlledBy(self.opponent.id) }.count }

    var playerMinionCount: Int {
        return entities.map { $0.1 }
            .filter { $0.isInPlay && $0.isMinion
                && $0.isControlledBy(self.player.id) }.count }

    var currentFormat: Format? {
        if currentGameMode != GameMode.Casual && currentGameMode != GameMode.Ranked {
            return nil
        }
        if let deck = activeDeck where !deck.standardViable() {
            return .Wild
        }
        return entities.map { $0.1 }
            .filter { !String.isNullOrEmpty($0.cardId)
                && !$0.info.created && $0.card.set != nil }
            .any { CardSet.wildSets().contains($0.card.set!) } ? .Wild : .Standard
    }

    static let instance = Game()

    init() {
        player = Player(local: true)
        opponent = Player(local: false)
        opponentSecrets = OpponentSecrets(game: self)
    }

    func reset() {
        Log.verbose?.message("Reseting Game")
        currentTurn = 0
        victoryScreenShow = false
        maxId = 0
        lastId = 0

        entities.removeAll()
        tmpEntities.removeAll()
        knownCardIds.removeAll()
        joustReveals = 0
        awaitingRankedDetection = true
        lastAssetUnload = 0
        gameStarted = false
        gameEnded = true
        gameStartDate = nil
        gameResult = .Unknow
        gameEndDate = nil
        waitingForFirstAssetUnload = true
        lastCardPlayed = nil
        currentEntityId = 0
        currentEntityHasCardId = false
        playerUsedHeroPower = false
        hasCoin = false
        currentEntityZone = .INVALID
        opponentUsedHeroPower = false
        determinedPlayers = false
        setupDone = false
        proposedKeyPoint = nil
        opponentSecrets?.clearSecrets()
        defendingEntity = nil
        attackingEntity = nil
        avengeDeathRattleCount = 0
        opponentSecretCount = 0
        awaitingAvenge = false
        isInMenu = true
        endGameStats = false
        wasInProgress = false
        hasBeenConceded = false

        dispatch_async(dispatch_get_main_queue()) {
            self.secretTracker?.window?.orderOut(self)
            self.timerHud?.window?.orderOut(self)
        }

        player.reset()
        opponent.reset()

        updateCardHuds()

        if let activeDeck = activeDeck {
            activeDeck.reset()
        }
        Log.verbose?.message("Game resetted")
    }

    func setCurrentEntity(id: Int) {
        currentEntityId = id
        if let entity = entities[id] {
            entity.info.hasOutstandingTagChanges = true
        }
    }

    func resetCurrentEntity() {
        currentEntityId = 0
    }

    func setActiveDeck(deck: Deck) {
        self.activeDeck = deck
        player.reset(self.gameEnded ? true : false)
        updatePlayerTracker(true)
        NSNotificationCenter.defaultCenter().postNotificationName("active_deck_changed", object: nil)
    }

    func removeActiveDeck() {
        self.activeDeck = nil
        updatePlayerTracker(true)
        NSNotificationCenter.defaultCenter().postNotificationName("active_deck_changed", object: nil)
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

    // MARK: - game state
    func gameStart() {
        if gameStarted {
            return
        }
        reset()
        gameStarted = true
        gameStartDate = NSDate()
        gameEnded = false
        isInMenu = false

        Log.info?.message("----- Game Started -----")

        showNotification(.GameStart)
        self.updatePlayerTracker(true)
        self.updateOpponentTracker(true)
        dispatch_async(dispatch_get_main_queue()) {
            self.timerHud?.showWindow(self)

            TurnTimer.instance.start(self)
        }
    }

    func gameEnd() {
        Log.info?.message("----- Game End -----")
        gameStarted = false
        gameEndDate = NSDate()

        handleEndGame()
        updateOpponentTracker(true)

        dispatch_async(dispatch_get_main_queue()) {
            TurnTimer.instance.stop()
            self.timerHud?.window?.orderOut(self)
            self.cardHuds?.forEach {
                $0.window?.orderOut(self)
            }
        }

        showSecrets(false)
    }

    func inMenu() {
        if isInMenu {
            return
        }
        Log.verbose?.message("Game is now in menu")

        TurnTimer.instance.stop()

        // swiftlint:disable line_length
        /*if(Config.Instance.RecordReplays && _game.Entities.Count > 0 && !_game.SavedReplay && _game.CurrentGameStats != null
        && _game.CurrentGameStats.ReplayFile == null && RecordCurrentGameMode)
        _game.CurrentGameStats.ReplayFile = ReplayMaker.SaveToDisk(_game.PowerLog);*/
        // swiftlint:enable line_length
        ReplayMaker.saveToDisk()

        isInMenu = true
    }

    func handleEndGame() {
        Log.verbose?.message("currentRank: \(currentRank), currentGameMode: \(currentGameMode)")
        // when we loose the rank is not show, so we just wait 10 seconds max to
        // get the rank and then we save
        waitForRank(10) {
            self.saveStats()
        }
    }

    private func saveStats() {
        if endGameStats {
            return
        }
        endGameStats = true

        let _player = entities.map { $0.1 }.firstWhere { $0.isPlayer }
        if let _player = _player {
            hasCoin = !_player.hasTag(.FIRST_PLAYER)
        }

        if currentGameMode == .Ranked || currentGameMode == .Casual {
            Log.info?.message("Format: \(currentFormat)")
        }

        Log.info?.message("End game : mode = \(currentGameMode), "
            + "rank = \(currentRank), result = \(gameResult), "
            + "against = \(opponent.name)(\(opponent.playerClass)), "
            + "opponent played : \(opponent.displayRevealedCards) ")

        if currentRank == 0 && currentGameMode == .Ranked {
            Log.info?.message("rank is 0 and mode is ranked, ignore")
            return
        }

        if let deck = activeDeck,
            opponentName = opponent.name,
            opponentClass = opponent.playerClass {

            let statistic = Statistic()
            statistic.opponentName = opponentName
            statistic.opponentClass = opponentClass.lowercaseString
            statistic.gameResult = gameResult
            statistic.hasCoin = hasCoin
            statistic.playerRank = currentRank
            statistic.playerMode = currentGameMode
            statistic.numTurns = turnNumber()
            let startTime: NSDate
            if let gameStartDate = gameStartDate {
                startTime = gameStartDate
            } else {
                startTime = NSDate()
            }

            let endTime: NSDate
            if let gameEndDate = gameEndDate {
                endTime = gameEndDate
            } else {
                endTime = NSDate()
            }

            // swiftlint:disable line_length
            statistic.duration = Int(endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970)
            // swiftlint:enable line_length
            var cards = [String: Int]()
            opponent.displayRevealedCards.forEach({
                cards[$0.id] = $0.count
            })
            statistic.cards = cards
            deck.addStatistic(statistic)
            Decks.instance.update(deck)

            if HearthstatsAPI.isLogged() && Settings.instance.hearthstatsSynchronizeMatches {
                do {
                    try HearthstatsAPI.postMatch(self, deck: deck, stat: statistic)
                } catch {
                }
            }
        }
    }

    func waitForRank(seconds: Double, completion: () -> Void) {
        let timeout = NSDate().timeIntervalSince1970 + seconds
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while NSDate().timeIntervalSince1970 < timeout {
                NSThread.sleepForTimeInterval(0.5)
                if self.victoryScreenShow && self.currentRank != 0 {
                    break
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                completion()
            }
        }
    }

    func detectMode(seconds: Double, completion: () -> Void) {
        Log.info?.message("waiting for mode")
        awaitingRankedDetection = true
        // rankFound = false
        lastAssetUnload = NSDate().timeIntervalSince1970
        waitingForFirstAssetUnload = true
        let timeout = NSDate().timeIntervalSince1970 + seconds
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while self.waitingForFirstAssetUnload
                || NSDate().timeIntervalSince1970 - self.lastAssetUnload < timeout {
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

    func turnStart(player: PlayerType, turn: Int) {
        Log.info?.message("Turn \(turn) start for player \(player) ")
        if player == .Player {
            handleThaurissanCostReduction()
            showNotification(.TurnStart)
        }
        dispatch_async(dispatch_get_main_queue()) {
            TurnTimer.instance.setPlayer(player)
        }
    }

    func concede() {
        Log.info?.message("Game has been conceded : (")
        hasBeenConceded = true
    }

    func win() {
        Log.info?.message("You win ¯\\_(ツ) _ / ¯")
        gameResult = GameResult.Win

        if hasBeenConceded {
            showNotification(.OpponentConcede)
        }
    }

    func loss() {
        Log.info?.message("You lose : (")
        gameResult = GameResult.Loss
    }

    func tied() {
        Log.info?.message("You lose : ( / game tied: (")
        gameResult = GameResult.Draw
    }

    func isMulliganDone() -> Bool {
        let player = entities.map { $0.1 }.firstWhere { $0.isPlayer }
        let opponent = entities.map { $0.1 }.firstWhere { $0.hasTag(.PLAYER_ID) && !$0.isPlayer }

        if let player = player,
            opponent = opponent {
            return player.getTag(.MULLIGAN_STATE) == Mulligan.DONE.rawValue
                && opponent.getTag(.MULLIGAN_STATE) == Mulligan.DONE.rawValue
        }
        return false
    }

    func handleThaurissanCostReduction() {
        let thaurissan = opponent.board
            .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.EmperorThaurissan })
        if thaurissan == nil || thaurissan!.hasTag(.SILENCED) {
            return
        }

        for impFavor in opponent.board
            .filter({ $0.cardId ==
                CardIds.NonCollectible.Neutral.EmperorThaurissan_ImperialFavorEnchantment }) {
            if let entity = entities[impFavor.getTag(.ATTACHED)] {
                entity.info.costReduction += 1
            }
        }
    }

    // MARK: - Replay
    func proposeKeyPoint(type: KeyPointType, id: Int, player: PlayerType) {
        if let proposedKeyPoint = proposedKeyPoint {
            ReplayMaker.generate(proposedKeyPoint.type,
                                 id: proposedKeyPoint.id,
                                 player: proposedKeyPoint.player, game: self)
        }
        proposedKeyPoint = ReplayKeyPoint(data: nil, type: type, id: id, player: player)
    }

    func gameEndKeyPoint(victory: Bool, id: Int) {
        if let proposedKeyPoint = proposedKeyPoint {
            ReplayMaker.generate(proposedKeyPoint.type,
                                 id: proposedKeyPoint.id,
                                 player: proposedKeyPoint.player, game: self)
            self.proposedKeyPoint = nil
        }
        ReplayMaker.generate(victory ? .Victory : .Defeat, id: id, player: .Player, game: self)
    }

    // MARK: - player
    func setPlayerHero(cardId: String) {
        if let card = Cards.heroById(cardId) {
            player.playerClass = card.playerClass
            player.playerClassId = cardId
            Log.info?.message("Player class is \(card) ")
        }
    }

    func setPlayerRank(rank: Int) {
        if victoryScreenShow {
            Log.info?.message("Player rank is \(rank) ")
            currentRank = rank
        }
    }

    func setPlayerName(name: String) {
        player.name = name
    }

    func playerGet(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.createInHand(entity, turn: turn)
        updatePlayerTracker()
    }

    func playerBackToHand(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        updatePlayerTracker()
        player.boardToHand(entity, turn: turn)
    }

    func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.boardToDeck(entity, turn: turn)
        updatePlayerTracker()
    }

    func playerPlay(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.play(entity, turn: turn)
        updatePlayerTracker()

        secretsOnPlay(entity)
    }

    func secretsOnPlay(entity: Entity) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        if entity.isSpell {
            opponentSecrets?.setZero(CardIds.Secrets.Mage.Counterspell)

            if opponentMinionCount < 7 {
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(50 * Double(NSEC_PER_MSEC)))
                let queue = dispatch_get_main_queue()
                dispatch_after(when, queue) {
                    // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                    if entity.hasTag(.CARD_TARGET)
                        && self.entities[entity.getTag(.CARD_TARGET)] != nil
                        && self.entities[entity.getTag(.CARD_TARGET)]!.isMinion {
                        self.opponentSecrets?.setZero(CardIds.Secrets.Mage.Spellbender)
                    }

                    self.showSecrets(true)
                }
            }
        } else if entity.isMinion && playerMinionCount > 3 {
            opponentSecrets?.setZero(CardIds.Secrets.Paladin.SacredTrial)
            showSecrets(true)
        }
    }

    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.handDiscard(entity, turn: turn)
        updatePlayerTracker()
    }

    func playerSecretPlayed(entity: Entity, cardId: String?, turn: Int, fromZone: Zone) {
        if String.isNullOrEmpty(cardId) {
            return
        }

        switch fromZone {
        case .DECK:
            player.secretPlayedFromDeck(entity, turn: turn)
        case Zone.HAND:
            player.secretPlayedFromHand(entity, turn: turn)
            secretsOnPlay(entity)
        default:
            player.createInSecret(entity, turn: turn)
            return
        }
        updatePlayerTracker()
    }

    func playerMulligan(entity: Entity, cardId: String?) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        // TurnTimer.Instance.MulliganDone(ActivePlayer.Player);
        player.mulligan(entity)
        updatePlayerTracker()
    }

    func playerDraw(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        if cardId == "GAME_005" {
            playerGet(entity, cardId: cardId, turn: turn)
        } else {
            player.draw(entity, turn: turn)
            updatePlayerTracker()
        }
    }

    func playerRemoveFromDeck(entity: Entity, turn: Int) {
        player.removeFromDeck(entity, turn: turn)
        updatePlayerTracker()
    }

    func playerDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        player.deckDiscard(entity, turn: turn)
        updatePlayerTracker()
    }

    func playerDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        player.deckToPlay(entity, turn: turn)
        updatePlayerTracker()
    }

    func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        player.playToGraveyard(entity, cardId: cardId, turn: turn)
        updatePlayerTracker()
    }

    func playerJoust(entity: Entity, cardId: String?, turn: Int) {
        player.joustReveal(entity, turn: turn)
        updatePlayerTracker()
    }

    func playerGetToDeck(entity: Entity, cardId: String?, turn: Int) {
        player.createInDeck(entity, turn: turn)
        updatePlayerTracker()
    }

    func playerFatigue(value: Int) {
        Log.info?.message("Player get \(value) fatigue")
        player.fatigue = value
    }

    func playerCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        player.createInPlay(entity, turn: turn)
    }

    func playerStolen(entity: Entity, cardId: String?, turn: Int) {
        player.stolenByOpponent(entity, turn: turn)
        opponent.stolenFromOpponent(entity, turn: turn)

        if entity.isSecret {
            var heroClass: HeroClass?
            var className = "\(entity.getTag(.CLASS)) "
            if !String.isNullOrEmpty(className) {
                className = className.capitalizedString
                heroClass = HeroClass(rawValue: className)
                if heroClass == .None {
                    if let playerClass = opponent.playerClass {
                        heroClass = HeroClass(rawValue: playerClass)
                    }
                }
            } else {
                if let playerClass = opponent.playerClass {
                    heroClass = HeroClass(rawValue: playerClass)
                }
            }
            guard let _ = heroClass else { return }
            opponentSecretCount += 1
            opponentSecrets?.newSecretPlayed(heroClass!, id: entity.id, turn: turn)
            showSecrets(true)
        }
    }

    func playerRemoveFromPlay(entity: Entity, turn: Int) {
        player.removeFromPlay(entity, turn: turn)
    }

    func playerHeroPower(cardId: String, turn: Int) {
        Log.info?.message("Player Hero Power \(cardId) \(turn) ")

        if !Settings.instance.autoGrayoutSecrets {
            return
        }
        opponentSecrets?.setZero(CardIds.Secrets.Hunter.DartTrap)
        showSecrets(true)
    }

    // MARK: - opponent
    func setOpponentHero(cardId: String) {
        if let card = Cards.heroById(cardId) {
            opponent.playerClass = card.playerClass
            opponent.playerClassId = cardId
            Log.info?.message("Opponent class is \(card) ")
        }
    }

    func setOpponentName(name: String) {
        opponent.name = name
    }

    func opponentGet(entity: Entity, turn: Int, id: Int) {
        if !isMulliganDone() && entity.getTag(.ZONE_POSITION) == 5 {
            entity.cardId = CardIds.NonCollectible.Neutral.TheCoin
        }

        opponent.createInHand(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.boardToHand(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        opponent.boardToDeck(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentPlay(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.play(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentHandDiscard(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.handDiscard(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentSecretPlayed(entity: Entity, cardId: String?,
                              from: Int, turn: Int,
                                fromZone: Zone, otherId: Int) {
        opponentSecretCount += 1

        switch fromZone {
        case .DECK:
            opponent.secretPlayedFromDeck(entity, turn: turn)
        case .HAND:
            opponent.secretPlayedFromHand(entity, turn: turn)
            break
        default:
            opponent.createInSecret(entity, turn: turn)
        }
        updateCardHuds()

        var heroClass: HeroClass?
        var className = "\(entity.getTag(.CLASS))"
        if !String.isNullOrEmpty(className) {
            className = className.capitalizedString
            heroClass = HeroClass(rawValue: className)
            if heroClass == .None {
                if let playerClass = opponent.playerClass {
                    heroClass = HeroClass(rawValue: playerClass.capitalizedString)
                }
            }
        } else {
            if let playerClass = opponent.playerClass {
                heroClass = HeroClass(rawValue: playerClass.capitalizedString)
            }
        }
        Log.info?.message("Secret played by \(entity.getTag(.CLASS))"
            + " -> \(heroClass) -> \(opponent.playerClass)")
        guard let _ = heroClass else { return }

        opponentSecrets?.newSecretPlayed(heroClass!, id: otherId, turn: turn)
        showSecrets(true)
    }

    func opponentMulligan(entity: Entity, from: Int) {
        opponent.mulligan(entity)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentDraw(entity: Entity, turn: Int) {
        opponent.draw(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentRemoveFromDeck(entity: Entity, turn: Int) {
        opponent.removeFromDeck(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckDiscard(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckToPlay(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentPlayToGraveyard(entity: Entity, cardId: String?,
                                 turn: Int, playersTurn: Bool) {
        opponent.playToGraveyard(entity, cardId: cardId, turn: turn)
        if playersTurn && entity.isMinion {
            opponentMinionDeath(entity, turn: turn)
        }
        updateCardHuds()
        updateOpponentTracker()
    }

    func opponentJoust(entity: Entity, cardId: String?, turn: Int) {
        opponent.joustReveal(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentGetToDeck(entity: Entity, turn: Int) {
        opponent.createInDeck(entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentSecretTrigger(entity: Entity, cardId: String?, turn: Int, otherId: Int) {
        opponent.secretTriggered(entity, turn: turn)

        opponentSecretCount -= 1
        if let cardId = cardId {
            opponentSecrets?.secretRemoved(otherId, cardId: cardId)
        }
        if opponentSecretCount <= 0 {
            showSecrets(false)
        } else {
            if Settings.instance.autoGrayoutSecrets {
                opponentSecrets?.setZero(cardId!)
            }
            showSecrets(true)
        }
        updateCardHuds()
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
            opponentSecretCount -= 1
            opponentSecrets?.secretRemoved(entity.id, cardId: cardId!)
            if opponentSecretCount <= 0 {
                showSecrets(false)
            } else {
                if Settings.instance.autoGrayoutSecrets {
                    opponentSecrets?.setZero(cardId!)
                }
                showSecrets(true)
            }

            updateOpponentTracker()
        }
    }

    func opponentRemoveFromPlay(entity: Entity, turn: Int) {
        player.removeFromPlay(entity, turn: turn)
    }

    func opponentHeroPower(cardId: String, turn: Int) {
        Log.info?.message("Opponent Hero Power \(cardId) \(turn) ")
    }

    // MARK: - game actions
    func defendingEntity(entity: Entity?) {
        self.defendingEntity = entity
        if let attackingEntity = self.attackingEntity,
            defendingEntity = self.defendingEntity,
            entity = entity {
            if entity.isControlledBy(opponent.id) {
                opponentSecrets?.zeroFromAttack(attackingEntity, defender: defendingEntity)
            }
        }
    }

    func attackingEntity(entity: Entity?) {
        self.attackingEntity = entity
        if let attackingEntity = self.attackingEntity,
            defendingEntity = self.defendingEntity,
            entity = entity {
            if entity.isControlledBy(player.id) {
                opponentSecrets?.zeroFromAttack(attackingEntity, defender: defendingEntity)
            }
        }
    }

    func playerMinionPlayed() {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        opponentSecrets?.setZero(CardIds.Secrets.Hunter.Snipe)
        opponentSecrets?.setZero(CardIds.Secrets.Mage.MirrorEntity)
        opponentSecrets?.setZero(CardIds.Secrets.Paladin.Repentance)

        showSecrets(true)
    }

    func opponentMinionDeath(entity: Entity, turn: Int) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        if opponent.handCount < 10 {
            opponentSecrets?.setZero(CardIds.Secrets.Mage.Duplicate)
        }

        var numDeathrattleMinions = 0
        if entity.isActiveDeathrattle {
            if let count = CardIds.DeathrattleSummonCardIds[entity.cardId] {
                numDeathrattleMinions = count
            } else {
                if entity.cardId == CardIds.Collectible.Neutral.Stalagg
                    && opponent.graveyard
                        .any({ $0.cardId == CardIds.Collectible.Neutral.Feugen })
                    || entity.cardId == CardIds.Collectible.Neutral.Feugen
                    && opponent.graveyard
                        .any({ $0.cardId == CardIds.Collectible.Neutral.Stalagg }) {
                        numDeathrattleMinions = 1
                }
            }

            // swiftlint:disable line_length
            if entities.map({ $0.1 })
                .any({ $0.cardId == CardIds.NonCollectible.Druid.SouloftheForest_SoulOfTheForestEnchantment
                    && $0.getTag(.ATTACHED) == entity.id }) {
                numDeathrattleMinions += 1
            }

            if entities.map({ $0.1 })
                .any({ $0.cardId == CardIds.NonCollectible.Shaman.AncestralSpirit_AncestralSpiritEnchantment
                    && $0.getTag(.ATTACHED) == entity.id }) {
                numDeathrattleMinions += 1
            }
            // swiftlint:enable line_length

            if let opponentEntity = opponentEntity where
                opponentEntity.hasTag(.EXTRA_DEATHRATTLES) {
                numDeathrattleMinions *= (opponentEntity.getTag(.EXTRA_DEATHRATTLES) + 1)
            }

            avengeAsync(numDeathrattleMinions)

            // redemption never triggers if a deathrattle effect fills up the board
            // effigy can trigger ahead of the deathrattle effect, but only if
            // effigy was played before the deathrattle minion
            if opponentMinionCount < 7 - numDeathrattleMinions {
                opponentSecrets?.setZero(CardIds.Secrets.Paladin.Redemption)
                opponentSecrets?.setZero(CardIds.Secrets.Mage.Effigy)
            } else {
                // TODO need to properly break ties when effigy + deathrattle played in same turn
                let minionTurnPlayed = turn - entity.getTag(.NUM_TURNS_IN_PLAY)
                var secretOffset = 0
                if let secret = opponentSecrets!.secrets
                    .firstWhere({ $0.turnPlayed >= minionTurnPlayed }) {
                    secretOffset = opponentSecrets!.secrets.indexOf(secret)!
                }
                opponentSecrets?.setZeroOlder(CardIds.Secrets.Mage.Effigy, stopIndex: secretOffset)
            }
        }
        showSecrets(true)
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
                        self.showSecrets(true)

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
        if !entity.isHero || !entity.isControlledBy(opponent.id) {
            return
        }
        opponentSecrets?.setZero(CardIds.Secrets.Paladin.EyeForAnEye)
        showSecrets(true)
    }

    func opponentTurnStart(entity: Entity) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }
        if !entity.isMinion {
            return
        }
        opponentSecrets?.setZero(CardIds.Secrets.Paladin.CompetitiveSpirit)
        showSecrets(true)
    }

    // MARK: - UI
    func showSecrets(show: Bool) {
        guard Settings.instance.showSecretHelper else { return }

        dispatch_async(dispatch_get_main_queue()) {
            if show {
                if let opponentSecrets = self.opponentSecrets {
                    self.secretTracker?.setSecrets(opponentSecrets)
                    self.secretTracker?.showWindow(self)
                }
            } else {
                self.secretTracker?.window?.orderOut(self)
            }
        }
    }

    func updateCardHuds(force: Bool = false) {
        guard let _ = cardHuds else { return }

        lastCardsUpdateRequest = NSDate().timeIntervalSince1970
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(100 * Double(NSEC_PER_MSEC)))
        let queue = dispatch_get_main_queue()
        dispatch_after(when, queue) {
            if !force && NSDate().timeIntervalSince1970 - self.lastCardsUpdateRequest < 0.1 {
                return
            }
            if let cardHuds = self.cardHuds {
                let count = min(10, self.opponent.handCount)

                for (i, hud) in cardHuds.enumerate() {
                    if let entity = self.opponent.hand
                        .firstWhere({ $0.getTag(.ZONE_POSITION) == i + 1 })
                        where !self.gameEnded && Settings.instance.showCardHuds {
                        hud.setEntity(entity)
                        let frame = SizeHelper.opponentCardHudFrame(i, cardCount: count)
                        hud.window?.setFrame(frame, display: true)
                        hud.showWindow(self)
                    } else {
                        hud.window?.orderOut(self)
                    }
                }
            }
        }
    }

    private func updateTracker(tracker: Tracker?, reset: Bool = false) {
        if reset {
            let cards: [Card]?
            if tracker == self.playerTracker {
                playerUpdateRequests = 0
                cards = self.player.playerCardList
            } else {
                opponentUpdateRequests = 0
                cards = Settings.instance.clearTrackersOnGameEnd && gameEnded
                    ? [] : self.opponent.opponentCardList
            }
            if let cards = cards {
                dispatch_async(dispatch_get_main_queue()) {
                    tracker?.update(cards, reset: reset)
                }
            }
        } else {
            if tracker == playerTracker {
                playerUpdateRequests += 1
            } else {
                opponentUpdateRequests += 1
            }

            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(100 * Double(NSEC_PER_MSEC)))
            let queue = dispatch_get_main_queue()
            dispatch_after(when, queue) {
                let updateRequests: Int

                if tracker == self.playerTracker {
                    self.playerUpdateRequests -= 1
                    updateRequests = self.playerUpdateRequests
                } else {
                    self.opponentUpdateRequests -= 1
                    updateRequests = self.opponentUpdateRequests
                }

                if updateRequests > 0 {
                    return
                }
                let cards: [Card]?
                if tracker == self.playerTracker {
                    cards = self.player.playerCardList
                } else {
                    cards = Settings.instance.clearTrackersOnGameEnd
                        && self.gameEnded ? [] : self.opponent.opponentCardList
                }
                if let cards = cards {
                    tracker?.update(cards, reset: reset)
                }
            }
        }
    }

    func updatePlayerTracker(reset: Bool = false) {
        updateTracker(playerTracker, reset: reset)
    }

    func updateOpponentTracker(reset: Bool = false) {
        updateTracker(opponentTracker, reset: reset)
    }

    func hearthstoneIsActive(active: Bool) {
        if Settings.instance.autoPositionTrackers {
            if let tracker = self.playerTracker {
                changeTracker(tracker, active: active,
                              frame: SizeHelper.playerTrackerFrame())
            }
            if let tracker = self.opponentTracker {
                changeTracker(tracker, active: active,
                              frame: SizeHelper.opponentTrackerFrame())
            }
        }
        if let tracker = self.secretTracker {
            changeTracker(tracker, active: active, frame: SizeHelper.secretTrackerFrame())
        }
        if let tracker = self.timerHud {
            changeTracker(tracker, active: active, frame: SizeHelper.timerHudFrame())
        }

        updateCardHuds()
    }

    func changeTracker(tracker: NSWindowController, active: Bool, frame: NSRect) {
        guard frame != NSZeroRect else {return}

        tracker.window?.setFrame(frame, display: true)
        let level: Int
        if active {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
        tracker.window?.level = level
    }

     func showNotification(type: NotificationType) {
        if Hearthstone.instance.hearthstoneActive {
            return
        }

        let settings = Settings.instance
        guard type == .GameStart && settings.notifyGameStart
            || type == .OpponentConcede && settings.notifyOpponentConcede
            || type == .TurnStart && settings.notifyTurnStart else {
            return
        }

        let title: String, info: String

        switch type {
        case .GameStart:
            title = NSLocalizedString("Hearthstone", comment: "")
            info = NSLocalizedString("Your game begins", comment: "")
        case .OpponentConcede:
            title = NSLocalizedString("Victory", comment: "")
            info = NSLocalizedString("Your opponent have conceded", comment: "")
        case .TurnStart:
            title = NSLocalizedString("Hearthstone", comment: "")
            info = NSLocalizedString("It's your turn to play", comment: "")
        }

        (NSApplication.sharedApplication().delegate as? AppDelegate)?
            .sendNotification(title, info: info)
    }
}

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

struct PlayerTurn: Hashable {
    let player: PlayerType
    let turn: Int
    
    var hashValue: Int {
    return player.rawValue.hashValue ^ turn.hashValue
    }
}
func == (lhs: PlayerTurn, rhs: PlayerTurn) -> Bool {
    return lhs.player == rhs.player && lhs.turn == rhs.turn
}

class Game {
    // MARK: - vars
    var currentTurn = 0
    var maxId = 0
    var lastId = 0
    var gameTriggerCount = 0
    var powerLog: [String] = []
    var playedCards: [PlayedCard] = []

    var player: Player
    var opponent: Player
    var currentMode: Mode? = .INVALID
    var previousMode: Mode? = .INVALID
    var currentGameMode: GameMode = .None
    var entities = [Int: Entity]()
    var tmpEntities = [Entity]()
    var knownCardIds = [Int: String]()
    var joustReveals = 0
    var gameStarted = false
    var gameEnded = true {
        didSet {
            updateOpponentTracker(true)
        }
    }
    var gameStartDate: NSDate?
    var gameResult: GameResult = .Unknow
    var gameEndDate: NSDate?
    var playerTracker: Tracker?
    var opponentTracker: Tracker?
    var secretTracker: SecretTracker?
    var timerHud: TimerHud?
    var playerBoardDamage: BoardDamage?
    var opponentBoardDamage: BoardDamage?
    var cardHudContainer: CardHudContainer?
    
    var lastCardPlayed: Int?
    var activeDeck: Deck?
    var currentEntityId = 0
    var currentEntityHasCardId = false
    var playerUsedHeroPower = false
    private var hasCoin = false
    var currentEntityZone: Zone = .INVALID
    var opponentUsedHeroPower = false
    var determinedPlayers = false
    var setupDone = false
    var proposedKeyPoint: ReplayKeyPoint?
    var opponentSecrets: OpponentSecrets?
    private var defendingEntity: Entity?
    private var attackingEntity: Entity?
    private var avengeDeathRattleCount = 0
    private var opponentSecretCount = 0
    private var awaitingAvenge = false
    var isInMenu = true
    private var endGameStats = false
    var wasInProgress = false
    private var hasBeenConceded = false
    var enqueueTime: NSDate = NSDate.distantPast()
    private var lastCompetitiveSpiritCheck: Int = 0
    private var lastTurnStart: [Int] = [0, 0]
    private var turnQueue: Set<PlayerTurn> = Set()
    
    private var rankDetector = CVRankDetection()
    private var playerRanks: [Int] = []
    private var opponentRanks: [Int] = []

    private var lastCardsUpdateRequest = NSDate.distantPast().timeIntervalSince1970
    private var lastGameStartTimestamp: NSDate = NSDate.distantPast()

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
        
        playerRanks = []
        opponentRanks = []
        powerLog = []
        playedCards = []
        
        maxId = 0
        lastId = 0
        gameTriggerCount = 0

        entities.removeAll()
        tmpEntities.removeAll()
        knownCardIds.removeAll()
        joustReveals = 0
        gameStarted = false
        gameEnded = true
        gameStartDate = nil
        gameResult = .Unknow
        gameEndDate = nil
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
        lastTurnStart = [0, 0]

        player.reset()
        opponent.reset()
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.secretTracker?.window?.orderOut(strongSelf)
            strongSelf.timerHud?.window?.orderOut(strongSelf)
            strongSelf.playerBoardDamage?.window?.orderOut(strongSelf)
            strongSelf.opponentBoardDamage?.window?.orderOut(strongSelf)
            strongSelf.cardHudContainer?.reset()
        }
        
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
    }

    func removeActiveDeck() {
        self.activeDeck = nil
        updatePlayerTracker(true)
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

    // MARK: - game state
    func gameStart(timestamp: NSDate) {
        if currentGameMode == .Practice && !isInMenu && !gameEnded
            && lastGameStartTimestamp > NSDate.distantPast()
            && timestamp > lastGameStartTimestamp {
            adventureRestart()
        }
        
        lastGameStartTimestamp = timestamp
        
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
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if Settings.instance.showTimer {
                self?.timerHud?.showWindow(self)
                TurnTimer.instance.start(self)
            }
            if Settings.instance.showCardHuds {
                self?.cardHudContainer?.showWindow(self)
                self?.updateCardHuds()
            }
        }
        
        checkForRank()
    }
    
    private func adventureRestart() {
        // The game end is not logged in PowerTaskList
        Log.info?.message("Adventure was restarted. Simulating game end.")
        concede()
        loss()
        gameEnd()
        inMenu()
    }
    
    func checkForRank() {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(30 * Double(NSEC_PER_SEC)))
        let queue = dispatch_get_main_queue()
        dispatch_after(when, queue) {
            guard !self.gameEnded else { return }
            
            if self.currentGameMode == .Casual || self.currentGameMode == .Ranked {
                if let playerRank = self.rankDetector.playerRank(),
                    opponentRank = self.rankDetector.opponentRank() {
                    self.playerRanks.append(playerRank)
                    self.opponentRanks.append(opponentRank)
                    
                    // check if player rank is in range "opponent rank - 3 -> opponent rank + 3)
                    if (opponentRank - 3) ... (opponentRank + 3) ~= playerRank {
                        // we can imagine we are on ranked games
                        self.currentGameMode = .Ranked
                    }
                }
            }
            
            // check again every 30 seconds during the game to get 
            // something accurate
            self.checkForRank()
        }
    }

    func gameEnd() {
        Log.info?.message("----- Game End -----")
        gameStarted = false
        gameEndDate = NSDate()

        handleEndGame()
        updateOpponentTracker(true)

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            TurnTimer.instance.stop()
            self?.timerHud?.window?.orderOut(self)
            self?.cardHudContainer?.reset()
        }

        showSecrets(false)
    }

    func inMenu() {
        if isInMenu {
            return
        }
        Log.verbose?.message("Game is now in menu")

        TurnTimer.instance.stop()

        if Settings.instance.saveReplays {
            ReplayMaker.saveToDisk(powerLog)
        }

        isInMenu = true
    }

    func handleEndGame() {
        Log.verbose?.message("rank: \(playerRanks), currentGameMode: \(currentGameMode)")
  
        guard !endGameStats else { return }
        endGameStats = true
        
        guard currentGameMode != .Practice && currentGameMode != .None else { return }

        let _player = entities.map { $0.1 }.firstWhere { $0.isPlayer }
        if let _player = _player {
            hasCoin = !_player.hasTag(.FIRST_PLAYER)
        }

        if currentGameMode == .Ranked || currentGameMode == .Casual {
            Log.info?.message("Format: \(currentFormat)")
        }
        
        var result: [Int: Int] = [:]
        playerRanks.forEach({ result[$0] = (result[$0] ?? 0) + 1 })
        let currentRank = Array(result).sort { $0.1 < $1.1 }.last?.0 ?? -1
        
        Log.info?.message("End game : mode = \(currentGameMode), "
            + "rank = \(currentRank), result = \(gameResult), "
            + "against = \(opponent.name)(\(opponent.playerClass)), "
            + "opponent played : \(opponent.displayRevealedCards) ")

        if currentRank == -1 && currentGameMode == .Ranked {
            Log.info?.message("rank is -1 and mode is ranked, ignore")
            return
        }

        if let opponentName = opponent.name,
            opponentClass = opponent.playerClass,
            playerClass = player.playerClass {
            
            var result: [Int: Int] = [:]
            opponentRanks.forEach({ result[$0] = (result[$0] ?? 0) + 1 })
            let opponentRank = Array(result).sort { $0.1 < $1.1 }.last?.0 ?? -1
            
            var note = ""

            if Settings.instance.promptNotes
                && (currentGameMode == .Ranked || currentGameMode == .Casual) {
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    let alert = NSAlert()
                    alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
                    alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
                    let message = "Do you want to add some notes for this game ?"
                    alert.informativeText = NSLocalizedString(message, comment: "")
                    alert.alertStyle = .InformationalAlertStyle
                    let frame = NSRect(x: 0, y: 0, width: 300, height: 80)
                    let input = NSTextView(frame: frame)
                    alert.accessoryView = input
                    NSRunningApplication.currentApplication().activateWithOptions([
                        NSApplicationActivationOptions.ActivateAllWindows,
                        NSApplicationActivationOptions.ActivateIgnoringOtherApps])
                    NSApp.activateIgnoringOtherApps(true)
                    if alert.runModal() == NSAlertFirstButtonReturn {
                        note = input.string ?? ""
                    }
                    self?.saveMatch(currentRank,
                                   note: note,
                                   playerClass: playerClass,
                                   opponentName: opponentName,
                                   opponentClass: opponentClass,
                                   opponentRank: opponentRank)
                }
            } else {
                saveMatch(currentRank,
                          note: note,
                          playerClass: playerClass,
                          opponentName: opponentName,
                          opponentClass: opponentClass,
                          opponentRank: opponentRank)
            }
        }
    }
    
    private func saveMatch(rank: Int, note: String, playerClass: CardClass,
                           opponentName: String, opponentClass: CardClass, opponentRank: Int) {
        let statistic = Statistic()
        statistic.opponentName = opponentName
        statistic.opponentClass = opponentClass
        statistic.gameResult = gameResult
        statistic.hasCoin = hasCoin
        statistic.playerRank = rank
        statistic.playerMode = currentGameMode
        statistic.numTurns = turnNumber()
        statistic.note = note
        statistic.season = Database.currentSeason
        statistic.opponentRank = opponentRank
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
        
        statistic.duration = Int(endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970)
        var cards = [String: Int]()
        opponent.displayRevealedCards.forEach({
            cards[$0.id] = $0.count
        })
        statistic.cards = cards
        
        if let deck = activeDeck {
            deck.addStatistic(statistic)
            Decks.instance.update(deck)
            
            if HearthstatsAPI.isLogged() && Settings.instance.hearthstatsSynchronizeMatches {
                do {
                    if currentGameMode == .Arena {
                        try HearthstatsAPI.postArenaMatch(self, deck: deck, stat: statistic)
                    } else if currentGameMode != .Brawl {
                        try HearthstatsAPI.postMatch(self, deck: deck, stat: statistic)
                    }
                } catch {
                    Log.error?.message("Hearthstats error : \(error)")
                }
            }
        }
        
        if TrackOBotAPI.isLogged() && Settings.instance.trackobotSynchronizeMatches {
            do {
                try TrackOBotAPI.postMatch(self, playerClass: playerClass, stat: statistic)
            } catch {
                Log.error?.message("Track-o-Bot error : \(error)")
            }
        }
        
        if Settings.instance.hsReplaySynchronizeMatches {
            HSReplayAPI.getUploadToken { (token) in
                LogUploader.upload(self.powerLog, game: self, statistic: statistic) { result in
                    if case UploadResult.successful(let replayId) = result {
                        let opClass = NSLocalizedString(opponentClass.rawValue.lowercaseString,
                            comment: "")
                        HSReplayManager.instance.saveReplay(replayId,
                            deck: self.activeDeck?.name ?? "",
                            against: "\(opponentName) - \(opClass)")
                        self.showNotification(.HSReplayPush(replayId: replayId))
                    }
                }
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
    
    func turnsInPlayChange(entity: Entity, turn: Int) {
        guard let opponentEntity = opponentEntity else { return }
        
        if entity.isHero {
            let player: PlayerType = opponentEntity.isCurrentPlayer ? .Opponent : .Player
            if lastTurnStart[player.rawValue] >= turn {
                return
            }
            lastTurnStart[player.rawValue] = turn
            turnStart(player, turn: turn)
            return
        }
        if turn <= lastCompetitiveSpiritCheck || !Settings.instance.autoGrayoutSecrets
            || !entity.isMinion || !entity.isControlledBy(opponent.id)
            || !opponentEntity.isCurrentPlayer {
            return
        }
        lastCompetitiveSpiritCheck = turn
        opponentSecrets?.setZero(CardIds.Secrets.Paladin.CompetitiveSpirit)
        showSecrets(true)
    }
    
    func turnStart(player: PlayerType, turn: Int) {
        if !isMulliganDone() {
            Log.info?.message("--- Mulligan ---")
        }
        var turnNumber = turn
        if turnNumber == 0 {
            turnNumber += 1
        }
        turnQueue.insert(PlayerTurn(player: player, turn: turn))
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while !self.isMulliganDone() {
                NSThread.sleepForTimeInterval(0.1)
            }
            while let playerTurn = self.turnQueue.popFirst() {
                self.handleTurnStart(playerTurn)
            }
        }
    }
    
    func handleTurnStart(playerTurn: PlayerTurn) {
        let player = playerTurn.player
        Log.info?.message("Turn \(playerTurn.turn) start for player \(player) ")
        
        if player == .Player {
            handleThaurissanCostReduction()
        }
        
        if turnQueue.count > 0 {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            TurnTimer.instance.setPlayer(player)
        }
        
        if player == .Player && !isInMenu {
            showNotification(.TurnStart)
        }
        
        if player == .Player {
            // update opponent tracker in case of end of turn (C'Thun, draw, ...)
            updateOpponentTracker()
        } else {
            // update player tracker in case of end of turn (C'Thun, draw, ...)
            updatePlayerTracker()
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
        
        if let player = player, opponent = opponent {
            return player.getTag(.MULLIGAN_STATE) == Mulligan.DONE.rawValue
                && opponent.getTag(.MULLIGAN_STATE) == Mulligan.DONE.rawValue
        }
        return false
    }

    func handleThaurissanCostReduction() {
        let thaurissans = opponent.board.filter({
            $0.cardId == CardIds.Collectible.Neutral.EmperorThaurissan && !$0.hasTag(.SILENCED)
        })
        if thaurissans.isEmpty {
            return
        }

        for impFavor in opponent.board
            .filter({ $0.cardId ==
                CardIds.NonCollectible.Neutral.EmperorThaurissan_ImperialFavorEnchantment }) {
            if let entity = entities[impFavor.getTag(.ATTACHED)] {
                entity.info.costReduction += thaurissans.count
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
        if let cardId = cardId where !cardId.isEmpty {
            playedCards.append(PlayedCard(player: .Player, cardId: cardId, turn: turn))
        }
        
        if entity.hasTag(.RITUAL) {
            // if this entity has the RITUAL tag, it will trigger some C'Thun change
            // we wait 300ms so the proxy have the time to be updated
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(300 * Double(NSEC_PER_MSEC)))
            let queue = dispatch_get_main_queue()
            dispatch_after(when, queue) { [weak self] in
                self?.updatePlayerTracker()
            }
        } else {
            updatePlayerTracker()
        }

        secretsOnPlay(entity)
        updateOpponentTracker()
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
                dispatch_after(when, queue) { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                    if entity.hasTag(.CARD_TARGET)
                        && strongSelf.entities[entity.getTag(.CARD_TARGET)] != nil
                        && strongSelf.entities[entity.getTag(.CARD_TARGET)]!.isMinion {
                        strongSelf.opponentSecrets?.setZero(CardIds.Secrets.Mage.Spellbender)
                    }
                    strongSelf.opponentSecrets?.setZero(CardIds.Secrets.Hunter.CatTrick)
                    strongSelf.showSecrets(true)
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
        updatePlayerTracker()
    }

    func playerCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        player.createInPlay(entity, turn: turn)
    }

    func playerStolen(entity: Entity, cardId: String?, turn: Int) {
        player.stolenByOpponent(entity, turn: turn)
        opponent.stolenFromOpponent(entity, turn: turn)

        if entity.isSecret {
            var heroClass: CardClass?
            var className = "\(entity.getTag(.CLASS)) "
            if !String.isNullOrEmpty(className) {
                className = className.uppercaseString
                heroClass = CardClass(rawValue: className)
                if heroClass == .None {
                    if let playerClass = opponent.playerClass {
                        heroClass = playerClass
                    }
                }
            } else {
                if let playerClass = opponent.playerClass {
                    heroClass = playerClass
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
    
    func playerCreateInSetAside(entity: Entity, turn: Int) {
        player.createInSetAside(entity, turn: turn)
    }

    func playerHeroPower(cardId: String, turn: Int) {
        updateBoardAttack()
        player.heroPower(turn)
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
            updateOpponentTracker()
            Log.info?.message("Opponent class is \(card) ")
        }
    }

    func setOpponentName(name: String) {
        opponent.name = name
        updateOpponentTracker()
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
        
        if let cardId = cardId where !cardId.isEmpty {
            playedCards.append(PlayedCard(player: .Opponent, cardId: cardId, turn: turn))
        }
        
        if entity.hasTag(.RITUAL) {
            // if this entity has the RITUAL tag, it will trigger some C'Thun change
            // we wait 300ms so the proxy have the time to be updated
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(300 * Double(NSEC_PER_MSEC)))
            let queue = dispatch_get_main_queue()
            dispatch_after(when, queue) { [weak self] in
                self?.updateOpponentTracker()
            }
        } else {
            updateOpponentTracker()
        }
        updateCardHuds()
        updateOpponentTracker()
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

        var heroClass: CardClass?
        var className = "\(entity.getTag(.CLASS))"
        if !String.isNullOrEmpty(className) {
            className = className.uppercaseString
            heroClass = CardClass(rawValue: className)
            if heroClass == .None {
                if let playerClass = opponent.playerClass {
                    heroClass = playerClass
                }
            }
        } else {
            if let playerClass = opponent.playerClass {
                heroClass = playerClass
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
        updateOpponentTracker()
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
    
    func opponentCreateInSetAside(entity: Entity, turn: Int) {
        opponent.createInSetAside(entity, turn: turn)
    }

    func opponentHeroPower(cardId: String, turn: Int) {
        updateBoardAttack()
        opponent.heroPower(turn)
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
            let cardId = entity.cardId
            if let count = CardIds.DeathrattleSummonCardIds[cardId] {
                numDeathrattleMinions = count
            } else {
                if cardId == CardIds.Collectible.Neutral.Stalagg
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
            dispatch_after(when, queue) { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.opponentMinionCount - strongSelf.avengeDeathRattleCount > 0 {
                    strongSelf.opponentSecrets?.setZero(CardIds.Secrets.Paladin.Avenge)
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.showSecrets(true)

                        self?.awaitingAvenge = false
                        self?.avengeDeathRattleCount = 0
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

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if show {
                if let opponentSecrets = self?.opponentSecrets {
                    self?.secretTracker?.setSecrets(opponentSecrets)
                    self?.secretTracker?.window?.orderOut(self)
                    self?.secretTracker?.showWindow(self)
                }
            } else {
                self?.secretTracker?.window?.orderOut(self)
            }
        }
    }

    func updateCardHuds(force: Bool = false) {
        guard let _ = cardHudContainer else { return }
        guard Settings.instance.showCardHuds else { return }
        guard gameStarted else { return }

        lastCardsUpdateRequest = NSDate().timeIntervalSince1970
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(100 * Double(NSEC_PER_MSEC)))
        let queue = dispatch_get_main_queue()
        dispatch_after(when, queue) { [weak self] in
            guard let strongSelf = self else { return }
            
            if !force && NSDate().timeIntervalSince1970 - strongSelf.lastCardsUpdateRequest < 0.1 {
                return
            }
            strongSelf.cardHudContainer?.window?.orderOut(strongSelf)
            strongSelf.cardHudContainer?.showWindow(strongSelf)
            strongSelf.cardHudContainer?.update(strongSelf.opponent.hand,
                                                cardCount: strongSelf.opponent.handCount)
        }
    }
    
    func updateBoardAttack() {
        let board = BoardState()
        let settings = Settings.instance
        
        if settings.playerBoardDamage {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                guard let strongSelf = self else { return }
                
                if !strongSelf.gameEnded {
                    strongSelf.playerBoardDamage?.window?.orderOut(strongSelf)
                    strongSelf.playerBoardDamage?.showWindow(strongSelf)
                    strongSelf.playerBoardDamage?.update(board.player.damage)
                } else {
                    strongSelf.playerBoardDamage?.window?.orderOut(strongSelf)
                }
            }
        } else {
            self.playerBoardDamage?.window?.orderOut(self)
        }
        
        if settings.opponentBoardDamage {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                guard let strongSelf = self else { return }
                
                if !strongSelf.gameEnded {
                    strongSelf.opponentBoardDamage?.window?.orderOut(strongSelf)
                    strongSelf.opponentBoardDamage?.showWindow(strongSelf)
                    strongSelf.opponentBoardDamage?.update(board.opponent.damage)
                } else {
                    strongSelf.opponentBoardDamage?.window?.orderOut(strongSelf)
                }
            }
        } else {
            self.opponentBoardDamage?.window?.orderOut(self)
        }
    }

    func updatePlayerTracker(reset: Bool = false) {
        updateBoardAttack()
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if let cards = self?.player.playerCardList {
                self?.playerTracker?.update(cards, reset: reset)
            }
        }
    }

    func updateOpponentTracker(reset: Bool = false) {
        updateBoardAttack()
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if let cards = Settings.instance.clearTrackersOnGameEnd
                && self?.gameEnded ?? true ? [] : self?.opponent.opponentCardList {
                self?.opponentTracker?.update(cards, reset: reset)
            }
        }
    }

    func hearthstoneIsActive(active: Bool) {
        if Settings.instance.autoPositionTrackers {
            moveWindow(playerTracker,
                       active: active,
                       frame: SizeHelper.playerTrackerFrame())
            moveWindow(opponentTracker,
                       active: active,
                       frame: SizeHelper.opponentTrackerFrame())
        }
        if Settings.instance.showSecretHelper {
            moveWindow(secretTracker,
                       active: active,
                       frame: SizeHelper.secretTrackerFrame())
        }
        if Settings.instance.showTimer {
            moveWindow(timerHud,
                       active: active,
                       frame: SizeHelper.timerHudFrame())
        }
        if Settings.instance.showCardHuds {
            moveWindow(cardHudContainer,
                       active: active,
                       frame: SizeHelper.cardHudContainerFrame())
            updateCardHuds()
        }
        if Settings.instance.playerBoardDamage {
            moveWindow(playerBoardDamage,
                       active: active,
                       frame: SizeHelper.playerBoardDamageFrame())
        }
        if Settings.instance.opponentBoardDamage {
            moveWindow(opponentBoardDamage,
                       active: active,
                       frame: SizeHelper.opponentBoardDamageFrame())
        }
    }

    func moveWindow(windowController: NSWindowController?, active: Bool, frame: NSRect) {
        guard let windowController = windowController else { return }
        guard frame != NSRect.zero else { return }

        if windowController.window?.visible ?? false {
            windowController.window?.orderOut(self)
            windowController.window?.setFrame(frame, display: true)
            windowController.showWindow(self)
        } else {
            windowController.window?.setFrame(frame, display: true)
        }
        let level: Int
        if active {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
        windowController.window?.level = level
    }

     func showNotification(type: NotificationType) {
        let settings = Settings.instance

        switch type {
        case .GameStart:
            guard settings.notifyGameStart else { return }
            if Hearthstone.instance.hearthstoneActive { return }
            
            Toast.show(NSLocalizedString("Hearthstone", comment: ""),
                       message: NSLocalizedString("Your game begins", comment: ""))
        
        case .OpponentConcede:
            guard settings.notifyOpponentConcede else { return }
            if Hearthstone.instance.hearthstoneActive { return }
            
            Toast.show(NSLocalizedString("Victory", comment: ""),
                       message: NSLocalizedString("Your opponent have conceded", comment: ""))
            
        case .TurnStart:
            guard settings.notifyTurnStart else { return }
            if Hearthstone.instance.hearthstoneActive { return }
            
            Toast.show(NSLocalizedString("Hearthstone", comment: ""),
                       message: NSLocalizedString("It's your turn to play", comment: ""))
        
        case .HSReplayPush(let replayId):
            guard settings.showHSReplayPushNotification else { return }
            
            Toast.show(NSLocalizedString("HSReplay", comment: ""),
                       message: NSLocalizedString("Your replay has been uploaded on HSReplay",
                        comment: "")) {
                        HSReplayManager.showReplay(replayId)
            }

        }
    }
}

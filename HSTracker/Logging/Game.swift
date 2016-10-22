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

class Game {
    // MARK: - vars
    var currentTurn = 0
    var maxId = 0
    var lastId = 0
    var gameTriggerCount = 0
    var powerLog: [LogLine] = []
    var playedCards: [PlayedCard] = []

    var player: Player
    var opponent: Player
    var currentMode: Mode? = .invalid
    var previousMode: Mode? = .invalid
    var currentGameMode: GameMode = .none
    var entities = [Int: Entity]()
    var tmpEntities = [Entity]()
    var knownCardIds = [Int: String]()
    var joustReveals = 0
    var gameStarted = false
    var gameEnded = true {
        didSet {
            updateOpponentTracker(reset: true)
        }
    }
    var gameStartDate: Date?
    var gameResult: GameResult = .unknow
    var gameEndDate: Date?
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
    var currentEntityZone: Zone = .invalid
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
    var enqueueTime: Date = Date.distantPast
    private var lastCompetitiveSpiritCheck: Int = 0
    private var lastTurnStart: [Int] = [0, 0]
    private var turnQueue: Set<PlayerTurn> = Set()
    
    private var rankDetector = CVRankDetection()
    private var playerRanks: [Int] = []
    private var opponentRanks: [Int] = []

    private var lastCardsUpdateRequest = Date.distantPast.timeIntervalSince1970
    fileprivate var lastGameStartTimestamp: Date = Date.distantPast

    var playerEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.isPlayer }
    }

    var opponentEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.has(tag: .player_id) && !$0.isPlayer }
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
                && $0.isControlled(by: self.opponent.id) } != nil
    }

    var opponentMinionCount: Int {
        return entities.map { $0.1 }
            .filter { $0.isInPlay && $0.isMinion
                && $0.isControlled(by: self.opponent.id) }.count }

    var playerMinionCount: Int {
        return entities.map { $0.1 }
            .filter { $0.isInPlay && $0.isMinion
                && $0.isControlled(by: self.player.id) }.count }

    var currentFormat: Format? {
        if currentGameMode != .casual && currentGameMode != .ranked {
            return nil
        }
        if let deck = activeDeck, !deck.standardViable() {
            return .wild
        }
        return entities.map { $0.1 }
            .filter { !String.isNullOrEmpty($0.cardId)
                && !$0.info.created && $0.card.set != nil }
            .any { CardSet.wildSets().contains($0.card.set!) } ? .wild : .standard
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
        gameResult = .unknow
        gameEndDate = nil
        lastCardPlayed = nil
        currentEntityId = 0
        currentEntityHasCardId = false
        playerUsedHeroPower = false
        hasCoin = false
        currentEntityZone = .invalid
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
        
        DispatchQueue.main.async { [weak self] in
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

    func set(currentEntity id: Int) {
        currentEntityId = id
        if let entity = entities[id] {
            entity.info.hasOutstandingTagChanges = true
        }
    }

    func resetCurrentEntity() {
        currentEntityId = 0
    }

    func set(activeDeck deck: Deck) {
        self.activeDeck = deck
        player.reset(id: self.gameEnded ? true : false)
        updatePlayerTracker(reset: true)
    }

    func removeActiveDeck() {
        self.activeDeck = nil
        updatePlayerTracker(reset: true)
    }

    func set(playerTracker tracker: Tracker?) {
        self.playerTracker = tracker
        if let playerTracker = self.playerTracker {
            playerTracker.player = self.player
        }
    }

    func set(opponentTracker tracker: Tracker?) {
        self.opponentTracker = tracker
        if let opponentTracker = self.opponentTracker {
            opponentTracker.player = self.opponent
        }
    }

    // MARK: - game state
    func gameStart(at timestamp: Date) {
        if currentGameMode == .practice && !isInMenu && !gameEnded
            && lastGameStartTimestamp > Date.distantPast
            && timestamp > lastGameStartTimestamp {
            adventureRestart()
        }
        
        lastGameStartTimestamp = timestamp
        
        if gameStarted {
            return
        }
        reset()
        gameStarted = true
        gameStartDate = Date()
        gameEnded = false
        isInMenu = false

        Log.info?.message("----- Game Started -----")
        AppHealth.instance.setHearthstoneGameRunning(flag: true)

        showNotification(type: .gameStart)
        self.updatePlayerTracker(reset: true)
        self.updateOpponentTracker(reset: true)
        DispatchQueue.main.async { [weak self] in
            if Settings.instance.showTimer {
                self?.timerHud?.showWindow(self)
                TurnTimer.instance.start(game: self)
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
        let when = DispatchTime.now()
            + Double(Int64(30 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: when) {
            guard !self.gameEnded else { return }
            
            if self.currentGameMode == .casual || self.currentGameMode == .ranked {
                if let playerRank = self.rankDetector.playerRank(),
                    let opponentRank = self.rankDetector.opponentRank() {
                    self.playerRanks.append(playerRank)
                    self.opponentRanks.append(opponentRank)
                    
                    // check if player rank is in range "opponent rank - 3 -> opponent rank + 3)
                    if (opponentRank - 3) ... (opponentRank + 3) ~= playerRank {
                        // we can imagine we are on ranked games
                        self.currentGameMode = .ranked
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
        AppHealth.instance.setHearthstoneGameRunning(flag: false)
        gameStarted = false
        gameEndDate = Date()

        handleEndGame()
        updateOpponentTracker(reset: true)

        DispatchQueue.main.async { [weak self] in
            TurnTimer.instance.stop()
            self?.timerHud?.window?.orderOut(self)
            self?.cardHudContainer?.reset()
        }

        showSecrets(show: false)
    }

    func inMenu() {
        if isInMenu {
            return
        }
        Log.verbose?.message("Game is now in menu")

        TurnTimer.instance.stop()

        if Settings.instance.saveReplays {
            ReplayMaker.saveToDisk(powerLog: powerLog)
        }

        isInMenu = true
    }

    func handleEndGame() {
        Log.verbose?.message("rank: \(playerRanks), currentGameMode: \(currentGameMode)")
  
        guard !endGameStats else { return }
        endGameStats = true
        
        guard currentGameMode != .practice && currentGameMode != .none else { return }

        let _player = entities.map { $0.1 }.firstWhere { $0.isPlayer }
        if let _player = _player {
            hasCoin = !_player.has(tag: .first_player)
        }

        if currentGameMode == .ranked || currentGameMode == .casual {
            Log.info?.message("Format: \(currentFormat)")
        }
        
        var result: [Int: Int] = [:]
        playerRanks.forEach({ result[$0] = (result[$0] ?? 0) + 1 })
        let currentRank = Array(result).sorted { $0.1 < $1.1 }.last?.0 ?? -1
        
        Log.info?.message("End game : mode = \(currentGameMode), "
            + "rank = \(currentRank), result = \(gameResult), "
            + "against = \(opponent.name)(\(opponent.playerClass)), "
            + "opponent played : \(opponent.displayRevealedCards) ")

        if currentRank == -1 && currentGameMode == .ranked {
            Log.info?.message("rank is -1 and mode is ranked, ignore")
            return
        }

        if let opponentName = opponent.name,
            let opponentClass = opponent.playerClass,
            let playerClass = player.playerClass {
            
            var result: [Int: Int] = [:]
            opponentRanks.forEach({ result[$0] = (result[$0] ?? 0) + 1 })
            let opponentRank = Array(result).sorted { $0.1 < $1.1 }.last?.0 ?? -1
            
            var note = ""

            if Settings.instance.promptNotes
                && (currentGameMode == .ranked || currentGameMode == .casual) {
                DispatchQueue.main.async { [weak self] in
                    let alert = NSAlert()
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                    let message = "Do you want to add some notes for this game ?"
                    alert.informativeText = NSLocalizedString(message, comment: "")
                    alert.alertStyle = .informational
                    let frame = NSRect(x: 0, y: 0, width: 300, height: 80)
                    let input = NSTextView(frame: frame)
                    alert.accessoryView = input
                    NSRunningApplication.current().activate(options: [
                        NSApplicationActivationOptions.activateAllWindows,
                        NSApplicationActivationOptions.activateIgnoringOtherApps])
                    NSApp.activate(ignoringOtherApps: true)
                    if alert.runModal() == NSAlertFirstButtonReturn {
                        note = input.string ?? ""
                    }
                    self?.saveMatch(rank: currentRank,
                                   note: note,
                                   playerClass: playerClass,
                                   opponentName: opponentName,
                                   opponentClass: opponentClass,
                                   opponentRank: opponentRank)
                }
            } else {
                saveMatch(rank: currentRank,
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
        let startTime: Date
        if let gameStartDate = gameStartDate {
            startTime = gameStartDate
        } else {
            startTime = Date()
        }
        
        let endTime: Date
        if let gameEndDate = gameEndDate {
            endTime = gameEndDate
        } else {
            endTime = Date()
        }
        
        statistic.duration = Int(endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970)
        var cards = [String: Int]()
        opponent.displayRevealedCards.forEach({
            cards[$0.id] = $0.count
        })
        statistic.cards = cards
        
        if let deck = activeDeck {
            deck.add(statistic: statistic)
            Decks.instance.update(deck: deck)
            
            if HearthstatsAPI.isLogged() && Settings.instance.hearthstatsSynchronizeMatches {
                do {
                    if currentGameMode == .arena {
                        try HearthstatsAPI.postArenaMatch(game: self, deck: deck, stat: statistic)
                    } else if currentGameMode != .brawl {
                        try HearthstatsAPI.postMatch(game: self, deck: deck, stat: statistic)
                    }
                } catch {
                    Log.error?.message("Hearthstats error : \(error)")
                }
            }
        }
        
        if TrackOBotAPI.isLogged() && Settings.instance.trackobotSynchronizeMatches {
            do {
                try TrackOBotAPI.postMatch(game: self, playerClass: playerClass, stat: statistic)
            } catch {
                Log.error?.message("Track-o-Bot error : \(error)")
            }
        }
        
        if Settings.instance.hsReplaySynchronizeMatches {
            HSReplayAPI.getUploadToken { (token) in
                LogUploader.upload(logLines: self.powerLog, game: self,
                                   statistic: statistic) { result in
                    if case UploadResult.successful(let replayId) = result {
                        let opClass = NSLocalizedString(opponentClass.rawValue,
                            comment: "")
                        HSReplayManager.instance.saveReplay(replayId: replayId,
                            deck: self.activeDeck?.name ?? "",
                            against: "\(opponentName) - \(opClass)")
                        self.showNotification(type: .hsReplayPush(replayId: replayId))
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
            return (gameEntity[.turn] + 1) / 2
        }
        return 0
    }
    
    func turnsInPlayChange(entity: Entity, turn: Int) {
        guard let opponentEntity = opponentEntity else { return }
        
        if entity.isHero {
            let player: PlayerType = opponentEntity.isCurrentPlayer ? .opponent : .player
            if lastTurnStart[player.rawValue] >= turn {
                return
            }
            lastTurnStart[player.rawValue] = turn
            turnStart(player: player, turn: turn)
            return
        }
        if turn <= lastCompetitiveSpiritCheck || !Settings.instance.autoGrayoutSecrets
            || !entity.isMinion || !entity.isControlled(by: opponent.id)
            || !opponentEntity.isCurrentPlayer {
            return
        }
        lastCompetitiveSpiritCheck = turn
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
        showSecrets(show: true)
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
        
        DispatchQueue.global().async {
            while !self.isMulliganDone() {
                Thread.sleep(forTimeInterval: 0.1)
            }
            while let playerTurn = self.turnQueue.popFirst() {
                self.handleTurnStart(playerTurn: playerTurn)
            }
        }
    }
    
    func handleTurnStart(playerTurn: PlayerTurn) {
        let player = playerTurn.player
        Log.info?.message("Turn \(playerTurn.turn) start for player \(player) ")
        
        if player == .player {
            handleThaurissanCostReduction()
        }
        
        if turnQueue.count > 0 {
            return
        }
        
        DispatchQueue.main.async {
            TurnTimer.instance.set(player: player)
        }
        
        if player == .player && !isInMenu {
            showNotification(type: .turnStart)
        }
        
        if player == .player {
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
        gameResult = .win

        if hasBeenConceded {
            showNotification(type: .opponentConcede)
        }
    }

    func loss() {
        Log.info?.message("You lose : (")
        gameResult = .loss
    }

    func tied() {
        Log.info?.message("You lose : ( / game tied: (")
        gameResult = .draw
    }

    func isMulliganDone() -> Bool {
        let player = entities.map { $0.1 }.firstWhere { $0.isPlayer }
        let opponent = entities.map { $0.1 }.firstWhere { $0.has(tag: .player_id) && !$0.isPlayer }
        
        if let player = player, let opponent = opponent {
            return player[.mulligan_state] == Mulligan.done.rawValue
                && opponent[.mulligan_state] == Mulligan.done.rawValue
        }
        return false
    }

    func handleThaurissanCostReduction() {
        let thaurissans = opponent.board.filter({
            $0.cardId == CardIds.Collectible.Neutral.EmperorThaurissan && !$0.has(tag: .silenced)
        })
        if thaurissans.isEmpty {
            return
        }

        for impFavor in opponent.board
            .filter({ $0.cardId ==
                CardIds.NonCollectible.Neutral.EmperorThaurissan_ImperialFavorEnchantment }) {
            if let entity = entities[impFavor[.attached]] {
                entity.info.costReduction += thaurissans.count
            }
        }
    }

    // MARK: - Replay
    func proposeKeyPoint(type: KeyPointType, id: Int, player: PlayerType) {
        if let proposedKeyPoint = proposedKeyPoint {
            ReplayMaker.generate(type: proposedKeyPoint.type,
                                 id: proposedKeyPoint.id,
                                 player: proposedKeyPoint.player, game: self)
        }
        proposedKeyPoint = ReplayKeyPoint(data: nil, type: type, id: id, player: player)
    }

    func gameEndKeyPoint(victory: Bool, id: Int) {
        if let proposedKeyPoint = proposedKeyPoint {
            ReplayMaker.generate(type: proposedKeyPoint.type,
                                 id: proposedKeyPoint.id,
                                 player: proposedKeyPoint.player, game: self)
            self.proposedKeyPoint = nil
        }
        ReplayMaker.generate(type: victory ? .victory : .defeat, id: id,
                             player: .player, game: self)
    }

    // MARK: - player
    func set(playerHero cardId: String) {
        if let card = Cards.hero(byId: cardId) {
            player.playerClass = card.playerClass
            player.playerClassId = cardId
            Log.info?.message("Player class is \(card) ")
        }
    }

    func set(playerName name: String) {
        player.name = name
    }

    func playerGet(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.createInHand(entity: entity, turn: turn)
        updatePlayerTracker()
    }

    func playerBackToHand(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        updatePlayerTracker()
        player.boardToHand(entity: entity, turn: turn)
    }

    func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.boardToDeck(entity: entity, turn: turn)
        updatePlayerTracker()
    }

    func playerPlay(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        
        player.play(entity: entity, turn: turn)
        if let cardId = cardId, !cardId.isEmpty {
            playedCards.append(PlayedCard(player: .player, cardId: cardId, turn: turn))
        }
        
        if entity.has(tag: .ritual) {
            // if this entity has the RITUAL tag, it will trigger some C'Thun change
            // we wait 300ms so the proxy have the time to be updated
            let when = DispatchTime.now()
                + Double(Int64(300 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
            let queue = DispatchQueue.main
            queue.asyncAfter(deadline: when) { [weak self] in
                self?.updatePlayerTracker()
            }
        } else {
            updatePlayerTracker()
        }

        secretsOnPlay(entity: entity)
        updateOpponentTracker()
    }

    func secretsOnPlay(entity: Entity) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        if entity.isSpell {
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.Counterspell)

            if opponentMinionCount < 7 {
                let when = DispatchTime.now()
                    + Double(Int64(50 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
                let queue = DispatchQueue.main
                queue.asyncAfter(deadline: when) { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                    if entity.has(tag: .card_target)
                        && strongSelf.entities[entity[.card_target]] != nil
                        && strongSelf.entities[entity[.card_target]]!.isMinion {
                        strongSelf.opponentSecrets?
                            .setZero(cardId: CardIds.Secrets.Mage.Spellbender)
                    }
                    strongSelf.opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.CatTrick)
                    strongSelf.showSecrets(show: true)
                }
            }
        } else if entity.isMinion && playerMinionCount > 3 {
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.SacredTrial)
            showSecrets(show: true)
        }
    }

    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.handDiscard(entity: entity, turn: turn)
        updatePlayerTracker()
    }

    func playerSecretPlayed(entity: Entity, cardId: String?, turn: Int, fromZone: Zone) {
        if String.isNullOrEmpty(cardId) {
            return
        }

        switch fromZone {
        case .deck:
            player.secretPlayedFromDeck(entity: entity, turn: turn)
        case .hand:
            player.secretPlayedFromHand(entity: entity, turn: turn)
            secretsOnPlay(entity: entity)
        default:
            player.createInSecret(entity: entity, turn: turn)
            return
        }
        updatePlayerTracker()
    }

    func playerMulligan(entity: Entity, cardId: String?) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        // TurnTimer.Instance.MulliganDone(ActivePlayer.Player);
        player.mulligan(entity: entity)
        updatePlayerTracker()
    }

    func playerDraw(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        if cardId == "GAME_005" {
            playerGet(entity: entity, cardId: cardId, turn: turn)
        } else {
            player.draw(entity: entity, turn: turn)
            updatePlayerTracker()
        }
    }

    func playerRemoveFromDeck(entity: Entity, turn: Int) {
        player.removeFromDeck(entity: entity, turn: turn)
        updatePlayerTracker()
    }

    func playerDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        player.deckDiscard(entity: entity, turn: turn)
        updatePlayerTracker()
    }

    func playerDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        player.deckToPlay(entity: entity, turn: turn)
        updatePlayerTracker()
    }

    func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        player.playToGraveyard(entity: entity, cardId: cardId, turn: turn)
        updatePlayerTracker()
    }

    func playerJoust(entity: Entity, cardId: String?, turn: Int) {
        player.joustReveal(entity: entity, turn: turn)
        updatePlayerTracker()
    }

    func playerGetToDeck(entity: Entity, cardId: String?, turn: Int) {
        player.createInDeck(entity: entity, turn: turn)
        updatePlayerTracker()
    }

    func playerFatigue(value: Int) {
        Log.info?.message("Player get \(value) fatigue")
        player.fatigue = value
        updatePlayerTracker()
    }

    func playerCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        player.createInPlay(entity: entity, turn: turn)
    }

    func playerStolen(entity: Entity, cardId: String?, turn: Int) {
        player.stolenByOpponent(entity: entity, turn: turn)
        opponent.stolenFromOpponent(entity: entity, turn: turn)

        if entity.isSecret {
            var heroClass: CardClass?
            var className = "\(entity[.tag_class]) "
            if !String.isNullOrEmpty(className) {
                className = className.lowercased()
                heroClass = CardClass(rawValue: className)
                if heroClass == .none {
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
            opponentSecrets?.newSecretPlayed(heroClass: heroClass!, id: entity.id, turn: turn)
            showSecrets(show: true)
        }
    }

    func playerRemoveFromPlay(entity: Entity, turn: Int) {
        player.removeFromPlay(entity: entity, turn: turn)
    }
    
    func playerCreateInSetAside(entity: Entity, turn: Int) {
        player.createInSetAside(entity: entity, turn: turn)
    }

    func playerHeroPower(cardId: String, turn: Int) {
        updateBoardAttack()
        player.heroPower(turn: turn)
        Log.info?.message("Player Hero Power \(cardId) \(turn) ")

        if !Settings.instance.autoGrayoutSecrets {
            return
        }
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.DartTrap)
        showSecrets(show: true)
    }

    // MARK: - opponent
    func set(opponentHero cardId: String) {
        if let card = Cards.hero(byId: cardId) {
            opponent.playerClass = card.playerClass
            opponent.playerClassId = cardId
            updateOpponentTracker()
            Log.info?.message("Opponent class is \(card) ")
        }
    }

    func set(opponentName name: String) {
        opponent.name = name
        updateOpponentTracker()
    }

    func opponentGet(entity: Entity, turn: Int, id: Int) {
        if !isMulliganDone() && entity[.zone_position] == 5 {
            entity.cardId = CardIds.NonCollectible.Neutral.TheCoin
        }

        opponent.createInHand(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.boardToHand(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        opponent.boardToDeck(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentPlay(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.play(entity: entity, turn: turn)
        
        if let cardId = cardId, !cardId.isEmpty {
            playedCards.append(PlayedCard(player: .opponent, cardId: cardId, turn: turn))
        }
        
        if entity.has(tag: .ritual) {
            // if this entity has the RITUAL tag, it will trigger some C'Thun change
            // we wait 300ms so the proxy have the time to be updated
            let when = DispatchTime.now()
                + Double(Int64(300 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
            let queue = DispatchQueue.main
            queue.asyncAfter(deadline: when) { [weak self] in
                self?.updateOpponentTracker()
            }
        } else {
            updateOpponentTracker()
        }
        updateCardHuds()
        updateOpponentTracker()
    }

    func opponentHandDiscard(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.handDiscard(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentSecretPlayed(entity: Entity, cardId: String?,
                              from: Int, turn: Int,
                                fromZone: Zone, otherId: Int) {
        opponentSecretCount += 1

        switch fromZone {
        case .deck:
            opponent.secretPlayedFromDeck(entity: entity, turn: turn)
        case .hand:
            opponent.secretPlayedFromHand(entity: entity, turn: turn)
            break
        default:
            opponent.createInSecret(entity: entity, turn: turn)
        }
        updateCardHuds()

        var heroClass: CardClass?
        var className = "\(entity[.tag_class])"
        if !String.isNullOrEmpty(className) {
            className = className.lowercased()
            heroClass = CardClass(rawValue: className)
            if heroClass == .none {
                if let playerClass = opponent.playerClass {
                    heroClass = playerClass
                }
            }
        } else {
            if let playerClass = opponent.playerClass {
                heroClass = playerClass
            }
        }
        Log.info?.message("Secret played by \(entity[.tag_class])"
            + " -> \(heroClass) -> \(opponent.playerClass)")
        guard let _ = heroClass else { return }

        opponentSecrets?.newSecretPlayed(heroClass: heroClass!, id: otherId, turn: turn)
        showSecrets(show: true)
    }

    func opponentMulligan(entity: Entity, from: Int) {
        opponent.mulligan(entity: entity)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentDraw(entity: Entity, turn: Int) {
        opponent.draw(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentRemoveFromDeck(entity: Entity, turn: Int) {
        opponent.removeFromDeck(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckDiscard(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckToPlay(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentPlayToGraveyard(entity: Entity, cardId: String?,
                                 turn: Int, playersTurn: Bool) {
        opponent.playToGraveyard(entity: entity, cardId: cardId, turn: turn)
        if playersTurn && entity.isMinion {
            opponentMinionDeath(entity: entity, turn: turn)
        }
        updateCardHuds()
        updateOpponentTracker()
    }

    func opponentJoust(entity: Entity, cardId: String?, turn: Int) {
        opponent.joustReveal(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentGetToDeck(entity: Entity, turn: Int) {
        opponent.createInDeck(entity: entity, turn: turn)
        updateOpponentTracker()
        updateCardHuds()
    }

    func opponentSecretTrigger(entity: Entity, cardId: String?, turn: Int, otherId: Int) {
        opponent.secretTriggered(entity: entity, turn: turn)

        opponentSecretCount -= 1
        if let cardId = cardId {
            opponentSecrets?.secretRemoved(id: otherId, cardId: cardId)
        }
        if opponentSecretCount <= 0 {
            showSecrets(show: false)
        } else {
            if Settings.instance.autoGrayoutSecrets {
                opponentSecrets?.setZero(cardId: cardId!)
            }
            showSecrets(show: true)
        }
        updateCardHuds()
    }

    func opponentFatigue(value: Int) {
        opponent.fatigue = value
        updateOpponentTracker()
    }

    func opponentCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.createInPlay(entity: entity, turn: turn)
    }

    func opponentStolen(entity: Entity, cardId: String?, turn: Int) {
        opponent.stolenByOpponent(entity: entity, turn: turn)
        player.stolenFromOpponent(entity: entity, turn: turn)

        if entity.isSecret {
            opponentSecretCount -= 1
            opponentSecrets?.secretRemoved(id: entity.id, cardId: cardId!)
            if opponentSecretCount <= 0 {
                showSecrets(show: false)
            } else {
                if Settings.instance.autoGrayoutSecrets {
                    opponentSecrets?.setZero(cardId: cardId!)
                }
                showSecrets(show: true)
            }

            updateOpponentTracker()
        }
    }

    func opponentRemoveFromPlay(entity: Entity, turn: Int) {
        player.removeFromPlay(entity: entity, turn: turn)
    }
    
    func opponentCreateInSetAside(entity: Entity, turn: Int) {
        opponent.createInSetAside(entity: entity, turn: turn)
    }

    func opponentHeroPower(cardId: String, turn: Int) {
        updateBoardAttack()
        opponent.heroPower(turn: turn)
        Log.info?.message("Opponent Hero Power \(cardId) \(turn) ")
    }

    // MARK: - game actions
    func defending(entity: Entity?) {
        self.defendingEntity = entity
        if let attackingEntity = self.attackingEntity,
            let defendingEntity = self.defendingEntity,
            let entity = entity {
            if entity.isControlled(by: opponent.id) {
                opponentSecrets?.zeroFromAttack(attacker: attackingEntity,
                                                defender: defendingEntity)
            }
        }
    }

    func attacking(entity: Entity?) {
        self.attackingEntity = entity
        if let attackingEntity = self.attackingEntity,
            let defendingEntity = self.defendingEntity,
            let entity = entity {
            if entity.isControlled(by: player.id) {
                opponentSecrets?.zeroFromAttack(attacker: attackingEntity,
                                                defender: defendingEntity)
            }
        }
    }

    func playerMinionPlayed() {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.Snipe)
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.MirrorEntity)
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.Repentance)

        showSecrets(show: true)
    }

    func opponentMinionDeath(entity: Entity, turn: Int) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        if opponent.handCount < 10 {
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.Duplicate)
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
                    && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }

            if entities.map({ $0.1 })
                .any({ $0.cardId == CardIds.NonCollectible.Shaman.AncestralSpirit_AncestralSpiritEnchantment
                    && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }
            // swiftlint:enable line_length

            if let opponentEntity = opponentEntity,
                opponentEntity.has(tag: .extra_deathrattles) {
                numDeathrattleMinions *= (opponentEntity[.extra_deathrattles] + 1)
            }

            avengeAsync(deathRattleCount: numDeathrattleMinions)

            // redemption never triggers if a deathrattle effect fills up the board
            // effigy can trigger ahead of the deathrattle effect, but only if
            // effigy was played before the deathrattle minion
            if opponentMinionCount < 7 - numDeathrattleMinions {
                opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.Redemption)
                opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.Effigy)
            } else {
                // TODO need to properly break ties when effigy + deathrattle played in same turn
                let minionTurnPlayed = turn - entity[.num_turns_in_play]
                var secretOffset = 0
                if let secret = opponentSecrets!.secrets
                    .firstWhere({ $0.turnPlayed >= minionTurnPlayed }) {
                    secretOffset = opponentSecrets!.secrets.index(of: secret)!
                }
                opponentSecrets?.setZeroOlder(cardId: CardIds.Secrets.Mage.Effigy,
                                              stopIndex: secretOffset)
            }
        }
        showSecrets(show: true)
    }

    func avengeAsync(deathRattleCount: Int) {
        avengeDeathRattleCount += deathRattleCount
        if awaitingAvenge {
            return
        }
        awaitingAvenge = true
        if opponentMinionCount != 0 {
            let when = DispatchTime.now()
                + Double(Int64(50 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
            let queue = DispatchQueue.main
            queue.asyncAfter(deadline: when) { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.opponentMinionCount - strongSelf.avengeDeathRattleCount > 0 {
                    strongSelf.opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.Avenge)
                    DispatchQueue.main.async { [weak self] in
                        self?.showSecrets(show: true)

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
        if !entity.isHero || !entity.isControlled(by: opponent.id) {
            return
        }
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.EyeForAnEye)
        showSecrets(show: true)
    }

    func opponentTurnStart(entity: Entity) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }
        if !entity.isMinion {
            return
        }
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
        showSecrets(show: true)
    }

    // MARK: - UI
    func showSecrets(show: Bool) {
        guard Settings.instance.showSecretHelper else { return }

        DispatchQueue.main.async { [weak self] in
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

        lastCardsUpdateRequest = Date().timeIntervalSince1970
        let when = DispatchTime.now()
            + Double(Int64(100 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: when) { [weak self] in
            guard let strongSelf = self else { return }
            
            if !force && Date().timeIntervalSince1970 - strongSelf.lastCardsUpdateRequest < 0.1 {
                return
            }
            strongSelf.cardHudContainer?.window?.orderOut(strongSelf)
            strongSelf.cardHudContainer?.showWindow(strongSelf)
            strongSelf.cardHudContainer?.update(entities: strongSelf.opponent.hand,
                                                cardCount: strongSelf.opponent.handCount)
        }
    }
    
    func updateBoardAttack() {
        let board = BoardState()
        let settings = Settings.instance
        
        if settings.playerBoardDamage {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                
                if !strongSelf.gameEnded {
                    strongSelf.playerBoardDamage?.window?.orderOut(strongSelf)
                    strongSelf.playerBoardDamage?.showWindow(strongSelf)
                    strongSelf.playerBoardDamage?.update(attack: board.player.damage)
                } else {
                    strongSelf.playerBoardDamage?.window?.orderOut(strongSelf)
                }
            }
        } else {
            self.playerBoardDamage?.window?.orderOut(self)
        }
        
        if settings.opponentBoardDamage {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                
                if !strongSelf.gameEnded {
                    strongSelf.opponentBoardDamage?.window?.orderOut(strongSelf)
                    strongSelf.opponentBoardDamage?.showWindow(strongSelf)
                    strongSelf.opponentBoardDamage?.update(attack: board.opponent.damage)
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
        DispatchQueue.main.async { [weak self] in
            if let cards = self?.player.playerCardList {
                self?.playerTracker?.update(cards: cards, reset: reset)
            }
        }
    }

    func updateOpponentTracker(reset: Bool = false) {
        updateBoardAttack()
        
        DispatchQueue.main.async { [weak self] in
            if let cards = Settings.instance.clearTrackersOnGameEnd
                && self?.gameEnded ?? true ? [] : self?.opponent.opponentCardList {
                self?.opponentTracker?.update(cards: cards, reset: reset)
            }
        }
    }

    func hearthstoneIsActive(active: Bool) {
        if Settings.instance.autoPositionTrackers {
            moveWindow(windowController: playerTracker,
                       active: active,
                       frame: SizeHelper.playerTrackerFrame())
            moveWindow(windowController: opponentTracker,
                       active: active,
                       frame: SizeHelper.opponentTrackerFrame())
        }
        if Settings.instance.showSecretHelper {
            moveWindow(windowController: secretTracker,
                       active: active,
                       frame: SizeHelper.secretTrackerFrame())
        }
        if Settings.instance.showTimer {
            moveWindow(windowController: timerHud,
                       active: active,
                       frame: SizeHelper.timerHudFrame())
        }
        if Settings.instance.showCardHuds {
            moveWindow(windowController: cardHudContainer,
                       active: active,
                       frame: SizeHelper.cardHudContainerFrame())
            updateCardHuds()
        }
        if Settings.instance.playerBoardDamage {
            moveWindow(windowController: playerBoardDamage,
                       active: active,
                       frame: SizeHelper.playerBoardDamageFrame())
        }
        if Settings.instance.opponentBoardDamage {
            moveWindow(windowController: opponentBoardDamage,
                       active: active,
                       frame: SizeHelper.opponentBoardDamageFrame())
        }
    }

    func moveWindow(windowController: NSWindowController?, active: Bool, frame: NSRect) {
        guard let windowController = windowController else { return }
        guard frame != NSRect.zero else { return }

        if windowController.window?.isVisible ?? false {
            windowController.window?.orderOut(self)
            windowController.window?.setFrame(frame, display: true)
            windowController.showWindow(self)
        } else {
            windowController.window?.setFrame(frame, display: true)
        }
        let level: Int
        if active {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow))
        }
        windowController.window?.level = level
    }

     func showNotification(type: NotificationType) {
        let settings = Settings.instance

        switch type {
        case .gameStart:
            guard settings.notifyGameStart else { return }
            if Hearthstone.instance.hearthstoneActive { return }
            
            Toast.show(title: NSLocalizedString("Hearthstone", comment: ""),
                       message: NSLocalizedString("Your game begins", comment: ""))
        
        case .opponentConcede:
            guard settings.notifyOpponentConcede else { return }
            if Hearthstone.instance.hearthstoneActive { return }
            
            Toast.show(title: NSLocalizedString("Victory", comment: ""),
                       message: NSLocalizedString("Your opponent have conceded", comment: ""))
            
        case .turnStart:
            guard settings.notifyTurnStart else { return }
            if Hearthstone.instance.hearthstoneActive { return }
            
            Toast.show(title: NSLocalizedString("Hearthstone", comment: ""),
                       message: NSLocalizedString("It's your turn to play", comment: ""))
        
        case .hsReplayPush(let replayId):
            guard settings.showHSReplayPushNotification else { return }
            
            Toast.show(title: NSLocalizedString("HSReplay", comment: ""),
                       message: NSLocalizedString("Your replay has been uploaded on HSReplay",
                        comment: "")) {
                        HSReplayManager.showReplay(replayId: replayId)
            }

        }
    }
}

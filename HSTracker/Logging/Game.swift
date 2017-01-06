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
import RealmSwift

struct PlayingDeck {
    let id: String
    let name: String
    let hsDeckId: Int64?
    let playerClass: CardClass
    let cards: [Card]
    let isArena: Bool
}

class Game {
    // MARK: - vars
    var currentTurn = 0
    var lastId = 0
    var gameTriggerCount = 0
    var powerLog: [LogLine] = []
    var playedCards: [PlayedCard] = []
    var currentGameStats: GameStats?
    var lastGame: GameStats?

    var player: Player
    var opponent: Player
    var currentMode: Mode? = .invalid
    var previousMode: Mode? = .invalid

    private var _spectator: Bool?
    var spectator: Bool {
        if let _spectator = _spectator {
            return _spectator
        }
        _spectator = Hearthstone.instance.mirror?.isSpectating()
        if let _spectator = _spectator {
            return _spectator
        }
        return false
    }

    private var _currentGameMode: GameMode = .none
    var currentGameMode: GameMode {
        if spectator {
            return .spectator
        }

        if _currentGameMode == .none {
            _currentGameMode = GameMode(gameType: currentGameType)
        }
        return _currentGameMode
    }

    private var _currentGameType: GameType = .gt_unknown
    var currentGameType: GameType {

        if _currentGameType != .gt_unknown {
            return _currentGameType
        }
        if let gameType = Hearthstone.instance.mirror?.getGameType() as? Int,
            let type = GameType(rawValue: gameType) {
            _currentGameType = type
        }
        return _currentGameType
    }

    var _matchInfoCacheInvalid = true
    var entities: [Int: Entity] = [:]
    var tmpEntities: [Entity] = []
    var knownCardIds: [Int: [String]] = [:]
    var joustReveals = 0
    var gameStarted = false
    var gameEnded = true {
        didSet {
            WindowManager.default.updateTrackers(reset: true)
        }
    }
    var lastCardPlayed: Int?

    var currentDeck: PlayingDeck?

    var currentEntityId = 0
    var currentEntityHasCardId = false
    var playerUsedHeroPower = false
    private var hasCoin = false
    var currentEntityZone: Zone = .invalid
    var opponentUsedHeroPower = false
    var determinedPlayers: Bool {
        return player.id > 0 && opponent.id > 0
    }
    var setupDone = false
    var proposedKeyPoint: ReplayKeyPoint?
    var opponentSecrets: OpponentSecrets?
    private var defendingEntity: Entity?
    private var attackingEntity: Entity?
    private var avengeDeathRattleCount = 0
    private var opponentSecretCount = 0
    private var awaitingAvenge = false
    var isInMenu = true
    private var handledGameEnd = false
    var wasInProgress = false
    var enqueueTime: Date = Date.distantPast
    private var lastCompetitiveSpiritCheck: Int = 0
    private var lastTurnStart: [Int] = [0, 0]
    private var turnQueue: Set<PlayerTurn> = Set()

    private var maxBlockId: Int = 0
    private(set) var currentBlock: Block?
    
    fileprivate var lastGameStartTimestamp: Date = Date.distantPast

    private var _matchInfo: MatchInfo?
    var matchInfo: MatchInfo? {
        if let _matchInfo = _matchInfo {
            return _matchInfo
        }
        if let matchInfo = Hearthstone.instance.mirror?.getMatchInfo() {
            _matchInfo = MatchInfo(info: matchInfo)
        }
        return _matchInfo
    }

    var arenaInfo: ArenaInfo? {
        if let _arenaInfo = Hearthstone.instance.mirror?.getArenaDeck() {
            return ArenaInfo(info: _arenaInfo)
        }
        return nil
    }

    var brawlInfo: BrawlInfo? {
        if let _brawlInfo = Hearthstone.instance.mirror?.getBrawlInfo() {
            return BrawlInfo(info: _brawlInfo)
        }
        return nil
    }

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

    private var _currentFormat = FormatType.ft_unknown
    var currentFormat: Format {
        if let mirror = Hearthstone.instance.mirror,
            let mirrorFormat = mirror.getFormat() as? Int,
            _currentFormat == .ft_unknown,
            let format = FormatType(rawValue: mirrorFormat) {
            _currentFormat = format
        }
        return Format(formatType: _currentFormat)
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

        powerLog = []
        playedCards = []
        
        lastId = 0
        gameTriggerCount = 0
        maxBlockId = 0
        currentBlock = nil

        _matchInfo = nil
        _currentFormat = .ft_unknown
        _currentGameType = .gt_unknown
        currentGameStats = GameStats()

        entities.removeAll()
        tmpEntities.removeAll()
        knownCardIds.removeAll()
        joustReveals = 0
        gameStarted = false
        gameEnded = true
        lastCardPlayed = nil
        currentEntityId = 0
        currentEntityHasCardId = false
        playerUsedHeroPower = false
        hasCoin = false
        currentEntityZone = .invalid
        opponentUsedHeroPower = false
        setupDone = false
        proposedKeyPoint = nil
        opponentSecrets?.clearSecrets()
        defendingEntity = nil
        attackingEntity = nil
        avengeDeathRattleCount = 0
        opponentSecretCount = 0
        awaitingAvenge = false
        isInMenu = true
        handledGameEnd = false
        wasInProgress = false
        lastTurnStart = [0, 0]

        player.reset()
        if let currentdeck = self.currentDeck {
            player.playerClass = currentdeck.playerClass
        }
        opponent.reset()

        if let localPlayer = matchInfo?.localPlayer,
            let opposingPlayer = matchInfo?.opposingPlayer,
            !_matchInfoCacheInvalid {
            player.name = localPlayer.name
            player.id = localPlayer.playerId
            opponent.name = opposingPlayer.name
            opponent.id = opposingPlayer.playerId
        }

        WindowManager.default.hideGameTrackers()
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

    func blockStart() {
        maxBlockId += 1
        let blockId = maxBlockId
        currentBlock = currentBlock?.createChild(blockId: blockId)
            ?? Block(parent: nil, id: blockId)
    }

    func blockEnd() {
        currentBlock = currentBlock?.parent
    }

    func set(activeDeck deck: Deck?) {
        if let deck = deck {
            var cards: [Card] = []
            for deckCard in deck.cards {
                if let card = Cards.by(cardId: deckCard.id) {
                    card.count = deckCard.count
                    cards.append(card)
                }
            }
            currentDeck = PlayingDeck(id: deck.deckId,
                                      name: deck.name,
                                      hsDeckId: deck.hsDeckId.value,
                                      playerClass: deck.playerClass,
                                      cards: cards.sortCardList(),
                                      isArena: deck.isArena
            )
        } else {
            currentDeck = nil
        }
        player.playerClass = currentDeck?.playerClass
        WindowManager.default.updateTrackers(reset: true)
    }

    func removeActiveDeck() {
        currentDeck = nil
        WindowManager.default.updateTrackers(reset: true)
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
        gameEnded = false
        isInMenu = false

        Log.info?.message("----- Game Started -----")
        AppHealth.instance.setHearthstoneGameRunning(flag: true)

        showNotification(type: .gameStart)

        if Settings.instance.showTimer {
            TurnTimer.instance.start(game: self)
        }

        WindowManager.default.updateTrackers(reset: true)

        cacheMatchInfo()
        currentGameStats?.startTime = timestamp
    }

    private func invalidateMatchInfoCache() {
        _matchInfoCacheInvalid = true
    }

    private func cacheMatchInfo() {
        if !_matchInfoCacheInvalid { return }

        _matchInfoCacheInvalid = false
        DispatchQueue.global().async {
            guard let mirror = Hearthstone.instance.mirror else { return }

            var matchInfo: MirrorMatchInfo? = mirror.getMatchInfo()
            while matchInfo == nil {
                matchInfo = mirror.getMatchInfo()
                Thread.sleep(forTimeInterval: 0.1)
            }
            if let matchInfo = matchInfo {
                DispatchQueue.main.async { [weak self] in
                    Log.info?.message("\(matchInfo.localPlayer.name) vs "
                        + "\(matchInfo.opposingPlayer.name)")
                    self?._matchInfo = MatchInfo(info: matchInfo)
                    if let _matchInfo = self?.matchInfo {
                        self?.player.name = _matchInfo.localPlayer.name
                        self?.opponent.name = _matchInfo.opposingPlayer.name
                        self?.player.id = _matchInfo.localPlayer.playerId
                        self?.opponent.id = _matchInfo.opposingPlayer.playerId

                        WindowManager.default.updateTrackers()
                    }
                }
            }
        }
    }

    private func adventureRestart() {
        // The game end is not logged in PowerTaskList
        Log.info?.message("Adventure was restarted. Simulating game end.")
        concede()
        loss()
        gameEnd()
        inMenu()
    }

    func gameEnd() {
        Log.info?.message("----- Game End -----")
        AppHealth.instance.setHearthstoneGameRunning(flag: false)
        gameStarted = false
        currentGameStats?.endTime = Date()

        DispatchQueue.main.async { [weak self] in
            self?.handleEndGame()
        }

        WindowManager.default.updateTrackers(reset: true)
        WindowManager.default.hideGameTrackers()
        TurnTimer.instance.stop()
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

        //resetStoredGameState()
        /*if let currentDeck = self.currentDeck,
            currentDeck.isArenaRunCompleted,
            Settings.instance.autoArchiveArenaDeck {

            if let realm = try? Realm(),
                let deck = realm.objects(Deck.self)
                    .filter("deckId = '\(currentDeck.id)'").first {
                do {
                    try realm.write {
                        deck.isActive = false
                    }
                } catch {
                    Log.error?.message("Can not update deck. Error : \(error)")
                }
            }
        }*/
    }

    func handleEndGame() {
        if currentGameStats == nil || handledGameEnd {
            Log.warning?.message("HandleGameEnd was already called.")
            return
        }
        handledGameEnd = true
        invalidateMatchInfoCache()

        guard let currentGameStats = currentGameStats else {
            Log.error?.message("No current game stats, ignoring")
            return
        }

        if currentGameMode == .spectator && currentGameStats.result == .none {
            Log.info?.message("Game was spectator mode without a game result."
                + " Probably exited spectator mode early.")
            return
        }

        if let build = BuildDates.latestBuild {
            currentGameStats.hearthstoneBuild.value = build.build
        }
        currentGameStats.season = Database.currentSeason

        if let name = player.name {
            currentGameStats.playerName = name
        }
        if let _player = entities.map({ $0.1 }).firstWhere({ $0.isPlayer }) {
            currentGameStats.coin = !_player.has(tag: .first_player)
        }

        if let name = opponent.name {
            currentGameStats.opponentName = name
        } else if currentGameStats.opponentHero != .neutral {
            currentGameStats.opponentName = currentGameStats.opponentHero.rawValue
        }

        currentGameStats.turns = turnNumber()

        currentGameStats.gameMode = currentGameMode
        currentGameStats.format = currentFormat

        if let matchInfo = self.matchInfo, currentGameMode == .ranked {
            let wild = currentFormat == .wild

            currentGameStats.rank = wild
                ? matchInfo.localPlayer.wildRank
                : matchInfo.localPlayer.standardRank
            currentGameStats.opponentRank = wild
                ? matchInfo.opposingPlayer.wildRank
                : matchInfo.opposingPlayer.standardRank
            currentGameStats.legendRank = wild
                ? matchInfo.localPlayer.wildLegendRank
                : matchInfo.localPlayer.standardLegendRank
            currentGameStats.opponentLegendRank = wild
                ? matchInfo.opposingPlayer.wildLegendRank
                : matchInfo.opposingPlayer.standardLegendRank
            currentGameStats.stars = wild
                ? matchInfo.localPlayer.wildStars
                : matchInfo.localPlayer.standardStars
        } else if currentGameMode == .arena {
            currentGameStats.arenaLosses = arenaInfo?.losses ?? 0
            currentGameStats.arenaWins = arenaInfo?.wins ?? 0
        } else if let brawlInfo = self.brawlInfo, currentGameMode == .brawl {
            currentGameStats.brawlWins = brawlInfo.wins
            currentGameStats.brawlLosses = brawlInfo.losses
        }

        currentGameStats.gameType = currentGameType
        if let serverInfo = Hearthstone.instance.mirror?.getGameServerInfo() {
            currentGameStats.serverInfo = ServerInfo(info: serverInfo)
        }
        currentGameStats.playerCardbackId = matchInfo?.localPlayer.cardBackId ?? 0
        currentGameStats.opponentCardbackId = matchInfo?.opposingPlayer.cardBackId ?? 0
        currentGameStats.friendlyPlayerId = matchInfo?.localPlayer.playerId ?? 0
        currentGameStats.scenarioId = matchInfo?.missionId ?? 0
        currentGameStats.brawlSeasonId = matchInfo?.brawlSeasonId ?? 0
        currentGameStats.rankedSeasonId = matchInfo?.rankedSeasonId ?? 0
        currentGameStats.hsDeckId.value = currentDeck?.hsDeckId

        if Settings.instance.promptNotes {
            let message = NSLocalizedString("Do you want to add some notes for this game ?",
                                            comment: "")
            let frame = NSRect(x: 0, y: 0, width: 300, height: 80)
            let input = NSTextView(frame: frame)

            if NSAlert.show(style: .informational, message: message,
                            accessoryView: input, forceFront: true) {
                currentGameStats.note = input.string ?? ""
            }
        }

        Log.verbose?.message("End game: \(currentGameStats)")

        if let realm = try? Realm(),
            let currentDeck = currentDeck,
            let deck = realm.objects(Deck.self).filter("deckId = '\(currentDeck.id)'").first {
            do {
                try realm.write {
                    deck.gameStats.append(currentGameStats)
                    player.revealedCards.filter({
                        $0.collectible
                    }).forEach({
                        let card = RealmCard(id: $0.id, count: $0.count)
                        currentGameStats.revealedCards.append(card)
                    })
                    opponent.opponentCardList.filter({
                        !$0.isCreated
                    }).forEach({
                        let card = RealmCard(id: $0.id, count: $0.count)
                        currentGameStats.opponentCards.append(card)
                    })

                    if Settings.instance.autoArchiveArenaDeck &&
                        currentGameMode == .arena && deck.isArena && deck.arenaFinished() {
                        deck.isActive = false
                    }
                }
            } catch {
                Log.error?.message("Can't save statistic : \(error)")
            }
        }

        syncStats()
        lastGame = currentGameStats
    }

    private func syncStats() {
        guard let currentGameStats = currentGameStats else { return }
        guard currentGameMode != .practice && currentGameMode != .none else {
            Log.info?.message("Game was in \(currentGameMode), don't send to third-party")
            return
        }

        if Settings.instance.hsReplaySynchronizeMatches {
            HSReplayAPI.getUploadToken { _ in
                LogUploader.upload(logLines: self.powerLog,
                                   statistic: currentGameStats) { result in
                    if case UploadResult.successful(let replayId) = result {
                        self.showNotification(type: .hsReplayPush(replayId: replayId))
                        NotificationCenter.default
                            .post(name: Notification.Name(rawValue: "reload_decks"), object: nil)
                    }
                }
            }
        }

        if TrackOBotAPI.isLogged() && Settings.instance.trackobotSynchronizeMatches {
            do {
                try TrackOBotAPI.postMatch(stat: currentGameStats)
            } catch {
                Log.error?.message("Track-o-Bot error : \(error)")
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
        if turn <= lastCompetitiveSpiritCheck
            || !entity.isMinion || !entity.isControlled(by: opponent.id)
            || !opponentEntity.isCurrentPlayer {
            WindowManager.default.updateTrackers()
            return
        }
        lastCompetitiveSpiritCheck = turn
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
        WindowManager.default.updateTrackers()
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
        
        WindowManager.default.updateTrackers()
    }

    func concede() {
        Log.info?.message("Game has been conceded : (")
        currentGameStats?.wasConceded = true
    }

    func win() {
        Log.info?.message("You win ¯\\_(ツ) _ / ¯")
        currentGameStats?.result = .win

        if let currentGameStats = currentGameStats,
            currentGameStats.wasConceded {
            showNotification(type: .opponentConcede)
        }
    }

    func loss() {
        Log.info?.message("You lose : (")
        currentGameStats?.result = .loss
    }

    func tied() {
        Log.info?.message("You lose : ( / game tied: (")
        currentGameStats?.result = .draw
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

    /*private var storedPowerLogs: [Int: [LogLine]] = [:]
    private var storedPlayerNames: [Int: String] = [:]
    private var storedGameStats: GameStats?
    func storeGameState() {
        guard let _serverInfo = Hearthstone.instance.mirror?.getGameServerInfo() else { return }
        let serverInfo = ServerInfo(info: _serverInfo)
        if serverInfo.gameHandle == 0 {
            return
        }

        Log.info?.message("Storing powerlog for gameId=\(serverInfo.gameHandle)")
        storedPowerLogs[serverInfo.gameHandle] = powerLog

        if player.id != -1 && storedPlayerNames[player.id] == nil {
            storedPlayerNames[player.id] = player.name
        }
        if opponent.id != -1 && storedPlayerNames[opponent.id] == nil {
            storedPlayerNames[opponent.id] = opponent.name
        }
        if storedGameStats == nil {
            storedGameStats = currentGameStats
        }
    }

    func getStoredPlayerName(id: Int) -> String? {
        if let name = storedPlayerNames[id] {
            return name
        }
        return nil
    }

    private func resetStoredGameState() {
        storedPowerLogs.removeAll()
        storedPlayerNames.removeAll()
        storedGameStats = nil
    }*/

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

            currentGameStats?.playerHero = card.playerClass
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
        WindowManager.default.updateTrackers()
    }

    func playerBackToHand(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        WindowManager.default.updateTrackers()
        player.boardToHand(entity: entity, turn: turn)
    }

    func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.boardToDeck(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
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
            queue.asyncAfter(deadline: when) {
                WindowManager.default.updateTrackers()
            }
        }

        secretsOnPlay(entity: entity)
        WindowManager.default.updateTrackers()
    }

    func secretsOnPlay(entity: Entity) {
        if entity.isSpell {
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.Counterspell)

            if opponentMinionCount < 7 {
                let when = DispatchTime.now() + DispatchTimeInterval.milliseconds(50)
                DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                    if entity.has(tag: .card_target)
                        && strongSelf.entities[entity[.card_target]] != nil
                        && strongSelf.entities[entity[.card_target]]!.isMinion {
                        strongSelf.opponentSecrets?
                            .setZero(cardId: CardIds.Secrets.Mage.Spellbender)
                    }
                    strongSelf.opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.CatTrick)
                    WindowManager.default.updateTrackers()
                }
            }
        } else if entity.isMinion && playerMinionCount > 3 {
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.SacredTrial)
            WindowManager.default.updateTrackers()
        }
    }

    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.handDiscard(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
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
        WindowManager.default.updateTrackers()
    }

    func playerMulligan(entity: Entity, cardId: String?) {
        if String.isNullOrEmpty(cardId) {
            return
        }

        player.mulligan(entity: entity)
        WindowManager.default.updateTrackers()
    }

    func playerDraw(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        if cardId == "GAME_005" {
            playerGet(entity: entity, cardId: cardId, turn: turn)
        } else {
            player.draw(entity: entity, turn: turn)
            WindowManager.default.updateTrackers()
        }
    }

    func playerRemoveFromDeck(entity: Entity, turn: Int) {
        player.removeFromDeck(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func playerDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        player.deckDiscard(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func playerDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        player.deckToPlay(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        player.playToGraveyard(entity: entity, cardId: cardId, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func playerJoust(entity: Entity, cardId: String?, turn: Int) {
        player.joustReveal(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func playerGetToDeck(entity: Entity, cardId: String?, turn: Int) {
        player.createInDeck(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func playerFatigue(value: Int) {
        Log.info?.message("Player get \(value) fatigue")
        player.fatigue = value
        WindowManager.default.updateTrackers()
    }

    func playerCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        player.createInPlay(entity: entity, turn: turn)
    }

    func playerStolen(entity: Entity, cardId: String?, turn: Int) {
        player.stolenByOpponent(entity: entity, turn: turn)
        opponent.stolenFromOpponent(entity: entity, turn: turn)

        if entity.isSecret {
            var heroClass: CardClass?
            var className = "\(entity[.class])"
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
            WindowManager.default.updateTrackers()
        }
    }

    func playerRemoveFromPlay(entity: Entity, turn: Int) {
        player.removeFromPlay(entity: entity, turn: turn)
    }
    
    func playerCreateInSetAside(entity: Entity, turn: Int) {
        player.createInSetAside(entity: entity, turn: turn)
    }

    func playerHeroPower(cardId: String, turn: Int) {
        player.heroPower(turn: turn)
        Log.info?.message("Player Hero Power \(cardId) \(turn) ")

        opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.DartTrap)
        WindowManager.default.updateTrackers()
    }

    // MARK: - opponent
    func set(opponentHero cardId: String) {
        if let card = Cards.hero(byId: cardId) {
            opponent.playerClass = card.playerClass
            opponent.playerClassId = cardId
            WindowManager.default.updateTrackers()
            Log.info?.message("Opponent class is \(card) ")

            currentGameStats?.opponentHero = card.playerClass
        }
    }

    func set(opponentName name: String) {
        opponent.name = name
        WindowManager.default.updateTrackers()
    }

    func opponentGet(entity: Entity, turn: Int, id: Int) {
        if !isMulliganDone() && entity[.zone_position] == 5 {
            entity.cardId = CardIds.NonCollectible.Neutral.TheCoin
        }

        opponent.createInHand(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.boardToHand(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func opponentPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        opponent.boardToDeck(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
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
            queue.asyncAfter(deadline: when) {
                WindowManager.default.updateTrackers()
            }
        }
        WindowManager.default.updateTrackers()
    }

    func opponentHandDiscard(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.handDiscard(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
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

        var heroClass: CardClass?
        var className = "\(entity[.class])"
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
        Log.info?.message("Secret played by \(entity[.class])"
            + " -> \(heroClass) -> \(opponent.playerClass)")
        if let hero = heroClass {
            opponentSecrets?.newSecretPlayed(heroClass: hero, id: otherId, turn: turn)
        }
        WindowManager.default.updateTrackers()
    }

    func opponentMulligan(entity: Entity, from: Int) {
        opponent.mulligan(entity: entity)
        WindowManager.default.updateTrackers()
    }

    func opponentDraw(entity: Entity, turn: Int) {
        opponent.draw(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func opponentRemoveFromDeck(entity: Entity, turn: Int) {
        opponent.removeFromDeck(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func opponentDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckDiscard(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func opponentDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckToPlay(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func opponentPlayToGraveyard(entity: Entity, cardId: String?,
                                 turn: Int, playersTurn: Bool) {
        opponent.playToGraveyard(entity: entity, cardId: cardId, turn: turn)
        if playersTurn && entity.isMinion {
            opponentMinionDeath(entity: entity, turn: turn)
        }
        WindowManager.default.updateTrackers()
    }

    func opponentJoust(entity: Entity, cardId: String?, turn: Int) {
        opponent.joustReveal(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func opponentGetToDeck(entity: Entity, turn: Int) {
        opponent.createInDeck(entity: entity, turn: turn)
        WindowManager.default.updateTrackers()
    }

    func opponentSecretTrigger(entity: Entity, cardId: String?, turn: Int, otherId: Int) {
        opponent.secretTriggered(entity: entity, turn: turn)

        opponentSecretCount -= 1
        if let cardId = cardId {
            opponentSecrets?.secretRemoved(id: otherId, cardId: cardId)
        }

        if opponentSecretCount > 0 {
            opponentSecrets?.setZero(cardId: cardId!)
        }
        WindowManager.default.updateTrackers()
    }

    func opponentFatigue(value: Int) {
        opponent.fatigue = value
        WindowManager.default.updateTrackers()
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
            if opponentSecretCount > 0 {
                opponentSecrets?.setZero(cardId: cardId!)
            }

            WindowManager.default.updateTrackers()
        }
    }

    func opponentRemoveFromPlay(entity: Entity, turn: Int) {
        player.removeFromPlay(entity: entity, turn: turn)
    }
    
    func opponentCreateInSetAside(entity: Entity, turn: Int) {
        opponent.createInSetAside(entity: entity, turn: turn)
    }

    func opponentHeroPower(cardId: String, turn: Int) {
        opponent.heroPower(turn: turn)
        Log.info?.message("Opponent Hero Power \(cardId) \(turn) ")
        WindowManager.default.updateTrackers()
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
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.Snipe)
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.MirrorEntity)
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.PotionOfPolymorph)
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.Repentance)

        WindowManager.default.updateTrackers()
    }

    func opponentMinionDeath(entity: Entity, turn: Int) {
         if opponent.handCount < 10 {
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.Duplicate)
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.GetawayKodo)
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

            if entities.map({ $0.1 })
                .any({ $0.cardId == CardIds.NonCollectible.Druid
                    .SouloftheForest_SoulOfTheForestEnchantment
                    && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }

            if entities.map({ $0.1 })
                .any({ $0.cardId == CardIds.NonCollectible.Shaman
                    .AncestralSpirit_AncestralSpiritEnchantment
                    && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }
        }

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

        WindowManager.default.updateTrackers()
    }

    func avengeAsync(deathRattleCount: Int) {
        avengeDeathRattleCount += deathRattleCount
        if awaitingAvenge {
            return
        }
        awaitingAvenge = true
        if opponentMinionCount != 0 {
            let when = DispatchTime.now() + DispatchTimeInterval.milliseconds(50)
            DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.opponentMinionCount - strongSelf.avengeDeathRattleCount > 0 {
                    strongSelf.opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.Avenge)
                    WindowManager.default.updateTrackers()

                    self?.awaitingAvenge = false
                    self?.avengeDeathRattleCount = 0
                }
            }
        }
    }

    func opponentDamage(entity: Entity) {
        if !entity.isHero || !entity.isControlled(by: opponent.id) {
            return
        }
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.EyeForAnEye)
        WindowManager.default.updateTrackers()
    }

    func opponentTurnStart(entity: Entity) {
        if !entity.isMinion {
            return
        }
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
        WindowManager.default.updateTrackers()
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

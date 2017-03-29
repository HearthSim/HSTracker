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
import HearthMirror

struct PlayingDeck {
    let id: String
    let name: String
    let hsDeckId: Int64?
    let playerClass: CardClass
    let heroId: String
    let cards: [Card]
    let isArena: Bool
}

/**
 * Game object represents the current state of the tracker
 */
class Game: PowerEventHandler {

	/**
	 * View controller of this game object
	 */
    private let windowManager = WindowManager()
    
	private var hearthstoneRunState: HearthstoneRunState {
		didSet {
			if hearthstoneRunState.isRunning {
				// delay update as game might not have a proper window
				DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: { [unowned self] in
					self.updateTrackers()
				})
			} else {
				self.updateTrackers()
			}
		}
	}
    private var selfAppActive: Bool = true
	
    func setHearthstoneRunning(flag: Bool) {
        hearthstoneRunState.isRunning = flag
    }
    
    func setHearthstoneActived(flag: Bool) {
        hearthstoneRunState.isActive = flag
    }
	
	func setSelfActivated(flag: Bool) {
		self.selfAppActive = flag
        self.updateTrackers()
	}
	
	// MARK: - PowerEventHandler protocol
	
	func add(entity: Entity) {
		if entities[entity.id] == .none {
			entities[entity.id] = entity
		}
	}
	
	func set(currentEntity id: Int) {
		currentEntityId = id
		if let entity = entities[id] {
			entity.info.hasOutstandingTagChanges = true
		}
	}
	
	func determinedPlayers() -> Bool {
		return player.id > 0 && opponent.id > 0
	}
	
    // MARK: - GUI calls
    @objc func updateTrackers(reset: Bool = false) {
        // TODO: this call should be in a slow/hashed queue with small fixed size
        SizeHelper.hearthstoneWindow.reload()
        
        self.updatePlayerTracker(reset: reset)
		self.updateOpponentTracker(reset: reset)
    }
	
	@objc private func updateOpponentTracker(reset: Bool = false) {
		DispatchQueue.main.async { [unowned self] in
			
			let tracker = self.windowManager.opponentTracker
			if Settings.showOpponentTracker &&
				( (Settings.hideAllTrackersWhenNotInGame && !self.gameEnded)
					|| !Settings.hideAllTrackersWhenNotInGame) &&
				( (Settings.hideAllWhenGameInBackground &&
					self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground) {
				
				// update cards
				tracker.update(cards: self.opponent.opponentCardList, reset: reset)
				
				let gameStarted = !self.isInMenu && self.entities.count >= 67
				tracker.updateCardCounter(deckCount: !gameStarted ? 30 : self.opponent.deckCount,
				                          handCount: !gameStarted ? 0 : self.opponent.handCount,
				                          hasCoin: self.opponent.hasCoin,
				                          gameStarted: gameStarted)

				tracker.showCthunCounter = self.showOpponentCthunCounter
				tracker.showSpellCounter = self.showOpponentSpellsCounter
				tracker.showDeathrattleCounter = self.showOpponentDeathrattleCounter
				tracker.showGraveyard = self.showOpponentGraveyard
				tracker.showJadeCounter = self.showOpponentJadeCounter
				tracker.proxy = self.opponentCthunProxy
				tracker.nextJadeSize = self.opponentNextJadeGolem
				tracker.fatigueCounter = self.opponent.fatigue
				tracker.spellsPlayedCount = self.opponent.spellsPlayedCount
				tracker.deathrattlesPlayedCount = self.opponent.deathrattlesPlayedCount
				tracker.playerName = self.opponent.name
				tracker.graveyard = self.opponent.graveyard
				tracker.playerClassId = self.opponent.playerClassId
				
				tracker.currentFormat = self.currentFormat
				tracker.currentGameMode = self.currentGameMode
				tracker.matchInfo = self.matchInfo
				
				tracker.setWindowSizes()
				var rect: NSRect?
				
				if Settings.autoPositionTrackers && self.hearthstoneRunState.isRunning {
					rect = SizeHelper.opponentTrackerFrame()
				} else {
					rect = Settings.opponentTrackerFrame
					if rect == nil {
						let x = WindowManager.screenFrame.origin.x + 50
						rect = NSRect(x: x,
						              y: WindowManager.top + WindowManager.screenFrame.origin.y,
						              width: WindowManager.cardWidth,
						              height: WindowManager.top)
					}
				}
				tracker.hasValidFrame = true
				self.windowManager.show(controller: tracker, show: true, frame: rect, title: "Opponent tracker")
			} else {
				self.windowManager.show(controller: tracker, show: false)
			}
		}
	}

    @objc private func updatePlayerTracker(reset: Bool = false) {
        DispatchQueue.main.async { [unowned self] in
			
            let tracker = self.windowManager.playerTracker
            if Settings.showPlayerTracker &&
                ( (Settings.hideAllTrackersWhenNotInGame && !self.gameEnded)
                    || (!Settings.hideAllTrackersWhenNotInGame) || self.selfAppActive ) &&
                ( (Settings.hideAllWhenGameInBackground &&
                    self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground) {
                
                // update cards
                tracker.update(cards: self.player.playerCardList, reset: reset)
                
                // update card counter values
                let gameStarted = !self.isInMenu && self.entities.count >= 67
                tracker.updateCardCounter(deckCount: !gameStarted ? 30 : self.player.deckCount,
                                          handCount: !gameStarted ? 0 : self.player.handCount,
                                          hasCoin: self.player.hasCoin,
                                          gameStarted: gameStarted)
                
                tracker.showCthunCounter = self.showPlayerCthunCounter
                tracker.showSpellCounter = self.showPlayerSpellsCounter
                tracker.showDeathrattleCounter = self.showPlayerDeathrattleCounter
                tracker.showGraveyard = self.showPlayerGraveyard
                tracker.showJadeCounter = self.showPlayerJadeCounter
                tracker.proxy = self.playerCthunProxy
                tracker.nextJadeSize = self.playerNextJadeGolem
                tracker.fatigueCounter = self.player.fatigue
                tracker.spellsPlayedCount = self.player.spellsPlayedCount
                tracker.deathrattlesPlayedCount = self.player.deathrattlesPlayedCount
                
                if let currentDeck = self.currentDeck {
                    if let deck = RealmHelper.getDeck(with: currentDeck.id) {
                        tracker.recordTrackerMessage = StatsHelper
                            .getDeckManagerRecordLabel(deck: deck,
                                                       mode: .all)
                    }
                    tracker.playerName = currentDeck.name
                    if !currentDeck.heroId.isEmpty {
                        tracker.playerClassId = currentDeck.heroId
                    } else {
                        tracker.playerClassId = currentDeck.playerClass.defaultHeroCardId
                    }
                }
                
                tracker.graveyard = self.player.graveyard
                
                tracker.currentFormat = self.currentFormat
                tracker.currentGameMode = self.currentGameMode
                tracker.matchInfo = self.matchInfo
                
                tracker.setWindowSizes()
                
                var rect: NSRect?
                
                if Settings.autoPositionTrackers && self.hearthstoneRunState.isRunning {
                    rect = SizeHelper.playerTrackerFrame()
                } else {
                    rect = Settings.playerTrackerFrame
                    if rect == nil {
                        let x = WindowManager.screenFrame.width - WindowManager.cardWidth
                            + WindowManager.screenFrame.origin.x
                        rect = NSRect(x: x,
                                      y: WindowManager.top + WindowManager.screenFrame.origin.y,
                                      width: WindowManager.cardWidth,
                                      height: WindowManager.top)
                    }
                }
                tracker.hasValidFrame = true
                self.windowManager.show(controller: tracker, show: true,
                                   frame: rect, title: "Player tracker",
                                   overlay: self.hearthstoneRunState.isActive)
            } else {
                self.windowManager.show(controller: tracker, show: false)
            }
        }
    }

    // MARK: - vars
    var currentTurn = 0
    var lastId = 0
    var gameTriggerCount = 0
    var powerLog: [LogLine] = []
    var playedCards: [PlayedCard] = []
    var currentGameStats: InternalGameStats?
    var lastGame: InternalGameStats?

	var player: Player!
    var opponent: Player!
    var currentMode: Mode? = .invalid
    var previousMode: Mode? = .invalid

    private var _spectator: Bool = false
    var spectator: Bool {
		if self.gameEnded {
			return false
		}
		
		return _spectator
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
        if let gameType = MirrorHelper.getGameType(),
            let type = GameType(rawValue: gameType) {
            _currentGameType = type
        }
        return _currentGameType
    }

    var entities: [Int: Entity] = [:]
    var tmpEntities: [Entity] = []
    var knownCardIds: [Int: [String]] = [:]
    var joustReveals = 0

    var lastCardPlayed: Int?
    var gameEnded = true
    internal private(set) var currentDeck: PlayingDeck?

    var currentEntityId = 0
    var currentEntityHasCardId = false
    var playerUsedHeroPower = false
    private var hasCoin = false
    var currentEntityZone: Zone = .invalid
    var opponentUsedHeroPower = false
	var wasInProgress = false
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
    
    var enqueueTime = Date.distantPast
    private var lastCompetitiveSpiritCheck: Int = 0
    private var lastTurnStart: [Int] = [0, 0]
    private var turnQueue: Set<PlayerTurn> = Set()

    private var maxBlockId: Int = 0
    private(set) var currentBlock: Block?
    
    fileprivate var lastGameStartTimestamp: Date = Date.distantPast

    private var matchInfo: MatchInfo?
	
    var arenaInfo: ArenaInfo? {
        if let _arenaInfo = MirrorHelper.getArenaDeck() {
            return ArenaInfo(info: _arenaInfo)
        }
        return nil
    }

    var brawlInfo: BrawlInfo? {
        if let _brawlInfo = MirrorHelper.getBrawlInfo() {
            return BrawlInfo(info: _brawlInfo)
        }
        return nil
    }

    var playerEntity: Entity? {
		return entities.map { $0.1 }.firstWhere { $0.isPlayer(eventHandler: self) }
    }

    var opponentEntity: Entity? {
        return entities.map { $0.1 }.firstWhere { $0.has(tag: .player_id) && !$0.isPlayer(eventHandler: self) }
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

    private(set) var currentFormat = Format(formatType: FormatType.ft_unknown)

	// MARK: - Lifecycle
	
    init(hearthstoneRunState: HearthstoneRunState) {
        self.hearthstoneRunState = hearthstoneRunState
		player = Player(local: true, game: self)
        opponent = Player(local: false, game: self)
        opponentSecrets = OpponentSecrets(game: self)
		windowManager.startManager()
		
		let center = NotificationCenter.default
		
		// events that should update the player tracker
		let playerTrackerUpdateEvents = ["show_player_tracker", "show_player_draw", "show_player_mulligan",
		                                 "show_player_play", "rarity_colors", "remove_cards_from_deck",
		                                 "highlight_last_drawn", "highlight_cards_in_hand", "highlight_discarded",
		                                 "show_player_get", "player_draw_chance", "player_card_count",
		                                 "player_cthun_frame", "player_yogg_frame", "player_deathrattle_frame",
		                                 "show_win_loss_ratio", "player_in_hand_color", "show_deck_name",
		                                 "player_graveyard_details_frame", "player_graveyard_frame"]
		
		// events that should update the opponent's tracker
		let opponentTrackerUpdateEvents = ["show_opponent_tracker", "show_opponent_draw", "show_opponent_mulligan",
		                                   "show_opponent_play", "opponent_card_count", "opponent_draw_chance",
		                                   "opponent_cthun_frame", "opponent_yogg_frame", "opponent_deathrattle_frame",
		                                   "show_opponent_class", "opponent_graveyard_frame",
		                                   "opponent_graveyard_details_frame"]
		
		// events that should update all trackers
		let allTrackerUpdateEvents = ["rarity_colors", "reload_decks", "window_locked", "auto_position_trackers",
		                              "space_changed", "hearthstone_closed", "hearthstone_running",
		                              "hearthstone_active", "hearthstone_deactived", "can_join_fullscreen",
		                              "hide_all_trackers_when_not_in_game", "hide_all_trackers_when_game_in_background",
		                              "card_size"]
		
		for option in playerTrackerUpdateEvents {
			center.addObserver(self,
			                   selector: #selector(updatePlayerTracker),
			                   name: NSNotification.Name(rawValue: option),
			                   object: nil)
		}
		
		for option in opponentTrackerUpdateEvents {
			center.addObserver(self,
			                   selector: #selector(updateOpponentTracker),
			                   name: NSNotification.Name(rawValue: option),
			                   object: nil)
		}
		
		for option in allTrackerUpdateEvents {
			center.addObserver(self,
			                   selector: #selector(updateTrackers),
			                   name: NSNotification.Name(rawValue: option),
			                   object: nil)
		}
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

        matchInfo = nil
        currentFormat = Format(formatType: FormatType.ft_unknown)
        _currentGameType = .gt_unknown
        currentGameStats = InternalGameStats()

        entities.removeAll()
        tmpEntities.removeAll()
        knownCardIds.removeAll()
        joustReveals = 0
		
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
        lastTurnStart = [0, 0]

        player.reset()
        if let currentdeck = self.currentDeck {
            player.playerClass = currentdeck.playerClass
        }
        opponent.reset()

        windowManager.hideGameTrackers()
		
		_spectator = false
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

	func set(activeDeckId: String?) {
		Settings.activeDeck = activeDeckId
		
		if let id = activeDeckId, let deck = RealmHelper.getDeck(with: id) {
			set(activeDeck: deck)
		} else {
			currentDeck = nil
			player.playerClass = nil
			currentGameStats?.playerHero = .neutral
			updateTrackers(reset: true)
		}
	}
	
	private func set(activeDeck deck: Deck) {
		
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
                                  heroId: deck.heroId,
                                  cards: cards.sortCardList(),
                                  isArena: deck.isArena
        )
        player.playerClass = currentDeck?.playerClass
        currentGameStats?.playerHero = currentDeck?.playerClass ?? .neutral
        updateTrackers(reset: true)
    }

    func removeActiveDeck() {
        currentDeck = nil
        Settings.activeDeck = nil
        updateTrackers(reset: true)
    }

    // MARK: - game state
    private var lastGameStart = Date.distantPast
    func gameStart(at timestamp: Date) {
        Log.info?.message("currentGameMode: \(currentGameMode), isInMenu: \(isInMenu), "
            + "handledGameEnd: \(handledGameEnd), "
            + "lastGameStartTimestamp: \(lastGameStartTimestamp), " +
            "timestamp: \(timestamp)")
        if currentGameMode == .practice && !isInMenu && !handledGameEnd
            && lastGameStartTimestamp > Date.distantPast
            && timestamp > lastGameStartTimestamp {
            adventureRestart()
            return
        }

        lastGameStartTimestamp = timestamp
        if lastGameStart > Date.distantPast
            && (abs(lastGameStart.timeIntervalSinceNow) < 5) {
            // game already started
            return
        }

        ImageUtils.clearCache()
        reset()
        lastGameStart = Date()

		gameEnded = false
        isInMenu = false
        handledGameEnd = false

        Log.info?.message("----- Game Started -----")
        AppHealth.instance.setHearthstoneGameRunning(flag: true)

        showNotification(type: .gameStart)

        if Settings.showTimer {
			// TODO: fix turn timer
            TurnTimer.instance.start(game: self)
        }
		
		// update spectator information
		_spectator = MirrorHelper.isSpectating() ?? false
		
		// update current match info
		if let matchInfo = MirrorHelper.getMatchInfo() {
			Log.info?.message("\(matchInfo.localPlayer.name) vs "
				+ "\(matchInfo.opposingPlayer.name)")
			self.matchInfo = MatchInfo(info: matchInfo)
			
			if let minfo = self.matchInfo {
				self.player.name = minfo.localPlayer.name
				self.opponent.name = minfo.opposingPlayer.name
				self.player.id = minfo.localPlayer.playerId
				self.opponent.id = minfo.opposingPlayer.playerId
			}
		}
		
		// update game format
		if let mirrorFormat = MirrorHelper.getFormat(),
			let format = FormatType(rawValue: mirrorFormat) {
			self.currentFormat = Format(formatType: format)
		}
		
        updateTrackers(reset: true)

        currentGameStats?.startTime = timestamp
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
        currentGameStats?.endTime = Date()

        handleEndGame()

        opponentSecrets?.clearSecrets()
        updateTrackers(reset: true)
        windowManager.hideGameTrackers()
        TurnTimer.instance.stop()
    }

    func inMenu() {
        if isInMenu {
            return
        }
        Log.verbose?.message("Game is now in menu")

        TurnTimer.instance.stop()

        if Settings.saveReplays {
            ReplayMaker.saveToDisk(powerLog: powerLog)
        }

        isInMenu = true

        //resetStoredGameState()
        /*if let currentDeck = self.currentDeck,
            currentDeck.isArenaRunCompleted,
            Settings.autoArchiveArenaDeck {

            RealmHelper.set(deck: currentDeck.id, active: false)
        }*/
    }

    func handleEndGame() {
        DispatchQueue.main.sync { [unowned self] in
            if let stats = self.currentGameStats {
                Log.verbose?.message("currentGameStats: \(stats), "
                    + "handledGameEnd: \(self.handledGameEnd)")
            } else if self.currentGameStats == nil || self.handledGameEnd {
                Log.warning?.message("HandleGameEnd was already called.")
                return
            }
            self.handledGameEnd = true
            
            guard let currentGameStats = self.currentGameStats else {
                Log.error?.message("No current game stats, ignoring")
                return
            }
            
            if self.currentGameMode == .spectator && currentGameStats.result == .none {
                Log.info?.message("Game was spectator mode without a game result."
                    + " Probably exited spectator mode early.")
                return
            }
            
            if let build = BuildDates.latestBuild {
                currentGameStats.hearthstoneBuild = build.build
            }
            currentGameStats.season = Database.currentSeason
            
            if let name = self.player.name {
                currentGameStats.playerName = name
            }
			if let _player = self.entities.map({ $0.1 }).firstWhere({ $0.isPlayer(eventHandler: self) }) {
                currentGameStats.coin = !_player.has(tag: .first_player)
            }
            
            if let name = self.opponent.name {
                currentGameStats.opponentName = name
            } else if currentGameStats.opponentHero != .neutral {
                currentGameStats.opponentName = currentGameStats.opponentHero.rawValue
            }
            
            currentGameStats.turns = self.turnNumber()
            
            currentGameStats.gameMode = self.currentGameMode
            currentGameStats.format = self.currentFormat
            
            if let matchInfo = self.matchInfo, self.currentGameMode == .ranked {
                let wild = self.currentFormat == .wild
                
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
            } else if self.currentGameMode == .arena {
                currentGameStats.arenaLosses = self.arenaInfo?.losses ?? 0
                currentGameStats.arenaWins = self.arenaInfo?.wins ?? 0
            } else if let brawlInfo = self.brawlInfo, self.currentGameMode == .brawl {
                currentGameStats.brawlWins = brawlInfo.wins
                currentGameStats.brawlLosses = brawlInfo.losses
            }
            
            currentGameStats.gameType = self.currentGameType
            if let serverInfo = MirrorHelper.getGameServerInfo() {
                currentGameStats.serverInfo = ServerInfo(info: serverInfo)
            }
            currentGameStats.playerCardbackId = self.matchInfo?.localPlayer.cardBackId ?? 0
            currentGameStats.opponentCardbackId = self.matchInfo?.opposingPlayer.cardBackId ?? 0
            currentGameStats.friendlyPlayerId = self.matchInfo?.localPlayer.playerId ?? 0
            currentGameStats.scenarioId = self.matchInfo?.missionId ?? 0
            currentGameStats.brawlSeasonId = self.matchInfo?.brawlSeasonId ?? 0
            currentGameStats.rankedSeasonId = self.matchInfo?.rankedSeasonId ?? 0
            currentGameStats.hsDeckId = self.currentDeck?.hsDeckId
            
            if Settings.promptNotes {
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
			
			self.player.revealedCards.filter({
				$0.collectible
			}).forEach({
				currentGameStats.revealedCards.append($0)
			})
			
			self.opponent.opponentCardList.filter({
				!$0.isCreated
			}).forEach({
				currentGameStats.opponentCards.append($0)
			})
			
			let stats = currentGameStats.toGameStats()
			
			if let currentDeck = self.currentDeck {
				if let deck = RealmHelper.getDeck(with: currentDeck.id) {
					
					RealmHelper.addStatistics(to: deck, stats: stats)
					if Settings.autoArchiveArenaDeck &&
						self.currentGameMode == .arena && deck.isArena && deck.arenaFinished() {
						RealmHelper.set(deck: deck, active: false)
					}
				}
			}
			
            self.lastGame = currentGameStats
            self.logIsComplete()
        }
    }

    private func logIsComplete() {
        if logContainsGoldRewardState || currentGameMode == .practice && logContainsStateComplete {
            DispatchQueue.main.async { [weak self] in
                self?.syncStats()
            }
            return
        }

        Log.info?.message("GOLD_REWARD_STATE not found")
        Thread.sleep(forTimeInterval: 0.5)

        if logContainsStateComplete || isInMenu {
            DispatchQueue.main.async { [weak self] in
                self?.syncStats()
            }
            return
        }

        Log.info?.message("STATE COMPLETE not found")
        for i in 0...5 {
            Thread.sleep(forTimeInterval: 1)
            if logContainsStateComplete || isInMenu {
                break
            }
			Log.info?.message("Waiting for STATE COMPLETE... (\(i))")
        }
        DispatchQueue.main.async { [weak self] in
            self?.syncStats()
        }
    }

    private var logContainsGoldRewardState: Bool {
        return powerLog.filter({ $0.line.contains("tag=GOLD_REWARD_STATE value=1") }).count == 2
    }

    private var logContainsStateComplete: Bool {
        return powerLog.any({ $0.line.contains("tag=STATE value=COMPLETE") })
    }

    private func syncStats() {
        guard let currentGameStats = lastGame else { return }
        guard currentGameMode != .practice && currentGameMode != .none else {
            Log.info?.message("Game was in \(currentGameMode), don't send to third-party")
            return
        }

        if Settings.hsReplaySynchronizeMatches && (
            (currentGameStats.gameMode == .ranked &&
                Settings.hsReplayUploadRankedMatches) ||
            (currentGameStats.gameMode == .casual &&
                Settings.hsReplayUploadCasualMatches) ||
            (currentGameStats.gameMode == .arena &&
                Settings.hsReplayUploadArenaMatches) ||
            (currentGameStats.gameMode == .brawl &&
                Settings.hsReplayUploadBrawlMatches) ||
            (currentGameStats.gameMode == .practice &&
                Settings.hsReplayUploadAdventureMatches) ||
            (currentGameStats.gameMode == .friendly &&
                Settings.hsReplayUploadFriendlyMatches) ||
            (currentGameStats.gameMode == .spectator &&
                Settings.hsReplayUploadFriendlyMatches)) {
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

        if TrackOBotAPI.isLogged() && Settings.trackobotSynchronizeMatches {
            do {
                try TrackOBotAPI.postMatch(stat: currentGameStats, cards: playedCards)
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
            updateTrackers()
            return
        }
        lastCompetitiveSpiritCheck = turn
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
        updateTrackers()
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
        if Settings.fullGameLog {
            Log.info?.message("Turn \(playerTurn.turn) start for player \(player) ")
        }

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

        updateTrackers()
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
		let player = entities.map { $0.1 }.firstWhere { $0.isPlayer(eventHandler: self) }
        let opponent = entities.map { $0.1 }.firstWhere { $0.has(tag: .player_id) && !$0.isPlayer(eventHandler: self) }

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
                                 player: proposedKeyPoint.player, eventHandler: self)
        }
        proposedKeyPoint = ReplayKeyPoint(data: nil, type: type, id: id, player: player)
    }

    func gameEndKeyPoint(victory: Bool, id: Int) {
        if let proposedKeyPoint = proposedKeyPoint {
            ReplayMaker.generate(type: proposedKeyPoint.type,
                                 id: proposedKeyPoint.id,
                                 player: proposedKeyPoint.player, eventHandler: self)
            self.proposedKeyPoint = nil
        }
        ReplayMaker.generate(type: victory ? .victory : .defeat, id: id,
                             player: .player, eventHandler: self)
    }

    // MARK: - player
    func set(playerHero cardId: String) {
        if let card = Cards.hero(byId: cardId) {
            player.playerClass = card.playerClass
            player.playerClassId = cardId
            if Settings.fullGameLog {
                Log.info?.message("Player class is \(card) ")
            }

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
        updateTrackers()
    }

    func playerBackToHand(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        updateTrackers()
        player.boardToHand(entity: entity, turn: turn)
    }

    func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.boardToDeck(entity: entity, turn: turn)
        updateTrackers()
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
            let when = DispatchTime.now() + DispatchTimeInterval.milliseconds(300)
            DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
                self?.updateTrackers()
            }
        }

        secretsOnPlay(entity: entity)
        updateTrackers()
    }

    func secretsOnPlay(entity: Entity) {
        if entity.isSpell {
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.Counterspell)

            if opponentMinionCount < 7 {
                let when = DispatchTime.now() + DispatchTimeInterval.milliseconds(50)
                DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
                    // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                    if let target = self?.entities[entity[.card_target]],
                        target.isMinion && entity.has(tag: .card_target) {
                        self?.opponentSecrets?
                            .setZero(cardId: CardIds.Secrets.Mage.Spellbender)
                    }
                    self?.opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.CatTrick)
                    self?.updateTrackers()
                }
            }
        } else if entity.isMinion && playerMinionCount > 3 {
            opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.SacredTrial)
            updateTrackers()
        }
    }

    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        player.handDiscard(entity: entity, turn: turn)
        updateTrackers()
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
        updateTrackers()
    }

    func playerMulligan(entity: Entity, cardId: String?) {
        if String.isNullOrEmpty(cardId) {
            return
        }

        player.mulligan(entity: entity)
        updateTrackers()
    }

    func playerDraw(entity: Entity, cardId: String?, turn: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        if cardId == "GAME_005" {
            playerGet(entity: entity, cardId: cardId, turn: turn)
        } else {
            player.draw(entity: entity, turn: turn)
            updateTrackers()
        }
    }

    func playerRemoveFromDeck(entity: Entity, turn: Int) {
        player.removeFromDeck(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        player.deckDiscard(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        player.deckToPlay(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        player.playToGraveyard(entity: entity, cardId: cardId, turn: turn)
        updateTrackers()
    }

    func playerJoust(entity: Entity, cardId: String?, turn: Int) {
        player.joustReveal(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerGetToDeck(entity: Entity, cardId: String?, turn: Int) {
        player.createInDeck(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerFatigue(value: Int) {
        if Settings.fullGameLog {
            Log.info?.message("Player get \(value) fatigue")
        }
        player.fatigue = value
        updateTrackers()
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
            updateTrackers()
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
        if Settings.fullGameLog {
            Log.info?.message("Player Hero Power \(cardId) \(turn) ")
        }

        opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.DartTrap)
        updateTrackers()
    }

    // MARK: - opponent
    func set(opponentHero cardId: String) {
        if let card = Cards.hero(byId: cardId) {
            opponent.playerClass = card.playerClass
            opponent.playerClassId = cardId
            updateTrackers()
            if Settings.fullGameLog {
                Log.info?.message("Opponent class is \(card) ")
            }

            currentGameStats?.opponentHero = card.playerClass
        }
    }

    func set(opponentName name: String) {
        opponent.name = name
        updateTrackers()
    }

    func opponentGet(entity: Entity, turn: Int, id: Int) {
        if !isMulliganDone() && entity[.zone_position] == 5 {
            entity.cardId = CardIds.NonCollectible.Neutral.TheCoin
        }

        opponent.createInHand(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.boardToHand(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        opponent.boardToDeck(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentPlay(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.play(entity: entity, turn: turn)

        if let cardId = cardId, !cardId.isEmpty {
            playedCards.append(PlayedCard(player: .opponent, cardId: cardId, turn: turn))
        }

        if entity.has(tag: .ritual) {
            // if this entity has the RITUAL tag, it will trigger some C'Thun change
            // we wait 300ms so the proxy have the time to be updated
            let when = DispatchTime.now() + DispatchTimeInterval.milliseconds(300)
            DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
                self?.updateTrackers()
            }
        }
        updateTrackers()
    }

    func opponentHandDiscard(entity: Entity, cardId: String?, from: Int, turn: Int) {
        opponent.handDiscard(entity: entity, turn: turn)
        updateTrackers()
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
        let className = "\(entity[.class])".lowercased()
        if let tagClass = TagClass(rawValue: entity[.class]) {
            heroClass = tagClass.cardClassValue
        } else if let _heroClass = CardClass(rawValue: className), !String.isNullOrEmpty(className) {
            heroClass = _heroClass
        } else if let playerClass = opponent.playerClass {
            heroClass = playerClass
        }

        if Settings.fullGameLog {
            Log.info?.message("Secret played by \(entity[.class])"
                + " -> \(String(describing: heroClass)) "
                + "-> \(String(describing: opponent.playerClass))")
        }
        if let hero = heroClass {
            opponentSecrets?.newSecretPlayed(heroClass: hero, id: otherId, turn: turn)
        }
        updateTrackers()
    }

    func opponentMulligan(entity: Entity, from: Int) {
        opponent.mulligan(entity: entity)
        updateTrackers()
    }

    func opponentDraw(entity: Entity, turn: Int) {
        opponent.draw(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentRemoveFromDeck(entity: Entity, turn: Int) {
        opponent.removeFromDeck(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentDeckDiscard(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckDiscard(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentDeckToPlay(entity: Entity, cardId: String?, turn: Int) {
        opponent.deckToPlay(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentPlayToGraveyard(entity: Entity, cardId: String?,
                                 turn: Int, playersTurn: Bool) {
        opponent.playToGraveyard(entity: entity, cardId: cardId, turn: turn)
        if playersTurn && entity.isMinion {
            opponentMinionDeath(entity: entity, turn: turn)
        }
        updateTrackers()
    }

    func opponentJoust(entity: Entity, cardId: String?, turn: Int) {
        opponent.joustReveal(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentGetToDeck(entity: Entity, turn: Int) {
        opponent.createInDeck(entity: entity, turn: turn)
        updateTrackers()
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
        updateTrackers()
    }

    func opponentFatigue(value: Int) {
        opponent.fatigue = value
        updateTrackers()
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

            updateTrackers()
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
        if Settings.fullGameLog {
            Log.info?.message("Opponent Hero Power \(cardId) \(turn) ")
        }
        updateTrackers()
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
				updateTrackers()
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
				updateTrackers()
            }
        }
    }

    func playerMinionPlayed() {
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Hunter.Snipe)
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.MirrorEntity)
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Mage.PotionOfPolymorph)
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.Repentance)

        updateTrackers()
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

        updateTrackers()
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
                    self?.updateTrackers()

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
        updateTrackers()
    }

    func opponentTurnStart(entity: Entity) {
        if !entity.isMinion {
            return
        }
        opponentSecrets?.setZero(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
        updateTrackers()
    }

     func showNotification(type: NotificationType) {
		/* TODO: move this to separate part
         guard let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone else { return }

        switch type {
        case .gameStart:
            guard Settings.notifyGameStart else { return }
            if hearthstone.hearthstoneActive { return }

            Toast.show(title: NSLocalizedString("Hearthstone", comment: ""),
                       message: NSLocalizedString("Your game begins", comment: ""))

        case .opponentConcede:
            guard Settings.notifyOpponentConcede else { return }
            if hearthstone.hearthstoneActive { return }

            Toast.show(title: NSLocalizedString("Victory", comment: ""),
                       message: NSLocalizedString("Your opponent have conceded", comment: ""))

        case .turnStart:
            guard Settings.notifyTurnStart else { return }
            if hearthstone.hearthstoneActive { return }

            Toast.show(title: NSLocalizedString("Hearthstone", comment: ""),
                       message: NSLocalizedString("It's your turn to play", comment: ""))

        case .hsReplayPush(let replayId):
            guard Settings.showHSReplayPushNotification else { return }

            Toast.show(title: NSLocalizedString("HSReplay", comment: ""),
                       message: NSLocalizedString("Your replay has been uploaded on HSReplay",
                        comment: "")) {
                        HSReplayManager.showReplay(replayId: replayId)
            }

        }*/
    }
}

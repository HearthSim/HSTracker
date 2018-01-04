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
class Game: NSObject, PowerEventHandler {

	/**
	 * View controller of this game object
	 */
	#if DEBUG
		internal let windowManager = WindowManager()
	#else
		private let windowManager = WindowManager()
	#endif
	
	static let guiUpdateDelay: TimeInterval = 0.5
	
	private let turnTimer: TurnTimer
    
	private var hearthstoneRunState: HearthstoneRunState {
		didSet {
			if hearthstoneRunState.isRunning {
				// delay update as game might not have a proper window
				DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
					self?.updateTrackers()
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
	
	func handleEntitiesChange(changed: [(old: Entity, new: Entity)]) {

        if let playerPair = changed.first(where: { $0.old.id == self.player.id }) {
			// TODO: player entity changed
			if let oldName = playerPair.old.name, let newName = playerPair.new.name, oldName != newName {
				print("Player entity name changed from \(oldName) to \(newName)")
			} else {
                // get added/removed tags
                let newTags = playerPair.new.tags.keys.filter { !playerPair.old.tags.keys.contains($0) }
                
                if newTags.contains(.mulligan_state) {
                    print("Player new mulligan state: \(playerPair.new[.mulligan_state])")
                }
			}
		}
	}
	
	func add(entity: Entity) {
		if entities[entity.id] == .none {
			entities[entity.id] = entity
		}
	}
	
	func determinedPlayers() -> Bool {
        return player.id > 0 && opponent.id > 0
	}
	
	private var guiNeedsUpdate = false
	private var guiUpdateResets = false
	private let _queue = DispatchQueue(label: "be.michotte.hstracker.guiupdate", attributes: [])
	
    private func _updateTrackers(notification: Notification) {
        self._updateTrackers()
    }
    private func _updateTrackers() {
		SizeHelper.hearthstoneWindow.reload()
		
		self.updatePlayerTracker(reset: guiUpdateResets)
		self.updateOpponentTracker(reset: guiUpdateResets)
        self.updateCardHud()
        self.updateTurnTimer()
        self.updateBoardStateTrackers()
		self.updateArenaHelper()
        self.updateSecretTracker()
	}
	
    // MARK: - GUI calls
    var shouldShowGUIElement: Bool {
        return
            // do not show gui while spectating
            !(Settings.dontTrackWhileSpectating && self.spectator) &&
                // do not show gui while game is in background
                !((Settings.hideAllWhenGameInBackground || Settings.hideAllWhenGameInBackground) && !self.hearthstoneRunState.isActive)
    }
    
    func updateTrackers(reset: Bool = false) {
		self.guiNeedsUpdate = true
		self.guiUpdateResets = reset || self.guiUpdateResets
    }
	
	@objc fileprivate func updateOpponentTracker(reset: Bool = false) {
		DispatchQueue.main.async { [unowned(unsafe) self] in
			
			let tracker = self.windowManager.opponentTracker
			if Settings.showOpponentTracker &&
            !(Settings.dontTrackWhileSpectating && self.spectator) &&
				((Settings.hideAllTrackersWhenNotInGame && !self.gameEnded)
					|| (!Settings.hideAllTrackersWhenNotInGame) || self.selfAppActive ) &&
				((Settings.hideAllWhenGameInBackground &&
					self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground || self.selfAppActive) {
				
				// update cards
                if self.gameEnded && Settings.clearTrackersOnGameEnd {
                    tracker.update(cards: [], reset: reset)
                } else {
                    tracker.update(cards: self.opponent.opponentCardList, reset: reset)
                }
				
				let gameStarted = !self.isInMenu && self.entities.count >= 67
				tracker.updateCardCounter(deckCount: !gameStarted ? 30 : self.opponent.deckCount,
				                          handCount: !gameStarted ? 0 : self.opponent.handCount,
				                          hasCoin: self.opponent.hasCoin,
				                          gameStarted: gameStarted)

				tracker.showCthunCounter = self.showOpponentCthunCounter
				tracker.showSpellCounter = Settings.showOpponentSpell
				tracker.showDeathrattleCounter = Settings.showOpponentDeathrattle
				tracker.showGraveyard = Settings.showOpponentGraveyard
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
                self.windowManager.show(controller: tracker, show: true,
                                        frame: rect, title: "Opponent tracker",
                                        overlay: self.hearthstoneRunState.isActive)
			} else {
				self.windowManager.show(controller: tracker, show: false)
			}
		}
	}

    @objc fileprivate func updatePlayerTracker(reset: Bool = false) {
        DispatchQueue.main.async { [unowned(unsafe) self] in
			
            let tracker = self.windowManager.playerTracker
            if Settings.showPlayerTracker &&
                !(Settings.dontTrackWhileSpectating && self.spectator) &&
                ( (Settings.hideAllTrackersWhenNotInGame && !self.gameEnded)
                    || (!Settings.hideAllTrackersWhenNotInGame) || self.selfAppActive ) &&
                ((Settings.hideAllWhenGameInBackground &&
                    self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground || self.selfAppActive) {
                
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
                tracker.showGraveyard = Settings.showPlayerGraveyard
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

    func updateTurnTimer() {
        DispatchQueue.main.async { [unowned(unsafe) self] in

            if Settings.showTimer && !self.gameEnded && self.shouldShowGUIElement {
                var rect: NSRect?
                if Settings.autoPositionTrackers {
                    rect = SizeHelper.timerHudFrame()
                } else {
                    rect = Settings.timerHudFrame
                    if rect == nil {
                        rect = SizeHelper.timerHudFrame()
                    }
                }
                if let timerHud = self.turnTimer.timerHud {
                    timerHud.hasValidFrame = true
                    self.windowManager.show(controller: timerHud, show: true, frame: rect, title: nil, overlay: self.hearthstoneRunState.isActive)
                }
            } else {
                if let timerHud = self.turnTimer.timerHud {
                    self.windowManager.show(controller: timerHud, show: false)
                }
            }
            
        }
    }
    
    func updateSecretTracker(cards: [Card]) {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            self.windowManager.secretTracker.set(cards: cards)
            self.windowManager.secretTracker.table?.reloadData()
            self.updateSecretTracker()
        }
    }
    
    func updateSecretTracker() {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            
            let tracker = self.windowManager.secretTracker
            
            if Settings.showSecretHelper && !self.gameEnded &&
                ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive)
                    || !Settings.hideAllWhenGameInBackground) {
                if tracker.cards.count > 0 {
                    tracker.table?.reloadData()
                    self.windowManager.show(controller: tracker, show: true,
                                            frame: SizeHelper.secretTrackerFrame(height: tracker.frameHeight),
                                            title: nil, overlay: self.hearthstoneRunState.isActive)
                } else {
                    self.windowManager.show(controller: tracker, show: false)
                }
            } else {
                self.windowManager.show(controller: tracker, show: false)
            }
        }
    }
    
    func updateCardHud() {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            
            let tracker = self.windowManager.cardHudContainer
            
            if Settings.showCardHuds && self.shouldShowGUIElement {
                if !self.gameEnded {
                    tracker.update(entities: self.opponent.hand,
                                            cardCount: self.opponent.handCount)
                    self.windowManager.show(controller: tracker, show: true,
                         frame: SizeHelper.cardHudContainerFrame(), title: nil,
                         overlay: self.hearthstoneRunState.isActive)
                } else {
                    self.windowManager.show(controller: tracker, show: false)
                }
            } else {
                self.windowManager.show(controller: tracker, show: false)
            }
        }
    }
    
    func updateBoardStateTrackers() {
        DispatchQueue.main.async {
            // board damage
            let board = BoardState(game: self)
            
            let playerBoardDamage = self.windowManager.playerBoardDamage
            let opponentBoardDamage = self.windowManager.opponentBoardDamage
            
            var rect: NSRect?
            
            if Settings.playerBoardDamage && self.shouldShowGUIElement {
                if !self.gameEnded {
                    var heroPowerDmg = 0
                    if let heroPower = board.player.heroPower, self.player.currentMana >= heroPower.cost {
                        heroPowerDmg = heroPower.damage

                        // Garrison Commander = hero power * 2
                        if board.player.cards.first(where: { $0.cardId == "AT_080"}) != nil {
                            heroPowerDmg *= 2
                        }
                    }
                    playerBoardDamage.update(attack: board.player.damage + heroPowerDmg)
                    if Settings.autoPositionTrackers {
                        rect = SizeHelper.playerBoardDamageFrame()
                    } else {
                        rect = Settings.playerBoardDamageFrame
                        if rect == nil {
                            rect = SizeHelper.playerBoardDamageFrame()
                        }
                    }
                    playerBoardDamage.hasValidFrame = true
                    self.windowManager.show(controller: playerBoardDamage, show: true,
                         frame: rect, title: nil, overlay: self.hearthstoneRunState.isActive)
                } else {
                    self.windowManager.show(controller: playerBoardDamage, show: false)
                }
            } else {
                self.windowManager.show(controller: playerBoardDamage, show: false)
            }
            
            if Settings.opponentBoardDamage && self.shouldShowGUIElement {
                if !self.gameEnded {
                    var heroPowerDmg = 0
                    if let heroPower = board.opponent.heroPower {
                        heroPowerDmg = heroPower.damage

                        // Garrison Commander = hero power * 2
                        if board.opponent.cards.first(where: { $0.cardId == "AT_080"}) != nil {
                            heroPowerDmg *= 2
                        }
                    }
                    opponentBoardDamage.update(attack: board.opponent.damage + heroPowerDmg)
                    if Settings.autoPositionTrackers {
                        rect = SizeHelper.opponentBoardDamageFrame()
                    } else {
                        rect = Settings.opponentBoardDamageFrame
                        if rect == nil {
                            rect = SizeHelper.opponentBoardDamageFrame()
                        }
                    }
                    opponentBoardDamage.hasValidFrame = true
                    self.windowManager.show(controller: opponentBoardDamage, show: true,
                         frame: SizeHelper.opponentBoardDamageFrame(), title: nil,
                         overlay: self.hearthstoneRunState.isActive)
                } else {
                    self.windowManager.show(controller: opponentBoardDamage, show: false)
                }
            } else {
                self.windowManager.show(controller: opponentBoardDamage, show: false)
            }
        }
    }
	
	func updateArenaHelper() {
		DispatchQueue.main.async {
			
			let tracker = self.windowManager.arenaHelper
			
			if Settings.showArenaHelper && ArenaWatcher.isRunning() &&
                !(Settings.dontTrackWhileSpectating && self.spectator) &&
				self.windowManager.arenaHelper.cards.count == 3 &&
				((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive)
					|| !Settings.hideAllWhenGameInBackground ) {
				tracker.table?.reloadData()
				self.windowManager.show(controller: tracker, show: true, frame: SizeHelper.arenaHelperFrame(),
                                        title: nil, overlay: self.hearthstoneRunState.isActive)
			} else {
				self.windowManager.show(controller: tracker, show: false)
			}
		}
	}
	
    // MARK: - Vars
	var startTime: Date?
    var currentTurn = 0
    var lastId = 0
    var gameTriggerCount = 0
	private var playerDeckAutodetected: Bool = false
    
    private var powerLog: [LogLine] = []
    func add(powerLog: LogLine) {
        self.powerLog.append(powerLog)
    }
    
    var playedCards: [PlayedCard] = []
    var proposedAttackerEntityId: Int = 0
    var proposedDefenderEntityId: Int = 0
	var player: Player!
    var opponent: Player!
    var currentMode: Mode? = .invalid
    var previousMode: Mode? = .invalid
	
	var gameResult: GameResult = .unknown
	var wasConceded: Bool = false

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
        if self.gameEnded {
            return .gt_unknown
        }
        if let gameType = MirrorHelper.getGameType(),
            let type = GameType(rawValue: gameType) {
            _currentGameType = type
        }
        return _currentGameType
    }
    
    private var _serverInfo: MirrorGameServerInfo?
    var serverInfo: MirrorGameServerInfo? {
        if _serverInfo == nil {
            _serverInfo = MirrorHelper.getGameServerInfo()
        }
        return _serverInfo
    }

	var entities: [Int: Entity] = [:] {
		didSet {
			// collect all elements that changed
			let newKeys = entities.keys
			
			let changedElements = Array(newKeys.filter {
				if let oldEntity = oldValue[$0] {
					return oldEntity != self.entities[$0]
				}
				return false
			}).map { (old: oldValue[$0]!, new: self.entities[$0]!) }
			self.handleEntitiesChange(changed: changedElements)
		}
	}
    var tmpEntities: [Entity] = []
    var knownCardIds: [Int: [String]] = [:]
    var joustReveals = 0

    var lastCardPlayed: Int?
    var gameEnded = true
    internal private(set) var currentDeck: PlayingDeck?

    var currentEntityHasCardId = false
    var playerUsedHeroPower = false
    private var hasCoin = false
    var currentEntityZone: Zone = .invalid
    var opponentUsedHeroPower = false
	var wasInProgress = false
    var setupDone = false
    var secretsManager: SecretsManager?
    var proposedAttacker = 0
    var proposedDefender = 0
    private var defendingEntity: Entity?
    private var attackingEntity: Entity?
    private var avengeDeathRattleCount = 0
    private var awaitingAvenge = false
    var isInMenu = true
    private var handledGameEnd = false
    
	var enqueueTime = LogDate(date: Date.distantPast)
    private var lastTurnStart: [Int] = [0, 0]
    private var turnQueue: Set<PlayerTurn> = Set()
    
	fileprivate var lastGameStartTimestamp: LogDate = LogDate(date: Date.distantPast)

    private var _matchInfo: MatchInfo?
    
    var matchInfo: MatchInfo? {
        
        if _matchInfo != nil {
            return _matchInfo
        }
        
        if !self.gameEnded, let mInfo = MirrorHelper.getMatchInfo() {
            self._matchInfo = MatchInfo(info: mInfo)
            logger.info("\(String(describing: self._matchInfo?.localPlayer.name))"
                + " vs \(String(describing: self._matchInfo?.opposingPlayer.name))"
                + " matchInfo: \(String(describing: self._matchInfo))")
            
            if let minfo = self._matchInfo {
                self.player.name = minfo.localPlayer.name
                self.opponent.name = minfo.opposingPlayer.name
                self.player.id = minfo.localPlayer.playerId
                self.opponent.id = minfo.opposingPlayer.playerId
                self._currentGameType = minfo.gameType
                self.currentFormat = minfo.formatType
            }
            
            // request a mirror read so we have this data at the end of the game
            _ = self.serverInfo
        }
        
        return _matchInfo
    }
	
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
        return entities.map { $0.1 }.first { $0[.player_id] == self.player.id }
    }

    var opponentEntity: Entity? {
        return entities.map { $0.1 }.first { $0.has(tag: .player_id) && !$0.isPlayer(eventHandler: self) }
    }

    var gameEntity: Entity? {
        return entities.map { $0.1 }.first { $0.name == "GameEntity" }
    }

    var isMinionInPlay: Bool {
        return entities.map { $0.1 }.first { $0.isInPlay && $0.isMinion } != nil
    }

    var isOpponentMinionInPlay: Bool {
        return entities.map { $0.1 }
            .first { $0.isInPlay && $0.isMinion
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

    var opponentHandCount: Int {
        return entities.map { $0.1 }
            .filter { $0.isInHand && $0.isControlled(by: self.opponent.id) }.count }

    private(set) var currentFormat = Format(formatType: FormatType.ft_unknown)

	// MARK: - Lifecycle
    private var allTrackerUpdateObserver: NSObjectProtocol?
    
    init(hearthstoneRunState: HearthstoneRunState) {
        self.hearthstoneRunState = hearthstoneRunState
		turnTimer = TurnTimer(gui: windowManager.timerHud)
        super.init()
		player = Player(local: true, game: self)
        opponent = Player(local: false, game: self)
        secretsManager = SecretsManager(game: self)
        secretsManager?.onChanged = { [weak self] cards in
            self?.updateSecretTracker(cards: cards)
        }
		
		windowManager.startManager()
        windowManager.playerTracker.window?.delegate = self
        windowManager.opponentTracker.window?.delegate = self
		
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
		                              "card_size", "theme"]
		
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
			/*center.addObserver(self,
			                   selector: #selector(updateTrackers),
			                   name: NSNotification.Name(rawValue: option),
			                   object: nil)*/
            allTrackerUpdateObserver = center.addObserver(forName: NSNotification.Name(rawValue: option), object: self, queue: OperationQueue.main, using: _updateTrackers)
		}
		
		// start gui updater thread
		_queue.async {
			while true {
				if self.guiNeedsUpdate {
					self.guiNeedsUpdate = false
					self._updateTrackers()
					self.guiUpdateResets = false
				}
				
				Thread.sleep(forTimeInterval: Game.guiUpdateDelay)
			}
		}
    }

    func reset() {
        logger.verbose("Reseting Game")
        currentTurn = 0

        playedCards.removeAll()
		
		self.gameResult = .unknown
		self.wasConceded = false

        lastId = 0
        gameTriggerCount = 0

        _matchInfo = nil
        currentFormat = Format(formatType: FormatType.ft_unknown)
        _currentGameType = .gt_unknown
		_currentGameMode = .none
        _serverInfo = nil

        entities.removeAll()
        tmpEntities.removeAll()
        knownCardIds.removeAll()
        joustReveals = 0
		
        lastCardPlayed = nil
        
        currentEntityHasCardId = false
        playerUsedHeroPower = false
        hasCoin = false
        currentEntityZone = .invalid
        opponentUsedHeroPower = false
        setupDone = false
        secretsManager?.reset()
        proposedAttacker = 0
        proposedDefender = 0
        defendingEntity = nil
        attackingEntity = nil
        avengeDeathRattleCount = 0
        awaitingAvenge = false
        lastTurnStart = [0, 0]

        player.reset()
        if let currentdeck = self.currentDeck {
            player.playerClass = currentdeck.playerClass
        }
        opponent.reset()
        updateSecretTracker(cards: [])
        windowManager.hideGameTrackers()
		
		_spectator = false
    }

	func set(activeDeckId: String?, autoDetected: Bool) {
		Settings.activeDeck = activeDeckId
		self.playerDeckAutodetected = autoDetected
		
		if let id = activeDeckId, let deck = RealmHelper.getDeck(with: id) {
			set(activeDeck: deck)
		} else {
			currentDeck = nil
			player.playerClass = nil
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
        updateTrackers(reset: true)
    }

    func removeActiveDeck() {
        currentDeck = nil
        Settings.activeDeck = nil
        updateTrackers(reset: true)
    }

    // MARK: - game state
    private var lastGameStart = Date.distantPast
    func gameStart(at timestamp: LogDate) {
        logger.info("currentGameMode: \(currentGameMode), isInMenu: \(isInMenu), "
            + "handledGameEnd: \(handledGameEnd), "
            + "lastGameStartTimestamp: \(lastGameStartTimestamp), " +
            "timestamp: \(timestamp)")
        if currentGameMode == .practice && !isInMenu && !handledGameEnd
			&& lastGameStartTimestamp > LogDate(date: Date.distantPast)
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
        
        // remove every line before _last_ create game
        if let index = self.powerLog.reversed().index(where: { $0.line.contains("CREATE_GAME") }) {
            self.powerLog = self.powerLog.reversed()[...index].reversed() as [LogLine]
        } else {
            self.powerLog = []
        }

		gameEnded = false
        isInMenu = false
        handledGameEnd = false

        logger.info("----- Game Started -----")
        AppHealth.instance.setHearthstoneGameRunning(flag: true)

        NotificationManager.showNotification(type: .gameStart)

        if Settings.showTimer {
            self.turnTimer.start()
        }
		
		// update spectator information
		_spectator = MirrorHelper.isSpectating() ?? false
		
        updateTrackers(reset: true)

        self.startTime = Date()
    }

    private func adventureRestart() {
        // The game end is not logged in PowerTaskList
        logger.info("Adventure was restarted. Simulating game end.")
        concede()
        loss()
        gameEnd()
        inMenu()
    }

    func gameEnd() {
        logger.info("----- Game End -----")
        AppHealth.instance.setHearthstoneGameRunning(flag: false)
		
        handleEndGame()

        secretsManager?.reset()
        updateTrackers(reset: true)
        windowManager.hideGameTrackers()
        turnTimer.stop()
    }

    func inMenu() {
        if isInMenu {
            return
        }
        logger.verbose("Game is now in menu")

        turnTimer.stop()

        isInMenu = true
    }
	
	private func generateEndgameStatistics() -> InternalGameStats? {
		let result = InternalGameStats()
		
		result.startTime = self.startTime ?? Date()
		result.endTime = Date()
		
		result.playerHero = currentDeck?.playerClass ?? player.playerClass ?? .neutral
		result.opponentHero = opponent.playerClass ?? .neutral
		
		result.wasConceded = self.wasConceded
		result.result = self.gameResult
		
		if let build = BuildDates.latestBuild {
			result.hearthstoneBuild = build.build
		}
		result.season = Database.currentSeason
		
		if let name = self.player.name {
			result.playerName = name
		}
		if let _player = self.entities.map({ $0.1 }).first(where: { $0.isPlayer(eventHandler: self) }) {
			result.coin = !_player.has(tag: .first_player)
		}
		
		if let name = self.opponent.name {
			result.opponentName = name
		} else if result.opponentHero != .neutral {
			result.opponentName = result.opponentHero.rawValue
		}
		
		result.turns = self.turnNumber()
		
		result.gameMode = self.currentGameMode
		result.format = self.currentFormat
		
		if let matchInfo = self.matchInfo, self.currentGameMode == .ranked {
			let wild = self.currentFormat == .wild
			
			result.rank = wild
				? matchInfo.localPlayer.wildRank
				: matchInfo.localPlayer.standardRank
			result.opponentRank = wild
				? matchInfo.opposingPlayer.wildRank
				: matchInfo.opposingPlayer.standardRank
			result.legendRank = wild
				? matchInfo.localPlayer.wildLegendRank
				: matchInfo.localPlayer.standardLegendRank
			result.opponentLegendRank = wild
				? matchInfo.opposingPlayer.wildLegendRank
				: matchInfo.opposingPlayer.standardLegendRank
			result.stars = wild
				? matchInfo.localPlayer.wildStars
				: matchInfo.localPlayer.standardStars
		} else if self.currentGameMode == .arena {
			result.arenaLosses = self.arenaInfo?.losses ?? 0
			result.arenaWins = self.arenaInfo?.wins ?? 0
		} else if let brawlInfo = self.brawlInfo, self.currentGameMode == .brawl {
			result.brawlWins = brawlInfo.wins
			result.brawlLosses = brawlInfo.losses
		}
		
		result.gameType = self.currentGameType
		if let serverInfo = self.serverInfo {
			result.serverInfo = ServerInfo(info: serverInfo)
		}
		result.playerCardbackId = self.matchInfo?.localPlayer.cardBackId ?? 0
		result.opponentCardbackId = self.matchInfo?.opposingPlayer.cardBackId ?? 0
		result.friendlyPlayerId = self.matchInfo?.localPlayer.playerId ?? 0
		result.scenarioId = self.matchInfo?.missionId ?? 0
		result.brawlSeasonId = self.matchInfo?.brawlSeasonId ?? 0
		result.rankedSeasonId = self.matchInfo?.rankedSeasonId ?? 0
		result.hsDeckId = self.currentDeck?.hsDeckId
		
		self.player.revealedCards.filter({
			$0.collectible
		}).forEach({
			result.revealedCards.append($0)
		})
		
		self.opponent.opponentCardList.filter({
			!$0.isCreated
		}).forEach({
			result.opponentCards.append($0)
		})
		
		return result
	}

    func handleEndGame() {
		
		if self.handledGameEnd {
			logger.warning("HandleGameEnd was already called.")
			return
		}

		guard let currentGameStats = generateEndgameStatistics() else {
			logger.error("Error: could not generate endgame statistics")
			return
		}
		
		logger.verbose("currentGameStats: \(currentGameStats), "
			+ "handledGameEnd: \(self.handledGameEnd)")
		
        self.handledGameEnd = true
        
        if self.currentGameMode == .spectator && currentGameStats.result == .none {
            logger.info("Game was spectator mode without a game result."
                + " Probably exited spectator mode early.")
            return
        }
        
        /*if Settings.promptNotes {
            let message = NSLocalizedString("Do you want to add some notes for this game ?",
                                            comment: "")
            let frame = NSRect(x: 0, y: 0, width: 300, height: 80)
            let input = NSTextView(frame: frame)
            
            if NSAlert.show(style: .informational, message: message,
                            accessoryView: input, forceFront: true) {
                currentGameStats.note = input.string ?? ""
            }
        }*/

        logger.verbose("End game: \(currentGameStats)")
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
		
		self.syncStats(logLines: self.powerLog, stats: currentGameStats)
    }

    private var logContainsGoldRewardState: Bool {
        return powerLog.filter({ $0.line.contains("tag=GOLD_REWARD_STATE value=1") }).count == 2
    }

    private var logContainsStateComplete: Bool {
        return powerLog.any({ $0.line.contains("tag=STATE value=COMPLETE") })
    }

	private func syncStats(logLines: [LogLine], stats: InternalGameStats) {

        guard currentGameMode != .practice && currentGameMode != .none && currentGameMode != .spectator else {
            logger.info("Game was in \(currentGameMode), don't send to third-party")
            return
        }
        
        if TrackOBotAPI.isLogged() && Settings.trackobotSynchronizeMatches {
            do {
                try TrackOBotAPI.postMatch(stat: stats, cards: playedCards)
            } catch {
                logger.error("Track-o-Bot error : \(error)")
            }
        }

        if Settings.hsReplaySynchronizeMatches && (
            (stats.gameMode == .ranked &&
                Settings.hsReplayUploadRankedMatches) ||
            (stats.gameMode == .casual &&
                Settings.hsReplayUploadCasualMatches) ||
            (stats.gameMode == .arena &&
                Settings.hsReplayUploadArenaMatches) ||
            (stats.gameMode == .brawl &&
                Settings.hsReplayUploadBrawlMatches) ||
            (stats.gameMode == .practice &&
                Settings.hsReplayUploadAdventureMatches) ||
            (stats.gameMode == .friendly &&
                Settings.hsReplayUploadFriendlyMatches) ||
            (stats.gameMode == .spectator &&
                Settings.hsReplayUploadFriendlyMatches)) {
			
			let (uploadMetaData, statId) = UploadMetaData.generate(stats: stats,
				deck: self.playerDeckAutodetected && self.currentDeck != nil ? self.currentDeck : nil )
			
            HSReplayAPI.getUploadToken { _ in
                
                LogUploader.upload(logLines: logLines,
                                   metaData: (uploadMetaData, statId)) { result in
                    if case UploadResult.successful(let replayId) = result {
                        NotificationManager.showNotification(type: .hsReplayPush(replayId: replayId))
                        NotificationCenter.default
                            .post(name: Notification.Name(rawValue: "reload_decks"), object: nil)
                    } else if case UploadResult.failed(let error) = result {
                        NotificationManager.showNotification(type: .hsReplayUploadFailed(error: error))
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
        secretsManager?.handleTurnsInPlayChange(entity: entity, turn: turn)
    }

    func turnStart(player: PlayerType, turn: Int) {
        if !isMulliganDone() {
            logger.info("--- Mulligan ---")
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
            logger.info("Turn \(playerTurn.turn) start for player \(player) ")
        }

        if player == .player {
            handleThaurissanCostReduction()
        }

        if turnQueue.count > 0 {
            return
        }

        var timeout = -1
        if player == .player && playerEntity!.has(tag: .timeout) {
            timeout = playerEntity![.timeout]
        } else if player == .opponent && opponentEntity!.has(tag: .timeout) {
            timeout = opponentEntity![.timeout]
        }
		
        turnTimer.startTurn(for: player, timeout: timeout)

        if player == .player && !isInMenu {
            NotificationManager.showNotification(type: .turnStart)
        }

        updateTrackers()
    }

    func concede() {
        logger.info("Game has been conceded : (")
        self.wasConceded = true
    }

    func win() {
        logger.info("You win ¯\\_(ツ) _ / ¯")
        self.gameResult = .win

        if self.wasConceded {
            NotificationManager.showNotification(type: .opponentConcede)
        }
    }

    func loss() {
        logger.info("You lose : (")
        self.gameResult = .loss
    }

    func tied() {
        logger.info("You lose : ( / game tied: (")
        self.gameResult = .draw
    }

    func isMulliganDone() -> Bool {
		let player = entities.map { $0.1 }.first { $0.isPlayer(eventHandler: self) }
        let opponent = entities.map { $0.1 }
            .first { $0.has(tag: .player_id) && !$0.isPlayer(eventHandler: self) }

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

    // MARK: - player
    func set(playerHero cardId: String) {
        if let card = Cards.hero(byId: cardId) {
            player.playerClass = card.playerClass
            player.playerClassId = cardId
            if Settings.fullGameLog {
                logger.info("Player class is \(card) ")
            }
        }
    }

    func set(playerName name: String) {
        player.name = name
    }

    func playerGet(entity: Entity, cardId: String?, turn: Int) {
        if cardId.isBlank {
            return
        }
        player.createInHand(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerBackToHand(entity: Entity, cardId: String?, turn: Int) {
        if cardId.isBlank {
            return
        }
        updateTrackers()
        player.boardToHand(entity: entity, turn: turn)
    }

    func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int) {
        if cardId.isBlank {
            return
        }
        player.boardToDeck(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerPlay(entity: Entity, cardId: String?, turn: Int) {
        if cardId.isBlank {
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

        secretsManager?.handleCardPlayed(entity: entity)
        updateTrackers()
    }

    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int) {
        if cardId.isBlank {
            return
        }
        player.handDiscard(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerSecretPlayed(entity: Entity, cardId: String?, turn: Int, fromZone: Zone) {
        if cardId.isBlank { return }

        if !entity.isSecret {
            if entity.isQuest {
                player.questPlayedFromHand(entity: entity, turn: turn)
            }
            return
        }

        switch fromZone {
        case .deck:
            player.secretPlayedFromDeck(entity: entity, turn: turn)
        case .hand:
            player.secretPlayedFromHand(entity: entity, turn: turn)
            secretsManager?.handleCardPlayed(entity: entity)
        default:
            player.createInSecret(entity: entity, turn: turn)
            return
        }
        updateTrackers()
    }

    func playerMulligan(entity: Entity, cardId: String?) {
        if cardId.isBlank {
            return
        }

        player.mulligan(entity: entity)
        updateTrackers()
    }

    func playerDraw(entity: Entity, cardId: String?, turn: Int) {
        if cardId.isBlank {
            return
        }
        if cardId == CardIds.NonCollectible.Neutral.TheCoin {
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
            logger.info("Player get \(value) fatigue")
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
            if !className.isBlank {
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
            guard heroClass != nil else { return }
            secretsManager?.newSecret(entity: entity)
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
            logger.info("Player Hero Power \(cardId) \(turn) ")
        }

        secretsManager?.handleHeroPower()
    }

    // MARK: - Opponent actions
    func set(opponentHero cardId: String) {
        if let card = Cards.hero(byId: cardId) {
            opponent.playerClass = card.playerClass
            opponent.playerClassId = cardId
            updateTrackers()
            if Settings.fullGameLog {
                logger.info("Opponent class is \(card) ")
            }
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
        if !entity.isSecret {
            if entity.isQuest {
                opponent.questPlayedFromHand(entity: entity, turn: turn)
            }
            return
        }

        switch fromZone {
        case .deck:
            opponent.secretPlayedFromDeck(entity: entity, turn: turn)
        case .hand:
            opponent.secretPlayedFromHand(entity: entity, turn: turn)
        default:
            opponent.createInSecret(entity: entity, turn: turn)
        }

        var heroClass: CardClass?
        let className = "\(entity[.class])".lowercased()
        if let tagClass = TagClass(rawValue: entity[.class]) {
            heroClass = tagClass.cardClassValue
        } else if let _heroClass = CardClass(rawValue: className), !className.isBlank {
            heroClass = _heroClass
        } else if let playerClass = opponent.playerClass {
            heroClass = playerClass
        }

        if Settings.fullGameLog {
            logger.info("Secret played by \(entity[.class])"
                + " -> \(String(describing: heroClass)) "
                + "-> \(String(describing: opponent.playerClass))")
        }
        if heroClass != nil {
            secretsManager?.newSecret(entity: entity)
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
        if !entity.isSecret { return }

        opponent.secretTriggered(entity: entity, turn: turn)
        secretsManager?.removeSecret(entity: entity)
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
            secretsManager?.removeSecret(entity: entity)
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
            logger.info("Opponent Hero Power \(cardId) \(turn) ")
        }
        updateTrackers()
    }

    // MARK: - Game actions
    func defending(entity: Entity?) {
        self.defendingEntity = entity
        if let attackingEntity = self.attackingEntity,
            let defendingEntity = self.defendingEntity,
            let entity = entity {
            if entity.isControlled(by: opponent.id) {
                secretsManager?.handleAttack(attacker: attackingEntity, defender: defendingEntity)
            }
        }
    }

    func attacking(entity: Entity?) {
        self.attackingEntity = entity
        if let attackingEntity = self.attackingEntity,
            let defendingEntity = self.defendingEntity,
            let entity = entity {
            if entity.isControlled(by: player.id) {
                secretsManager?.handleAttack(attacker: attackingEntity, defender: defendingEntity)
            }
        }
    }

    func playerMinionPlayed() {
        secretsManager?.handleMinionPlayed()
    }

    func opponentMinionDeath(entity: Entity, turn: Int) {
        secretsManager?.handleMinionDeath(entity: entity)
    }

    func opponentDamage(entity: Entity) {
        secretsManager?.handleOpponentDamage(entity: entity)
    }

    func opponentTurnStart(entity: Entity) {

    }
	
	// MARK: - Arena
	
	func setArenaOptions(cards: [Card]) {
		self.windowManager.arenaHelper.set(cards: cards)
		self.updateArenaHelper()
	}
}

// MARK: NSWindowDelegate functions
extension Game: NSWindowDelegate {
    
    func windowDidResize(_ notification: Notification) {
        
        guard let window = notification.object as? NSWindow else { return }
        
        if window == self.windowManager.playerTracker.window {
            self.updatePlayerTracker(reset: false)
            onWindowMove(tracker: self.windowManager.playerTracker)
        } else if window == self.windowManager.opponentTracker.window {
            self.updateOpponentTracker(reset: false)
            onWindowMove(tracker: self.windowManager.opponentTracker)
        }
    }
    
    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window == self.windowManager.playerTracker.window {
            onWindowMove(tracker: self.windowManager.playerTracker)
        } else if window == self.windowManager.opponentTracker.window {
            onWindowMove(tracker: self.windowManager.opponentTracker)
        }
    }
    
    private func onWindowMove(tracker: Tracker) {
        if !tracker.isWindowLoaded || !tracker.hasValidFrame {return}
        if tracker.playerType == .player {
            Settings.playerTrackerFrame = tracker.window?.frame
        } else {
            Settings.opponentTrackerFrame = tracker.window?.frame
        }
    }
}

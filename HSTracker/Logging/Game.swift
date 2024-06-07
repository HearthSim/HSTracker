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
import AppCenterAnalytics

struct Sideboard {
    let ownerCardId: String
    let cards: [Card]
}

struct PlayingDeck {
    let id: String
    let name: String
    let hsDeckId: Int64?
    let playerClass: CardClass
    let heroId: String
    let cards: [Card]
    let isArena: Bool
    let shortid: String
    let sideboards: [Sideboard]
}

/**
 * Game object represents the current state of the tracker
 */
class Game: NSObject, PowerEventHandler {
	/**
	 * View controller of this game object
	 */
    internal let windowManager = WindowManager()
	
    static let guiUpdateDelay: TimeInterval = 0.5
	
	private let turnTimer: TurnTimer
    
    private var mulliganState: MulliganState!
    
	private var hearthstoneRunState: HearthstoneRunState {
		didSet {
			if hearthstoneRunState.isRunning {
				// delay update as game might not have a proper window
				DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
					self?.updateTrackers()
                    self?.updateBattlegroundsOverlays()
                    self?.updateConstructedMulliganOverlays()
				})
			} else {
				self.updateTrackers()
                self.updateBattlegroundsOverlays()
                self.updateConstructedMulliganOverlays()
			}
		}
	}
    
    var isRunning: Bool {
        return hearthstoneRunState.isRunning
    }
    
    private var selfAppActive: Bool = true
    
    lazy var queueEvents: QueueEvents = QueueEvents(game: self)
    
    var _mulliganGuideParams: MulliganGuideParams?
	
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
    
    func getBattlegroundsBoardStateFor(id: Int) -> BoardSnapshot? {
        return _battlegroundsBoardState.getSnapshot(entityId: id)
    }
    
    var gameId = ""
        
    //We do count+1 because the friendly hero is not in setaside
    func battlegroundsHeroCount() -> Int {
        return entities.values.filter { x in x.isHero && x.isInSetAside && (x.has(tag: .bacon_hero_can_be_drafted) || x.has(tag: .bacon_skin) || x.has(tag: .player_tech_level)) }.count + 1 }
    
    func snapshotBattlegroundsBoardState() {
        _battlegroundsBoardState.snapshotCurrentBoard()
    }
	
	// MARK: - PowerEventHandler protocol
	
	func handleEntitiesChange(changed: [(old: Entity, new: Entity)]) {
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
	private let _queue = DispatchQueue(label: "net.hearthsim.hstracker.guiupdate", attributes: [])
	
    private func updateAllTrackers() {
		SizeHelper.hearthstoneWindow.reload()
		
		self.updatePlayerTracker(reset: guiUpdateResets)
		self.updateOpponentTracker(reset: guiUpdateResets)
        self.updateCardHud()
        self.updateTurnTimer()
        self.updateBoardStateTrackers()
		self.updateArenaHelper()
        self.updateSecretTracker()
        self.updateBattlegroundsOverlay()
        self.updateBattlegroundsTierOverlay(reset: guiUpdateResets)
        self.updateBobsBuddyOverlay()
        self.updateTurnCounterOverlay()
        self.updateToaster()
        self.updateOpponentIcons()
        self.updatePlayerIcons()
        self.updateExperienceOverlay()
        self.updateMercenariesTaskListButton()
        self.updateBoardOverlay()
        self.updateConstructedMulliganOverlays()
	}
	
    // MARK: - GUI calls
    var shouldShowGUIElement: Bool {
        return
            // do not show gui while spectating
            !(Settings.dontTrackWhileSpectating && self.spectator) &&
                // do not show gui while game is in background
                !((Settings.hideAllWhenGameInBackground || Settings.hideAllWhenGameInBackground) && !self.hearthstoneRunState.isActive)
    }
    
    var shouldShowTracker: Bool {
        return ((Settings.hideAllTrackersWhenNotInGame && !self.gameEnded) || (!Settings.hideAllTrackersWhenNotInGame) || self.selfAppActive ) && ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground || self.selfAppActive)
    }
    
    func updateTrackers(reset: Bool = false) {
        _queue.async {
            self.guiNeedsUpdate = true
            self.guiUpdateResets = reset || self.guiUpdateResets
        }
    }
	
	@objc fileprivate func updateOpponentTracker(reset: Bool = false) {
		DispatchQueue.main.async { [unowned(unsafe) self] in
			
			let tracker = self.windowManager.opponentTracker
			if Settings.showOpponentTracker &&
                (!self.isBattlegroundsMatch() && !self.isMercenariesMatch() && self.currentGameType != .gt_unknown) &&
            !(Settings.dontTrackWhileSpectating && self.spectator) &&
				((Settings.hideAllTrackersWhenNotInGame && !self.gameEnded)
					|| (!Settings.hideAllTrackersWhenNotInGame) || self.selfAppActive ) &&
				((Settings.hideAllWhenGameInBackground &&
					self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground || self.selfAppActive) {
				
				// update cards
                if self.gameEnded && Settings.clearTrackersOnGameEnd {
                    tracker.update(cards: [], top: [], bottom: [], sideboards: [], reset: reset)
                } else {
                    tracker.update(cards: self.opponent.opponentCardList, top: [], bottom: [], sideboards: [], reset: reset)
                }
				
				let gameStarted = !self.isInMenu && self.entities.count >= 67
                tracker.updateCardCounter(deckCount: !gameStarted || !isMulliganDone() ? 30 - self.opponent.handCount : self.opponent.deckCount,
				                          handCount: !gameStarted ? 0 : self.opponent.handCount,
				                          hasCoin: self.opponent.hasCoin,
				                          gameStarted: gameStarted)

				tracker.showCthunCounter = false
				tracker.showSpellCounter = false
				tracker.showDeathrattleCounter = Settings.showOpponentDeathrattle
				tracker.showGraveyard = Settings.showOpponentGraveyard
				tracker.showJadeCounter = false
				tracker.fatigueCounter = self.opponent.fatigue
				tracker.deathrattlesPlayedCount = self.opponent.deathrattlesPlayedCount
                tracker.showLibramCounter = false
                
                if let fullname = self.opponent.name {
                    let names = fullname.components(separatedBy: "#")
                    tracker.playerName = names[0]
                }
				
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
                self.windowManager.show(controller: self.windowManager.linkOpponentDeckPanel, show: false)
            }
		}
	}
    
    func updateOpponentIcons() {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            var anyVisible = false
            let showTracker = shouldShowTracker && !isBattlegroundsMatch() && !isMercenariesMatch() && isMulliganDone()
            let icons = self.windowManager.opponentWotogIcons
            icons.jadeVisibility = showOpponentJadeCounter && showTracker
            if icons.jadeVisibility {
                anyVisible = true
                icons.jade = opponentNextJadeGolem
            }
            icons.cthunVisibility = showOpponentCthunCounter && showTracker
            if icons.cthunVisibility {
                anyVisible = true
                let player = opponentEntity
                icons.cthunAttack = (player?.has(tag: .cthun_attack_buff) ?? false) ? (player?[.cthun_attack_buff] ?? 0) + 6 : 6
                icons.cthunHealth = (player?.has(tag: .cthun_health_buff) ?? false) ? (player?[.cthun_health_buff] ?? 0) + 6 : 6
            }
            icons.spellsVisibility = showOpponentSpellsCounter && showTracker
            if icons.spellsVisibility {
                anyVisible = true
                icons.spellsCounter = opponent.spellsPlayedCount
            }
            icons.pogoVisibility = showOpponentPogoHopperCounter && showTracker
            if icons.pogoVisibility {
                anyVisible = true
                icons.pogoCounter = ((opponent.pogoHopperPlayedCount + 1) * 2) - 1
            }
            icons.galakrondVisibility = showOpponentGalakrondCounter && showTracker
            if icons.galakrondVisibility {
                anyVisible = true
                icons.galakrondCounter = opponentGalakrondInvokeCounter
            }
            icons.libramVisibility = showOpponentLibramCounter && showTracker
            if icons.libramVisibility {
                anyVisible = true
                icons.libramCounter = opponentLibramCounter
            }
            icons.abyssalVisibility = showOpponentAbyssalCounter && showTracker
            if icons.abyssalVisibility {
                anyVisible = true
                icons.abyssalCurse = self.opponent.abyssalCurseCount
            }
            icons.excavateVisibility = showOpponentExcavateCounter && showTracker
            if icons.excavateVisibility {
                anyVisible = true
                icons.excavate = opponentEntity?[.gametag_2822] ?? 0
            }
            icons.spellSchoolsVisibility = showOpponentSpellSchoolsCounter && showTracker
            if icons.spellSchoolsVisibility {
                anyVisible = true
                icons.spellSchools = Array(opponent.playedSpellSchools)
            }
            if anyVisible {
                let frame = SizeHelper.opponentWotogIconsFrame()
                self.windowManager.show(controller: icons, show: true,
                                        frame: frame, overlay: self.hearthstoneRunState.isActive)
            } else {
                self.windowManager.show(controller: icons, show: false)
            }
        }
    }

    func updatePlayerIcons() {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            var anyVisible = false
            let showTracker = shouldShowTracker && !isBattlegroundsMatch() && !isMercenariesMatch() && isMulliganDone()
            let icons = self.windowManager.playerWotogIcons
            icons.jadeVisibility = showPlayerJadeCounter && showTracker
            if icons.jadeVisibility {
                anyVisible = true
                icons.jade = playerNextJadeGolem
            }
            icons.cthunVisibility = showPlayerCthunCounter && showTracker
            if icons.cthunVisibility {
                anyVisible = true
                let player = playerEntity
                icons.cthunAttack = (player?.has(tag: .cthun_attack_buff) ?? false) ? (player?[.cthun_attack_buff] ?? 0) + 6 : 6
                icons.cthunHealth = (player?.has(tag: .cthun_health_buff) ?? false) ? (player?[.cthun_health_buff] ?? 0) + 6 : 6
            }
            icons.spellsVisibility = showPlayerSpellsCounter && showTracker
            if icons.spellsVisibility {
                anyVisible = true
                icons.spellsCounter = player.spellsPlayedCount
            }
            icons.pogoVisibility = showPlayerPogoHopperCounter && showTracker
            if icons.pogoVisibility {
                anyVisible = true
                icons.pogoCounter = ((player.pogoHopperPlayedCount + 1) * 2) - 1
            }
            icons.galakrondVisibility = showPlayerGalakrondCounter && showTracker
            if icons.galakrondVisibility {
                anyVisible = true
                icons.galakrondCounter = playerGalakrondInvokeCounter
            }
            icons.libramVisibility = showPlayerLibramCounter && showTracker
            if icons.libramVisibility {
                anyVisible = true
                icons.libramCounter = playerLibramCounter
            }
            icons.abyssalVisibility = showPlayerAbyssalCounter  && showTracker
            if icons.abyssalVisibility {
                anyVisible = true
                icons.abyssalCurse = self.player.abyssalCurseCount
            }
            icons.excavateTierVisibility = showPlayerExcavateTier && showTracker
            if icons.excavateTierVisibility {
                anyVisible = true
                icons.excavateTier = playerEntity?[.current_excavate_tier] ?? 0
                icons.updateExcavateTierLabel()
            }
            icons.spellSchoolsVisibility = showPlayerSpellSchoolsCounter && showTracker
            if icons.spellSchoolsVisibility {
                anyVisible = true
                icons.spellSchools = Array(player.playedSpellSchools)
            }
            if anyVisible {
                let frame = SizeHelper.playerWotogIconsFrame()
                self.windowManager.show(controller: icons, show: true,
                                        frame: frame, overlay: self.hearthstoneRunState.isActive)
            } else {
                self.windowManager.show(controller: icons, show: false)
            }
        }
    }

    @objc func updatePlayerTracker(reset: Bool = false) {
        DispatchQueue.main.async { [unowned(unsafe) self] in
			
            let tracker = self.windowManager.playerTracker
            if Settings.showPlayerTracker &&
                !(Settings.dontTrackWhileSpectating && self.spectator) &&
                (!self.isBattlegroundsMatch() && !self.isMercenariesMatch() && self.currentGameType != .gt_unknown) &&
                ( (Settings.hideAllTrackersWhenNotInGame && !self.gameEnded)
                    || (!Settings.hideAllTrackersWhenNotInGame) || self.selfAppActive ) &&
                ((Settings.hideAllWhenGameInBackground &&
                    self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground || self.selfAppActive) {
                
                // update cards
                let dredged = player.deck.filter { x in x.info.deckIndex != 0 }.sorted(by: { x, y in x.info.deckIndex > y.info.deckIndex })
                let top = dredged.filter { x in x.info.deckIndex > 0 }.compactMap { (x) -> Card in
                    let card = x.card.copy()
                    card.deckListIndex = x.info.deckIndex
                    card.count = 1
                    return card
                }
                let bottom = dredged.filter { x in x.info.deckIndex < 0 }.compactMap { (x) -> Card in
                    let card = x.card.copy()
                    card.deckListIndex = x.info.deckIndex
                    card.count = 1
                    return card
                }

                tracker.update(cards: self.player.playerCardList, top: top, bottom: bottom, sideboards: self.player.playerSideboardsDict, reset: reset)
                
                // update card counter values
                let gameStarted = !self.isInMenu && self.entities.count >= 67
                tracker.updateCardCounter(deckCount: !gameStarted ? 30 : self.player.deckCount,
                                          handCount: !gameStarted ? 0 : self.player.handCount,
                                          hasCoin: self.player.hasCoin,
                                          gameStarted: gameStarted)
                
                tracker.showCthunCounter = false
                tracker.showSpellCounter = false
                tracker.showDeathrattleCounter = self.showPlayerDeathrattleCounter
                tracker.showGraveyard = Settings.showPlayerGraveyard
                tracker.showJadeCounter = false
                tracker.fatigueCounter = self.player.fatigue
                tracker.deathrattlesPlayedCount = self.player.deathrattlesPlayedCount
                tracker.showLibramCounter = false
                                
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
                } else {
                    tracker.playerName = player.name
                    tracker.playerClassId = playerHeroId
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
    
    func updateTurnCounter(turn: Int) {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            self.windowManager.turnCounter.setTurnNumber(turn: turn)

            let isBG = self.isBattlegroundsMatch() && !self.gameEnded

            if isBG && Settings.showTurnCounter && ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground) {
                let rect = SizeHelper.turnCounterFrame()
                self.windowManager.show(controller: self.windowManager.turnCounter, show: true, frame: rect, title: nil, overlay: self.hearthstoneRunState.isActive)
            } else {
                self.windowManager.show(controller: self.windowManager.turnCounter, show: false)
            }
        }
    }

    func updateTurnTimer() {
        DispatchQueue.main.async { [unowned(unsafe) self] in

            if Settings.showTimer && !self.gameEnded && self.shouldShowGUIElement && !isBattlegroundsMatch() && !isMercenariesMatch() {
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
        self.windowManager.secretTracker.set(cards: cards)
        self.updateSecretTracker()
    }
    
    func updateSecretTracker() {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            
            let tracker = self.windowManager.secretTracker
            
            if Settings.showSecretHelper && !self.gameEnded &&
                ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive)
                    || !Settings.hideAllWhenGameInBackground) && !isBattlegroundsMatch() {
                if tracker.cardCount() > 0 {
                    tracker.setWindowSizes()
                    let rect = SizeHelper.secretTrackerFrame(height: tracker.frameHeight)
                    tracker.contentViewController?.preferredContentSize = rect.size
                    self.windowManager.show(controller: tracker, show: true,
                                            frame: rect,
                                            title: nil, overlay: self.hearthstoneRunState.isActive)
                } else {
                    self.windowManager.show(controller: tracker, show: false)
                }
            } else {
                self.windowManager.show(controller: tracker, show: false)
            }
        }
    }
    
    func updateConstructedMulliganOverlays() {
        DispatchQueue.main.async {
            let hsActive = self.hearthstoneRunState.isActive
            
            if self.windowManager.constructedMulliganGuide.viewModel.visibility {
                if hsActive {
                    self.windowManager.show(controller: self.windowManager.constructedMulliganGuide, show: true, frame: SizeHelper.hearthstoneWindow.frame, overlay: true)
                    DispatchQueue.main.async {
                        self.windowManager.constructedMulliganGuide.updateScaling()
                    }
                } else {
                    self.windowManager.show(controller: self.windowManager.constructedMulliganGuide, show: false)
                }
            }
            
            if self.windowManager.constructedMulliganGuidePreLobby.isVisible {
                if hsActive && Settings.showMulliganGuidePreLobby {
                    self.windowManager.show(controller: self.windowManager.constructedMulliganGuidePreLobby, show: true, frame: SizeHelper.constructedMulliganGuidePreLobbyFrame(), overlay: true)
                    DispatchQueue.main.async {
                        self.windowManager.constructedMulliganGuidePreLobby.updateScaling()
                    }
                } else {
                    self.windowManager.show(controller: self.windowManager.constructedMulliganGuidePreLobby, show: false)
                }
            } else {
                self.windowManager.show(controller: self.windowManager.constructedMulliganGuidePreLobby, show: false)
            }
        }
    }
    
    func updateBattlegroundsOverlays() {
        DispatchQueue.main.async {
            let hsActive = self.hearthstoneRunState.isActive
            
            if self.windowManager.battlegroundsSession.visibility {
                if hsActive {
                    var rect = SizeHelper.battlegroundsSessionFrame()
                    if !Settings.autoPositionTrackers {
                        if let savedRect = Settings.battlegroundsSessionFrame {
                            rect = savedRect
                        }
                    }

                    self.windowManager.show(controller: self.windowManager.battlegroundsSession, show: true, frame: rect, overlay: true)
                    self.windowManager.battlegroundsSession.updateScaling()
                } else {
                    self.windowManager.show(controller: self.windowManager.battlegroundsSession, show: false)
                }
            }
            if self.windowManager.tier7PreLobby.isVisible {
                if hsActive {
                    self.windowManager.show(controller: self.windowManager.tier7PreLobby, show: true, frame: SizeHelper.tier7PreLobbyFrame(), overlay: true)
                } else {
                    self.windowManager.show(controller: self.windowManager.tier7PreLobby, show: false)
                }
            } else if self.windowManager.tier7PreLobby.window?.isVisible ?? false {
                self.windowManager.show(controller: self.windowManager.tier7PreLobby, show: false)
            }
            
            if self.windowManager.battlegroundsHeroPicking.viewModel.visibility {
                if hsActive {
                    self.windowManager.show(controller: self.windowManager.battlegroundsHeroPicking, show: true, frame: SizeHelper.hearthstoneWindow.frame, overlay: true)
                    DispatchQueue.main.async {
                        self.windowManager.battlegroundsHeroPicking.updateScaling()
                    }
                } else {
                    self.windowManager.show(controller: self.windowManager.battlegroundsHeroPicking, show: false)
                }
            }
            
            if self.windowManager.battlegroundsQuestPicking.viewModel.visibility {
                if hsActive {
                    self.windowManager.show(controller: self.windowManager.battlegroundsQuestPicking, show: true, frame: SizeHelper.hearthstoneWindow.frame, overlay: true)
                    DispatchQueue.main.async {
                        self.windowManager.battlegroundsQuestPicking.updateScaling()
                    }
                } else {
                    self.windowManager.show(controller: self.windowManager.battlegroundsQuestPicking, show: false)
                }
            }
        }
    }
    
    func updateBattlegroundsOverlay() {
        let rect = SizeHelper.battlegroundsOverlayFrame()

        DispatchQueue.main.async {
            let isBG = self.isBattlegroundsMatch() && !self.gameEnded

            if isBG && ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive)
                    || !Settings.hideAllWhenGameInBackground) {
                
                self.windowManager.show(controller: self.windowManager.battlegroundsOverlay, show: true, frame: rect, title: nil, overlay: true)
            } else {
                self.windowManager.show(controller: self.windowManager.battlegroundsOverlay, show: false)
            }
        }
    }
    
    func updateToaster() {
        let rect = SizeHelper.toastFrame()

        DispatchQueue.main.async {
            if self.windowManager.toastWindowController.displayed {
                self.windowManager.show(controller: self.windowManager.toastWindowController, show: true, frame: rect, title: nil, overlay: true)
            } else {
                self.windowManager.show(controller: self.windowManager.toastWindowController, show: false)
            }
        }

    }
    
    func updateTurnCounterOverlay() {
        let rect = SizeHelper.turnCounterFrame()
        
        DispatchQueue.main.async {
            let isBG = self.isBattlegroundsMatch() && !self.gameEnded
            if isBG && Settings.showTurnCounter &&
                ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive)
                 || !Settings.hideAllWhenGameInBackground) && !self.hideBattlegroundsTurn {
                let turn = self.turnNumber()
                if turn > 0 {
                    self.windowManager.turnCounter.setTurnNumber(turn: turn)
                }
                self.windowManager.show(controller: self.windowManager.turnCounter, show: true, frame: rect, title: nil, overlay: true)
            } else {
                self.windowManager.show(controller: self.windowManager.turnCounter, show: false)
            }
        }
    }

    func updateBobsBuddyOverlay() {
        let rect = SizeHelper.bobsPanelOverlayFrame()
        
        DispatchQueue.main.async {
            let isBG = self.isBattlegroundsMatch() && !self.gameEnded
            if isBG && Settings.showBobsBuddy &&
                ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive)
                    || !Settings.hideAllWhenGameInBackground) && !self.hideBobsBuddy {
                self.windowManager.show(controller: self.windowManager.bobsBuddyPanel, show: true, frame: rect, title: nil, overlay: true)
            } else {
                self.windowManager.show(controller: self.windowManager.bobsBuddyPanel, show: false)
            }
        }
    }
    
    func updateBattlegroundsTierOverlay(reset: Bool) {
        let rect = SizeHelper.battlegroundsTierOverlayFrame()
                
        DispatchQueue.main.async {
            let isBG = self.isBattlegroundsMatch() && !self.gameEnded

            let controller = self.windowManager.battlegroundsTierOverlay

            if isBG && Settings.showTiers && ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive)
                                              || !Settings.hideAllWhenGameInBackground) && !self.hideBattlegroundsTier {
                self.windowManager.show(controller: controller, show: true, frame: rect, title: nil, overlay: true)
                controller.tierOverlay?.unhideTier()
                if reset {
                    controller.tierOverlay?.displayTier(tier: controller.tierOverlay.currentTier, force: true)
                }
            } else {
                self.windowManager.show(controller: controller, show: false)
                controller.tierOverlay?.hideTier()
            }
        }
    }
    
    func updateExperienceOverlay() {
        let rect = SizeHelper.experienceOverlayFrame()
        
        DispatchQueue.main.async {
            let experiencePanel = self.windowManager.experiencePanel
            if Settings.showExperienceCounter && experiencePanel.visible && ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground) {
                self.windowManager.show(controller: experiencePanel, show: true, frame: rect, title: nil, overlay: true)
            } else {
                self.windowManager.show(controller: experiencePanel, show: false)
            }
        }
    }
    
    static let experienceFadeDelay = 6.0
    
    func experienceChangedAsync(experience: Int, experienceNeeded: Int, level: Int, levelChange: Int, animate: Bool) {
        let currentMode = self.currentMode ?? .invalid
        let previousMode = self.previousMode ?? .invalid
        
        logger.debug("Experience changed. Current mode \(currentMode), previous \(previousMode)")
        
        while let cm = self.currentMode, let pm = self.previousMode, cm == Mode.gameplay && pm == Mode.bacon {
            Thread.sleep(forTimeInterval: 0.500)
        }
        logger.debug("Showing experience counter now")
        let experienceCounter = windowManager.experiencePanel.experienceTracker
        experienceCounter.xpDisplay = "\(experience)/\(experienceNeeded)"
        experienceCounter.levelDisplay = "\(level+1)"
        experienceCounter.xpPercentage = (Double(experience) / Double(experienceNeeded))
        if animate {
            DispatchQueue.main.async {
                experienceCounter.needsDisplay = true
                self.windowManager.experiencePanel.visible = true
                self.updateExperienceOverlay()
                self.guiNeedsUpdate = true
            }
            Thread.sleep(forTimeInterval: Game.experienceFadeDelay)
        } else {
            DispatchQueue.main.async {
                experienceCounter.needsDisplay = true
                
            }
        }
        if currentMode != Mode.hub {
            windowManager.experiencePanel.visible = false
            guiNeedsUpdate = true
        }
    }

    func updateCardHud() {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            
            let tracker = self.windowManager.cardHudContainer
            
            if Settings.showCardHuds && self.shouldShowGUIElement && !self.gameEnded && !self.isBattlegroundsMatch() {
                tracker.update(entities: self.opponent.hand,
                                        cardCount: self.opponent.handCount)
                self.windowManager.show(controller: tracker, show: true,
                     frame: SizeHelper.cardHudContainerFrame(), title: nil,
                     overlay: self.hearthstoneRunState.isActive)
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
            
            if Settings.playerBoardDamage && self.shouldShowGUIElement && (self.currentGameMode != .battlegrounds && self.currentGameMode != .mercenaries) && self.isMulliganDone() {
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
            
            if Settings.opponentBoardDamage && self.shouldShowGUIElement && (self.currentGameMode != .battlegrounds && self.currentGameMode != .mercenaries) && self.isMulliganDone() {
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
				self.windowManager.arenaHelper.cardCount() == 3 &&
				((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive)
					|| !Settings.hideAllWhenGameInBackground ) {
                tracker.setWindowSizes()
                self.windowManager.arenaHelper.table?.reloadData()
				self.windowManager.show(controller: tracker, show: true, frame: SizeHelper.arenaHelperFrame(),
                                        title: nil, overlay: self.hearthstoneRunState.isActive)
			} else {
				self.windowManager.show(controller: tracker, show: false)
			}
		}
	}
    
    func updateBoardOverlay() {
        DispatchQueue.main.async {
            let oppTracker = self.windowManager.opponentBoardOverlay
            let playerTracker = self.windowManager.playerBoardOverlay

            let show = (!self.isMercenariesMatch() && Settings.showFlavorText) || (self.isMercenariesMatch())
            if !self.isInMenu && show || (self.isMulliganDone() || self.isMercenariesMatch()) && !self.gameEnded && ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground) {
                self.windowManager.show(controller: oppTracker, show: true, frame: SizeHelper.opponentBoardOverlay(), title: nil, overlay: self.hearthstoneRunState.isActive)
                oppTracker.updateBoardState(player: self.opponent)
                self.windowManager.show(controller: playerTracker, show: true, frame: SizeHelper.playerBoardOverlay(), title: nil, overlay: self.hearthstoneRunState.isActive)
                playerTracker.updateBoardState(player: self.player)
            } else {
                self.windowManager.show(controller: oppTracker, show: false)
                self.windowManager.show(controller: playerTracker, show: false)
            }
        }
    }
	
    func updateMercenariesTaskListButton() {
        DispatchQueue.main.async {
          let merc = self.windowManager.mercenariesTaskListButton
            if Settings.showMercsTasks && merc.visible && ((Settings.hideAllWhenGameInBackground && self.hearthstoneRunState.isActive) || !Settings.hideAllWhenGameInBackground) {
                let rect = SizeHelper.mercenariesTaskListButton()
                self.windowManager.show(controller: merc, show: true, frame: rect, title: nil, overlay: true)
            } else {
                self.windowManager.show(controller: self.windowManager.mercenariesTaskListView, show: false)
                self.windowManager.show(controller: merc, show: false)
            }
        }
    }
    
    func showBattlegroundsSession(_ show: Bool, _ force: Bool = false) {
        DispatchQueue.main.async {
            if show {
                if !Settings.showSessionRecap || !self.isAnyBattlegroundsSessionSettingActive() {
                    return
                }
                
                self.windowManager.battlegroundsSession.update()
                self.windowManager.battlegroundsSession.show()
                self.windowManager.battlegroundsSession.visibility = true
            } else {
                self.windowManager.battlegroundsSession.visibility = false
                self.windowManager.show(controller: self.windowManager.battlegroundsSession, show: false)
            }
            self.updateBattlegroundsOverlays()
            DispatchQueue.main.async {
                self.updateBattlegroundsOverlays()
            }
        }
    }
    
    func setBaconState(_ mode: SelectedBattlegroundsGameMode, _ isAnyOpen: Bool) {
        windowManager.tier7PreLobby.viewModel.battlegroundsGameMode = mode
        windowManager.tier7PreLobby.viewModel.isModalOpen = !queueEvents.isInQueue && isAnyOpen
        windowManager.battlegroundsSession.battlegroundsGameMode = mode
        if #available(macOS 10.15, *) {
            DispatchQueue.main.async {
                self.updateTier7PreLobbyVisibility()
            }
        }
    }
    
    func setBaconQueue(_ isAnyOpen: Bool) {
        if #available(macOS 10.15, *) {
            DispatchQueue.main.async {
                self.updateTier7PreLobbyVisibility()
            }
        }
    }
        
    @available(macOS 10.15, *)
    @MainActor
    func updateTier7PreLobbyVisibility() {
        let show = isRunning && isInMenu && !queueEvents.isInQueue && SceneHandler.scene == .bacon && Settings.enableTier7Overlay && Settings.showBattlegroundsTier7PreLobby && (windowManager.tier7PreLobby.viewModel.battlegroundsGameMode == .solo || windowManager.tier7PreLobby.viewModel.battlegroundsGameMode == .duos) && windowManager.tier7PreLobby.viewModel.visibility
        if show {
            Task.init {
                _ = await windowManager.tier7PreLobby.viewModel.update()
            }
            if Settings.showBattlegroundsTier7PreLobby || !(HSReplayAPI.accountData?.is_tier7 ?? false) {
                Task.init {
                    _ = await windowManager.tier7PreLobby.viewModel.update()
                }
            }
            if self.hearthstoneRunState.isActive {
                self.windowManager.tier7PreLobby.isVisible = true
                self.windowManager.show(controller: self.windowManager.tier7PreLobby, show: true, frame: SizeHelper.tier7PreLobbyFrame())
            }
        } else {
            self.windowManager.tier7PreLobby.isVisible = false
            self.windowManager.show(controller: self.windowManager.tier7PreLobby, show: false)
        }
    }

    // MARK: - Vars
    
    var buildNumber: Int = 0
    var playerIDNameMapping: [Int: String] = [:]
    
	var startTime: Date?
    var currentTurn = 0
    var lastId = 0
    var gameTriggerCount = 0
    var playerDeckAutodetected: Bool = false
    private var hasValidDeck = false
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
    private var _battlegroundsBoardState: BattlegroundsBoardState!
    
    private var _brawlInfo: BrawlInfo?
	
	var gameResult: GameResult = .unknown
	var wasConceded: Bool = false

    private var _spectator: Bool?
    var spectator: Bool {
        if _spectator == nil {
            _spectator = MirrorHelper.isSpectating()
        }
        return _spectator ?? false
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
        if currentMode == .gameplay, let gameType = MirrorHelper.getGameType(),
            let type = GameType(rawValue: gameType) {
            _currentGameType = type
        }
        return .gt_unknown
    }
    
    private var _serverInfo: MirrorGameServerInfo?
    var serverInfo: MirrorGameServerInfo? {
        if _serverInfo == nil {
            _serverInfo = MirrorHelper.getGameServerInfo()
        }
        return _serverInfo
    }

	var entities =  SynchronizedDictionary<Int, Entity>()
    var tmpEntities = SynchronizedArray<Entity>()
    var knownCardIds = SynchronizedDictionary<Int, [(String, DeckLocation)]>()
    var joustReveals = 0
    var dredgeCounter = 0

    var lastCardPlayed: Int?
    var gameEnded = true
    internal private(set) var currentDeck: PlayingDeck?

    var currentEntityHasCardId = false
    var playerUsedHeroPower = false
    private var hasCoin = false
    var currentEntityZone: Zone = .invalid
    var currentRegion = Region.unknown
    var opponentUsedHeroPower = false
	var wasInProgress = false
    var setupDone = false
    var secretsManager: SecretsManager?
    var proposedAttacker = 0
    var proposedDefender = 0
    var isDungeonMatch: Bool = false
    private var defendingEntity: Entity?
    private var attackingEntity: Entity?
    private var avengeDeathRattleCount = 0
    private var awaitingAvenge = false
    var isInMenu = true
    private var handledGameEnd = false
    
	var enqueueTime = LogDate(date: Date.distantPast)
    private var lastTurnStart: [Int] = [0, 0]
    private var turnQueue: ConcurrentSet<PlayerTurn> = ConcurrentSet()
    
	fileprivate var lastGameStartTimestamp: LogDate = LogDate(date: Date.distantPast)

    private var _matchInfoCacheInvalid = true
    private var _matchInfo: MatchInfo?
    
    private var _battlegroundsRatingInfo: MirrorBattlegroundRatingInfo?
    
    private var _mercenariesRating: Int?
    
    var mercenariesRating: Int? {
        if _mercenariesRating == nil {
            if let rating = MirrorHelper.getMercenariesRating() {
                _mercenariesRating = rating
            }
        }
        return _mercenariesRating
    }
    
    var mercenariesMapInfo: MirrorMercenariesMapInfo? {
        return MirrorHelper.getMercenariesMapInfo()
    }
    
    private var _availableRaces: [Race]?
    
    private var _unavailableRaces: [Race]?
    
    var adventureOpponentId: String?
    
    var hideBobsBuddy = false
    var hideBattlegroundsTier = false
    var hideBattlegroundsTurn = false
    
    var availableRaces: [Race]? {
        if _availableRaces == nil {
            if let races = MirrorHelper.getAvailableBattlegroundsRaces() {
                let newRaces = races.compactMap({ x in x.intValue > 0 && x.intValue < Race.allCases.count ? Race.allCases[x.intValue] : nil })
                logger.info("Battlegrounds available races: \(newRaces) - from mirror \(races)")
                if newRaces.count > 0 && newRaces.count == races.count {
                    _availableRaces = newRaces
                    return _availableRaces
                }
            }
        }
        return _availableRaces
    }
    
    var unavailableRaces: [Race]? {
        if _unavailableRaces == nil {
            if let races = availableRaces, races.count > 0 && races[0] != .invalid {
                var newRaces = [Race]()
                for race in Database.battlegroundRaces where !races.contains(race) {
                    newRaces.append(race)
                }
                if newRaces.count > 0 {
                    logger.info("Battlegrounds unavailable races: \(newRaces) - all races \(races)")
                    _unavailableRaces = newRaces
                    return _unavailableRaces
                } else {
                    return nil
                }
            }
        }
        return _unavailableRaces
    }

    var battlegroundsRatingInfo: MirrorBattlegroundRatingInfo? {
        if let info = _battlegroundsRatingInfo {
            return info
        }
        
        _battlegroundsRatingInfo = MirrorHelper.getBattlegroundsRatingInfo()
        
        logger.debug("Got battlegroundsRatingInfo=\(_battlegroundsRatingInfo ?? MirrorBattlegroundRatingInfo())")
        return _battlegroundsRatingInfo
    }
    
    var matchInfo: MatchInfo? {
        
        if _matchInfo != nil {
            return _matchInfo
        }
        
        if !self.gameEnded, let mInfo = MirrorHelper.getMatchInfo() {
            let matchInfo = MatchInfo(info: mInfo)
            logger.info("\(matchInfo.localPlayer.name)"
                + " vs \(matchInfo.opposingPlayer.name)"
                + " matchInfo: \(matchInfo)")            
            self.player.name = matchInfo.localPlayer.name
            self.opponent.name = matchInfo.opposingPlayer.name
            self.player.id = matchInfo.localPlayer.playerId
            self.opponent.id = matchInfo.opposingPlayer.playerId
            self._currentGameType = matchInfo.gameType

            let opponentStarLevel = matchInfo.opposingPlayer.standardMedalInfo.starLevel
            logger.info("LADDER opponentStarLevel=\(opponentStarLevel)")
            return matchInfo
        }
        return nil
    }
    
    var playerMedalInfo: MatchInfo.MedalInfo? {
        guard let localPlayer = matchInfo?.localPlayer, currentGameType == .gt_ranked else {
            return nil
        }
        switch currentFormat {
        case .standard:
            return localPlayer.standardMedalInfo
        case .wild:
            return localPlayer.wildMedalInfo
        case .classic:
            return localPlayer.classicMedalInfo
        case .twist:
            return localPlayer.twistMedalInfo
        default:
            return nil
        }
    }
	
    var arenaInfo: ArenaInfo? {
        if let _arenaInfo = MirrorHelper.getArenaDeck() {
            return ArenaInfo(info: _arenaInfo)
        }
        return nil
    }

    var brawlInfo: BrawlInfo? {
        if let brawlInfo = _brawlInfo {
            return brawlInfo
        }
        if let _brawlInfo = MirrorHelper.getBrawlInfo() {
            return BrawlInfo(info: _brawlInfo)
        }
        return nil
    }

    var playerEntity: Entity? {
        return entities.values.filter { $0[.player_id] == self.player.id }.sorted { $0.id < $1.id }.first
    }

    var opponentEntity: Entity? {
        return entities.values.filter { $0.has(tag: .player_id) && !$0.isPlayer(eventHandler: self) }.sorted { $0.id < $1.id }.first
    }

    var gameEntity: Entity? {
        return entities.values.first { $0.name == "GameEntity" }
    }

    var isMinionInPlay: Bool {
        return entities.values.first { $0.isInPlay && $0.isMinion } != nil
    }

    var isOpponentMinionInPlay: Bool {
        return entities.values
            .first { $0.isInPlay && $0.isMinion
                && $0.isControlled(by: self.opponent.id) } != nil
    }

    var opponentMinionCount: Int {
        return entities.values
            .filter { $0.isInPlay && $0.isMinion && !$0.has(tag: .untouchable)
                && $0.isControlled(by: self.opponent.id) }.count }
    
    var opponentBoardCount: Int {
        return entities.values
            .filter { $0.isInPlay && $0.takesBoardSlot
                && $0.isControlled(by: self.opponent.id) }.count
    }

    var playerMinionCount: Int {
        return entities.values
            .filter { $0.isInPlay && $0.isMinion
                && $0.isControlled(by: self.player.id) }.count }

    var playerBoardCount: Int {
        return entities.values
            .filter { $0.isInPlay && $0.takesBoardSlot
                && $0.isControlled(by: self.player.id) }.count }

    var opponentHandCount: Int {
        return entities.values
            .filter { $0.isInHand && $0.isControlled(by: self.opponent.id) }.count }
    
    var opponentSecretCount: Int {
        return entities.values
            .filter { $0.isSecret && $0.isControlled(by: self.opponent.id) }.count
    }
    
    var playerHandCount: Int {
        return entities.values
            .filter { $0.isInHand && $0.isControlled(by: self.player.id) }.count }

    var inAiMatch: Bool {
        return currentMode == Mode.gameplay && currentGameType == GameType.gt_vs_ai
    }
    
    var inAdventureScreen: Bool {
        return currentMode == Mode.adventure
    }
    
    var inPVPDungeonRunScreen: Bool {
        return currentMode == Mode.pvp_dungeon_run
    }
    
    var inPVPDungeonRunMatch: Bool {
        return currentMode == Mode.gameplay && previousMode == Mode.pvp_dungeon_run
    }
    
    var playerHeroId: String {
        return player.hero?.cardId ?? ""
    }

    var opponentHeroId: String {
        return opponent.hero?.cardId ?? ""
    }
    
    var opponentHeroHealth: Int {
        return opponent.hero?[.health] ?? 0
    }

    private var _currentFormatType = FormatType.ft_unknown
    var currentFormatType: FormatType {
        if _currentFormatType == .ft_unknown, let ft = FormatType(rawValue: MirrorHelper.getFormat() ?? 0) {
            _currentFormatType =  ft
        }
        return _currentFormatType
    }
    var currentFormat: Format {
        return Format(formatType: _currentFormatType) 
    }
    
    var lastPlagueDrawn: String?

	// MARK: - Lifecycle
    private var observers: [NSObjectProtocol] = []
    
    init(hearthstoneRunState: HearthstoneRunState) {
        self.hearthstoneRunState = hearthstoneRunState
		turnTimer = TurnTimer(gui: windowManager.timerHud)
        super.init()
        _battlegroundsBoardState = BattlegroundsBoardState(game: self)
		player = Player(local: true, game: self)
        opponent = Player(local: false, game: self)
        secretsManager = SecretsManager(game: self, availableSecrets: RemoteArenaSettings())
        secretsManager?.onChanged = { [weak self] cards in
            self?.updateSecretTracker(cards: cards)
        }
        mulliganState = MulliganState(game: self)
		
		windowManager.startManager()
        windowManager.playerTracker.window?.delegate = self
        windowManager.opponentTracker.window?.delegate = self
        windowManager.battlegroundsSession.window?.delegate = self
		
		let center = NotificationCenter.default
		
		// events that should update the player tracker
		let playerTrackerUpdateEvents = [Settings.show_player_tracker, Settings.rarity_colors, Settings.remove_cards_from_deck,
		                                 Settings.highlight_last_drawn, Settings.highlight_cards_in_hand, Settings.highlight_discarded,
		                                 Settings.show_player_get, Settings.player_draw_chance, Settings.player_card_count,
		                                 Settings.player_cthun_frame, Settings.player_yogg_frame, Settings.player_deathrattle_frame,
		                                 Settings.show_win_loss_ratio, Settings.player_in_hand_color, Settings.show_deck_name,
		                                 Settings.player_graveyard_details_frame, Settings.player_graveyard_frame,
                                         Settings.player_cards_top, Settings.player_cards_bottom, Settings.player_jade_frame,
                                         Settings.player_libram_counter, Settings.player_abyssal_counter, Settings.player_cards_top,
                                         Settings.player_cards_bottom, Settings.hide_player_sideboards]
		
		// events that should update the opponent's tracker
		let opponentTrackerUpdateEvents = [Settings.show_opponent_tracker, Settings.opponent_card_count, Settings.opponent_draw_chance,
		                                   Settings.opponent_cthun_frame, Settings.opponent_yogg_frame, Settings.opponent_deathrattle_frame,
		                                   Settings.show_opponent_class, Settings.opponent_graveyard_frame,
		                                   Settings.opponent_graveyard_details_frame,
                                           Settings.opponent_jade_frame, Settings.opponent_libram_counter, Settings.opponent_abyssal_counter]
		
		// events that should update all trackers
		let allTrackerUpdateEvents = [Settings.rarity_colors, Events.reload_decks, Settings.window_locked, Settings.auto_position_trackers,
		                              Events.space_changed, Events.hearthstone_closed, Events.hearthstone_running,
		                              Events.hearthstone_active, Events.hearthstone_deactived, Settings.can_join_fullscreen,
		                              Settings.hide_all_trackers_when_not_in_game, Settings.hide_all_trackers_when_game_in_background,
		                              Settings.card_size, Settings.theme_token]
        
        for option in playerTrackerUpdateEvents {
            let observer = center.addObserver(forName: NSNotification.Name(rawValue: option), object: nil, queue: OperationQueue.main) { _ in
                self.updatePlayerTracker()
            }
            self.observers.append(observer)
        }
        
        for option in opponentTrackerUpdateEvents {
            let observer = center.addObserver(forName: NSNotification.Name(rawValue: option), object: nil, queue: OperationQueue.main) { _ in
                self.updateOpponentTracker()
            }
            self.observers.append(observer)
        }
		
		for option in allTrackerUpdateEvents {
            let observer = center.addObserver(forName: NSNotification.Name(rawValue: option), object: nil, queue: OperationQueue.main) { _ in
                self.updateAllTrackers()
            }
            self.observers.append(observer)
		}
		
		// start gui updater thread
		_queue.async {
//			while true {
            self.internalUpdateCheck()
//				Thread.sleep(forTimeInterval: Game.guiUpdateDelay)
//			}
		}
    }
    
    deinit {
        for observer in self.observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private var counter = 0
    
    private func internalUpdateCheck() {
        if self.guiNeedsUpdate {
            self.guiNeedsUpdate = false
            self.updateAllTrackers()
            self.guiUpdateResets = false
            self.counter = 0
        } else if self.counter > 3 {
            let rect = SizeHelper.hearthstoneWindow.frame
            SizeHelper.hearthstoneWindow.reload()
            if rect != SizeHelper.hearthstoneWindow.frame {
                self.updateAllTrackers()
                self.updateBattlegroundsOverlays()
                self.updateConstructedMulliganOverlays()
            }
            self.counter = 0
        } else {
            self.counter += 1
        }
        
        self.updateBoardOverlay()

        _queue.asyncAfter(deadline: DispatchTime.now() + Game.guiUpdateDelay, execute: {
            self.internalUpdateCheck()
        })
    }

    func reset() {
        logger.verbose("Reseting Game")
        currentTurn = 0
        hasValidDeck = false
        gameId = UUID.init().uuidString

        playedCards.removeAll()
		
		self.gameResult = .unknown
		self.wasConceded = false

        lastId = 0
        gameTriggerCount = 0

        _matchInfo = nil
        _currentFormatType = .ft_unknown
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
		
		_spectator = nil
        _availableRaces = nil
        _unavailableRaces = nil
        _brawlInfo = nil
        _battlegroundsBoardState.reset()
        _battlegroundsHeroPickStatsParams = nil
        _battlegroundsHeroPickState = nil
        _mulliganGuideParams = nil
        windowManager.battlegroundsDetailsWindow.reset()
        DispatchQueue.main.async {
            self.windowManager.bobsBuddyPanel.resetDisplays()
        }
        updateTurnCounter(turn: 1)
        
        hideBobsBuddy = false
        hideBattlegroundsTier = false
        hideBattlegroundsTurn = false
        
        adventureOpponentId = nil
        dredgeCounter = 0
        
        OpponentDeadForTracker.reset()
    }
    
    func cacheBrawlInfo() {
        if let info = MirrorHelper.getBrawlInfo() {
            _brawlInfo = BrawlInfo(info: info)
        }
    }
    
    func cacheBattlegroundRatingInfo() {
        _battlegroundsRatingInfo = MirrorHelper.getBattlegroundsRatingInfo()
    }
    
    func cacheMercenariesRatingInfo() {
        if let rating = MirrorHelper.getMercenariesRating() {
            _mercenariesRating = rating
        }
    }
    
    func cacheSpectator() {
        _spectator = MirrorHelper.isSpectating()
    }
    
    func cacheGameType() {
        if let currentGameType = MirrorHelper.getGameType(), currentGameType != GameType.gt_unknown.rawValue {
            _currentGameType = GameType(rawValue: currentGameType) ?? .gt_unknown
        } else {
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                self.cacheGameType()
            }
        }
    }

	func set(activeDeckId: String?, autoDetected: Bool) {
		if let id = activeDeckId, let deck = RealmHelper.getDeck(with: id) {
			set(activeDeck: deck, autoDetected: autoDetected)
            hasValidDeck = true
            logger.info("has Valid Mirror Deck: \(deck.cards.count) cards")
		} else {
			currentDeck = nil
			player.playerClass = nil
			updateTrackers(reset: true)
            logger.info("no Valid Mirror Deck")
		}
	}
	
    func set(activeDeck deck: Deck, autoDetected: Bool) {
        Settings.activeDeck = deck.deckId
        playerDeckAutodetected = autoDetected
		
        var cards: [Card] = []
        for deckCard in deck.cards {
            if let card = Cards.by(cardId: deckCard.id) {
                card.count = deckCard.count
                cards.append(card)
            }
        }
        let deckId = deck.deckId
        let name = deck.name
        let hsDeckId = deck.hsDeckId.value
        let playerClass = deck.playerClass
        let heroId = deck.heroId
        let isArena = deck.isArena
        var sideboards = [Sideboard]()
        
        for sideboard in deck.sideboards {
            let s = Sideboard(ownerCardId: sideboard.ownerCardId, cards: sideboard.cards.compactMap { y in
                let card = Cards.by(cardId: y.id)
                card?.count = y.count
                return card
            })
            sideboards.append(s)
        }
        
        let shortid = DeckSerializer.serialize(deck: HearthDbConverter.toHearthDbDeck(deck: deck))
        DispatchQueue.main.async {
            cards = cards.sortCardList()
            self.currentDeck = PlayingDeck(id: deckId,
                                      name: name,
                                      hsDeckId: hsDeckId,
                                      playerClass: playerClass,
                                      heroId: heroId,
                                      cards: cards.sortCardList(),
                                      isArena: isArena,
                                      shortid: shortid ?? "",
                                      sideboards: sideboards)
            self.player.playerClass = self.currentDeck?.playerClass
            self.updateTrackers(reset: true)
        }
    }

    func removeActiveDeck() {
        currentDeck = nil
        Settings.activeDeck = nil
        updateTrackers(reset: true)
    }

    private func isValidPlayerInfo(playerInfo: MatchInfo.Player?, allowMissing: Bool = true) -> Bool {
        let name = playerInfo?.name ?? ""
        let valid = allowMissing || !name.isBlank
        logger.debug("valid=\(valid), gameMode=\(currentGameMode), player=\(name), starLevel=\(playerInfo?.standardMedalInfo.starLevel ?? 0)")
        return valid
    }
    
    func invalidateMatchInfoCache() {
        _matchInfoCacheInvalid = true
    }

    // MARK: - game state
    private func cacheMatchInfo() {
        if !_matchInfoCacheInvalid {
            return
        }
        DispatchQueue.global().async {
            var minfo: MatchInfo? = self.matchInfo
            while minfo == nil || !self.isValidPlayerInfo(playerInfo: minfo?.localPlayer) || !self.isValidPlayerInfo(playerInfo: minfo?.opposingPlayer, allowMissing: self.isMercenariesMatch()) {
                logger.info("Waiting for matchInfo... (matchInfo=\(String(describing: minfo)), localPlayer=\(self.matchInfo?.localPlayer.name ?? "Unknown"), opposingPlayer=\(self.matchInfo?.opposingPlayer.name ?? "Unknown"))")
                Thread.sleep(forTimeInterval: 1)
                minfo = self.matchInfo
            }
            if let minfo = minfo {
                self.updatePlayers(matchInfo: minfo)
                self._matchInfoCacheInvalid = false
                self._matchInfo = minfo
            }
        }
    }
    
    private func updatePlayers(matchInfo: MatchInfo) {
        func getName(player: MatchInfo.Player) -> String {
            if let btag = player.battleTag {
                return btag
            }
            return player.name
        }
        let pname = getName(player: matchInfo.localPlayer)
        player.name = pname
        let oname = getName(player: matchInfo.opposingPlayer)
        opponent.name = oname
        player.id = matchInfo.localPlayer.playerId
        opponent.id = matchInfo.opposingPlayer.playerId
        logger.info("\(pname) [PlayerId=\(player.id)] vs \(oname) [PlayerId=\(opponent.id)]")
    }
    
    private var lastGameStart = Date.distantPast
    func gameStart(at timestamp: LogDate) {
        invalidateMatchInfoCache()
        if currentGameMode == .practice && !isInMenu && !handledGameEnd
			&& lastGameStartTimestamp > LogDate(date: Date.distantPast)
            && timestamp > lastGameStartTimestamp {
            adventureRestart()
        }

        lastGameStartTimestamp = timestamp
        if lastGameStart > Date.distantPast
            && (abs(lastGameStart.timeIntervalSinceNow) < 5) {
            // game already started
            return
        }

        lastGameStart = Date()
        
        // remove every line before _last_ create game
        if let index = self.powerLog.reversed().firstIndex(where: { $0.line.contains("CREATE_GAME") }) {
            self.powerLog = self.powerLog.reversed()[...index].reversed() as [LogLine]
        } else {
            self.powerLog = []
        }
        
		gameEnded = false
        isInMenu = false
        handledGameEnd = false

        cacheMatchInfo()
        cacheGameType()
        cacheSpectator()

        logger.info("----- Game Started -----")
        logger.info("currentGameMode: \(currentGameMode), isInMenu: \(isInMenu), "
            + "handledGameEnd: \(handledGameEnd), "
            + "lastGameStartTimestamp: \(lastGameStartTimestamp), " +
            "timestamp: \(timestamp)")
        AppHealth.instance.setHearthstoneGameRunning(flag: true)

        NotificationManager.showNotification(type: .gameStart)

        if Settings.showTimer {
            self.turnTimer.start()
        }
		
		// update spectator information
        if spectator || currentGameMode == .mercenaries { // no deck for mercenaries
            set(activeDeckId: nil, autoDetected: false)
        }
        
        if isMercenariesPveMatch() {
            _ = MercenariesCoins.update()
        }
		
        updateTrackers(reset: true)

        self.startTime = Date()
        
        Analytics.trackEvent("match_start", withProperties: ["gameMode": "\(self.currentGameMode)",
                                                             "gameType": "\(self.currentGameType)",
                                                             "spectator": "\(self.spectator)"])
        
        windowManager.linkOpponentDeckPanel.isFriendlyMatch = isFriendlyMatch
        
        if isBattlegroundsMatch() && currentGameMode == .spectator {
            showBattlegroundsSession(true)
        }
        
        if isFriendlyMatch {
            if !Settings.interactedWithLinkOpponentDeck {
                windowManager.linkOpponentDeckPanel.autoShown = true
                windowManager.linkOpponentDeckPanel.show()
            }
        }
    }
    
    private var _lastReconnectStartTimestamp: Date = Date.distantPast
    func handleGameReconnect(timestamp: Date) {
        DispatchQueue.global().async {
            logger.info("Joined after mulligan, assuming reconnect.")
            
            if DateInterval(start: self._lastReconnectStartTimestamp, end: Date()).duration < 5.0 { // game already started
                return
            }
            self._lastReconnectStartTimestamp = timestamp
            
            for _ in 0 ..< 20 where self.gameEntity == nil || self.currentMode != .gameplay {
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            if self.gameEntity == nil || self.currentMode != .gameplay {
                return
            }
            
            if self.isBattlegroundsMatch() {
                if (self.gameEntity?[.step] ?? 0) > Step.begin_mulligan.rawValue {
                    self.windowManager.battlegroundsSession.update()
                    BattlegroundsLeaderboardWatcher.start()
                    if self.isBattlegroundsDuosMatch() {
                        BattlegroundsTeammateBoardStateWatcher.start()
                    }
                    self.updateBattlegroundsOverlays()
                }
            }
        }
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
        self.powerLog = []

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
        
        DispatchQueue.main.async {
            self.updateMulliganGuidePreLobby()
        }
    }
	
	private func generateEndgameStatistics() -> InternalGameStats? {
		let result = InternalGameStats()
		
		result.startTime = self.startTime ?? Date()
		result.endTime = Date()
		
		result.playerHero = currentDeck?.playerClass ?? player.playerClass ?? .neutral
		result.opponentHero = opponent.playerClass ?? .neutral
        
        let oppHero = entities.values.first(where: { x in x[.player_id] == opponent.id && x.isHero })

        result.opponentHeroCardId = oppHero?.cardId
		
		result.wasConceded = self.wasConceded
		result.result = self.gameResult
		
        result.hearthstoneBuild = self.buildNumber
		result.season = Database.currentSeason
		
		if let name = self.player.name {
			result.playerName = name
		}
		if let _player = self.entities.values.first(where: { $0.isPlayer(eventHandler: self) }) {
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
            let classic = self.currentFormat == .classic
            let twist = self.currentFormat == .twist
            
            let localPlayer = matchInfo.localPlayer
            let opposingPlayer = matchInfo.opposingPlayer
            
            let playerInfo = classic ? localPlayer.classicMedalInfo : wild ? localPlayer.wildMedalInfo : twist ? localPlayer.twistMedalInfo : localPlayer.standardMedalInfo
            let opponentInfo = classic ? opposingPlayer.classicMedalInfo : wild ? opposingPlayer.wildMedalInfo : twist ? opposingPlayer.twistMedalInfo : opposingPlayer.standardMedalInfo
            result.leagueId = playerInfo.leagueId
            if playerInfo.leagueId < 5 {
                result.rank = classic ? localPlayer.classicRank : wild ? localPlayer.wildRank : twist ? localPlayer.twistRank : localPlayer.standardRank
                result.opponentRank = classic ? opposingPlayer.classicRank : wild ? opposingPlayer.wildRank : twist ? opposingPlayer.twistRank : opposingPlayer.standardRank
            }
            result.starLevel = playerInfo.starLevel
            result.starMultiplier = playerInfo.starsPerWin
            result.stars = playerInfo.stars
            result.opponentStarLevel = opponentInfo.starLevel
            result.legendRank = playerInfo.legendRank
            result.opponentLegendRank = opponentInfo.legendRank
		} else if self.currentGameMode == .arena {
			result.arenaLosses = self.arenaInfo?.losses ?? 0
			result.arenaWins = self.arenaInfo?.wins ?? 0
		} else if self.currentGameMode == .brawl, let brawlInfo = self.brawlInfo {
			result.brawlWins = brawlInfo.wins
			result.brawlLosses = brawlInfo.losses
        } else if isBattlegroundsMatch(), let rating = self.currentBattlegroundsRating {
            result.battlegroundsRating = rating
        } else if isMercenariesMatch() {
            if isMercenariesPvpMatch(), let rating = self.mercenariesRating {
                result.mercenariesRating = rating
            }
            if isMercenariesPveMatch() {
                if let mapInfo = self.mercenariesMapInfo {
                    result.mercenariesBountyRunId = String(mapInfo.seed.intValue)
                    result.mercenariesBountyRunTurnsTaken = mapInfo.turnsTaken.intValue
                    result.mercenariesBountyRunCompletedNodes = mapInfo.completedNodes.intValue
                }
            }
            let delta = MercenariesCoins.update()
            if delta.count > 0 {
                result.mercenariesBountyRunRewards = delta
            }
        }
		
		result.gameType = self.currentGameType
		if let serverInfo = self.serverInfo {
			result.serverInfo = ServerInfo(info: serverInfo)
		}
		result.playerCardbackId = self.matchInfo?.localPlayer.cardBackId ?? 0
		result.opponentCardbackId = self.matchInfo?.opposingPlayer.cardBackId ?? 0
		result.friendlyPlayerId = self.matchInfo?.localPlayer.playerId ?? 0
        result.opposingPlayerId = self.matchInfo?.opposingPlayer.playerId ?? 0
		result.scenarioId = self.matchInfo?.missionId ?? 0
		result.brawlSeasonId = self.matchInfo?.brawlSeasonId ?? 0
		result.rankedSeasonId = self.matchInfo?.rankedSeasonId ?? 0
        
        let confirmedCards = self.player.revealedCards.filter { x in x.collectible } + self.player.knownCardsInDeck.filter { x in x.collectible && !x.isCreated }
        if let currentDeck, currentDeck.hsDeckId ?? 0 > 0 {
            result.hsDeckId = self.currentDeck?.hsDeckId
            result.setPlayerCards(currentDeck, confirmedCards)
            result.setPlayerSideboards(currentDeck.sideboards)
        }
        result.setOpponentCards(opponent.opponentCardList.filter { x in !x.isCreated })
		
        if currentGameType == .gt_battlegrounds || currentGameType == .gt_battlegrounds_friendly {
            result.battlegroundsRaces = self.availableRaces?.compactMap({ x in Race.allCases.firstIndex(of: x)}) ?? []
        }
        
        result.deckId = currentDeck?.id ?? ""
		
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
                
        // clear any left over hover
        DispatchQueue.main.async {
            self.windowManager.forceHideFloatingCard()
        }
        logger.verbose("End game: \(currentGameStats)")
        let stats = currentGameStats.toGameStats()
        invalidateMatchInfoCache()
        // reset the turn counter
        updateTurnCounter(turn: 1)
        
        if isMercenariesMatch() {
            updatePostGameMercenariesRating(gameStats: currentGameStats)
        }
        
        if isBattlegroundsMatch() {
            BobsBuddyInvoker.instance(gameId: gameId, turn: turnNumber())?.startShopping(isGameOver: true)
            OpponentDeadForTracker.reset()
            DispatchQueue.main.async {
                self.windowManager.battlegroundsTierOverlay.tierOverlay.reset()
            }
            updatePostGameBattlegroundsRating(gameStats: currentGameStats)
            recordBattlegroundsGame(gameStats: currentGameStats)
            windowManager.battlegroundsSession.onGameEnd(gameStats: currentGameStats)
            windowManager.battlegroundsHeroPicking.viewModel.reset()
            windowManager.battlegroundsQuestPicking.viewModel.reset()
            hideBattlegroundsHeroPanel()
        }
        if isConstructedMatch() {
            hideMulliganToast()
            DispatchQueue.main.async {
                self.player.mulliganCardStats = nil
                self.hideMulliganGuideStats()
            }
        }

        if let currentDeck = self.currentDeck {
            var skip = false
            if previousMode == Mode.adventure {
                let heroId = adventureOpponentId
                // don't add the result to statistics for Bob encounters
                if heroId == CardIds.NonCollectible.Neutral.BartenderBob || heroId == CardIds.NonCollectible.Neutral.BazaarBob {
                    skip = true
                }
            }
            if !skip, let deck = RealmHelper.getDeck(with: currentDeck.id) {
                
                RealmHelper.addStatistics(to: deck, stats: stats)
                if Settings.autoArchiveArenaDeck &&
                    self.currentGameMode == .arena && deck.isArena && deck.arenaFinished() {
                    RealmHelper.set(deck: deck, active: false)
                }
            }
        }
		
        if currentGameMode == .spectator && currentGameStats.result == .unknown {
            logger.info("Game was spectator mode without a game result."
                + " Probably exited spectator mode early.")
            return
        }

		self.syncStats(logLines: self.powerLog, stats: currentGameStats)
    }
    
    private func updatePostGameBattlegroundsRating(gameStats: InternalGameStats) {
        if let data = UploadMetaData.retryWhileNull(f: MirrorHelper.getBattlegroundsRatingChange) {
            gameStats.battlegroundsRatingAfter = data.ratingNew.intValue
        } else {
            logger.warning("Could not get battlegrounds rating")
        }
    }

    private func updatePostGameMercenariesRating(gameStats: InternalGameStats) {
        if let data = UploadMetaData.retryWhileNull(f: MirrorHelper.getMercenariesRating) {
            gameStats.mercenariesRating = data
        } else {
            logger.warning("Could not get mercenaries rating")
        }
    }

    private func syncStats(logLines: [LogLine], stats: InternalGameStats) {

        guard currentGameMode != .practice && currentGameMode != .none && currentGameMode != .spectator else {
            logger.info("Game was in \(currentGameMode), don't send to third-party")
            return
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
                Settings.hsReplayUploadFriendlyMatches) ||
            (isBattlegroundsMatch() &&
                Settings.hsReplayUploadBattlegroundsMatches) ||
            (stats.gameMode == .duels &&
                Settings.hsReplayUploadDuelsMatches) ||
            (stats.gameMode == .mercenaries && Settings.hsReplayUploadMercenariesMatches)) {
			
            let (uploadMetaData, statId) = UploadMetaData.generate(stats: stats, buildNumber: self.buildNumber,
                                                                   game: self )
			
            let showUploadNotification = stats.gameMode == .practice || stats.gameMode == .arena || stats.gameMode == .brawl || stats.gameMode == .ranked || stats.gameMode == .friendly || stats.gameMode == .casual || stats.gameMode == .spectator || stats.gameMode == .duels
            HSReplayAPI.getUploadToken { _ in
                
                LogUploader.upload(logLines: logLines, buildNumber: self.buildNumber,
                                   metaData: (uploadMetaData, statId)) { result in
                    if case UploadResult.successful(let replayId) = result {
                        if stats.gameMode == .battlegrounds {
                            Sentry.sendQueuedBobsBuddyEvents(shortId: replayId)
                        }
                        if showUploadNotification {
                            NotificationManager.showNotification(type: .hsReplayPush(replayId: replayId))
                        }
                        NotificationCenter.default
                            .post(name: Notification.Name(rawValue: Events.reload_decks), object: nil)
                    } else if case UploadResult.failed(let error) = result {
                        if stats.gameMode == .battlegrounds {
                            Sentry.sendQueuedBobsBuddyEvents(shortId: nil)
                        }
                        if showUploadNotification {
                            NotificationManager.showNotification(type: .hsReplayUploadFailed(error: error))
                        }
                    }
                }
            }
        } else {
            if stats.gameMode == .battlegrounds {
                Sentry.sendQueuedBobsBuddyEvents(shortId: nil)
            }
        }
    }
    
    func recordBattlegroundsGame(gameStats: InternalGameStats) {
        if spectator {
            return
        }
        let hero = entities.values.first(where: { x in x[.player_id] == player.id && x.isHero })
        let heroCardId = hero?.cardId
        let finalBoard = entities.values.filter({ x in x.isMinion && x.isInZone(zone: .play) && x.isControlled(by: player.id)}).compactMap({ x in x.copy() }).sorted(by: { x, y in
            x[.zone_position] < y[.zone_position]
        })
        let friendlyGame = currentGameType == .gt_battlegrounds_friendly || currentGameType == .gt_battlegrounds_duo_friendly
        let duos = isBattlegroundsDuosMatch()
        let placement = min(hero?[.player_leaderboard_place] ?? 0, duos ? 4 : 8)
        if let heroCardId = heroCardId, placement > 0 {
            BattlegroundsLastGames.instance.addGame(startTime: gameStats.startTime, endTime: gameStats.endTime, hero: BattlegroundsUtils.getOriginalHeroId(heroId: heroCardId), rating: gameStats.battlegroundsRating, ratingAfter: gameStats.battlegroundsRatingAfter, placement: placement, finalBoard: finalBoard, friendlyGame: friendlyGame, duos: duos)
            windowManager.battlegroundsSession.update()
        } else {
            logger.error("Missing data while trying to record battleground game")
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
    
    // return raw turn number, needed for BG
    func turn() -> Int {
        if let gameEntity = self.gameEntity {
            return gameEntity[.turn]
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
            self.player.onTurnStart()
            handleThaurissanCostReduction()
            secretsManager?.handlePlayerTurnStart()
        } else {
            opponent.onTurnStart()
            secretsManager?.handleOpponentTurnStart()
        }

        if turnQueue.count > 0 {
            return
        }

        var timeout = -1
        if player == .player && ((playerEntity?.has(tag: .timeout)) != nil) {
            timeout = playerEntity![.timeout]
        } else if player == .opponent && ((opponentEntity?.has(tag: .timeout)) != nil) {
            timeout = opponentEntity![.timeout]
        }
		
        turnTimer.startTurn(for: player, timeout: timeout)

        if player == .player && !isInMenu {
            // Clear some state that should never be active at the start of a turn in case another hiding mechanism fails
            DispatchQueue.main.async {
                // Clear some state that should never be active at the start of a turn in case another hiding mechanism fails
                self.hideMulliganGuideStats()
                self.player.mulliganCardStats = nil
                
                self.windowManager.battlegroundsHeroPicking.viewModel.reset()
                self.windowManager.battlegroundsQuestPicking.viewModel.reset()
                self.hideBattlegroundsHeroPanel()
                self.windowManager.battlegroundsSession.update()
            }
            
            if isBattlegroundsMatch() {
                DispatchQueue.main.async { [self] in
                    OpponentDeadForTracker.shoppingStarted(game: self)
                    if playerTurn.turn > 1 {
                        BobsBuddyInvoker.instance(gameId: self.gameId, turn: self.turnNumber() - 1)?.startShopping()
                        windowManager.battlegroundsTierOverlay.tierOverlay.onHeroPowers(heroPowers: self.player.board.filter { x in x.isHeroPower }.compactMap { x in x.cardId })
                    }
                }
            }

            NotificationManager.showNotification(type: .turnStart)
        }
        
        updateTurnCounter(turn: turnNumber())
        
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

    func isBattlegroundsMatch() -> Bool {
        return isBattlegroundsSoloMatch() || isBattlegroundsDuosMatch()
    }
    
    func isBattlegroundsSoloMatch() -> Bool {
        return currentGameType == .gt_battlegrounds || currentGameType == .gt_battlegrounds_friendly || currentGameType == .gt_battlegrounds_ai_vs_ai || currentGameType == .gt_battlegrounds_player_vs_ai
    }
    
    func isBattlegroundsDuosMatch() -> Bool {
        return currentGameType == .gt_battlegrounds_duo || currentGameType == .gt_battlegrounds_duo_vs_ai || currentGameType == .gt_battlegrounds_duo_friendly || currentGameType == .gt_battlegrounds_duo_ai_vs_ai
    }
    
    var currentBattlegroundsRating: Int? {
        return isBattlegroundsMatch() ? isBattlegroundsDuosMatch() ? battlegroundsRatingInfo?.duosRating.intValue : battlegroundsRatingInfo?.rating.intValue : nil
    }
    
    var isFriendlyMatch: Bool { return currentGameType == .gt_vs_friend }
    
    var isArenaMatch: Bool { return currentGameType == .gt_arena }
    
    func isAnyBattlegroundsSessionSettingActive() -> Bool {
        return Settings.showMinionsSection || Settings.showMMR || Settings.showLatestGames
    }
    
    func isMercenariesMatch() -> Bool {
        return currentGameType == .gt_mercenaries_ai_vs_ai || currentGameType == .gt_mercenaries_friendly || currentGameType == .gt_mercenaries_pve || currentGameType == .gt_mercenaries_pvp || currentGameType == .gt_mercenaries_pve_coop
    }
    
    func isMercenariesPvpMatch() -> Bool {
        return currentGameType == .gt_mercenaries_pvp
    }
    
    func isMercenariesPveMatch() -> Bool {
        return currentGameType == .gt_mercenaries_pve || currentGameType == .gt_mercenaries_pve_coop
    }
    
    func isConstructedMatch() -> Bool {
        return currentGameType == .gt_ranked || currentGameType == .gt_casual || currentGameType == .gt_vs_friend /*|| currentGameType == .gt_vs_ai */
    }
    
    func isMulliganDone() -> Bool {
        if isBattlegroundsMatch() {
                return true
        }
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
        let thaurissans = opponent.board.filter { x in
            (x.cardId == CardIds.Collectible.Neutral.EmperorThaurissan || x.cardId == CardIds.Collectible.Neutral.EmperorThaurissanWONDERS) && !x.has(tag: .silenced)
        }
        if thaurissans.isEmpty {
            return
        }

        handleOpponentHandCostReduction(value: thaurissans.count)
    }
    
    func handlePlayerDredge() {
        updatePlayerTracker()
    }
    
    func handlePlayerUnknownCardAddedToDeck() {
        for card in player.deck {
            card.info.deckIndex = 0
        }
    }
    
    func handlePlayerHandCostReduction(value: Int) {
        for card in player.hand {
            card.info.costReduction += value
        }
    }
    
    func handleOpponentHandCostReduction(value: Int) {
        for card in opponent.hand {
            card.info.costReduction += value
        }
    }
    
    func handleChameleosReveal(cardId: String) {
        self.opponent.predictUniqueCardInDeck(cardId: cardId, isCreated: false)
        self.updateOpponentTracker()
    }
    
    func handleEntityLostArmor(entity: Entity, value: Int) {
        if playerEntity?.isCurrentPlayer ?? false {
            secretsManager?.handleEntityLostArmor(entity: entity, value: value)
        }
    }
    
    func handleMercenariesStateChange() {
        updateBoardOverlay()
    }
    
    func handleCardCopy() {
        self.updateOpponentTracker()
    }
    
    func set(buildNumber: Int) {
        self.buildNumber = buildNumber
    }
    
    func add(playerName: String, for ID: Int) {
        self.playerIDNameMapping[ID] = playerName
    }
    
    func playerName(for ID: Int) -> String? {
        return self.playerIDNameMapping[ID]
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

    func playerPlay(entity: Entity, cardId: String?, turn: Int, parentCardId: String) {
        if cardId.isBlank {
            return
        }
        
        player.play(entity: entity, turn: turn)
        if let cardId = cardId, !cardId.isEmpty {
            playedCards.append(PlayedCard(player: .player, cardId: cardId, turn: turn))
        }

        secretsManager?.handleCardPlayed(entity: entity, parentCardId: parentCardId)
        updateTrackers()
    }

    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int) {
        if cardId.isBlank {
            return
        }
        player.handDiscard(entity: entity, turn: turn)
        updateTrackers()
    }

    func playerSecretPlayed(entity: Entity, cardId: String?, turn: Int, fromZone: Zone, parentCardId: String) {
        if cardId.isBlank { return }

        if !entity.isSecret {
            if entity.isQuest  && !entity.isQuestlinePart || entity.isSideQuest {
                player.questPlayedFromHand(entity: entity, turn: turn)
            } else if entity.isSigil {
                player.sigilPlayedFromHand(entity: entity, turn: turn)
            } else if entity.isObjective {
                player.objectivePlayedFromHand(entity: entity, turn: turn)
            }
            return
        }

        switch fromZone {
        case .deck:
            player.secretPlayedFromDeck(entity: entity, turn: turn)
        case .hand:
            player.secretPlayedFromHand(entity: entity, turn: turn)
            secretsManager?.handleCardPlayed(entity: entity, parentCardId: parentCardId)
        default:
            player.createInSecret(entity: entity, turn: turn)
            return
        }
        updateTrackers()
    }
    
    func handlePlayerLibramReduction(change: Int) {
        player.updateLibramReduction(change: change)
    }
    
    func handleOpponentLibramReduction(change: Int) {
        opponent.updateLibramReduction(change: change)
    }
    
    func handlePlayerAbyssalCurse(value: Int) {
        player.updateAbyssalCurse(value: value)
    }
    
    func handleOpponentAbyssalCurse(value: Int) {
        opponent.updateAbyssalCurse(value: value)
    }
    
    func handlePlayerTechLevel(entity: Entity, techLevel: Int) {
        guard techLevel >= 1 && techLevel <= 6 else { return }
        
        let playerId = entity[.player_id]
        
        if playerId > 0 {
            _battlegroundsBoardState.handlePlayerTechLevel(playerId, techLevel)
        }
    }
    
    func handlePlayerTriples(entity: Entity, triples: Int) {
        guard triples > 0 else { return }
        let techLevel = entity[.player_tech_level]
        guard techLevel >= 1 && techLevel <= 6 else { return }
        
        let playerId = entity[.player_id]
        
        if playerId > 0 {
            _battlegroundsBoardState.handlePlayerTriples(playerId, techLevel, triples)
        }
    }
    
    func handlePlayerBuddiesGained(entity: Entity, num: Int) {
        guard num > 0 else { return }
        
        let playerId = entity[.player_id]
        
        if playerId > 0 {
            _battlegroundsBoardState.handlePlayerBuddiesGained(playerId, num)
        }
    }
    
    func handlePlayerHeroPowerQuestRewardDatabaseId(entity: Entity, num: Int) {
        guard num > 0 else { return }

        let playerId = entity[.player_id]
        
        if playerId > 0 {
            _battlegroundsBoardState.handlePlayerHeroPowerQuestRewardDatabaseId(playerId, num)
        }
    }
    
    func handlePlayerHeroPowerQuestRewardCompleted(entity: Entity, num: Int) {
        guard num > 0 else { return }

        let playerId = entity[.player_id]

        if playerId > 0 {
            _battlegroundsBoardState.handlePlayerHeroPowerQuestRewardCompleted(playerId)
        }
    }
    
    func handlePlayerHeroQuestRewardDatabaseId(entity: Entity, num: Int) {
        guard num > 0 else { return }
        
        let playerId = entity[.player_id]
        
        if playerId > 0 {
            _battlegroundsBoardState.handlePlayerHeroQuestRewardDatabaseId(playerId, num)
        }
    }
    
    func handlePlayerHeroQuestRewardCompleted(entity: Entity, num: Int) {
        guard num > 0 else { return }
        
        let playerId = entity[.player_id]
        
        if playerId > 0 {
            _battlegroundsBoardState.handlePlayerHeroQuestRewardCompleted(playerId)
        }
    }
    
    @available(macOS 10.15.0, *)
    private func getBattlegroundsHeroPickStats() async -> BattlegroundsHeroPickStats? {
        if spectator {
            return nil
        }

        if !Settings.enableTier7Overlay {
            return nil
        }

        if RemoteConfig.data?.tier7?.disabled ?? false {
            // TODO: fix me
            //throw new HeroPickingDisabledException("Hero picking remotely disabled")
            return nil
        }

        let userOwnsTier7 = HSReplayAPI.accountData?.is_tier7 ?? false
        if !userOwnsTier7 && (Tier7Trial.remainingTrials ?? 0) == 0 {
            return nil
        }

        let parameters = getBattlegroundsHeroPickParams()

        // Avoid using a trial when we can't get the api params anyway.
        guard let parameters else {
            // FIXME: todo 
            //throw new HeroPickingException("Unable to get API parameters")
            return nil
        }

        // Use a trial if we can
        var token: String?
        if !userOwnsTier7 {
            if let acc = MirrorHelper.getAccountId() {
                token = await Tier7Trial.activate(hi: acc.hi.int64Value, lo: acc.lo.int64Value)
            }
            if token == nil {
                // FIXME: add
                //throw new HeroPickingException("Unable to get trial token")
                return nil
            }
        }

#if(DEBUG)
        logger.debug("Fetching Battlegrounds Hero Pick stats with parameters=\(parameters)...")
#endif

        // At this point the user either owns tier7 or has an active trial!

        let isDuos = isBattlegroundsDuosMatch()
        
        let stats = (token != nil && !userOwnsTier7) ?
            // trial
            isDuos ? await HSReplayAPI.getTier7DuosHeroPickStats(token: token, parameters: parameters) : await HSReplayAPI.getTier7HeroPickStats(token: token, parameters: parameters) :
            // tier 7
            isDuos ? await HSReplayAPI.getTier7DuosHeroPickStats(parameters: parameters) : await HSReplayAPI.getTier7HeroPickStats(parameters: parameters)

        if stats == nil {
            // FIXME: add
            //throw new HeroPickingException("Invalid server response")
        }

        return stats
    }
    
    private var _battlegroundsHeroPickStatsParams: BattlegroundsHeroPickStatsParams?
    
    func cacheBattlegroundsHeroPickParams() {
        if _battlegroundsHeroPickStatsParams != nil {
            return
        }

        guard let availableRaces else {
            return
        }

        guard let heroDbfIds = battlegroundsHeroPickState.offeredHeroDbfIds else {
            return
        }

        _battlegroundsHeroPickStatsParams = BattlegroundsHeroPickStatsParams(hero_dbf_ids: heroDbfIds, minion_types: availableRaces.compactMap { x in Int(Race.allCases.firstIndex(of: x)!) }, anomaly_dbf_id: BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: gameEntity), game_language: "\(Settings.hearthstoneLanguage ?? .enUS)", battlegrounds_rating: battlegroundsRatingInfo?.rating.intValue)
    }
    
    private func getBattlegroundsHeroPickParams() -> BattlegroundsHeroPickStatsParams? {
        return _battlegroundsHeroPickStatsParams
    }
    
    private var _battlegroundsHeroPickState: BattlegroundsHeroPickState?
    private var battlegroundsHeroPickState: BattlegroundsHeroPickState {
        if let state = _battlegroundsHeroPickState {
            return state
        }
        let state = BattlegroundsHeroPickState(self)
        _battlegroundsHeroPickState = state

        return state
    }
    
    func snapshotBattlegroundsOfferedHeroes(_ heroes: [Entity]) {
        _ = battlegroundsHeroPickState.snapshotOfferedHeroes(heroes)
    }
    func snapshotBattlegroundsHeroPick() {
        _ = battlegroundsHeroPickState.snapshotPickedHero()
    }
    
    @MainActor
    private func showBattlegroundsHeroPickingStats(_ heroStats: [BattlegroundsHeroPickStats.BattlegroundsSingleHeroPickStats], _ parameters: [String: String]?, _ minMmr: Int?, _ anomalyAdjusted: Bool) {
        if #available(macOS 10.15, *) {
            Task.detached {
                await self.windowManager.battlegroundsHeroPicking.viewModel.setHeroStats(stats: heroStats, parameters: parameters, minMmr: minMmr, anomalyadjusted: anomalyAdjusted)
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    private func waitForMulliganStart(_ timeout: Int = 60) async {
        for _ in 0 ..< 16*60*timeout {
            if isInMenu || (gameEntity?[.step] ?? 0) > Step.begin_mulligan.rawValue {
                return
            }
            if MirrorHelper.isMulliganWaitingForUserInput() {
                break
            }
            do {
                try await Task.sleep(nanoseconds: 16_000_000)
            } catch {
                logger.error(error)
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    private func handleBattlegroundsStart() async {
        BattlegroundsLeaderboardWatcher.start()
        OpponentDeadForTracker.reset()
        var heroes = [Entity]()
        for _ in 0 ..< 10 {
            await Task.sleep(seconds: 500)
            heroes = player.playerEntities.filter { x in x.isHero && (x.has(tag: .bacon_hero_can_be_drafted) || x.has(tag: .bacon_skin))}
            if heroes.count >= 2 {
                break
            }
        }

        await Task.sleep(seconds: 500)
        
        await windowManager.battlegroundsSession.update()
        
        if isBattlegroundsDuosMatch() {
            BattlegroundsTeammateBoardStateWatcher.start()
        }
        
        if gameEntity?[.step] != Step.begin_mulligan.rawValue {
            return
        }

        snapshotBattlegroundsOfferedHeroes(heroes)
        cacheBattlegroundsHeroPickParams()

        let heroIds = heroes.sorted(by: { (a, b) -> Bool in a.zonePosition < b.zonePosition }).compactMap { x in x.card.dbfId }
            
        async let statsTask = getBattlegroundsHeroPickStats()
                
        // Wait for the mulligan to be ready
        await waitForMulliganStart()
        
        async let waitAndAppear: () = Task.sleep(seconds: 500)
        
        var battlegroundsHeroPickStats: BattlegroundsHeroPickStats?
        
        let (finalResults, _) = await (statsTask, waitAndAppear)
        battlegroundsHeroPickStats = finalResults
            
        var toastParams: [String: String]?
            
        if let stats = battlegroundsHeroPickStats {
            toastParams = stats.toast.parameters
            DispatchQueue.main.async {
                self.showBattlegroundsHeroPickingStats(heroIds.compactMap { dbfId in stats.data.first { x in x.hero_dbf_id == dbfId }}, stats.toast.parameters, stats.toast.min_mmr, stats.toast.anomaly_adjusted ?? false)
            }
        }
        // TODO: handle errors, exceptions
            
        if Settings.showHeroToast {
            showBattlegroundsHeroPanel(heroIds, isBattlegroundsDuosMatch(), toastParams)
        }
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
        if cardId == CardIds.NonCollectible.Neutral.TheCoinBasic {
            playerGet(entity: entity, cardId: cardId, turn: turn)
        } else {
            player.draw(entity: entity, turn: turn)
            updateTrackers()
        }
        secretsManager?.handleCardDrawn(entity: entity)
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

    func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int, playersTurn: Bool) {
        player.playToGraveyard(entity: entity, cardId: cardId, turn: turn)
        if playersTurn && entity.isMinion {
            playerMinionDeath(entity: entity)
        }
        
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
            entity.cardId = CardIds.NonCollectible.Neutral.TheCoinBasic
        }

        opponent.createInHand(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int) {
        opponent.boardToHand(entity: entity, turn: turn)
        updateTrackers()
    }
    
    func opponentHandToDeck(entity: Entity, cardId: String?, turn: Int) {
        if cardId != nil && cardId != "" && entity.has(tag: .tradeable) {
            opponent.predictUniqueCardInDeck(cardId: cardId ?? "", isCreated: false)
        }
        opponent.handToDeck(entity: entity, turn: turn)
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
            if entity.isQuest && !entity.isQuestlinePart || entity.isSideQuest {
                opponent.questPlayedFromHand(entity: entity, turn: turn)
            } else if entity.isSigil {
                opponent.sigilPlayedFromHand(entity: entity, turn: turn)
            } else if entity.isObjective {
                opponent.objectivePlayedFromHand(entity: entity, turn: turn)
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

    func opponentDraw(entity: Entity, turn: Int, cardId: String, drawerId: Int?) {
        entity.info.drawerId = drawerId
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
        if !playersTurn && entity.info.wasTransformed {
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 3.0)
                if let transformedSecret = self.secretsManager?.secrets.filter({ x in x.entity.id == entity.id }).first {
                    self.secretsManager?.removeSecret(entity: transformedSecret.entity)
                }
            }
        }
        updateTrackers()
    }
    
    func getMaestraDbfid() -> Int {
        return Cards.by(cardId: CardIds.NonCollectible.Neutral.MaestraoftheMasquerade_DisguiseEnchantment)?.dbfId ?? -1
    }
    
    func isMaestraHero(entity: Entity) -> Bool {
        return entity.isHero && entity[GameTag.creator_dbid] == getMaestraDbfid()
    }

    func OpponentIsDisguisedRogue() {
        set(opponentHero: CardIds.Collectible.Rogue.ValeeraSanguinar)
        //Core.Overlay.SetWinRates()
        opponent.predictUniqueCardInDeck(cardId: CardIds.Collectible.Rogue.MaestraOfTheMasquerade, isCreated: false)
        updateOpponentTracker()
    }
    
    func opponentJoust(entity: Entity, cardId: String?, turn: Int) {
        opponent.joustReveal(entity: entity, turn: turn)
        updateTrackers()
    }

    func opponentGetToDeck(entity: Entity, turn: Int) {
        opponent.createInDeck(entity: entity, turn: turn)
        updateTrackers()
    }
    
    func handleOpponentSecretRemove(entity: Entity, cardId: String?, turn: Int) {
        if !entity.isSecret {
            return
        }
        opponent.removeFromPlay(entity: entity, turn: turn)
        secretsManager?.removeSecret(entity: entity)
        updateOpponentTracker()
    }

    func opponentSecretTrigger(entity: Entity, cardId: String?, turn: Int, otherId: Int) {
        if !entity.isSecret { return }

        opponent.secretTriggered(entity: entity, turn: turn)
        secretsManager?.removeSecret(entity: entity)
        
        if isBattlegroundsMatch() && Settings.showBobsBuddy {
            BobsBuddyInvoker.instance(gameId: gameId, turn: turnNumber())?.updateOpponentSecret(entity: entity)
        }
    }

    func opponentFatigue(value: Int) {
        opponent.fatigue = value
        updateTrackers()
    }

    func opponentCreateInPlay(entity: Entity, cardId: String?, turn: Int) {
        if isMaestraHero(entity: entity) {
            OpponentIsDisguisedRogue()
        }
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
        
    func handleBattlegroundsPlayerQuestPicked(entity: Entity) {
        if isBattlegroundsMatch() {
            if #available(macOS 10.15, *) {
                Task.detached {
                    self.windowManager.battlegroundsQuestPicking.viewModel.reset()
                }
            }
        }
    }

    func handleBattlegroundsPlayerQuestPickerRemoval(entity: Entity) {
        if isBattlegroundsMatch() {
            if #available(macOS 10.15, *) {
                Task.detached {
                    self.windowManager.battlegroundsQuestPicking.viewModel.reset()
                }
            }
        }
    }
        
    func handleQuestRewardDatabaseId(id: Int, value: Int) {
        if isBattlegroundsMatch(), let entity = entities[id], entity.isControlled(by: player.id) {
            if #available(macOS 10.15, *) {
                Task.detached {
                    await self.windowManager.battlegroundsQuestPicking.viewModel.onBattlegroundsQuest(questEntity: entity)
                }
            }
        }
    }

    // MARK: - Game actions
    func defending(entity: Entity?) {
        self.defendingEntity = entity
        guard let attackingEntity = self.attackingEntity, let defendingEntity = self.defendingEntity, let entity = entity else {
            return
        }
        if entity.isControlled(by: opponent.id) {
            secretsManager?.handleAttack(attacker: attackingEntity, defender: defendingEntity)
        }
        attackEvent()
    }

    func attacking(entity: Entity?) {
        self.attackingEntity = entity
        guard let attackingEntity = self.attackingEntity, let defendingEntity = self.defendingEntity, let entity = entity else {
            return
        }
        if entity.isControlled(by: player.id) {
            secretsManager?.handleAttack(attacker: attackingEntity, defender: defendingEntity)
        }
        attackEvent()
    }
    
    private func attackEvent() {
        if isBattlegroundsMatch() && Settings.showBobsBuddy, let attackingEntity = attackingEntity, let defendingEntity = defendingEntity {
            BobsBuddyInvoker.instance(gameId: gameId, turn: turnNumber())?.updateAttackingEntities(attacker: attackingEntity, defender: defendingEntity)
        }
    }
    
    func handleProposedAttackerChange(entity: Entity) {
        if isBattlegroundsMatch() && Settings.showBobsBuddy {
            BobsBuddyInvoker.instance(gameId: gameId, turn: turnNumber())?.handleNewAttackingEntity(newAttacker: entity)
        }
    }

    func playerMinionPlayed(entity: Entity) {
        secretsManager?.handleMinionPlayed(entity: entity)
    }
    
    func playerMinionDeath(entity: Entity) {
        secretsManager?.handlePlayerMinionDeath(entity: entity)
    }

    func opponentMinionDeath(entity: Entity, turn: Int) {
        secretsManager?.handleOpponentMinionDeath(entity: entity)
    }

    func opponentTurnStart(entity: Entity) {

    }
    
    func entityPredamage(entity: Entity, damage: Int) {
    }
    
    func entityDamage(dealer: Entity, entity: Entity, damage: Int) {
        if player.entity?.isCurrentPlayer ?? false {
            secretsManager?.entityDamage(dealer: dealer, target: entity, damage: damage)
        }
    }

    func startCombat() {
        snapshotBattlegroundsBoardState()
        
        BobsBuddyInvoker.instance(gameId: gameId, turn: turnNumber())?.startCombat()
    }
    
    var chameleosReveal: (Int, String)?
	
	// MARK: - Arena
	
	func setArenaOptions(cards: [Card]) {
		self.windowManager.arenaHelper.set(cards: cards)
		self.updateArenaHelper()
	}
    
    // MARK: - Mulligan
    
    @MainActor
    func showMulliganGuideStats(stats: [SingleCardStats], maxRank: Int, selectedParams: [String: String?]?) {
        windowManager.constructedMulliganGuide.viewModel.setMulliganData(stats: stats, maxRank: maxRank, selectedParams: selectedParams)
    }
    
    @MainActor
    func hideMulliganGuideStats() {
        windowManager.constructedMulliganGuide.viewModel.reset()
    }
    
    func handleBeginMulligan() {
        if isBattlegroundsMatch() {
            if #available(macOS 10.15, *) {
                Task.detached {
                    await self.handleBattlegroundsStart()
                }
            }
        } else if isConstructedMatch() || isFriendlyMatch || isArenaMatch {
            if #available(macOS 10.15, *) {
                Task.detached {
                    await self.handleHearthstoneMulliganPhase()
                }
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    func handlePlayerMulliganDone() async {
        if isBattlegroundsMatch() {
            snapshotBattlegroundsHeroPick()
            hideBattlegroundsHeroPanel()
            windowManager.battlegroundsHeroPicking.viewModel.reset()
        } else if isConstructedMatch() || isFriendlyMatch || isArenaMatch {
            hideMulliganToast()
            
            let openingHand = snapshotOpeningHand()
            
            if let mulliganCardStats, Settings.enableMulliganGuide {
                let numSwappedCards = self.getMulliganSwappedCards()?.count ?? 0
                if numSwappedCards > 0 {
                    // show the updated cards
                    let dbfIds = openingHand.compactMap { x in x.card.deckbuildingCard.dbfId }
                    if dbfIds.count > 0 {
                        DispatchQueue.main.async {
                            self.showMulliganGuideStats(stats: dbfIds.compactMap { dbfId in
                                if let l = mulliganCardStats[dbfId] {
                                    return l
                                } else {
                                    return SingleCardStats(dbf_id: dbfId)
                                }
                            }, maxRank: mulliganCardStats.count, selectedParams: nil)
                        }
                    }
                }
                // Delay until the cards fly away
                do {
                    try await Task.sleep(nanoseconds: 2_375_000_000 + UInt64(max(1, numSwappedCards)) * 475_000_000)
                } catch {
                    logger.error(error)
                }
                
                // Wait for the mulligan to be complete (component or animation)
                for _ in 0 ..< 7_500 { // 2 minutes
                    if isInMenu || (gameEntity?[.step] ?? 0) > Step.begin_mulligan.rawValue {
                        DispatchQueue.main.async {
                            self.hideMulliganGuideStats()
                            self.player.mulliganCardStats = nil
                        }
                        return
                    }
                    if (playerEntity?[.mulligan_state] ?? 0) >= Mulligan.done.rawValue && (opponentEntity?[.mulligan_state] ?? 0) >= Mulligan.done.rawValue {
                        break
                    }
                    do {
                        try await Task.sleep(nanoseconds: 16_000_000)
                    } catch {
                        logger.error(error)
                    }
                }
                DispatchQueue.main.async {
                    self.hideMulliganGuideStats()
                    self.player.mulliganCardStats = nil
                }
            }
        }
    }

    func handlePlayerSendChoices(choice: Choice) {
        if choice.choiceType == .mulligan {
            if isBattlegroundsMatch() {
                if choice.chosenEntities.count == 1 {
                    let hero = choice.chosenEntities.first
                    let heroPower = Cards.by(dbfId: hero?[.hero_power], collectible: false)?.id
                    if let hp = heroPower {
                        windowManager.battlegroundsTierOverlay.tierOverlay.onHeroPowers(heroPowers: [ hp ])
                    }
                } else {
                    logger.error("Could not reliably determine Battlegrounds hero power. \(choice.chosenEntities.count) hero(es) chosen.")
                }
                self.windowManager.battlegroundsQuestPicking.viewModel.reset()
            } else if isConstructedMatch() || isFriendlyMatch || isArenaMatch {
                _ = snapshotMulliganChoices(choice: choice)
            }
        } else if isBattlegroundsMatch() {
            windowManager.battlegroundsQuestPicking.viewModel.reset()
        }
    }
    
    @available(macOS 10.15.0, *)
    func handleHearthstoneMulliganPhase() async {
        for _ in 0 ..< 10 {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                logger.error(error)
            }
            let step = gameEntity?[.step] ?? 0
            if step == 0 {
                continue
            }
            if step > Step.begin_mulligan.rawValue {
                break
            }
            
            _ = snapshotMulligan()
            cacheMulliganGuideParams()
            
            var showToast = Settings.showMulliganToast && !isArenaMatch
            if showToast || Settings.enableMulliganGuide {
                if let currentDeck = currentDeck {
                    // Show Mulligan Guide Elements (Overlay and/or Toast)
                    let shortId = currentDeck.shortid
                    if !shortId.isEmpty {
                        let cards = player.playerEntities.filter { x in x.isInHand && !x.info.created }
                        let dbfIds = cards.sorted(by: { (a, b) in a.zonePosition < b.zonePosition }).compactMap { x in x.card.deckbuildingCard.dbfId }
                        var mulliganGuideData: MulliganGuideData?
                        
                        if Settings.enableMulliganGuide {
                            mulliganGuideData = await getMulliganGuideData()
                        }
                        
                        if let data = mulliganGuideData {
                            // Show mulligan guide with parameters as selected by the API
                            if showToast {
                                showMulliganToast(shortId, dbfIds, data.toast?.parameters, true)
                                showToast = false
                            }
                            
                            await waitForMulliganStart()
                            
                            var cardStats: [Int: SingleCardStats]?
                            // GroupBy before ToDictionary to deal with (unsupported) dbfId duplicates from the server
                            let grouped = Dictionary(uniqueKeysWithValues: data.deck_dbf_id_list.group({ x in x.dbf_id }).compactMap { x in (x.key, x.value[0])})
                            
                            cardStats = SingleCardStats.groupCardStats(stats: grouped, baseWinRate: data.base_winrate)
                            if let cardStats {
                                mulliganCardStats = cardStats
                                player.mulliganCardStats = Array(cardStats.values)
                                DispatchQueue.main.async {
                                    self.showMulliganGuideStats(stats: dbfIds.compactMap({ dbfId in
                                        if let stats = cardStats[dbfId] {
                                            return stats
                                        }
                                        return SingleCardStats(dbf_id: dbfId)
                                    }), maxRank: cardStats.count, selectedParams: data.selected_params)
                                }
                            }
                            // Something went wrong generating the card stats, continue to locally generated toast (if enabled)
                        }
                        
                        if showToast {
                            var parameters: [String: String]?
                            if !shortId.isEmpty {
                                let opponentClass = opponent.playerEntities.first { x in x.isHero && x.isInPlay }?.card.playerClass ?? CardClass.invalid
                                let isFirst = playerEntity?[.first_player] == 1
                                // Show mulligan toast with locally sourced parameters
                                parameters = [
                                    "opponentClasses": opponentClass.rawValue.uppercased(),
                                    "playerInitiative": isFirst ? "FIRST" : "COIN"
                                ]
                                
                                let playerStarLevel = playerMedalInfo?.starLevel ?? 0
                                if playerStarLevel > 0 {
                                    parameters?["mulliganPlayerStarLevel"] = String(playerStarLevel)
                                }
                                // Let the website do it's thing and fallback for non-Premium users
                                parameters?["mulliganAutoFilter"] = "yes"
                            }
                            showMulliganToast(shortId, dbfIds, parameters)
                        }
                    }
                }
            }
            break
        }
    }
    
    func getMulliganSwappedCards() -> [Entity]? {
        let offered = mulliganState.offeredCards
        let kept = mulliganState.keptCards

        // assemble a list of cards that were
        var retval = [Entity]()
        for card in offered where !kept.contains(card) {
            retval.append(card)
        }

        return retval
    }

    var mulliganCardStats: [Int: SingleCardStats]?

    func snapshotOpeningHand() -> [Entity] {
        return mulliganState.snapshotOpeningHand()
    }
    
    func snapshotMulliganChoices(choice: Choice) -> [Entity] {
        return mulliganState.snapshotMulliganChoices(choice: choice)
    }
    
    func snapshotMulligan() -> [Entity] {
        return mulliganState.snapshotMulligan()
    }
    
    func cacheMulliganGuideParams() {
        if _mulliganGuideParams != nil {
            return
        }
        
        guard let activeDeck = currentDeck else {
            return
        }

        let opponentClass = opponent.playerEntities.first { x in x.isHero && x.isInPlay }?.card.playerClass ?? CardClass.invalid
        let starLevel = playerMedalInfo?.starLevel ?? 0
        let starsPerWin = playerMedalInfo?.starsPerWin ?? 0

        _mulliganGuideParams = MulliganGuideParams(deckstring: activeDeck.shortid, game_type: BnetGameType.getBnetGameType(gameType: currentGameType, format: currentFormat).rawValue, format_type: currentFormatType.rawValue, opponent_class: opponentClass.rawValue.uppercased(), player_initiative: playerEntity?[.first_player] == 1 ? "FIRST" : "COIN", player_star_level: starLevel > 0 ? starLevel : nil, player_star_multiplier: starsPerWin > 0 ? starsPerWin : nil, player_region: Region.toBnetRegion(region: currentRegion))
    }
    
    @available(macOS 10.15.0, *)
    func getMulliganGuideData() async -> MulliganGuideData? {
        if spectator {
            return nil
        }
        //            if(Remote.Config.Data?.MulliganGuide?.Disabled ?? false)
        //{
        // return nil
        //}
        let userOwnsPremium = HSReplayAPI.accountData?.is_premium ?? false
        if !userOwnsPremium {
            // No trial support yet
            return nil
        }
        // Assemble request
        guard let parameters = getMulliganGuideParams() else {
            return nil
        }
        
        return await HSReplayAPI.getMulliganGuideData(parameters: parameters)
    }
    
    private func getMulliganGuideParams() -> MulliganGuideParams? {
        return _mulliganGuideParams
    }
    
    @MainActor
    private func showMulliganGuidePreLobby() {
        windowManager.constructedMulliganGuidePreLobby.isVisible = true
        let frame = SizeHelper.constructedMulliganGuidePreLobbyFrame()
        windowManager.show(controller: windowManager.constructedMulliganGuidePreLobby, show: true, frame: frame)
        DispatchQueue.main.async {
            self.windowManager.constructedMulliganGuidePreLobby.updateScaling()
        }
    }
    
    @MainActor
    private func hideMulliganGuidePreLobby() {
        windowManager.constructedMulliganGuidePreLobby.isVisible = false
        windowManager.show(controller: windowManager.constructedMulliganGuidePreLobby, show: false)
    }
    
    @MainActor
    func updateMulliganGuidePreLobby() {
        let isPremium = HSReplayAPI.accountData?.is_premium ?? false
        
        let show = isInMenu && SceneHandler.scene == .tournament && Settings.enableMulliganGuide &&  Settings.showMulliganGuidePreLobby && isPremium
        if show {
            showMulliganGuidePreLobby()
            if #available(macOS 10.15.0, *) {
                Task.detached { [self] in
                    await windowManager.constructedMulliganGuidePreLobby.viewModel.ensureLoaded()
                }
            }
        } else {
            hideMulliganGuidePreLobby()
        }
    }
    
    func setDeckPickerState(_ vft: VisualsFormatType, _ decksList: [CollectionDeckBoxVisual?], _ isModalOpen: Bool) {
        let vm = windowManager.constructedMulliganGuidePreLobby.viewModel
        if vm.decksOnPage == nil || decksList != vm.decksOnPage {
            vm.decksOnPage = decksList
        }
        vm.visualsFormatType = vft
        vm.isModalOpen = isModalOpen
    }
    
    func setConstructedQueue(_ inQueue: Bool) {
        windowManager.constructedMulliganGuidePreLobby.viewModel.isInQueue = inQueue
    }
    
    private let _mulliganToast = MulliganToastView(frame: NSRect.zero)
    func showMulliganToast(_ shortId: String, _ dbfIds: [Int], _ parameters: [String: String]?, _ showingMulliganStats: Bool = false) {
        DispatchQueue.main.async {
            self._mulliganToast.update(shortId, dbfIds, parameters, showingMulliganStats: showingMulliganStats)
            if self._mulliganToast.shouldShow() {
                AppDelegate.instance().coreManager.toaster.displayToast(view: self._mulliganToast, timeoutMillis: 0)
            }
        }
    }
    
    func showBattlegroundsHeroPanel(_ heroIds: [Int], _ duos: Bool, _ parameters: [String: String]?) {
        DispatchQueue.main.async {
            let toast = BgHeroesToastView(frame: NSRect.zero)
            toast.heroIds = heroIds
            toast.duos = duos
            toast.anomalyDbfId = BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: self.gameEntity)
            toast.parameters = parameters
            
            AppDelegate.instance().coreManager.toaster.displayToast(view: toast, timeoutMillis: 0)
        }
    }
    
    func hideBattlegroundsHeroPanel() {
        DispatchQueue.main.async {
            AppDelegate.instance().coreManager.toaster.hide()
        }
    }
    
    func hideMulliganToast() {
        DispatchQueue.main.async {
            AppDelegate.instance().coreManager.toaster.hide()
        }
    }
    
    private(set) var duosWasPlayerHeroModified: Bool = false
    private(set) var duosWasOpponentHeroModified: Bool = false

    func duosSetHeroModified(_ isPlayer: Bool) {
        if isPlayer {
            duosWasPlayerHeroModified = true
        } else {
            duosWasOpponentHeroModified = true
        }
    }

    func duosResetHeroTracking() {
        duosWasPlayerHeroModified = false
        duosWasOpponentHeroModified = false
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
        } else if window == self.windowManager.battlegroundsSession.window {
            if !window.frame.isEmpty && !window.frame.isInfinite {
                Settings.battlegroundsSessionFrame = window.frame
            }
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

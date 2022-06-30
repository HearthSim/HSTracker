//
//  WindowManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 20/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class WindowManager {
	
	var hearthstoneActive = false
	
    static let cardWidth: CGFloat = {
        switch Settings.cardSize {
        case .tiny: return CGFloat(kTinyFrameWidth)
        case .small: return CGFloat(kSmallFrameWidth)
        case .medium: return CGFloat(kMediumFrameWidth)
        case .big: return CGFloat(kFrameWidth)
        case .huge: return CGFloat(kHighRowFrameWidth)
        }
    }()
    static let screenFrame: NSRect = {
        return NSScreen.main!.frame
    }()
    static let top: CGFloat = {
        return screenFrame.height - 50
    }()

    var playerTracker: Tracker = {
        $0.playerType = .player
        return $0
    }(Tracker(windowNibName: "Tracker"))

    var opponentTracker: Tracker = {
        $0.playerType = .opponent
        return $0
    }(Tracker(windowNibName: "Tracker"))

    var secretTracker: CardList = {
        return $0
    }(CardList(windowNibName: "CardList"))
	
	var arenaHelper: CardList = {
		return $0
	}(CardList(windowNibName: "CardList"))
	
    var playerBoardDamage: BoardDamage = {
        $0.player = .player
        return $0
    }(BoardDamage(windowNibName: "BoardDamage"))

    var opponentBoardDamage: BoardDamage = {
        $0.player = .opponent
        return $0
    }(BoardDamage(windowNibName: "BoardDamage"))

    var timerHud: TimerHud = {
        return $0
    }(TimerHud(windowNibName: "TimerHud"))

    var turnCounter: TurnCounter = {
        return $0
    }(TurnCounter(windowNibName: "TurnCounter"))

    var battlegroundsOverlay: BattlegroundsOverlay = {
        return $0
    }(BattlegroundsOverlay(windowNibName: "BattlegroundsOverlay"))

    var battlegroundsDetailsWindow: BattlegroundsDetailsWindow = {
        return $0
    }(BattlegroundsDetailsWindow(windowNibName: "BattlegroundsDetailsWindow"))

    var battlegroundsTierOverlay: BattlegroundsTierOverlay = {
        return $0
    }(BattlegroundsTierOverlay(windowNibName: "BattlegroundsTierOverlay"))

    var battlegroundsTierDetailsWindowController: BattlegroundsTierDetailWindowController = {
        return $0
    }(BattlegroundsTierDetailWindowController(windowNibName: "BattlegroundsTierDetailWindowController"))
    
    var bobsBuddyPanel: BobsBuddyPanel = {
        return $0
    }(BobsBuddyPanel(windowNibName: "BobsBuddyPanel"))
    
    var experiencePanel: ExperienceOverlay = {
        return $0
    }(ExperienceOverlay(windowNibName: "ExperienceOverlay"))
    
    var opponentBoardOverlay: BoardOverlay = {
        $0.setPlayerType(playerType: .opponent)
        return $0
    }(BoardOverlay(windowNibName: "BoardOverlay"))
    
    var playerBoardOverlay: BoardOverlay = {
        $0.setPlayerType(playerType: .player)
        return $0
    }(BoardOverlay(windowNibName: "BoardOverlay"))
    
    var mercenariesTaskListButton: MercenariesTaskListButton = {
        return $0
    }(MercenariesTaskListButton(windowNibName: "MercenariesTaskListButton"))

    var mercenariesTaskListView: MercenariesTaskListView = {
        return $0
    }(MercenariesTaskListView(windowNibName: "MercenariesTaskListView"))
    
    var battlegroundsSession: BattlegroundsSession = {
        return $0
    }(BattlegroundsSession(windowNibName: "BattlegroundsSession"))
    
    var battlegroundsFinalBoard: BattlegroundsFinalBoard = {
        return $0
    }(BattlegroundsFinalBoard(windowNibName: "BattlegroundsFinalBoard"))
    
    var flavorText: FlavorText = {
        return $0
    }(FlavorText(windowNibName: "FlavorText"))

    var toastWindowController = ToastWindowController()

    var floatingCard: FloatingCard = {
        if let fWindow = $0.window {
            
            fWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.mainMenuWindow)) - 1)
            
            if Settings.canJoinFullscreen {
                fWindow.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]
            } else {
                fWindow.collectionBehavior = []
            }
            
            fWindow.styleMask = [.borderless, .nonactivatingPanel]
            fWindow.ignoresMouseEvents = true
            
            fWindow.orderFront(nil)
			fWindow.orderOut(nil)
        }
        return $0
    }(FloatingCard(windowNibName: "FloatingCard"))
    
    var floatingCard3: FloatingCard = {
        if let fWindow = $0.window {
            
            fWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.mainMenuWindow)) - 1)
            
            if Settings.canJoinFullscreen {
                fWindow.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]
            } else {
                fWindow.collectionBehavior = []
            }
            
            fWindow.styleMask = [.borderless, .nonactivatingPanel]
            fWindow.ignoresMouseEvents = true
            
            fWindow.orderFront(nil)
            fWindow.orderOut(nil)
        }
        return $0
    }(FloatingCard(windowNibName: "FloatingCard"))

    var floatingCard2: FloatingCard = {
        if let fWindow = $0.window {
            
            fWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.mainMenuWindow)) - 1)
            
            if Settings.canJoinFullscreen {
                fWindow.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]
            } else {
                fWindow.collectionBehavior = []
            }
            
            fWindow.styleMask = [.borderless, .nonactivatingPanel]
            fWindow.ignoresMouseEvents = true
            
            fWindow.orderFront(nil)
            fWindow.orderOut(nil)
        }
        return $0
    }(FloatingCard(windowNibName: "FloatingCard"))

    var cardHudContainer: CardHudContainer = {
        return $0
    }(CardHudContainer(windowNibName: "CardHudContainer"))
    
    var opponentWotogIcons: WotogCounter = {
        return $0
    }(WotogCounter(windowNibName: "WotogCounter"))

    var playerWotogIcons: WotogCounter = {
        return $0
    }(WotogCounter(windowNibName: "WotogCounter"))

    private var lastCardsUpdateRequest = Date.distantPast.timeIntervalSince1970

    var triggers: [NSObjectProtocol] = []
    
    func startManager() {
        secretTracker.isSecretPanel = true
        if triggers.count == 0 {
            let events = [
                Events.show_floating_card: self.showFloatingCard,
                Events.hide_floating_card: self.hideFloatingCard
            ]
            for (event, trigger) in events {
                let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: event), object: nil, queue: OperationQueue.main) { note in
                    trigger(note)
                }
                triggers.append(observer)
            }
        }
    }
    
    deinit {
        for observer in triggers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
	
	private func setHearthstoneActive() { hearthstoneActive = true }
	private func setHearthstoneBackground() { hearthstoneActive = false }

    func hideGameTrackers() {
		// TODO: use not defered gui instead
        DispatchQueue.main.async { [weak self] in
            self?.secretTracker.window?.orderOut(nil)
			self?.arenaHelper.window?.orderOut(nil)
            self?.timerHud.window?.orderOut(nil)
            self?.playerBoardDamage.window?.orderOut(nil)
            self?.opponentBoardDamage.window?.orderOut(nil)
            self?.battlegroundsDetailsWindow.window?.orderOut(nil)
            self?.bobsBuddyPanel.window?.orderOut(nil)
            self?.turnCounter.window?.orderOut(nil)
            self?.battlegroundsTierOverlay.window?.orderOut(nil)
            self?.cardHudContainer.reset()
            self?.playerBoardOverlay.window?.orderOut(nil)
            self?.opponentBoardOverlay.window?.orderOut(nil)
            self?.flavorText.window?.orderOut(nil)
        }
    }

    // MARK: - Floating card
    var closeRequestTimer: Timer?
    func showFloatingCard(_ notification: Notification) {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            guard Settings.showFloatingCard else { return }
            
            guard let card = notification.userInfo?["card"] as? Card,
                let arrayFrame = notification.userInfo?["frame"] as? [CGFloat] else {
                    return
            }
            
            var floatingCard = self.floatingCard
            if let index = notification.userInfo?["index"] as? Int {
                if index == 1 {
                    floatingCard = self.floatingCard2
                } else if index == 2 {
                    floatingCard = self.floatingCard3
                }
            }
            
            let useFrame = notification.userInfo?["useFrame"] as? Bool ?? false

            if let bgs = notification.userInfo?["battlegrounds"] as? Bool, bgs {
                floatingCard.isBattlegrounds = true
            } else {
                floatingCard.isBattlegrounds = false
            }
            if let timer = self.closeRequestTimer {
                timer.invalidate()
                self.closeRequestTimer = nil
            }
            
            floatingCard.set(card: card)
            
            if let fWindow = floatingCard.window {
                if !useFrame {
                    fWindow.setFrameOrigin(NSPoint(x: arrayFrame[0],
                                                                y: arrayFrame[1] - fWindow.frame.size.height/2))
                }

                fWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.mainMenuWindow)) - 1)
                
                if Settings.canJoinFullscreen {
                    fWindow.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]
                } else {
                    fWindow.collectionBehavior = []
                }
                
                fWindow.styleMask = [.borderless, .nonactivatingPanel]
                fWindow.ignoresMouseEvents = true
                
                if useFrame {
                    fWindow.setFrame(NSRect(x: arrayFrame[0], y: arrayFrame[1], width: arrayFrame[2], height: arrayFrame[3]), display: true)
                }

                fWindow.orderFront(nil)
            }
            
            var disableTimeout = false
            if let dt = notification.userInfo?["disableTimeout"] as? Bool, dt {
                disableTimeout = true
            }
            if !disableTimeout {
                self.closeRequestTimer = Timer.scheduledTimer(
                    timeInterval: 3,
                    target: self,
                    selector: #selector(self.forceHideFloatingCard),
                    userInfo: nil,
                    repeats: false)
            }
        }
    }

    func hideFloatingCard(_ notification: Notification) {
        guard Settings.showFloatingCard else { return }
        
        // hide popup
        guard let card = notification.userInfo?["card"] as? Card
            else {
                return
        }

        if card.id == floatingCard.card?.id {
            forceHideFloatingCard()
        }
    }
    
    @objc func forceHideFloatingCard() {
        DispatchQueue.main.async { [unowned(unsafe) self] in
            self.floatingCard.window?.orderOut(self)
            self.floatingCard2.window?.orderOut(self)
            self.floatingCard3.window?.orderOut(self)
            self.closeRequestTimer?.invalidate()
            self.closeRequestTimer = nil
        }
    }

    // MARK: - Utility functions
    func show(controller: OverWindowController, show: Bool,
              frame: NSRect? = nil, title: String? = nil, overlay: Bool = true) {
        guard let window = controller.window else { return }

        DispatchQueue.main.async {
            if show {
                // add the window in the "windows menu"
                if let title = title {
                    NSApp.addWindowsItem(window,
                                         title: NSLocalizedString(title, comment: ""),
                                         filename: false)
                    window.title = NSLocalizedString(title, comment: "")
                }

                // update gui elements
                controller.updateFrames()
                
                // show window and set size
                if let frame = frame {
                    window.setFrame(frame, display: true, animate: false)
                }

                // set the level of the window : over all if hearthstone is active
                // as a normal window otherwise
                let level: Int
                if overlay {
                    level = Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow)) - 1
                } else {
                    level = Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow))
                }
                window.level = NSWindow.Level(rawValue: level)

                // if the setting is on, set the window behavior to join all workspaces
                if Settings.canJoinFullscreen {
                    window.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]
                } else {
                    window.collectionBehavior = []
                }

                let locked = Settings.windowsLocked || controller.alwaysLocked
                if locked {
                    window.styleMask = [.borderless, .nonactivatingPanel]
                } else {
                    window.styleMask = [.titled, .miniaturizable,
                                        .resizable, .borderless,
                                        .nonactivatingPanel]
                }

                window.orderFront(nil)
            } else {
                if title != nil {
                    NSApp.removeWindowsItem(window)
                }
                window.orderOut(nil)
            }
        }
    }
}

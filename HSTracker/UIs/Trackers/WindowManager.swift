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
    
    var linkOpponentDeckPanel: LinkOpponentDeckPanel = {
        return $0
    }(LinkOpponentDeckPanel(windowNibName: "LinkOpponentDeckPanel"))

    var secretTracker: CardList = {
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
    
    var constructedMulliganGuide: ConstructedMulliganGuide = {
        return $0
    }(ConstructedMulliganGuide(windowNibName: "ConstructedMulliganGuide"))
    
    var constructedMulliganGuidePreLobby: ConstructedMulliganGuidePreLobby = {
        return $0
    }(ConstructedMulliganGuidePreLobby(windowNibName: "ConstructedMulliganGuidePreLobby"))
    
    var flavorText: FlavorText = {
        return $0
    }(FlavorText(windowNibName: "FlavorText"))
    
    var playerActiveEffectsOverlay: ActiveEffectsOverlay = {
        $0.isPlayer = true
        return $0
    }(ActiveEffectsOverlay(windowNibName: "ActiveEffectsOverlay"))

    var opponentActiveEffectsOverlay: ActiveEffectsOverlay = {
        $0.isPlayer = false
        return $0
    }(ActiveEffectsOverlay(windowNibName: "ActiveEffectsOverlay"))

    private var _playerPlayerResourcesOverlay: Any?
    @available(OSX 10.15, *)
    var playerPlayerResourcesOverlay: PlayerResourcesWindow? {
        if _playerPlayerResourcesOverlay == nil {
            _playerPlayerResourcesOverlay = PlayerResourcesWindow(windowNibName: "PlayerResourcesWindow")
        }
        return (_playerPlayerResourcesOverlay as? PlayerResourcesWindow)
    }
    
    private var _opponentPlayerResourcesOverlay: Any?
    @available(OSX 10.15, *)
    var opponentPlayerResourcesOverlay: PlayerResourcesWindow? {
        if _opponentPlayerResourcesOverlay == nil {
            _opponentPlayerResourcesOverlay = PlayerResourcesWindow(windowNibName: "PlayerResourcesWindow")
        }
        return (_opponentPlayerResourcesOverlay as? PlayerResourcesWindow)
    }

    private var _rootOverlay: Any?
    @available(OSX 10.15, *)
    var rootOverlay: RootOverlayWindow? {
        if _rootOverlay == nil {
            _rootOverlay = RootOverlayWindow(windowNibName: "RootOverlayWindow")
        }
        return (_rootOverlay as? RootOverlayWindow)
    }

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
    
    @available(macOS 10.15, *)
    var tooltipGridCards: RelatedCardsTooltipPanel {
        RelatedCardsTooltipPanel.shared
    }

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
            self?.timerHud.window?.orderOut(nil)
            self?.playerBoardDamage.window?.orderOut(nil)
            self?.opponentBoardDamage.window?.orderOut(nil)
            self?.cardHudContainer.reset()
            self?.playerBoardOverlay.window?.orderOut(nil)
            self?.opponentBoardOverlay.window?.orderOut(nil)
            self?.flavorText.window?.orderOut(nil)
            self?.playerActiveEffectsOverlay.window?.orderOut(nil)
            self?.opponentActiveEffectsOverlay.window?.orderOut(nil)
            if #available(macOS 10.15, *) {
                self?.tooltipGridCards.hide()
                RelatedCardsBrowserPanel.shared.hide()
            }
        }
    }

    // MARK: - Floating card
    var closeRequestTimer: Timer?
    func showFloatingCard(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
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
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.floatingCard.window?.orderOut(self)
            self.floatingCard2.window?.orderOut(self)
            self.floatingCard3.window?.orderOut(self)
            self.closeRequestTimer?.invalidate()
            self.closeRequestTimer = nil
            if #available(macOS 10.15, *) {
                self.tooltipGridCards.hide()
            }
        }
    }

    // MARK: - Utility functions
    @MainActor
    func show(controller: OverWindowController, show: Bool,
              frame: NSRect? = nil, title: String? = nil, overlay: Bool = true) {
        // `controller.window` loads the nib on first access, so the hop has to
        // happen before it is touched, not after.
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.show(controller: controller, show: show, frame: frame, title: title, overlay: overlay)
            }
            return
        }

        guard let window = controller.window else { return }
        
        if show {
            // add the window in the "windows menu"
            if let title = title {
                NSApp.addWindowsItem(window,
                                     title: String.localizedString(title, comment: ""),
                                     filename: false)
                window.title = String.localizedString(title, comment: "")
            }

            // update gui elements
            controller.updateFrames()
            
            // show window and set size
            if let frame = frame {
                if frame.origin.x.isFinite && frame.origin.y.isFinite && frame.size.width.isFinite && frame.size.height.isFinite {
                    window.setFrame(frame, display: true, animate: false)
                }
            }

            // Place overlays just above Hearthstone (normal level) but below
            // any system UI level so macOS Notification Center, menu bar, and
            // status items can render above them.
            let level: Int
            if overlay {
                level = Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)) + 1
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


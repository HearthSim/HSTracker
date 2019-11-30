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
    }(Tracker(windowNibName: NSNib.Name(rawValue: "Tracker")))

    var opponentTracker: Tracker = {
        $0.playerType = .opponent
        return $0
    }(Tracker(windowNibName: NSNib.Name(rawValue: "Tracker")))

    var secretTracker: CardList = {
        return $0
    }(CardList(windowNibName: NSNib.Name(rawValue: "CardList")))
	
	var arenaHelper: CardList = {
		return $0
	}(CardList(windowNibName: NSNib.Name(rawValue: "CardList")))
	
    var playerBoardDamage: BoardDamage = {
        $0.player = .player
        return $0
    }(BoardDamage(windowNibName: NSNib.Name(rawValue: "BoardDamage")))

    var opponentBoardDamage: BoardDamage = {
        $0.player = .opponent
        return $0
    }(BoardDamage(windowNibName: NSNib.Name(rawValue: "BoardDamage")))

    var timerHud: TimerHud = {
        return $0
    }(TimerHud(windowNibName: NSNib.Name(rawValue: "TimerHud")))

    var collectionFeedBack: CollectionFeedback = {
        return $0
    }(CollectionFeedback(windowNibName: NSNib.Name(rawValue: "CollectionFeedback")))

    var battlegroundsOverlay: BattlegroundsOverlay = {
        return $0
    }(BattlegroundsOverlay(windowNibName: NSNib.Name(rawValue: "BattlegroundsOverlay")))

    var battlegroundsDetailsWindow: BattlegroundsDetailsWindow = {
        return $0
    }(BattlegroundsDetailsWindow(windowNibName: NSNib.Name(rawValue: "BattlegroundsDetailsWindow")))

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
    }(FloatingCard(windowNibName: NSNib.Name(rawValue: "FloatingCard")))
    
    var cardHudContainer: CardHudContainer = {
        return $0
    }(CardHudContainer(windowNibName: NSNib.Name(rawValue: "CardHudContainer")))

    private var lastCardsUpdateRequest = Date.distantPast.timeIntervalSince1970

    var triggers: [NSObjectProtocol] = []
    
    func startManager() {
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
            self?.cardHudContainer.reset()
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
            if let timer = self.closeRequestTimer {
                timer.invalidate()
                self.closeRequestTimer = nil
            }
            
            if let drawchancetop = notification.userInfo?["drawchancetop"] as? Float,
                let drawchancetop2 = notification.userInfo?["drawchancetop2"] as? Float {
                self.floatingCard.set(card: card, drawChanceTop: drawchancetop,
                                 drawChanceTop2: drawchancetop2)
            } else {
                self.floatingCard.set(card: card, drawChanceTop: 0, drawChanceTop2: 0)
            }
            
            if let fWindow = self.floatingCard.window {
                fWindow.setFrameOrigin(NSPoint(x: arrayFrame[0],
                                                            y: arrayFrame[1] - fWindow.frame.size.height/2))
                
                fWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.mainMenuWindow)) - 1)
                
                if Settings.canJoinFullscreen {
                    fWindow.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]
                } else {
                    fWindow.collectionBehavior = []
                }
                
                fWindow.styleMask = [.borderless, .nonactivatingPanel]
                fWindow.ignoresMouseEvents = true
                
                fWindow.orderFront(nil)
            }
            
            self.closeRequestTimer = Timer.scheduledTimer(
                timeInterval: 3,
                target: self,
                selector: #selector(self.forceHideFloatingCard),
                userInfo: nil,
                repeats: false)
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
                    window.setFrame(frame, display: true)
                }

                // set the level of the window : over all if hearthstone is active
                // as a normal window otherwise
                let level: Int
                if overlay {
                    level = Int(CGWindowLevelForKey(CGWindowLevelKey.mainMenuWindow)) - 1
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

                let locked = Settings.windowsLocked
                if locked {
                    window.styleMask = [.borderless, .nonactivatingPanel]
                } else {
                    window.styleMask = [.titled, .miniaturizable,
                                        .resizable, .borderless,
                                        .nonactivatingPanel]
                }
                window.ignoresMouseEvents = locked

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

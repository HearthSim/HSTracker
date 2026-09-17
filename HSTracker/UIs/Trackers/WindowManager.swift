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
	
    // The two deck trackers, the secret helper and the link-opponent-deck panel
    // are RootOverlay children now - see RootOverlayViewModel's playerTracker /
    // opponentTracker / secretsPanel / linkOpponentDeck.

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
    
    @available(macOS 10.15, *)
    var tooltipGridCards: RelatedCardsTooltipPanel {
        RelatedCardsTooltipPanel.shared
    }

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
            if #available(macOS 10.15, *) {
                self?.rootOverlay?.viewModel.secretsPanel.isShown = false
                self?.rootOverlay?.viewModel.opponentHandMarkers.hide()
                self?.rootOverlay?.viewModel.boardOverlay.isShown = false
                self?.rootOverlay?.viewModel.flavorText.hide()
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
            
            let floatingCard = self.floatingCard
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
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.floatingCard.window?.orderOut(self)
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


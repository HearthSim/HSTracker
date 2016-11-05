//
//  WindowManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 20/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class WindowManager {
    static let `default` = WindowManager()

    static let cardWidth: CGFloat = {
        switch Settings.instance.cardSize {
        case .tiny: return CGFloat(kTinyFrameWidth)
        case .small: return CGFloat(kSmallFrameWidth)
        case .medium: return CGFloat(kMediumFrameWidth)
        case .big: return CGFloat(kFrameWidth)
        case .huge: return CGFloat(kHighRowFrameWidth)
        }
    }()
    static let screenFrame: NSRect = {
        return NSScreen.main()!.frame
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

    var secretTracker: SecretTracker = {
        $0.window?.orderFront(nil)
        return $0
    }(SecretTracker(windowNibName: "SecretTracker"))
    
    var playerBoardDamage: BoardDamage = {
        $0.player = .player
        $0.window?.orderFront(nil)
        return $0
    }(BoardDamage(windowNibName: "BoardDamage"))

    var opponentBoardDamage: BoardDamage = {
        $0.player = .opponent
        $0.window?.orderFront(nil)
        return $0
    }(BoardDamage(windowNibName: "BoardDamage"))

    var timerHud: TimerHud = {
        $0.window?.orderFront(nil)
        return $0
    }(TimerHud(windowNibName: "TimerHud"))

    var floatingCard: FloatingCard = {
        $0.window?.orderFront(nil)
        return $0
    }(FloatingCard(windowNibName: "FloatingCard"))
    
    var cardHudContainer: CardHudContainer = {
        $0.window?.orderFront(nil)
        return $0
    }(CardHudContainer(windowNibName: "CardHudContainer"))

    private var lastCardsUpdateRequest = Date.distantPast.timeIntervalSince1970

    private init() {
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startManager() {
        let events = [
            "show_floating_card": #selector(showFloatingCard(_:)),
            "hide_floating_card": #selector(hideFloatingCard(_:)),
            ]

        for (event, selector) in events {
            NotificationCenter.default.addObserver(self,
                                                   selector: selector,
                                                   name: NSNotification.Name(rawValue: event),
                                                   object: nil)
        }

        let reload = ["window_locked", "show_player_tracker", "show_opponent_tracker",
                      "auto_position_trackers", "space_changed", "hearthstone_closed",
                      "hearthstone_running", "hearthstone_active", "hearthstone_deactived",
                      "can_join_fullscreen"]
        for event in reload {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(updateTrackersAfterEvent),
                                                   name: NSNotification.Name(rawValue: event),
                                                   object: nil)
        }

        updateTrackers()
        forceHideFloatingCard()
    }

    func isReady() -> Bool {
        return playerTracker.window != nil && opponentTracker.window != nil
    }

    func hideGameTrackers() {
        DispatchQueue.main.async { [weak self] in
            self?.secretTracker.window?.orderOut(nil)
            self?.timerHud.window?.orderOut(nil)
            self?.playerBoardDamage.window?.orderOut(nil)
            self?.opponentBoardDamage.window?.orderOut(nil)
            self?.cardHudContainer.reset()
        }
    }

    @objc private func updateTrackersAfterEvent() {
        let time = DispatchTime.now() + DispatchTimeInterval.seconds(2)
        DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
            SizeHelper.hearthstoneWindow.reload()
            self?.updateTrackers()
        }
    }

    // MARK: - Updating trackers
    func updateTrackers(reset: Bool = false) {
        DispatchQueue.main.async {
            SizeHelper.hearthstoneWindow.reload()
        }
        let settings = Settings.instance
        let game = Game.instance

        // timer
        if Settings.instance.showTimer && game.gameStarted {
            show(controller: timerHud, show: true, frame: SizeHelper.timerHudFrame())
        } else {
            show(controller: timerHud, show: false)
        }

        // secret helper
        if settings.showSecretHelper {
            if let secrets = game.opponentSecrets, secrets.allSecrets().count > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.secretTracker.setSecrets(secrets: secrets.allSecrets())
                }
                show(controller: secretTracker, show: true, frame: SizeHelper.secretTrackerFrame())
            } else {
                show(controller: secretTracker, show: false)
            }
        } else {
            show(controller: secretTracker, show: false)
        }

        // card hud
        if settings.showCardHuds {
            if game.gameStarted {
                lastCardsUpdateRequest = Date().timeIntervalSince1970
                let when = DispatchTime.now() + DispatchTimeInterval.milliseconds(100)
                DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
                    if Date().timeIntervalSince1970 - (self?.lastCardsUpdateRequest ??
                            Date.distantPast.timeIntervalSince1970) > 0.1 {
                        guard let hud = self?.cardHudContainer else { return }

                        hud.update(entities: game.opponent.hand,
                                   cardCount: game.opponent.handCount)
                        self?.show(controller: hud, show: true,
                                   frame: SizeHelper.cardHudContainerFrame())
                    }
                }
            } else {
                show(controller: cardHudContainer, show: false)
            }
        } else {
            show(controller: cardHudContainer, show: false)
        }

        // board damage
        let board = BoardState()

        if settings.playerBoardDamage {
            if game.gameStarted {
                DispatchQueue.main.async { [weak self] in
                    self?.playerBoardDamage.update(attack: board.player.damage)
                }
                show(controller: playerBoardDamage, show: true,
                     frame: SizeHelper.playerBoardDamageFrame())
            } else {
                show(controller: playerBoardDamage, show: false)
            }
        } else {
            show(controller: playerBoardDamage, show: false)
        }

        if settings.opponentBoardDamage {
            if game.gameStarted {
                DispatchQueue.main.async { [weak self] in
                    self?.opponentBoardDamage.update(attack: board.opponent.damage)
                }
                show(controller: opponentBoardDamage, show: true,
                     frame: SizeHelper.opponentBoardDamageFrame())
            } else {
                show(controller: opponentBoardDamage, show: false)
            }
        } else {
            show(controller: opponentBoardDamage, show: false)
        }

        var rect: NSRect?

        if settings.showOpponentTracker {
            // opponent tracker
            DispatchQueue.main.async { [weak self] in
                let cards = settings.clearTrackersOnGameEnd && game.gameEnded
                    ? [] : game.opponent.opponentCardList
                self?.opponentTracker.update(cards: cards, reset: reset)
                self?.opponentTracker.setWindowSizes()
            }

            if settings.autoPositionTrackers && Hearthstone.instance.isHearthstoneRunning {
                rect = SizeHelper.opponentTrackerFrame()
            } else {
                rect = Settings.instance.opponentTrackerFrame
                if rect == nil {
                    let x = WindowManager.screenFrame.origin.x + 50
                    rect = NSRect(x: x,
                                  y: WindowManager.top + WindowManager.screenFrame.origin.y,
                                  width: WindowManager.cardWidth,
                                  height: WindowManager.top)
                }
            }
            show(controller: opponentTracker, show: true, frame: rect, title: "Opponent tracker")
        } else {
            show(controller: opponentTracker, show: false)
        }

        // player tracker
        if settings.showPlayerTracker {
            DispatchQueue.main.async { [weak self] in
                self?.playerTracker.update(cards: game.player.playerCardList, reset: reset)
                self?.playerTracker.setWindowSizes()
            }

            if settings.autoPositionTrackers && Hearthstone.instance.isHearthstoneRunning {
                rect = SizeHelper.playerTrackerFrame()
            } else {
                rect = settings.playerTrackerFrame
                if rect == nil {
                    let x = WindowManager.screenFrame.width - WindowManager.cardWidth
                        + WindowManager.screenFrame.origin.x
                    rect = NSRect(x: x,
                                  y: WindowManager.top + WindowManager.screenFrame.origin.y,
                                  width: WindowManager.cardWidth,
                                  height: WindowManager.top)
                }
            }
            show(controller: playerTracker, show: true, frame: rect, title: "Player tracker")
        } else {
            show(controller: playerTracker, show: false)
        }
    }

    // MARK: - Floating card
    var closeFloatingCardRequest = 0
    var closeRequestTimer: Timer?
    @objc func showFloatingCard(_ notification: Notification) {
        guard Settings.instance.showFloatingCard else { return }

        guard let card = notification.userInfo?["card"] as? Card,
            let arrayFrame = notification.userInfo?["frame"] as? [CGFloat] else {
                return
        }
        if closeRequestTimer != nil {
            closeRequestTimer?.invalidate()
            closeRequestTimer = nil
        }

        closeFloatingCardRequest += 1
        floatingCard.showWindow(self)
        let frame = NSRect(x: arrayFrame[0],
                           y: arrayFrame[1],
                           width: arrayFrame[2],
                           height: arrayFrame[3])
        floatingCard.window?.setFrame(frame, display: true)
        floatingCard.window?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.mainMenuWindow)) - 1
        floatingCard.set(card: card)

        closeRequestTimer = Timer.scheduledTimer(
            timeInterval: 3,
            target: self,
            selector: #selector(forceHideFloatingCard),
            userInfo: nil,
            repeats: false)
    }

    @objc func forceHideFloatingCard() {
        closeFloatingCardRequest = 0
        floatingCard.window?.orderOut(self)
        closeRequestTimer?.invalidate()
        closeRequestTimer = nil
    }

    @objc func hideFloatingCard(_ notification: Notification) {
        guard Settings.instance.showFloatingCard else { return }

        self.closeFloatingCardRequest -= 1
        let when = DispatchTime.now() + DispatchTimeInterval.milliseconds(100)
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: when) {
            if self.closeFloatingCardRequest > 0 {
                return
            }
            self.closeFloatingCardRequest = 0
            self.floatingCard.window?.orderOut(self)
            self.closeRequestTimer?.invalidate()
            self.closeRequestTimer = nil
        }
    }

    func showHideCardHuds(_ notification: Notification) {
        updateTrackers()
    }

    // MARK: - Utility functions
    private func show(controller: OverWindowController, show: Bool,
                      frame: NSRect? = nil, title: String? = nil) {
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

                // show window and set size
                if let frame = frame {
                    window.setFrame(frame, display: true)
                }

                // set the level of the window : over all if hearthstone is active
                // as a normal window otherwize
                let level: Int
                if Hearthstone.instance.hearthstoneActive {
                    level = Int(CGWindowLevelForKey(CGWindowLevelKey.mainMenuWindow)) - 1
                } else {
                    level = Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow))
                }
                window.level = level

                // if the setting is on, set the window behavior to join all workspaces
                if Settings.instance.canJoinFullscreen {
                    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                } else {
                    window.collectionBehavior = []
                }

                let locked = Settings.instance.windowsLocked
                if locked {
                    window.styleMask = [NSBorderlessWindowMask, NSNonactivatingPanelMask]
                } else {
                    window.styleMask = [NSTitledWindowMask, NSMiniaturizableWindowMask,
                                        NSResizableWindowMask, NSBorderlessWindowMask,
                                        NSNonactivatingPanelMask]
                }
                window.ignoresMouseEvents = locked

                window.orderFront(nil)
            } else {
                NSApp.removeWindowsItem(window)
                window.orderOut(nil)
            }
        }
    }
}

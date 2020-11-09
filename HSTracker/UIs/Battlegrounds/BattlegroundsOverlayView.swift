//
//  BattlegroundsOverlayView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 30/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation

class BattlegroundsOverlayView: NSView {
    var currentIndex = -1

    init() {
        super.init(frame: NSRect.zero)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        //let backgroundColor: NSColor = NSColor(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 0.3)
        let backgroundColor = NSColor.clear
        backgroundColor.set()
        dirtyRect.fill()
    }
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                                                                   options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                              owner: self,
                              userInfo: nil)

    override func updateTrackingAreas() {
        logger.debug("update Tracking Area")
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }

    func displayHero(at: Int) {
        // swiftlint:disable force_cast
        let windowManager = (NSApplication.shared.delegate as! AppDelegate).coreManager.game.windowManager
        // swiftlint:enable force_cast
        
        let game = AppDelegate.instance().coreManager.game
        
        if Settings.showOpponentWarband, let hero = game.entities.values.first(where: { ent in ent.has(tag: .player_leaderboard_place) && ent[.player_leaderboard_place] == at + 1}) {
            let board = game.lastKnownBattlegroundsBoardState[hero.cardId]
            if let board = board {
                windowManager.battlegroundsDetailsWindow.setBoard(board: board)
                let rect = SizeHelper.battlegroundsDetailsFrame()
                windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: true,
                                   frame: rect, overlay: true)
            } else {
                windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: false)
            }
        } else {
            windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: false)
        }
    }

    private var bobsBuddyHidden = false
    
    override func mouseMoved(with event: NSEvent) {
        let index = 7 - Int(CGFloat(event.locationInWindow.y / (self.frame.height/8)))
        
        if index != currentIndex {
            displayHero(at: index)
            currentIndex = index
            let windowManager = AppDelegate.instance().coreManager.game.windowManager
            AppDelegate.instance().coreManager.game.hideBobsBuddy = true
            if windowManager.bobsBuddyPanel.window != nil {
                bobsBuddyHidden = true
            }
            windowManager.show(controller: windowManager.bobsBuddyPanel, show: false)
        }
    }

    override func mouseEntered(with event: NSEvent) {
    }

    override func mouseExited(with event: NSEvent) {
        displayHero(at: -1)
        currentIndex = -1
        AppDelegate.instance().coreManager.game.hideBobsBuddy = false
        if bobsBuddyHidden {
            bobsBuddyHidden = false
            let windowManager = AppDelegate.instance().coreManager.game.windowManager
            windowManager.show(controller: windowManager.bobsBuddyPanel, show: true)
        }
    }
}

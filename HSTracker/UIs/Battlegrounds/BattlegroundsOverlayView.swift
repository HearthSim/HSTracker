//
//  BattlegroundsOverlayView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 30/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation
import kotlin_hslog

class BattlegroundsOverlayView: NSView {
    var heroes: [DeckEntry.Hero]?
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
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }

    func displayHero(at: Int) {
        // swiftlint:disable force_cast
        let windowManager = (NSApplication.shared.delegate as! AppDelegate).coreManager.game.windowManager
        // swiftlint:enable force_cast
        
//        var minions = [BattlegroundsMinion]()
//        minions.append(BattlegroundsMinion(CardId: "AT_005", attack: Int32(at), health: Int32(at), poisonous: false, divineShield: true))
//        minions.append(BattlegroundsMinion(CardId: "AT_006", attack: Int32(at), health: Int32(at), poisonous: true, divineShield: false))
//
//        let debugBoard = BattlegroundsBoard(currentTurn: 10, opponentHero: kotlin_hslog.Entity(), turn: 4, minions: minions)
//        windowManager.battlegroundsDetailsWindow.setBoard(board: debugBoard)
//
//        windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: true,
//                           frame: SizeHelper.battlegroundsDetailsFrame(), overlay: true)

        if let hero = heroes?.first(where: {$0.board.leaderboardPlace - 1 == at}) {
            windowManager.battlegroundsDetailsWindow.setBoard(board: hero.board)
            windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: true,
                               frame: SizeHelper.battlegroundsDetailsFrame(), overlay: true)
        } else {
            windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: false)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let index = 7 - Int(CGFloat(event.locationInWindow.y / (self.frame.height/8)))
        
        if index != currentIndex {
            displayHero(at: index)
            currentIndex = index
        }
    }

    override func mouseEntered(with event: NSEvent) {
    }

    override func mouseExited(with event: NSEvent) {
        displayHero(at: -1)
        currentIndex = -1
    }
    
    func setHeroes(heroes: [DeckEntry.Hero]) {
        self.heroes = heroes
    }
}

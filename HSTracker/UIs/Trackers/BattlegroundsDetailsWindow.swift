//
//  CollectionFeedback.swift
//  HSTracker
//
//  Created by Martin BONNIN on 13/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation
import TextAttributes

class BattlegroundsDetailsWindow: OverWindowController {
    @IBOutlet weak var boardAge: NSTextField!
    @IBOutlet weak var notFought: NSTextField!
    @IBOutlet weak var emptyBoard: NSTextField!
    
    @IBOutlet weak var minion1: BattlegroundsMinionView!
    @IBOutlet weak var minion2: BattlegroundsMinionView!
    @IBOutlet weak var minion3: BattlegroundsMinionView!
    @IBOutlet weak var minion4: BattlegroundsMinionView!
    @IBOutlet weak var minion5: BattlegroundsMinionView!
    @IBOutlet weak var minion6: BattlegroundsMinionView!
    @IBOutlet weak var minion7: BattlegroundsMinionView!

    @IBOutlet weak var tier1: BattlegroundsTierTriples!
    @IBOutlet weak var tier2: BattlegroundsTierTriples!
    @IBOutlet weak var tier3: BattlegroundsTierTriples!
    @IBOutlet weak var tier4: BattlegroundsTierTriples!
    @IBOutlet weak var tier5: BattlegroundsTierTriples!
    @IBOutlet weak var tier6: BattlegroundsTierTriples!
    
    var snapshot: BoardSnapshot?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        update()
    }
    
    func setBoard(board: BoardSnapshot) {
        self.snapshot = board
        update()
    }
    
    func reset() {
        self.snapshot = nil
        update()
    }
    
    func update() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.update()
            }
            return
        }
        if tier1 == nil {
            return
        }
        let minions = [ minion1, minion2, minion3, minion4, minion5, minion6, minion7 ]
        var index = 0
        
        if let snapshot = snapshot {
            tier1.turn = snapshot.techLevel[0]
            tier1.qty = snapshot.triples[0]
            tier2.turn = snapshot.techLevel[1]
            tier2.qty = snapshot.triples[1]
            tier3.turn = snapshot.techLevel[2]
            tier3.qty = snapshot.triples[2]
            tier4.turn = snapshot.techLevel[3]
            tier4.qty = snapshot.triples[3]
            tier5.turn = snapshot.techLevel[4]
            tier5.qty = snapshot.triples[4]
            tier6.turn = snapshot.techLevel[5]
            tier6.qty = snapshot.triples[5]
            
            for entity in snapshot.entities {
                if index >= 0 && index < minions.count {
                    minions[index]?.entity = entity
                    minions[index]?.needsDisplay = true
                    minions[index]?.isHidden = false
                    index += 1
                }
            }
            emptyBoard.isHidden = index != 0 || snapshot.turn == -1
            notFought.isHidden = snapshot.turn != -1
            
            boardAge.stringValue = snapshot.turn != -1 ? String.localizedStringWithFormat(NSLocalizedString("%d turn(s) ago", comment: ""), AppDelegate.instance().coreManager.game.turnNumber() - snapshot.turn) : ""
        } else {
            tier1.turn = 0
            tier1.qty = 0
            tier2.turn = 0
            tier2.qty = 0
            tier3.turn = 0
            tier3.qty = 0
            tier4.turn = 0
            tier4.qty = 0
            tier5.turn = 0
            tier5.qty = 0
            tier6.turn = 0
            tier6.qty = 0
            emptyBoard.isHidden = true
            notFought.isHidden = false
            boardAge.stringValue = ""
        }
        tier1.update()
        tier2.update()
        tier3.update()
        tier4.update()
        tier5.update()
        tier6.update()
        
        while index < 7 {
            minions[index]?.entity = nil
            minions[index]?.isHidden = true
            index += 1
        }
    }
}

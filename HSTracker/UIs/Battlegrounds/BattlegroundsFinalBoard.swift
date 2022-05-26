//
//  BattlegroundsFinalBoard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/19/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsFinalBoard: OverWindowController {
    override var alwaysLocked: Bool { true }
    
    @IBOutlet weak var minion1: BattlegroundsMinionView!
    @IBOutlet weak var minion2: BattlegroundsMinionView!
    @IBOutlet weak var minion3: BattlegroundsMinionView!
    @IBOutlet weak var minion4: BattlegroundsMinionView!
    @IBOutlet weak var minion5: BattlegroundsMinionView!
    @IBOutlet weak var minion6: BattlegroundsMinionView!
    @IBOutlet weak var minion7: BattlegroundsMinionView!

    var board: [Entity] = []
    
    override func windowDidLoad() {
        super.windowDidLoad()
        if board.count > 0 {
            setBoard(board: board)
        }
    }
    
    func setBoard(board: [Entity]) {
        logger.debug("Setting board with \(board.count) entities")
        self.board = board
        if minion1 == nil {
            return
        }
        let boardMinions = [ minion1, minion2, minion3, minion4, minion5, minion6, minion7 ]
        var i = 0
        for entity in board {
            boardMinions[i]?.entity = entity
            boardMinions[i]?.needsDisplay = true
            i += 1
        }
        while i < 7 {
            boardMinions[i]?.entity = nil
            boardMinions[i]?.needsDisplay = true
            i += 1
        }
        self.window?.contentView?.needsDisplay = true
    }

}

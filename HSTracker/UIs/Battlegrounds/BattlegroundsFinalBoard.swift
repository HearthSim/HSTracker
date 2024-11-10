//
//  BattlegroundsFinalBoard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/19/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class BattlegroundsFinalBoard: OverWindowController {
    override var alwaysLocked: Bool { true }
    
    @IBOutlet var minion1: BattlegroundsMinionView!
    @IBOutlet var minion2: BattlegroundsMinionView!
    @IBOutlet var minion3: BattlegroundsMinionView!
    @IBOutlet var minion4: BattlegroundsMinionView!
    @IBOutlet var minion5: BattlegroundsMinionView!
    @IBOutlet var minion6: BattlegroundsMinionView!
    @IBOutlet var minion7: BattlegroundsMinionView!
    
    @IBOutlet var timespanLabel: NSTextField!

    var board: [Entity] = []
    var endTime: Date?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        if board.count > 0 {
            setBoard(board: board, endTime: endTime)
        }
    }
    
    func setBoard(board: [Entity], endTime: Date?) {
        logger.debug("Setting board with \(board.count) entities")
        self.board = board
        self.endTime = endTime
        if minion1 == nil {
            return
        }
        let boardMinions = [ minion1, minion2, minion3, minion4, minion5, minion6, minion7 ]
        var i = 0
        for entity in board {
            boardMinions[i]?.entity = entity
            boardMinions[i]?.needsDisplay = true
            i += 1
            if i > 6 {
                break
            }
        }
        while i < 7 {
            boardMinions[i]?.entity = nil
            boardMinions[i]?.needsDisplay = true
            i += 1
        }
        if let endTime = endTime {
            if #available(macOS 10.15, *) {
                let formatter = RelativeDateTimeFormatter()
                timespanLabel.stringValue = formatter.localizedString(fromTimeInterval: endTime.timeIntervalSinceNow)
            } else {
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .full
                formatter.allowedUnits = [ .hour, .minute ]
                formatter.maximumUnitCount = 1
                timespanLabel.stringValue = formatter.string(from: Date().timeIntervalSince(endTime)) ?? ""
            }
        } else {
            timespanLabel.stringValue = ""
        }
        self.window?.contentView?.needsDisplay = true
    }

}

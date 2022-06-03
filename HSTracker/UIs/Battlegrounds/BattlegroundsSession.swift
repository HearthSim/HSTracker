//
//  BattlegroundsSession.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/12/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsSession: OverWindowController {
    @IBOutlet weak var outerBox: NSBox!
    
    @IBOutlet weak var tribesSection: NSStackView!
    @IBOutlet weak var tribe1: BattlegroundsTribe!
    @IBOutlet weak var tribe2: BattlegroundsTribe!
    @IBOutlet weak var tribe3: BattlegroundsTribe!
    @IBOutlet weak var tribe4: BattlegroundsTribe!
    
    @IBOutlet weak var mmrLabel: NSTextFieldCell!
    @IBOutlet weak var finalLabel: NSTextFieldCell!
    @IBOutlet weak var heroLabel: NSTextFieldCell!
    @IBOutlet weak var minionsBannedLabel: NSTextFieldCell!
    @IBOutlet weak var mmrTitleLabel: NSTextField!
    @IBOutlet weak var noGamesLabelA: NSTextField!
    @IBOutlet weak var noGamesLabelB: NSTextField!
    @IBOutlet weak var latestGamesLabel: NSTextField!
    @IBOutlet weak var mmrSection: NSStackView!
    @IBOutlet weak var mmrLabelA: NSTextField!
    @IBOutlet weak var mmrFieldA: NSTextField!
    @IBOutlet weak var mmrLabelB: NSTextField!
    @IBOutlet weak var mmrFieldB: NSTextField!
    
    @IBOutlet weak var latestGamesSection: NSStackView!
    @IBOutlet weak var noGamesSection: NSView!
    @IBOutlet weak var lastGames: NSStackView!
    
    private var sessionGames = [BattlegroundsLastGames.GameItem]()
        
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    func onGameStart() {
        DispatchQueue.main.async {
            self.updateBannedMinionsVisibility()
            self.update()
        }
    }
    
    func onGameEnd(gameStats: InternalGameStats) {
        DispatchQueue.main.async {
            self.update()
        }
    }
    
    func show() {
        if window?.occlusionState.contains(.visible) ?? false {
            return
        }
        update()
        updateSectionsVisibilities()
    }
    
    private func updateBannedMinionsVisibility() {
        let game = AppDelegate.instance().coreManager.game
        let shouldShow = Settings.showBannedTribes && game.isBattlegroundsMatch() && game.currentMode == .gameplay
        tribesSection.isHidden = !shouldShow
    }
    
    func updateSectionsVisibilities() {
        updateBannedMinionsVisibility()
        mmrSection.isHidden = !Settings.showMMR
        latestGamesSection.isHidden = !Settings.showLatestGames
    }

    func update() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.update()
            }
            return
        }
        let game = AppDelegate.instance().coreManager.game
        let unavail = game.unavailableRaces
        if let races = unavail, races.count >= 3 {
            tribesSection.isHidden = false
            let sorted = races.sorted(by: { (a, b) in NSLocalizedString(a.rawValue, comment: "") < NSLocalizedString(b.rawValue, comment: "") })
            tribe1.setRace(newRace: sorted[0])
            tribe2.setRace(newRace: sorted[1])
            tribe3.setRace(newRace: sorted[2])
            if sorted.count > 3 {
                tribe4.setRace(newRace: sorted[3])
            }
            var font = tribe1.tribeLabel.font
            var minSize = tribe1.tribeLabel.font?.pointSize ?? 13.0
            if tribe2.tribeLabel.font?.pointSize ?? 13.0 < minSize {
                font = tribe2.tribeLabel.font
                minSize = font?.pointSize ?? 13.0
            }
            if tribe3.tribeLabel.font?.pointSize ?? 13.0 < minSize {
                font = tribe3.tribeLabel.font
                minSize = font?.pointSize ?? 13.0
            }
            if tribe4.tribeLabel.font?.pointSize ?? 13.0 < minSize {
                font = tribe4.tribeLabel.font
                minSize = font?.pointSize ?? 13.0
            }
            tribe1.tribeLabel.font = font
            tribe2.tribeLabel.font = font
            tribe3.tribeLabel.font = font
            tribe4.tribeLabel.font = font
        } else {
            tribesSection.isHidden = true
        }
        
        let firstGame = updateLatestGames()
        
        let rating = game.battlegroundsRating ?? 0
        let ratingStart = firstGame?.rating ?? rating
        
        minionsBannedLabel.stringValue = NSLocalizedString("Minions Banned", comment: "")
        noGamesLabelA.stringValue = NSLocalizedString("No games played this session.", comment: "")
        noGamesLabelB.stringValue = NSLocalizedString("Latest 10 games will appear here.", comment:"")
        mmrTitleLabel.stringValue = NSLocalizedString("MMR", comment: "")
        latestGamesLabel.stringValue = NSLocalizedString("Latest Games", comment: "")
        heroLabel.stringValue = NSLocalizedString("Hero", comment: "")
        finalLabel.stringValue = NSLocalizedString("Final", comment: "")
        mmrLabel.stringValue = NSLocalizedString("MMR", comment: "")

        if Settings.showMMRStartCurrent {
            mmrLabelA.stringValue = NSLocalizedString("Start", comment: "")
            mmrFieldA.stringValue = formatRating(mmr: ratingStart)
            mmrLabelB.stringValue = NSLocalizedString("Current", comment: "")
            mmrFieldB.stringValue = formatRating(mmr: rating)
            mmrFieldB.textColor = NSColor.white
        } else {
            mmrLabelA.stringValue = NSLocalizedString("Current", comment: "")
            mmrFieldA.stringValue = formatRating(mmr: rating)
            mmrLabelB.stringValue = NSLocalizedString("Change", comment: "")
            let mmrDelta = rating - ratingStart
            mmrFieldB.stringValue = "\(mmrDelta > 0 ? "+" : "")\(formatRating(mmr: mmrDelta))"
            mmrFieldB.textColor = mmrDelta == 0 ? NSColor.white : mmrDelta > 0 ? BattlegroundsGameView.mmrPositive : BattlegroundsGameView.mmrNegative
        }
    }

    private func updateLatestGames() -> BattlegroundsLastGames.GameItem? {
        sessionGames.removeAll()
        let sortedGames = BattlegroundsLastGames.instance.games.sorted(by: { (a, b) in a.startTime < b.startTime })
        deleteOldGames(games: sortedGames)
        sessionGames = getSessionGames(sortedGames: sortedGames)
        let firstGame = sessionGames.first
        if sessionGames.count > 10 {
            sessionGames.removeSubrange(0 ..< sessionGames.count - 10)
        }
        sessionGames = sessionGames.sorted(by: { (a, b) in a.startTime > b.startTime })
        for subview in lastGames.subviews.reversed() where subview as? BattlegroundsGameView != nil {
            subview.removeFromSuperview()
        }
        for game in sessionGames {
            let gameView = BattlegroundsGameView(frame: NSRect(x: 0, y: 0, width: 200, height: 34))
            gameView.update(game: game)
            self.lastGames.addArrangedSubview(gameView)
        }
        
        if sessionGames.count == 0 {
            noGamesSection.isHidden = false
            lastGames.isHidden = true
        } else {
            noGamesSection.isHidden = true
            lastGames.isHidden = false
        }
        return firstGame
    }
    
    private func getSessionGames(sortedGames: [BattlegroundsLastGames.GameItem]) -> [BattlegroundsLastGames.GameItem] {
        var sessionStartTime: Date?
        var previousGameEndTime: Date?
        var previousGameRatingAfter = 0
        for g in sortedGames {
            if let previousGameEndTime = previousGameEndTime {
                let gStartTime = g.startTime
                let ts = gStartTime.timeIntervalSince(previousGameEndTime)
                let diffMMR = g.rating - previousGameRatingAfter
                let ratingReseted = g.rating < 500 && diffMMR < -500
                
                if ts / 3600 >= 6 || ratingReseted {
                    sessionStartTime = gStartTime
                }
            }
            previousGameEndTime = g.endTime
            previousGameRatingAfter = g.ratingAfter
        }
        
        var sessionGames = [BattlegroundsLastGames.GameItem]()
        if let sessionStartTime = sessionStartTime {
            sessionGames = sortedGames.filter({ x in x.startTime >= sessionStartTime })
        } else {
            sessionGames = sortedGames
        }
        if sessionGames.count > 0, let lastGame = sessionGames.last {
            // Check for MMR reset on last game
            var ratingResetedAfterLastGame = false
            if let currentMMR = AppDelegate.instance().coreManager.game.battlegroundsRating {
                let sessionLastMMR = lastGame.ratingAfter
                ratingResetedAfterLastGame = currentMMR < 500 && currentMMR - sessionLastMMR < -500
            }
            if Date().timeIntervalSince(lastGame.endTime) >= 6 * 60 * 60 || ratingResetedAfterLastGame {
                return []
            }
        }
        return sessionGames
    }
    
    private func deleteOldGames(games: [BattlegroundsLastGames.GameItem]) {
        games.forEach({ x in
            if abs(x.startTime.timeIntervalSinceNow) > 7 * 24 * 60 * 60 {
                BattlegroundsLastGames.instance.removeGame(startTime: x.startTime)
            }
        })
    }
    
    private func formatRating(mmr: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let mmrText = numberFormatter.string(from: NSNumber(value: mmr)) ?? "0"
        return mmrText
    }
}

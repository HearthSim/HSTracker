//
//  BattlegroundsTierOverlay.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/14/20
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

@IBDesignable
class BobsBuddyPanel: OverWindowController {
    
    @IBOutlet var lethalRateStack: NSStackView!
    @objc dynamic var lethalRateDisplay: String = "-"
    @objc dynamic var winRateDisplay: String = "-"
    @objc dynamic var tieRateDisplay: String = "-"
    @objc dynamic var lossRateDisplay: String = "-"
    @IBOutlet var opponentLethalRateStack: NSStackView!
    @objc dynamic var opponentLethalRateDisplay: String = "-"
    @IBOutlet var spinner: NSProgressIndicator!
    @objc dynamic var percentagesVisibility: Bool = true
    @objc dynamic var spinnerVisibility: Bool = false
    @objc dynamic var warningIconVisibility: Bool = false
    @objc dynamic var statusMessage: String = "-"
    @objc dynamic var averageDamageGivenDisplay: String = "-"
    @IBOutlet var averageDamageGivenView: NSView!
    @objc dynamic var averageDamageTakenDisplay: String = "-"
    @IBOutlet var averageDamageTakenView: NSView!
    @IBOutlet var boxMainHeightConstraint: NSLayoutConstraint!
    @IBOutlet var boxAverageDamageGivenHeightConstraint: NSLayoutConstraint!
    @IBOutlet var boxAverageDamageTakenHeightConstraint: NSLayoutConstraint!
    @IBOutlet var boxStatus: ClickableBox!
    @IBOutlet var boxAverageDamageGiven: ClickableBox!
    @IBOutlet var boxAverageDamageTaken: ClickableBox!
    
    var state: BobsBuddyState = .initial
    var _errorState: BobsBuddyErrorState = .none
    var errorState: BobsBuddyErrorState {
        get {
            return _errorState
        }
        set {
            if _errorState == newValue {
                return
            }
            _errorState = newValue
            warningIconVisibility = newValue != .none
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        spinner.appearance = NSAppearance(named: .vibrantLight)
        self.window!.ignoresMouseEvents = false
        self.boxStatus.clicked = self.bottomBar_mouseDown
        self.boxAverageDamageGiven.clicked = self.averageDamage_mouseDown
        self.boxAverageDamageTaken.clicked = self.averageDamage_mouseDown
        
        statusMessage = StatusMessageConverter.getStatusMessage(state: state, errorState: errorState, statsShown: showingResults, errorMessage: nil)
    }
    
    func formatPercent(p: Float) -> String {
        return String(format: "%.1f%%", p*100.0)
    }
    
    private var showingResults: Bool = false
    
    func showResults(show: Bool) {
        var sh = show
        if errorState != .none {
            sh = false
        }
        
        showingResults = sh
        let duration = 0.2
        let avgDmgH: CGFloat = Settings.showAverageDamage ? 32 : 0
        DispatchQueue.main.async {
            if sh {
                NSAnimationContext.runAnimationGroup({context in
                    context.duration = duration
                    self.boxMainHeightConstraint?.constant = 32
                    self.boxAverageDamageGivenHeightConstraint?.constant = avgDmgH
                    self.boxAverageDamageTakenHeightConstraint?.constant = avgDmgH
                    context.allowsImplicitAnimation = true
                })
            } else {
                NSAnimationContext.runAnimationGroup({context in
                    context.duration = duration
                    self.boxMainHeightConstraint?.constant = 0
                    self.boxAverageDamageGivenHeightConstraint?.constant = 0
                    self.boxAverageDamageTakenHeightConstraint?.constant = 0
                    context.allowsImplicitAnimation = true
                })
            }
        }
    }
    
    func setState(st: BobsBuddyState) {
        if st == state {
            return
        }
        
        let lastState = state
        state = st
                
        if state == .combat || state == .combatPartial {
            clearErrorState()
            showResults(show: Settings.showBobsBuddyDuringCombat)
        } else if state == .shopping || state == .shoppingAfterPartial || state == .gameOver || state == .gameOverAfterPartial {
            if !Settings.showBobsBuddyDuringShopping {
                showResults(show: true)
            } else if showingResults {
                // If the user has disabled the "Show During Shopping" setting we would usually hide Bob's Buddy here.
                // However we want to keep the panel expanded if the user left it expanded during combat and either:
                // - the game has ended (so we don't hide it again on the results screen), or
                // - the previous simulation was deferred (so that the user can see the result).
                showResults(show: state == .gameOver || state == .gameOverAfterPartial || lastState == .combatWithoutSimulation)
            }
        } else if state == .combatWithoutSimulation {
            showResults(show: false)
        } else if state == .waitingForTeammates {
            clearErrorState()
            showResults(show: false)
        }
        
        statusMessage = StatusMessageConverter.getStatusMessage(state: state, errorState: errorState, statsShown: showingResults, errorMessage: nil)
    }
    
    func setErrorState(error: BobsBuddyErrorState, message: String? = nil, show: Bool = false) {
        errorState = error
        statusMessage = StatusMessageConverter.getStatusMessage(state: state, errorState: errorState, statsShown: showingResults, errorMessage: message)
        showResults(show: show)
    }
    
    private func clearErrorState() {
        if errorState != .updateRequired && errorState != .monoNotFound && errorState != .failedToLoad {
            errorState = .none
        }
    }
    
    @MainActor
    func resetDisplays() {
        resetText()
        lethalRateStack?.alphaValue = 0.3
        opponentLethalRateStack?.alphaValue = 0.3
        setState(st: .initial)
        clearErrorState()
        showResults(show: false)
        showPercentagesHideSpinners()
    }

    @MainActor
    func resetText() {
        winRateDisplay = "-"
        lossRateDisplay = "-"
        tieRateDisplay = "-"
        lethalRateDisplay = "-"
        opponentLethalRateDisplay = "-"
        averageDamageGivenDisplay = "-"
        averageDamageTakenDisplay = "-"
    }
    
    @MainActor
    func showPercentagesHideSpinners() {
        spinnerVisibility = false
        percentagesVisibility = true
        spinner?.stopAnimation(nil)
        //self.window!.ignoresMouseEvents = false
    }
    
    @MainActor
    func hidePercentagesShowSpinners() {
        spinnerVisibility = true
        percentagesVisibility = false
        spinner?.startAnimation(nil)
        //self.window!.ignoresMouseEvents = false
    }
    
    @MainActor
    func showCompletedSimulation(winRate: Float, tieRate: Float, lossRate: Float, playerLethal: Float, opponentLethal: Float, possibleResults: [Int32]) {
        showPercentagesHideSpinners()
        
        setAverageDamage(possibleResults: possibleResults)
        winRateDisplay = formatPercent(p: winRate)
        tieRateDisplay = formatPercent(p: tieRate)
        lossRateDisplay = formatPercent(p: lossRate)
        lethalRateDisplay = formatPercent(p: playerLethal)
        opponentLethalRateDisplay = formatPercent(p: opponentLethal)
        lethalRateStack.alphaValue = playerLethal > 0 ? 1 : 0.3
        opponentLethalRateStack.alphaValue = opponentLethal > 0 ? 1 : 0.3
        window?.ignoresMouseEvents = false
    }
    
    @MainActor
    func showPartialDuosSimulation(winRate: Float, tieRate: Float, lossRate: Float, playerLethal: Float, opponentLethal: Float, possibleResults: [Int32], friendlyWon: Bool, playerCanDie: Bool, opponentCanDie: Bool) {
        resetText()

        if winRate == 1 || lossRate == 1 {
            winRateDisplay = formatPercent(p: winRate)
            tieRateDisplay = formatPercent(p: tieRate)
            lossRateDisplay = formatPercent(p: lossRate)
        } else if friendlyWon {
            winRateDisplay = formatPercent(p: winRate)
        } else {
            lossRateDisplay = formatPercent(p: lossRate)
        }

        opponentLethalRateDisplay = "0%"
        opponentLethalRateStack.alphaValue = 0.3
        lethalRateDisplay = "0%"
        lethalRateStack.alphaValue = 0.3

        if opponentCanDie {
            opponentLethalRateDisplay = "\(opponentLethal == 1 ? "" : "≥")\(formatPercent(p: opponentLethal))"
            opponentLethalRateStack.alphaValue = opponentLethal > 0 ? 1 : 0.3
        }
        if playerCanDie {
            lethalRateDisplay = "\(playerLethal == 1 ? "" : "≥")\(formatPercent(p: playerLethal))"
            lethalRateStack.alphaValue = playerLethal > 0 ? 1 : 0.3
        }
        showPercentagesHideSpinners()
    }
    
    private func setAverageDamage(possibleResults: [Int32]) {
        let playerDamageDealtPossibilities = possibleResults.filter({ x in x > 0 })
        var opponentSortedDamageDealtPossibilites = possibleResults.filter({ x in x < 0 }).map({ y in y * -1 })
        opponentSortedDamageDealtPossibilites.sort()

        let _playerDamageDealtBounds = getTwentiethAndEightiethPercentileFor(possibleResults: playerDamageDealtPossibilities)
        let _opponentDamageDealtBounds = getTwentiethAndEightiethPercentileFor(possibleResults: opponentSortedDamageDealtPossibilites)
        
        averageDamageGivenView.alphaValue = _playerDamageDealtBounds[0] == 0 && _playerDamageDealtBounds.count == 1 ? 0.3 : 1.0
        averageDamageTakenView.alphaValue = _opponentDamageDealtBounds[0] == 0 && _opponentDamageDealtBounds.count == 1 ? 0.3 : 1.0
        //OpponentAverageDamageOpacity = _opponentDamageDealtBounds == null ? SoftLabelOpacity : 1;

        averageDamageGivenDisplay = formatDamageBoundsFrom(from: _playerDamageDealtBounds)
        averageDamageTakenDisplay = formatDamageBoundsFrom(from: _opponentDamageDealtBounds)
    }
    
    private func getTwentiethAndEightiethPercentileFor(possibleResults: [Int32]) -> [Int32] {
        let count = possibleResults.count
        if count == 0 {
            return [Int32](arrayLiteral: 0)
        }
        
        return [Int32](arrayLiteral: possibleResults[Int(floor(0.2 * Double(count)))],
                       possibleResults[Int(floor(0.8 * Double(count)))])
    }

    private func formatDamageBoundsFrom(from: [Int32]) -> String {
        if from.count == 1 {
            return "\(from[0])"
        }
        
        if from[0] == from[1] {
            return "\(from[0])"
        }
        
        return "\(from[0])-\(from[1])"
    }

    override func updateFrames() {
        self.window!.ignoresMouseEvents = false
    }
    
    @objc func bottomBar_mouseDown(event: NSEvent) {
        if state == .combat || state == .combatWithoutSimulation || state == .shopping {
            if !showingResults {
                showResults(show: true)
            } else {
                showResults(show: false)
            }
        }
    }

    @objc func averageDamage_mouseDown(event: NSEvent) {
    }
}

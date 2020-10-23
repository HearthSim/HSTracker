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
    
    @IBOutlet weak var lethalRateStack: NSStackView!
    @objc dynamic var lethalRateDisplay: String = "-"
    @objc dynamic var winRateDisplay: String = "-"
    @objc dynamic var tieRateDisplay: String = "-"
    @objc dynamic var lossRateDisplay: String = "-"
    @IBOutlet weak var opponentLethalRateStack: NSStackView!
    @objc dynamic var opponentLethalRateDisplay: String = "-"
    @IBOutlet weak var spinner: NSProgressIndicator!
    @objc dynamic var percentagesVisibility: Bool = true
    @objc dynamic var spinnerVisibility: Bool = false
    @objc dynamic var warningIconVisibility: Bool = false
    @objc dynamic var statusMessage: String = "-"
    @objc dynamic var averageDamageGivenDisplay: String = "-"
    @IBOutlet weak var averageDamageGivenView: NSView!
    @objc dynamic var averageDamageTakenDisplay: String = "-"
    @IBOutlet weak var averageDamageTakenView: NSView!
    @IBOutlet weak var boxMainHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var boxAverageDamageGivenHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var boxAverageDamageTakenHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var boxStatus: ClickableBox!
    @IBOutlet weak var boxAverageDamageGiven: ClickableBox!
    @IBOutlet weak var boxAverageDamageTaken: ClickableBox!
    
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
                    self.boxMainHeightConstraint.constant = 32
                    self.boxAverageDamageGivenHeightConstraint.constant = avgDmgH
                    self.boxAverageDamageTakenHeightConstraint.constant = avgDmgH
                    context.allowsImplicitAnimation = true
                })
            } else {
                NSAnimationContext.runAnimationGroup({context in
                    context.duration = duration
                    self.boxMainHeightConstraint.constant = 0
                    self.boxAverageDamageGivenHeightConstraint.constant = 0
                    self.boxAverageDamageTakenHeightConstraint.constant = 0
                    context.allowsImplicitAnimation = true
                })
            }
        }
    }
    
    func setState(st: BobsBuddyState) {
        if st == state {
            return
        }
        
        state = st
                
        if state == .combat {
            clearErrorState()
            showResults(show: Settings.showBobsBuddyDuringCombat)
        } else if state == .shopping {
            showResults(show: Settings.showBobsBuddyDuringShopping)
        }
        
        statusMessage = StatusMessageConverter.getStatusMessage(state: state, errorState: errorState, statsShown: showingResults)
    }
    
    func setErrorState(error: BobsBuddyErrorState) {
        errorState = error
        showResults(show: false)
        statusMessage = StatusMessageConverter.getStatusMessage(state: state, errorState: errorState, statsShown: showingResults)
    }
    
    private func clearErrorState() {
        if errorState != .updateRequired && errorState != .monoNotFound && errorState != .failedToLoad {
            errorState = .none
        }
    }
    
    func resetDisplays() {
        DispatchQueue.main.async {
            self.winRateDisplay = "-"
            self.lossRateDisplay = "-"
            self.tieRateDisplay = "-"
            self.averageDamageGivenDisplay = "-"
            self.averageDamageTakenDisplay = "-"
            self.lethalRateDisplay = "-"
            self.lethalRateStack.alphaValue = 0.3
            self.opponentLethalRateDisplay = "-"
            self.opponentLethalRateStack.alphaValue = 0.3
            self.setState(st: .initial)
            self.clearErrorState()
            self.showResults(show: false)
            self.showPercentagesHideSpinners()
        }
    }
    
    func showPercentagesHideSpinners() {
        DispatchQueue.main.async {
            self.spinnerVisibility = false
            self.percentagesVisibility = true
            self.spinner.stopAnimation(nil)
            //self.window!.ignoresMouseEvents = false
        }
    }
    
    func hidePercentagesShowSpinners() {
        DispatchQueue.main.async {
            self.spinnerVisibility = true
            self.percentagesVisibility = false
            self.spinner.startAnimation(nil)
            //self.window!.ignoresMouseEvents = false
        }
    }
    
    func showCompletedSimulation(winRate: Float, tieRate: Float, lossRate: Float, playerLethal: Float, opponentLethal: Float, possibleResults: [Int32]) {
        showPercentagesHideSpinners()
        
        DispatchQueue.main.async {
            self.setAverageDamage(possibleResults: possibleResults)
            self.winRateDisplay = self.formatPercent(p: winRate)
            self.tieRateDisplay = self.formatPercent(p: tieRate)
            self.lossRateDisplay = self.formatPercent(p: lossRate)
            self.lethalRateDisplay = self.formatPercent(p: playerLethal)
            self.opponentLethalRateDisplay = self.formatPercent(p: opponentLethal)
            self.lethalRateStack.alphaValue = playerLethal > 0 ? 1 : 0.3
            self.opponentLethalRateStack.alphaValue = opponentLethal > 0 ? 1 : 0.3
            self.window!.ignoresMouseEvents = false
        }
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
        if state == .combat || state == .shopping {
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

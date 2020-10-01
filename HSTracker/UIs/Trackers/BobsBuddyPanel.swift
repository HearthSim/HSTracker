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
    
    @IBOutlet weak var lethalRateDisplay: NSTextField!
    @IBOutlet weak var winRateDisplay: NSTextField!
    @IBOutlet weak var tieRateDisplay: NSTextField!
    @IBOutlet weak var lossRateDisplay: NSTextField!
    @IBOutlet weak var opponentLethalRateDisplay: NSTextField!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @objc dynamic var percentagesVisibility: Bool = true
    @objc dynamic var spinnerVisibility: Bool = false
    @objc dynamic var warningIconVisibility: Bool = false
    @objc dynamic var statusMessage: String = "-"
    @IBOutlet weak var boxMain: NSBox!
    @IBOutlet weak var boxMainHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var boxStatus: ClickableBox!
    
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
        self.boxMain.superview?.translatesAutoresizingMaskIntoConstraints = false
        spinner.appearance = NSAppearance(named: .vibrantLight)
        self.window!.ignoresMouseEvents = false
        self.boxStatus.clicked = self.bottomBar_mouseDown
    }
    
    func formatPercent(p: Float) -> String {
        return String(format: "%.1f%%", p*100.0)
    }
    
    func changeAlpha(c: Color, a: Float) -> Color {
        return Color(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent, alpha: CGFloat(a))
    }
    
    private var showingResults: Bool = false
    
    func showResults(show: Bool) {
        var sh = show
        if errorState != .none {
            sh = false
        }
        
        showingResults = sh
        let duration = 0.2
        DispatchQueue.main.async {
            if sh {
                NSAnimationContext.runAnimationGroup({context in
                    context.duration = duration
                    self.boxMainHeightConstraint.constant = 42
                    context.allowsImplicitAnimation = true
                    self.boxMain.superview?.layoutSubtreeIfNeeded()
                })
            } else {
                NSAnimationContext.runAnimationGroup({context in
                    context.duration = duration
                    self.boxMainHeightConstraint.constant = 2
                    context.allowsImplicitAnimation = true
                    self.boxMain.superview?.layoutSubtreeIfNeeded()
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
        winRateDisplay.stringValue = "-"
        lossRateDisplay.stringValue = "-"
        tieRateDisplay.stringValue = "-"
        let cl = lethalRateDisplay.textColor!
        lethalRateDisplay.textColor = changeAlpha(c: cl, a: 0)
        let cl2 = opponentLethalRateDisplay.textColor!
        opponentLethalRateDisplay.textColor = changeAlpha(c: cl2, a: 0)
        setState(st: .initial)
        clearErrorState()
        showResults(show: false)
        showPercentagesHideSpinners()
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
    
    func showCompletedSimulation(winRate: Float, tieRate: Float, lossRate: Float, playerLethal: Float, opponentLethal: Float) {
        showPercentagesHideSpinners()
        
        DispatchQueue.main.async {
            self.winRateDisplay.stringValue = self.formatPercent(p: winRate)
            self.tieRateDisplay.stringValue = self.formatPercent(p: tieRate)
            self.lossRateDisplay.stringValue = self.formatPercent(p: lossRate)
            self.lethalRateDisplay.stringValue = self.formatPercent(p: playerLethal)
            self.opponentLethalRateDisplay.stringValue = self.formatPercent(p: opponentLethal)
            let cl = self.lethalRateDisplay.textColor!
            self.lethalRateDisplay.textColor = self.changeAlpha(c: cl, a: playerLethal > 0 ? 1 : 0.3)
            let cl2 = self.opponentLethalRateDisplay.textColor!
            self.opponentLethalRateDisplay.textColor = self.changeAlpha(c: cl2, a: opponentLethal > 0 ? 1 : 0.3)
            self.window!.ignoresMouseEvents = false
        }
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
}

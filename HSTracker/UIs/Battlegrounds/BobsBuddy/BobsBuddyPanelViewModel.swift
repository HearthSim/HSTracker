//
//  BobsBuddyPanelViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/14/20
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// What BobsBuddyInvoker drives the panel through. It is a protocol, and not
// gated on the SwiftUI baseline, because the invoker isn't either: the view
// model behind it is a RootOverlay child and so has to be.
protocol BobsBuddyDisplay: AnyObject {
    func setState(st: BobsBuddyState)
    func setErrorState(error: BobsBuddyErrorState, message: String?, show: Bool)
    func resetDisplays()
    func resetText()
    func hidePercentagesShowSpinners()
    func showPercentagesHideSpinners()
    func showCompletedSimulation(winRate: Float, tieRate: Float, lossRate: Float, playerLethal: Float, opponentLethal: Float, possibleResults: [Int32])
    func showPartialDuosSimulation(winRate: Float, tieRate: Float, lossRate: Float, playerLethal: Float, opponentLethal: Float, possibleResults: [Int32], friendlyWon: Bool, playerCanDie: Bool, opponentCanDie: Bool)
}

extension BobsBuddyDisplay {
    func setErrorState(error: BobsBuddyErrorState) {
        setErrorState(error: error, message: nil, show: false)
    }

    func setErrorState(error: BobsBuddyErrorState, message: String?) {
        setErrorState(error: error, message: message, show: false)
    }

    func setErrorState(error: BobsBuddyErrorState, show: Bool) {
        setErrorState(error: error, message: nil, show: show)
    }
}

// Port of the state HDT's BobsBuddyPanel.xaml.cs keeps behind its own bindings.
@available(macOS 10.15, *)
class BobsBuddyPanelViewModel: ObservableObject, BobsBuddyDisplay {
    // Game.updateBobsBuddyOverlay, which is what used to show and hide the
    // panel's own window.
    @Published var isShown = false

    // The two storyboards: ResultPanel's height, and the average damage
    // panels' - 0 or 55 in HDT, animated over 0.2s.
    @Published private(set) var resultsExpanded = false
    @Published private(set) var averageDamageExpanded = false

    @Published private(set) var winRateDisplay = "-"
    @Published private(set) var tieRateDisplay = "-"
    @Published private(set) var lossRateDisplay = "-"
    @Published private(set) var playerLethalDisplay = "-"
    @Published private(set) var opponentLethalDisplay = "-"
    @Published private(set) var averageDamageGivenDisplay = "-"
    @Published private(set) var averageDamageTakenDisplay = "-"

    @Published private(set) var playerLethalOpacity = softLabelOpacity
    @Published private(set) var opponentLethalOpacity = softLabelOpacity
    @Published private(set) var playerAverageDamageOpacity = softLabelOpacity
    @Published private(set) var opponentAverageDamageOpacity = softLabelOpacity

    @Published private(set) var showSpinner = false
    @Published private(set) var warningIconVisible = false
    @Published private(set) var statusMessage = ""

    // BobsBuddyPanel.xaml.cs's own constant for a stat that is zero or unknown.
    static let softLabelOpacity = 0.3

    // The storyboards' Duration="0:0:0.2".
    private static let slideDuration = 0.2

    private var state: BobsBuddyState = .initial
    private var showingResults = false

    private var _errorState: BobsBuddyErrorState = .none
    private var errorState: BobsBuddyErrorState {
        get {
            return _errorState
        }
        set {
            if _errorState == newValue {
                return
            }
            _errorState = newValue
            warningIconVisible = newValue != .none
        }
    }

    init() {
        statusMessage = StatusMessageConverter.getStatusMessage(state: state, errorState: errorState, statsShown: showingResults, errorMessage: nil)
    }

    // MARK: - BobsBuddyDisplay

    func setState(st: BobsBuddyState) {
        onMain {
            guard st != self.state else {
                return
            }

            let lastState = self.state
            self.state = st

            if st == .combat || st == .combatPartial {
                self.clearErrorState()
                self.showResults(show: Settings.showBobsBuddyDuringCombat)
            } else if st == .shopping || st == .shoppingAfterPartial || st == .gameOver || st == .gameOverAfterPartial {
                if Settings.showBobsBuddyDuringShopping {
                    self.showResults(show: true)
                } else if self.showingResults {
                    // If the user has disabled the "Show During Shopping" setting we would usually hide Bob's Buddy here.
                    // However we want to keep the panel expanded if the user left it expanded during combat and either:
                    // - the game has ended (so we don't hide it again on the results screen), or
                    // - the previous simulation was deferred (so that the user can see the result).
                    self.showResults(show: st == .gameOver || st == .gameOverAfterPartial || lastState == .combatWithoutSimulation)
                } else {
                    self.showResults(show: false)
                }
            } else if st == .combatWithoutSimulation {
                self.showResults(show: false)
            } else if st == .waitingForTeammates {
                self.clearErrorState()
                self.showResults(show: false)
            }

            self.updateStatusMessage()
        }
    }

    func setErrorState(error: BobsBuddyErrorState, message: String? = nil, show: Bool = false) {
        onMain {
            self.errorState = error
            self.showResults(show: show)
            self.updateStatusMessage(errorMessage: message)
        }
    }

    func resetDisplays() {
        onMain {
            self.resetTextOnMain()
            self.playerLethalOpacity = Self.softLabelOpacity
            self.opponentLethalOpacity = Self.softLabelOpacity
            self.playerAverageDamageOpacity = Self.softLabelOpacity
            self.opponentAverageDamageOpacity = Self.softLabelOpacity
            self.state = .initial
            self.clearErrorState()
            self.showResults(show: false)
            self.showPercentagesHideSpinnersOnMain()
            self.updateStatusMessage()
        }
    }

    func resetText() {
        onMain {
            self.resetTextOnMain()
        }
    }

    func hidePercentagesShowSpinners() {
        onMain {
            self.showSpinner = true
        }
    }

    func showPercentagesHideSpinners() {
        onMain {
            self.showPercentagesHideSpinnersOnMain()
        }
    }

    func showCompletedSimulation(winRate: Float, tieRate: Float, lossRate: Float, playerLethal: Float, opponentLethal: Float, possibleResults: [Int32]) {
        onMain {
            self.showPercentagesHideSpinnersOnMain()

            self.setAverageDamage(possibleResults: possibleResults)
            self.winRateDisplay = Self.formatPercent(p: winRate)
            self.tieRateDisplay = Self.formatPercent(p: tieRate)
            self.lossRateDisplay = Self.formatPercent(p: lossRate)
            self.playerLethalDisplay = Self.formatPercent(p: playerLethal)
            self.opponentLethalDisplay = Self.formatPercent(p: opponentLethal)
            self.playerLethalOpacity = playerLethal > 0 ? 1 : Self.softLabelOpacity
            self.opponentLethalOpacity = opponentLethal > 0 ? 1 : Self.softLabelOpacity
        }
    }

    func showPartialDuosSimulation(winRate: Float, tieRate: Float, lossRate: Float, playerLethal: Float, opponentLethal: Float, possibleResults: [Int32], friendlyWon: Bool, playerCanDie: Bool, opponentCanDie: Bool) {
        onMain {
            self.resetTextOnMain()

            if winRate == 1 || lossRate == 1 {
                self.winRateDisplay = Self.formatPercent(p: winRate)
                self.tieRateDisplay = Self.formatPercent(p: tieRate)
                self.lossRateDisplay = Self.formatPercent(p: lossRate)
            } else if friendlyWon {
                self.winRateDisplay = Self.formatPercent(p: winRate, atLeast: true)
            } else {
                self.lossRateDisplay = Self.formatPercent(p: lossRate, atLeast: true)
            }

            self.opponentLethalDisplay = "0%"
            self.opponentLethalOpacity = Self.softLabelOpacity
            self.playerLethalDisplay = "0%"
            self.playerLethalOpacity = Self.softLabelOpacity

            if opponentCanDie {
                self.opponentLethalDisplay = Self.formatPercent(p: opponentLethal, atLeast: opponentLethal != 1)
                self.opponentLethalOpacity = opponentLethal > 0 ? 1 : Self.softLabelOpacity
            }
            if playerCanDie {
                self.playerLethalDisplay = Self.formatPercent(p: playerLethal, atLeast: playerLethal != 1)
                self.playerLethalOpacity = playerLethal > 0 ? 1 : Self.softLabelOpacity
            }
            self.showPercentagesHideSpinnersOnMain()
        }
    }

    // MARK: - The status bar's own click

    // BottomBar_MouseDown: the bar toggles the panel while a combat or the
    // shopping phase after it is in progress.
    func toggleResults() {
        onMain {
            guard self.state == .combat || self.state == .combatWithoutSimulation || self.state == .shopping else {
                return
            }
            self.showResults(show: !self.showingResults)
            self.updateStatusMessage()
        }
    }

    // MARK: - Internals

    private func showResults(show: Bool) {
        var show = show
        if errorState != .none {
            show = false
        }

        showingResults = show
        // Config.AlwaysShowAverageDamage in HDT: the two side panels slide with
        // the results only when the user asked for them.
        let showAverageDamage = show && Settings.showAverageDamage
        withAnimation(.easeInOut(duration: Self.slideDuration)) {
            resultsExpanded = show
            averageDamageExpanded = showAverageDamage
        }
    }

    private func resetTextOnMain() {
        winRateDisplay = "-"
        lossRateDisplay = "-"
        tieRateDisplay = "-"
        playerLethalDisplay = "-"
        opponentLethalDisplay = "-"
        averageDamageGivenDisplay = "-"
        averageDamageTakenDisplay = "-"
    }

    private func showPercentagesHideSpinnersOnMain() {
        showSpinner = false
    }

    private func clearErrorState() {
        if errorState != .updateRequired && errorState != .monoNotFound && errorState != .failedToLoad {
            errorState = .none
        }
    }

    private func updateStatusMessage(errorMessage: String? = nil) {
        statusMessage = StatusMessageConverter.getStatusMessage(state: state, errorState: errorState, statsShown: showingResults, errorMessage: errorMessage)
    }

    private func setAverageDamage(possibleResults: [Int32]) {
        let playerDamageDealtPossibilities = possibleResults.filter({ x in x > 0 })
        var opponentSortedDamageDealtPossibilites = possibleResults.filter({ x in x < 0 }).map({ y in y * -1 })
        opponentSortedDamageDealtPossibilites.sort()

        let playerDamageDealtBounds = Self.getTwentiethAndEightiethPercentileFor(possibleResults: playerDamageDealtPossibilities)
        let opponentDamageDealtBounds = Self.getTwentiethAndEightiethPercentileFor(possibleResults: opponentSortedDamageDealtPossibilites)

        playerAverageDamageOpacity = playerDamageDealtBounds[0] == 0 && playerDamageDealtBounds.count == 1 ? Self.softLabelOpacity : 1.0
        opponentAverageDamageOpacity = opponentDamageDealtBounds[0] == 0 && opponentDamageDealtBounds.count == 1 ? Self.softLabelOpacity : 1.0

        averageDamageGivenDisplay = Self.formatDamageBoundsFrom(from: playerDamageDealtBounds)
        averageDamageTakenDisplay = Self.formatDamageBoundsFrom(from: opponentDamageDealtBounds)
    }

    private static func getTwentiethAndEightiethPercentileFor(possibleResults: [Int32]) -> [Int32] {
        let count = possibleResults.count
        if count == 0 {
            return [Int32](arrayLiteral: 0)
        }

        return [Int32](arrayLiteral: possibleResults[Int(floor(0.2 * Double(count)))],
                       possibleResults[Int(floor(0.8 * Double(count)))])
    }

    private static func formatDamageBoundsFrom(from: [Int32]) -> String {
        if from.count == 1 {
            return "\(from[0])"
        }

        if from[0] == from[1] {
            return "\(from[0])"
        }

        return "\(from[0])-\(from[1])"
    }

    private static func formatPercent(p: Float, atLeast: Bool = false) -> String {
        return (atLeast ? "≥" : "") + String(format: "%.1f%%", locale: Language.culture, p * 100.0)
    }

    // BobsBuddyInvoker calls in from the mono thread and from its own promise
    // chain, and @Published has to be written on the main one.
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}

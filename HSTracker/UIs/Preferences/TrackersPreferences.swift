//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class TrackersPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.trackers
    
    var preferencePaneTitle = String.localizedString("Trackers", comment: "")
    
    var toolbarItemIcon = NSImage(named: "gear")!

    @IBOutlet weak var highlightCardsInHand: NSButton!
    @IBOutlet weak var highlightLastDrawn: NSButton!
    @IBOutlet weak var removeCards: NSButton!
    @IBOutlet weak var highlightDiscarded: NSButton!
    @IBOutlet weak var opacity: NSSlider!
    @IBOutlet weak var cardSize: NSComboBox!
    @IBOutlet weak var showTimer: NSButton!
    @IBOutlet weak var autoPositionTrackers: NSButton!
    @IBOutlet weak var showSecretHelper: NSButton!
    @IBOutlet weak var showRarityColors: NSButton!
    @IBOutlet weak var showFloatingCard: NSButton!
    @IBOutlet weak var theme: NSComboBox!
    @IBOutlet weak var allowFullscreen: NSButton!
    @IBOutlet weak var hideAllWhenNotInGame: NSButton!
    @IBOutlet weak var hideAllWhenGameInBackground: NSButton!
    @IBOutlet weak var disableTrackingInSpectatorMode: NSButton!
    @IBOutlet weak var showExperienceCounter: NSButton!
    @IBOutlet weak var showMulliganToast: NSButton!
    @IBOutlet weak var showFlavorText: NSButton!
    @IBOutlet weak var enableMulliganGuide: NSButton!
    @IBOutlet weak var showMulliganGuidePreLobby: NSButton!
    @IBOutlet weak var autoShowMulliganGuide: NSButton!
    
    let themes = ["classic", "frost", "dark", "minimal"]

    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard highlightCardsInHand != nil else {
            return
        }
                
        highlightCardsInHand.state = Settings.highlightCardsInHand ? .on : .off
        highlightLastDrawn.state = Settings.highlightLastDrawn ? .on : .off
        removeCards.state = Settings.removeCardsFromDeck ? .on : .off
        highlightDiscarded.state = Settings.highlightDiscarded ? .on : .off
        opacity.doubleValue = Settings.trackerOpacity
        var index: Int
        switch Settings.cardSize {
        case .tiny: index = 0
        case .small: index = 1
        case .medium: index = 2
        case .big: index = 3
        case .huge: index = 4
        }
        cardSize.selectItem(at: index)
        showTimer.state = Settings.showTimer ? .on : .off
        autoPositionTrackers.state = Settings.autoPositionTrackers ? .on : .off
        showSecretHelper.state = Settings.showSecretHelper ? .on : .off
        showRarityColors.state = Settings.showRarityColors ? .on : .off
        showFloatingCard.state = Settings.showFloatingCard ? .on : .off
        showExperienceCounter.state = Settings.showExperienceCounter ? .on : .off
        showMulliganToast.state = Settings.showMulliganToast ? .on : .off
        showFlavorText.state = Settings.showFlavorText ? .on : .off

        theme.selectItem(at: themes.firstIndex(of: Settings.theme) ?? 0)
        allowFullscreen.state = Settings.canJoinFullscreen ? .on : .off
        hideAllWhenNotInGame.state = Settings.hideAllTrackersWhenNotInGame ? .on : .off
        hideAllWhenGameInBackground.state = Settings.hideAllWhenGameInBackground
            ? .on : .off
        disableTrackingInSpectatorMode.state = Settings.dontTrackWhileSpectating ? .on : .off
        enableMulliganGuide.state = Settings.enableMulliganGuide ? .on : .off
        showMulliganGuidePreLobby.state = Settings.showMulliganGuidePreLobby ? .on : .off
        autoShowMulliganGuide.state = Settings.autoShowMulliganGuide ? .on : .off
    }

    @IBAction func sliderChange(_ sender: AnyObject) {
        Settings.trackerOpacity = opacity.doubleValue
    }

    @IBAction func comboboxChange(_ sender: NSComboBox) {
        if sender == cardSize {
            if let value = cardSize.objectValueOfSelectedItem as? String {
                let size: CardSize
                switch value {
                case String.localizedString("Tiny", comment: ""): size = .tiny
                case String.localizedString("Small", comment: ""): size = .small
                case String.localizedString("Big", comment: ""): size = .big
                case String.localizedString("Huge", comment: ""): size = .huge
                default: size = .medium
                }
                Settings.cardSize = size
            }
        } else if sender == theme {
            Settings.theme = themes[theme.indexOfSelectedItem]
        }
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == highlightCardsInHand {
            Settings.highlightCardsInHand = highlightCardsInHand.state == .on
        } else if sender == highlightLastDrawn {
            Settings.highlightLastDrawn = highlightLastDrawn.state == .on
        } else if sender == removeCards {
            Settings.removeCardsFromDeck = removeCards.state == .on
        } else if sender == highlightDiscarded {
            Settings.highlightDiscarded = highlightDiscarded.state == .on
        } else if sender == autoPositionTrackers {
            Settings.autoPositionTrackers = autoPositionTrackers.state == .on
            if Settings.autoPositionTrackers {
                Settings.windowsLocked = true
            }
        } else if sender == showSecretHelper {
            Settings.showSecretHelper = showSecretHelper.state == .on
        } else if sender == showRarityColors {
            Settings.showRarityColors = showRarityColors.state == .on
        } else if sender == showTimer {
            Settings.showTimer = showTimer.state == .on
        } else if sender == showFloatingCard {
            Settings.showFloatingCard = showFloatingCard.state == .on
        } else if sender == allowFullscreen {
            Settings.canJoinFullscreen = allowFullscreen.state == .on
        } else if sender == hideAllWhenNotInGame {
            Settings.hideAllTrackersWhenNotInGame = hideAllWhenNotInGame.state == .on
        } else if sender == hideAllWhenGameInBackground {
            Settings.hideAllWhenGameInBackground = hideAllWhenGameInBackground.state == .on
        } else if sender == disableTrackingInSpectatorMode {
            Settings.dontTrackWhileSpectating = disableTrackingInSpectatorMode.state == .on
        } else if sender == showExperienceCounter {
            Settings.showExperienceCounter = showExperienceCounter.state == .on
            let game = AppDelegate.instance().coreManager.game
            
            if showExperienceCounter.state == .on {
                if let mode = game.currentMode, mode == Mode.hub {
                    game.windowManager.experiencePanel.visible = true
                }
            } else {
                game.windowManager.experiencePanel.visible = false
            }
        } else if sender == showMulliganToast {
            Settings.showMulliganToast = showMulliganToast.state == .on
        } else if sender == showFlavorText {
            Settings.showFlavorText = showFlavorText.state == .on
        } else if sender == enableMulliganGuide {
            Settings.enableMulliganGuide = enableMulliganGuide.state == .on
            let game = AppDelegate.instance().coreManager.game
            if enableMulliganGuide.state == .on {
                game.hideMulliganGuideStats()
                // Clear the Mulligan overlay if it's visible
                game.player.mulliganCardStats = nil
            }
            game.updateMulliganGuidePreLobby()
        } else if sender == showMulliganGuidePreLobby {
            Settings.showMulliganGuidePreLobby = showMulliganGuidePreLobby.state == .on
            AppDelegate.instance().coreManager.game.updateMulliganGuidePreLobby()
        } else if sender == autoShowMulliganGuide {
            Settings.autoShowMulliganGuide = autoShowMulliganGuide.state == .on
        }
    }
}

// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let trackers = Self("trackers")
}

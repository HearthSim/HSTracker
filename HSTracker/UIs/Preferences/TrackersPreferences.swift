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
    
    var preferencePaneTitle = NSLocalizedString("Trackers", comment: "")
    
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
    @IBOutlet weak var showTopdeckChance: NSButton!
    @IBOutlet weak var theme: NSComboBox!
    @IBOutlet weak var allowFullscreen: NSButton!
    @IBOutlet weak var hideAllWhenNotInGame: NSButton!
    @IBOutlet weak var hideAllWhenGameInBackground: NSButton!
    @IBOutlet weak var disableTrackingInSpectatorMode: NSButton!
    @IBOutlet weak var floatingCardStyle: NSComboBox!
    @IBOutlet weak var showExperienceCounter: NSButton!
    
    let themes = ["classic", "frost", "dark", "minimal"]

    override func viewDidLoad() {
        super.viewDidLoad()
                
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
        showTopdeckChance.state = Settings.showTopdeckchance ? .on : .off
        showExperienceCounter.state = Settings.showExperienceCounter ? .on : .off

        floatingCardStyle.isEnabled = Settings.showFloatingCard
        switch Settings.floatingCardStyle {
        case .text: index = 0
        case .image: index = 1
        }
        floatingCardStyle.selectItem(at: index)

        theme.selectItem(at: themes.firstIndex(of: Settings.theme) ?? 0)
        allowFullscreen.state = Settings.canJoinFullscreen ? .on : .off
        hideAllWhenNotInGame.state = Settings.hideAllTrackersWhenNotInGame ? .on : .off
        hideAllWhenGameInBackground.state = Settings.hideAllWhenGameInBackground
            ? .on : .off
        disableTrackingInSpectatorMode.state = Settings.dontTrackWhileSpectating ? .on : .off
    }

    @IBAction func sliderChange(_ sender: AnyObject) {
        Settings.trackerOpacity = opacity.doubleValue
    }

    @IBAction func comboboxChange(_ sender: NSComboBox) {
        if sender == cardSize {
            if let value = cardSize.objectValueOfSelectedItem as? String {
                let size: CardSize
                switch value {
                case NSLocalizedString("Tiny", comment: ""): size = .tiny
                case NSLocalizedString("Small", comment: ""): size = .small
                case NSLocalizedString("Big", comment: ""): size = .big
                case NSLocalizedString("Huge", comment: ""): size = .huge
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
            showTopdeckChance.isEnabled = Settings.showFloatingCard
        } else if sender == showTopdeckChance {
            Settings.showTopdeckchance = showTopdeckChance.state == .on
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
        }
    }
}

// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let trackers = Self("trackers")
}

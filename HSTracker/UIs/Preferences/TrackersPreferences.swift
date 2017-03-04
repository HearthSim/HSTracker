//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class TrackersPreferences: NSViewController {

    @IBOutlet weak var highlightCardsInHand: NSButton!
    @IBOutlet weak var highlightLastDrawn: NSButton!
    @IBOutlet weak var removeCards: NSButton!
    @IBOutlet weak var showPlayerGet: NSButton!
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
    @IBOutlet weak var floatingCardStyle: NSComboBox!

    let themes = ["classic", "frost", "dark", "minimal"]

    override func viewDidLoad() {
        super.viewDidLoad()
        highlightCardsInHand.state = Settings.highlightCardsInHand ? NSOnState : NSOffState
        highlightLastDrawn.state = Settings.highlightLastDrawn ? NSOnState : NSOffState
        removeCards.state = Settings.removeCardsFromDeck ? NSOnState : NSOffState
        highlightDiscarded.state = Settings.highlightDiscarded ? NSOnState : NSOffState
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
        showTimer.state = Settings.showTimer ? NSOnState : NSOffState
        autoPositionTrackers.state = Settings.autoPositionTrackers ? NSOnState : NSOffState
        showSecretHelper.state = Settings.showSecretHelper ? NSOnState : NSOffState
        showRarityColors.state = Settings.showRarityColors ? NSOnState : NSOffState
        showFloatingCard.state = Settings.showFloatingCard ? NSOnState : NSOffState
        showTopdeckChance.state = Settings.showTopdeckchance ? NSOnState : NSOffState

        floatingCardStyle.isEnabled = Settings.showFloatingCard
        switch Settings.floatingCardStyle {
        case .text: index = 0
        case .image: index = 1
        }
        floatingCardStyle.selectItem(at: index)

        theme.selectItem(at: themes.index(of: Settings.theme) ?? 0)
        allowFullscreen.state = Settings.canJoinFullscreen ? NSOnState : NSOffState
        hideAllWhenNotInGame.state = Settings.hideAllTrackersWhenNotInGame ? NSOnState : NSOffState
        hideAllWhenGameInBackground.state = Settings.hideAllWhenGameInBackground
            ? NSOnState : NSOffState
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
            Settings.highlightCardsInHand = highlightCardsInHand.state == NSOnState
        } else if sender == highlightLastDrawn {
            Settings.highlightLastDrawn = highlightLastDrawn.state == NSOnState
        } else if sender == removeCards {
            Settings.removeCardsFromDeck = removeCards.state == NSOnState
        } else if sender == highlightDiscarded {
            Settings.highlightDiscarded = highlightDiscarded.state == NSOnState
        } else if sender == autoPositionTrackers {
            Settings.autoPositionTrackers = autoPositionTrackers.state == NSOnState
            if Settings.autoPositionTrackers {
                Settings.windowsLocked = true
            }
        } else if sender == showSecretHelper {
            Settings.showSecretHelper = showSecretHelper.state == NSOnState
        } else if sender == showRarityColors {
            Settings.showRarityColors = showRarityColors.state == NSOnState
        } else if sender == showTimer {
            Settings.showTimer = showTimer.state == NSOnState
        } else if sender == showFloatingCard {
            Settings.showFloatingCard = showFloatingCard.state == NSOnState
            showTopdeckChance.isEnabled = Settings.showFloatingCard
        } else if sender == showTopdeckChance {
            Settings.showTopdeckchance = showTopdeckChance.state == NSOnState
        } else if sender == allowFullscreen {
            Settings.canJoinFullscreen = allowFullscreen.state == NSOnState
        } else if sender == hideAllWhenNotInGame {
            Settings.hideAllTrackersWhenNotInGame = hideAllWhenNotInGame.state == NSOnState
        } else if sender == hideAllWhenGameInBackground {
            Settings.hideAllWhenGameInBackground = hideAllWhenGameInBackground.state == NSOnState
        }
    }
}

// MARK: - MASPreferencesViewController

extension TrackersPreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "trackers"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImageNameAdvanced)
    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("Trackers", comment: "")
    }
}

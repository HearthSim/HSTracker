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

    let themes = ["classic", "frost", "dark", "minimal"]

    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        highlightCardsInHand.state = settings.highlightCardsInHand ? NSOnState : NSOffState
        highlightLastDrawn.state = settings.highlightLastDrawn ? NSOnState : NSOffState
        removeCards.state = settings.removeCardsFromDeck ? NSOnState : NSOffState
        highlightDiscarded.state = settings.highlightDiscarded ? NSOnState : NSOffState
        opacity.doubleValue = settings.trackerOpacity
        let index: Int
        switch settings.cardSize {
        case .tiny: index = 0
        case .small: index = 1
        case .medium: index = 2
        case .big: index = 3
        case .huge: index = 4
        }
        cardSize.selectItem(at: index)
        showTimer.state = settings.showTimer ? NSOnState : NSOffState
        autoPositionTrackers.state = settings.autoPositionTrackers ? NSOnState : NSOffState
        showSecretHelper.state = settings.showSecretHelper ? NSOnState : NSOffState
        showRarityColors.state = settings.showRarityColors ? NSOnState : NSOffState
        showFloatingCard.state = settings.showFloatingCard ? NSOnState : NSOffState
        showFloatingCard.state = settings.showTopdeckchance ? NSOnState : NSOffState
        theme.selectItem(at: themes.index(of: settings.theme) ?? 0)
        allowFullscreen.state = settings.canJoinFullscreen ? NSOnState : NSOffState
    }

    @IBAction func sliderChange(_ sender: AnyObject) {
        let settings = Settings.instance
        settings.trackerOpacity = opacity.doubleValue
    }

    @IBAction func comboboxChange(_ sender: NSComboBox) {
        let settings = Settings.instance
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
                settings.cardSize = size
            }
        } else if sender == theme {
            settings.theme = themes[theme.indexOfSelectedItem] 
        }
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        let settings = Settings.instance

        if sender == highlightCardsInHand {
            settings.highlightCardsInHand = highlightCardsInHand.state == NSOnState
        } else if sender == highlightLastDrawn {
            settings.highlightLastDrawn = highlightLastDrawn.state == NSOnState
        } else if sender == removeCards {
            settings.removeCardsFromDeck = removeCards.state == NSOnState
        } else if sender == highlightDiscarded {
            settings.highlightDiscarded = highlightDiscarded.state == NSOnState
        } else if sender == autoPositionTrackers {
            settings.autoPositionTrackers = autoPositionTrackers.state == NSOnState
            if settings.autoPositionTrackers {
                settings.windowsLocked = true
            }
        } else if sender == showSecretHelper {
            settings.showSecretHelper = showSecretHelper.state == NSOnState
        } else if sender == showRarityColors {
            settings.showRarityColors = showRarityColors.state == NSOnState
        } else if sender == showTimer {
            settings.showTimer = showTimer.state == NSOnState
        } else if sender == showFloatingCard {
            settings.showFloatingCard = showFloatingCard.state == NSOnState
            if settings.showFloatingCard {
                showTopdeckChance.isEnabled = true
            } else {
                showTopdeckChance.isEnabled = false
            }
        } else if sender == showTopdeckChance {
            settings.showTopdeckchance = showTopdeckChance.state == NSOnState
        } else if sender == allowFullscreen {
            settings.canJoinFullscreen = allowFullscreen.state == NSOnState
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

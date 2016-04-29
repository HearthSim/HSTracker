//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class TrackersPreferences: NSViewController, MASPreferencesViewController {

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

    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        highlightCardsInHand.state = settings.highlightCardsInHand ? NSOnState : NSOffState
        highlightLastDrawn.state = settings.highlightLastDrawn ? NSOnState : NSOffState
        removeCards.state = settings.removeCardsFromDeck ? NSOnState : NSOffState
        highlightDiscarded.state = settings.highlightDiscarded ? NSOnState : NSOffState
        opacity.doubleValue = settings.trackerOpacity
        cardSize.selectItemAtIndex(settings.cardSize.rawValue)
        showTimer.state = settings.showTimer ? NSOnState : NSOffState
        autoPositionTrackers.state = settings.autoPositionTrackers ? NSOnState : NSOffState
        showSecretHelper.state = settings.showSecretHelper ? NSOnState : NSOffState
        showRarityColors.state = settings.showRarityColors ? NSOnState : NSOffState
        showFloatingCard.state = settings.showFloatingCard ? NSOnState : NSOffState
    }

    @IBAction func sliderChange(sender: AnyObject) {
        let settings = Settings.instance
        settings.trackerOpacity = opacity.doubleValue
    }

    @IBAction func comboboxChange(sender: NSComboBox) {
        let settings = Settings.instance
        if sender == cardSize {
            settings.cardSize = CardSize(rawValue: cardSize.indexOfSelectedItem)!
        }
    }

    @IBAction func checkboxClicked(sender: NSButton) {
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
        }
    }

    // MARK: - MASPreferencesViewController
    override var identifier: String? {
        get {
            return "trackers"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNameAdvanced)
    }

    var toolbarItemLabel: String! {
        return NSLocalizedString("Trackers", comment: "")
    }
}

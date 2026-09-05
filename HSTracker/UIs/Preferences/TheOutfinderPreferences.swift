//
//  TheOutfinderPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/4/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

/// Ports HDT's FlyoutControls/Options/Overlay/OverlayTheOutfinder.xaml{,.cs} - the dedicated
/// settings section for The OutFinder, with the same five checkboxes in the same order, and the
/// same nesting: the four detail options are disabled while the master switch is off.
class TheOutfinderPreferences: PreferencePaneController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.the_outfinder

    var preferencePaneTitle = String.localizedString("The OutFinder", comment: "")

    var toolbarItemIcon = NSImage(named: "settings-outfinder")!

    @IBOutlet var outfinderEnabled: NSButton!
    @IBOutlet var outfinderInDeck: NSButton!
    @IBOutlet var outfinderInHand: NSButton!
    @IBOutlet var outfinderUsePercentages: NSButton!
    @IBOutlet var outfinderUseCardTiles: NSButton!

    override func viewWillAppear() {
        super.viewWillAppear()

        guard outfinderEnabled != nil else {
            return
        }

        outfinderEnabled.state = Settings.outfinderEnabled ? .on : .off
        outfinderInDeck.state = Settings.outfinderInDeck ? .on : .off
        outfinderInHand.state = Settings.outfinderInHand ? .on : .off
        outfinderUsePercentages.state = Settings.outfinderUsePercentages ? .on : .off
        outfinderUseCardTiles.state = Settings.outfinderUseCardTiles ? .on : .off
        updateEnabledState()
    }

    // Mirrors the XAML's `IsEnabled="{Binding IsChecked, ElementName=CheckboxOutfinderEnabled}"`
    // on the StackPanel holding the other four checkboxes.
    private func updateEnabledState() {
        let enabled = outfinderEnabled.state == .on
        outfinderInDeck.isEnabled = enabled
        outfinderInHand.isEnabled = enabled
        outfinderUsePercentages.isEnabled = enabled
        outfinderUseCardTiles.isEnabled = enabled
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == outfinderEnabled {
            Settings.outfinderEnabled = outfinderEnabled.state == .on
            updateEnabledState()
        } else if sender == outfinderInDeck {
            Settings.outfinderInDeck = outfinderInDeck.state == .on
        } else if sender == outfinderInHand {
            Settings.outfinderInHand = outfinderInHand.state == .on
        } else if sender == outfinderUsePercentages {
            Settings.outfinderUsePercentages = outfinderUsePercentages.state == .on
        } else if sender == outfinderUseCardTiles {
            Settings.outfinderUseCardTiles = outfinderUseCardTiles.state == .on
        }
    }
}

// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let the_outfinder = Self("the_outfinder")
}

//
//  ArenaPreferences.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

/// Arenasmith options. Mirrors HDT's `FlyoutControls/Options/Overlay/OverlayArena`,
/// which lives under its Overlay page; HSTracker gives each game mode its own
/// pane, so this follows BattlegroundsPreferences instead.
class ArenaPreferences: PreferencePaneController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.arena

    var preferencePaneTitle = String.localizedString("Arena", comment: "")

    var toolbarItemIcon = NSImage(named: "settings-arena")!

    @IBOutlet var enableArenasmithOverlay: NSButton!
    @IBOutlet var showArenasmithPreLobby: NSButton!
    @IBOutlet var showArenaHeroPicking: NSButton!
    @IBOutlet var showArenasmithScore: NSButton!
    @IBOutlet var showArenaRelatedCards: NSButton!
    @IBOutlet var showArenaDeckSynergies: NSButton!
    @IBOutlet var showArenaRedraftDiscard: NSButton!
    @IBOutlet var showOpponentArenaPackages: NSButton!

    override func viewWillAppear() {
        super.viewWillAppear()

        guard enableArenasmithOverlay != nil else {
            return
        }

        enableArenasmithOverlay.state = Settings.enableArenasmithOverlay ? .on : .off
        showArenasmithPreLobby.state = Settings.showArenasmithPreLobby ? .on : .off
        showArenaHeroPicking.state = Settings.showArenaHeroPicking ? .on : .off
        showArenasmithScore.state = Settings.showArenasmithScore ? .on : .off
        showArenaRelatedCards.state = Settings.showArenaRelatedCards ? .on : .off
        showArenaDeckSynergies.state = Settings.showArenaDeckSynergies ? .on : .off
        showArenaRedraftDiscard.state = Settings.showArenaRedraftDiscard ? .on : .off
        // The stored setting is negative (hide), the checkbox is positive (show),
        // matching HDT's label.
        showOpponentArenaPackages.state = Settings.hideOpponentArenaPackages ? .off : .on

        updateEnabledState()
    }

    /// Every other checkbox is a sub-option of the overlay as a whole, so all
    /// seven grey out when it is off - HDT binds each one's IsEnabled to the
    /// Enable Arenasmith checkbox.
    private func updateEnabledState() {
        let enabled = Settings.enableArenasmithOverlay
        for checkbox in [showArenasmithPreLobby, showArenaHeroPicking, showArenasmithScore,
                         showArenaRelatedCards, showArenaDeckSynergies, showArenaRedraftDiscard,
                         showOpponentArenaPackages] {
            checkbox?.isEnabled = enabled
        }
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        let isOn = sender.state == .on

        if sender == enableArenasmithOverlay {
            Settings.enableArenasmithOverlay = isOn
            updateEnabledState()
        } else if sender == showArenasmithPreLobby {
            Settings.showArenasmithPreLobby = isOn
        } else if sender == showArenaHeroPicking {
            Settings.showArenaHeroPicking = isOn
        } else if sender == showArenasmithScore {
            Settings.showArenasmithScore = isOn
        } else if sender == showArenaRelatedCards {
            Settings.showArenaRelatedCards = isOn
        } else if sender == showArenaDeckSynergies {
            Settings.showArenaDeckSynergies = isOn
        } else if sender == showArenaRedraftDiscard {
            Settings.showArenaRedraftDiscard = isOn
        } else if sender == showOpponentArenaPackages {
            Settings.hideOpponentArenaPackages = !isOn
        }

        // The overlay reads these settings directly, so a change while the draft
        // screen is up needs to redraw rather than wait for the next pick.
        if #available(macOS 10.15, *) {
            let overlay = AppDelegate.instance().coreManager?.game.windowManager.rootOverlay?.viewModel
            overlay?.arenaPickHelper.settingsChanged()
            overlay?.arenaPreDraft.settingsChanged()
        }
    }
}

// MARK: - Preferences

extension Preferences.PaneIdentifier {
    static let arena = Self("arena")
}

//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 18/10/20.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class BattlegroundsPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.battlegrounds
    
    var preferencePaneTitle = NSLocalizedString("Battlegrounds", comment: "")
    
    var toolbarItemIcon = NSImage(named: "Mode_Battlegrounds_Dark")!

    @IBOutlet weak var enableTier7Overlay: NSButton!
    @IBOutlet weak var showTier7PreLobby: NSButton!
    @IBOutlet weak var showHeroPicking: NSButton!
    @IBOutlet weak var showQuestPicking: NSButton!
    @IBOutlet weak var showCompositionStats: NSButton!
    @IBOutlet weak var showBobsBuddy: NSButton!
    @IBOutlet weak var showBobsBuddyDuringCombat: NSButton!
    @IBOutlet weak var showBobsBuddyDuringShopping: NSButton!
    @IBOutlet weak var showTurnCounter: NSButton!
    @IBOutlet weak var showAverageDamage: NSButton!
    @IBOutlet weak var showOpponentWarband: NSButton!
    @IBOutlet weak var showTiers: NSButton!
    @IBOutlet weak var showBDonTiers: NSButton!
    @IBOutlet weak var showTavernTriples: NSButton!
    @IBOutlet weak var showHeroToast: NSButton!
    @IBOutlet weak var showSessionRecap: NSButton!
    @IBOutlet weak var showBannedTribes: NSButton!
    @IBOutlet weak var showMMR: NSButton!
    @IBOutlet weak var showMMRStartCurrent: NSButton!
    @IBOutlet weak var showMMRCurrentChange: NSButton!
    @IBOutlet weak var showLatestGames: NSButton!
    @IBOutlet weak var scalingSlider: NSSlider!
    @IBOutlet weak var scalingValue: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableTier7Overlay.state = Settings.enableTier7Overlay ? .on : .off
        showTier7PreLobby.state = Settings.showBattlegroundsTier7PreLobby ? .on : .off
        showHeroPicking.state = Settings.showBattlegroundsHeroPicking ? .on : .off
        showQuestPicking.state = Settings.showBattlegroundsQuestPicking ? .on : .off
        showCompositionStats.state = Settings.showBattlegroundsCompositionStats ? .on : .off
        showBobsBuddy.state = Settings.showBobsBuddy ? .on : .off
        showBobsBuddyDuringCombat.state = Settings.showBobsBuddyDuringCombat ? .on : .off
        showBobsBuddyDuringShopping.state = Settings.showBobsBuddyDuringShopping ? .on : .off
        showTurnCounter.state = Settings.showTurnCounter ? .on : .off
        showAverageDamage.state = Settings.showAverageDamage ? .on : .off
        showOpponentWarband.state = Settings.showOpponentWarband ? .on : .off
        showTiers.state = Settings.showTiers ? .on : .off
        showBDonTiers.state = Settings.showBattlecryDeathrattleOnTiers ? .on : .off
        showTavernTriples.state = Settings.showTavernTriples ? .on : .off
        showHeroToast.state = Settings.showHeroToast ? .on : .off
        showSessionRecap.state = Settings.showSessionRecap ? .on : .off
        showBannedTribes.state = Settings.showBannedTribes ? .on : .off
        showMMR.state = Settings.showMMR ? .on : .off
        showLatestGames.state = Settings.showLatestGames ? .on : .off
        showMMRStartCurrent.state = Settings.showMMRStartCurrent ? .on : .off
        showMMRCurrentChange.state = Settings.showMMRStartCurrent ? .off : .on
        scalingSlider.doubleValue = Settings.battlegroundsSessionScaling * 100.0
        scalingValue.doubleValue = Settings.battlegroundsSessionScaling
        updateEnablement()
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        let game = AppDelegate.instance().coreManager.game
        if sender == showBobsBuddy {
            Settings.showBobsBuddy = showBobsBuddy.state == .on
        } else if sender == showBobsBuddyDuringCombat {
            Settings.showBobsBuddyDuringCombat = showBobsBuddyDuringCombat.state == .on
        } else if sender == showBobsBuddyDuringShopping {
            Settings.showBobsBuddyDuringShopping = showBobsBuddyDuringShopping.state == .on
        } else if sender == showTurnCounter {
            Settings.showTurnCounter = showTurnCounter.state == .on
        } else if sender == showAverageDamage {
            Settings.showAverageDamage = showAverageDamage.state == .on
        } else if sender == showOpponentWarband {
            Settings.showOpponentWarband = showOpponentWarband.state == .on
        } else if sender == showTiers {
            Settings.showTiers = showTiers.state == .on
        } else if sender == showBDonTiers {
            Settings.showBattlecryDeathrattleOnTiers = sender.state == .on
        } else if sender == showTavernTriples {
            Settings.showTavernTriples = showTavernTriples.state == .on
        } else if sender == showHeroToast {
            Settings.showHeroToast = showHeroToast.state == .on
        } else if sender == showSessionRecap {
            Settings.showSessionRecap = sender.state == .on
            updateEnablement()
            if game.isBattlegroundsMatch() || game.currentMode == .bacon {
                if sender.state == .on {
                    game.showBattlegroundsSession(true, true)
                } else {
                    game.showBattlegroundsSession(false, true)
                }
            }
        } else if sender == showBannedTribes {
            Settings.showBannedTribes = sender.state == .on
        } else if sender == showMMR {
            Settings.showMMR = sender.state == .on
            updateEnablement()
        } else if sender == showLatestGames {
            Settings.showLatestGames = sender.state == .on
        } else if sender == showMMRStartCurrent {
            Settings.showMMRStartCurrent = true
            showMMRStartCurrent.state = .on
            showMMRCurrentChange.state = .off
        } else if sender == showMMRCurrentChange {
            Settings.showMMRStartCurrent = false
            showMMRStartCurrent.state = .off
            showMMRCurrentChange.state = .on
        } else if sender == enableTier7Overlay {
            Settings.enableTier7Overlay = sender.state == .on
            updateEnablement()
            if game.currentMode == .bacon {
                if #available(macOS 10.15, *) {
                    if sender.state == .on {
                        game.showTier7PreLobby(show: true, checkAccountStatus: true)
                    } else {
                        game.showTier7PreLobby(show: false, checkAccountStatus: false)
                    }
                }
            }
        } else if sender == showTier7PreLobby {
            Settings.showBattlegroundsTier7PreLobby = sender.state == .on
            if game.currentMode == .bacon {
                if #available(macOS 10.15, *) {
                    if sender.state == .on {
                        game.showTier7PreLobby(show: true, checkAccountStatus: true)
                    } else {
                        game.showTier7PreLobby(show: false, checkAccountStatus: false)
                    }
                }
            }
        } else if sender == showHeroPicking {
            Settings.showBattlegroundsHeroPicking = sender.state == .on
            if game.isBattlegroundsMatch() {
                if #available(macOS 10.15, *) {
                    game.windowManager.battlegroundsHeroPicking.viewModel.visibility = sender.state == .on
                }
            }

        } else if sender == showQuestPicking {
            Settings.showBattlegroundsQuestPicking = sender.state == .on
            if game.isBattlegroundsMatch() {
                if #available(macOS 10.15, *) {
                    game.windowManager.battlegroundsQuestPicking.viewModel.visibility = sender.state == .on
                }
            }
        } else if sender == showCompositionStats {
            Settings.showBattlegroundsCompositionStats = sender.state == .on
        }
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        Settings.battlegroundsSessionScaling = scalingSlider.doubleValue / 100.0
        scalingValue.doubleValue = scalingSlider.doubleValue / 100.0
    }
    
    private func updateEnablement() {
        var enabled = showSessionRecap.state == .on
        showBannedTribes.isEnabled = enabled
        showMMR.isEnabled = enabled
        showLatestGames.isEnabled = enabled
        showMMRStartCurrent.isEnabled = enabled
        showMMRCurrentChange.isEnabled = enabled
        if enabled {
            enabled = showMMR.state == .on
            showMMRStartCurrent.isEnabled = enabled
            showMMRCurrentChange.isEnabled = enabled
        }
        
        enabled = enableTier7Overlay.state == .on
        showTier7PreLobby.isEnabled = enabled
        showHeroPicking.isEnabled = enabled
        showQuestPicking.isEnabled = enabled
        showCompositionStats.isEnabled = enabled
    }
    
    @IBAction func reset(_ sender: NSButton) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Resetting current Session", comment: "")
        alert.informativeText = NSLocalizedString("By clicking 'Reset' you will clear your list of Latest Games and make your Start MMR the same as your current MMR.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Reset", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
        if alert.runModal() != NSApplication.ModalResponse.alertFirstButtonReturn {
            return
        }
        
        BattlegroundsLastGames.instance.reset()
        AppDelegate.instance().coreManager.game.windowManager.battlegroundsSession.update()

    }
}

// MARK: - Preferences

extension Preferences.PaneIdentifier {
    static let battlegrounds = Self("battlegrounds")
}

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
    
    var preferencePaneTitle = String.localizedString("Battlegrounds", comment: "")
    
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
    @IBOutlet weak var showTavernSpells: NSButton!
    @IBOutlet weak var showTavernTriples: NSButton!
    @IBOutlet weak var showHeroToast: NSButton!
    @IBOutlet weak var showSessionRecap: NSButton!
    @IBOutlet weak var showMinionTypes: NSButton!
    @IBOutlet weak var showAvailable: NSButton!
    @IBOutlet weak var showBanned: NSButton!
    @IBOutlet weak var showMMR: NSButton!
    @IBOutlet weak var showMMRStartCurrent: NSButton!
    @IBOutlet weak var showMMRCurrentChange: NSButton!
    @IBOutlet weak var showLatestGames: NSButton!
    @IBOutlet weak var scalingSlider: NSSlider!
    @IBOutlet weak var scalingValue: NSTextField!
    @IBOutlet weak var showBattlegroundsCompStats: NSButton!
    @IBOutlet weak var alwaysShowTavernTier7: NSButton!
    @IBOutlet weak var autoShowBattlegroundsTrinketPicking: NSButton!
    
    override func viewWillAppear() {
        super.viewWillAppear()
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
        showTavernSpells.state = Settings.showTavernSpells ? .on : .off
        showTavernTriples.state = Settings.showTavernTriples ? .on : .off
        showHeroToast.state = Settings.showHeroToast ? .on : .off
        showSessionRecap.state = Settings.showSessionRecap ? .on : .off
        showMinionTypes.state = Settings.showMinionsSection ? .on : .off
        showAvailable.state = Settings.showMinionTypes != 0 ? .on : .off
        showBanned.state = Settings.showMinionTypes == 0 ? .on : .off
        showMMR.state = Settings.showMMR ? .on : .off
        showLatestGames.state = Settings.showLatestGames ? .on : .off
        showMMRStartCurrent.state = Settings.showMMRStartCurrent ? .on : .off
        showMMRCurrentChange.state = Settings.showMMRStartCurrent ? .off : .on
        scalingSlider.doubleValue = Settings.battlegroundsSessionScaling * 100.0
        scalingValue.doubleValue = Settings.battlegroundsSessionScaling
        showBattlegroundsCompStats.state = Settings.showBattlegroundsTier7SessionCompStats ? .on : .off
        alwaysShowTavernTier7.state = Settings.alwaysShowTier7 ? .on : .off
        autoShowBattlegroundsTrinketPicking.state = Settings.autoShowBattlegroundsTrinketPicking ? .on : .off
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
            updateEnablement()
        } else if sender == showBDonTiers {
            Settings.showBattlecryDeathrattleOnTiers = sender.state == .on
        } else if sender == showTavernSpells {
            Settings.showTavernSpells = showTavernSpells.state == .on
        } else if sender == showTavernTriples {
            Settings.showTavernTriples = showTavernTriples.state == .on
        } else if sender == showHeroToast {
            Settings.showHeroToast = showHeroToast.state == .on
        } else if sender == showSessionRecap {
            Settings.showSessionRecap = sender.state == .on
            updateEnablement()
            if game.isBattlegroundsMatch() || game.currentMode == .bacon {
                if sender.state == .on {
                    game.updateBattlegroundsSessionVisibility()
                } else {
                    game.updateBattlegroundsSessionVisibility()
                }
            }
        } else if sender == showMinionTypes {
            Settings.showMinionsSection = sender.state == .on
            updateEnablement()
        } else if sender == showAvailable {
            Settings.showMinionTypes = 1
            showAvailable.state = .on
            showBanned.state = .off
            AppDelegate.instance().coreManager.game.windowManager.battlegroundsSession.update()
        } else if sender == showBanned {
            Settings.showMinionTypes = 0
            showAvailable.state = .off
            showBanned.state = .on
            AppDelegate.instance().coreManager.game.windowManager.battlegroundsSession.update()
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
            if #available(macOS 10.15, *) {
                game.updateTier7PreLobbyVisibility()
            }
        } else if sender == showTier7PreLobby {
            Settings.showBattlegroundsTier7PreLobby = sender.state == .on
            if #available(macOS 10.15, *) {
                game.updateTier7PreLobbyVisibility()
            }
        } else if sender == showHeroPicking {
            Settings.showBattlegroundsHeroPicking = sender.state == .on
        } else if sender == showQuestPicking {
            Settings.showBattlegroundsQuestPicking = sender.state == .on
            if game.isBattlegroundsMatch() {
                if #available(macOS 10.15, *) {
                    game.windowManager.battlegroundsQuestPicking.viewModel.visibility = sender.state == .on
                }
            }
        } else if sender == showCompositionStats {
            Settings.showBattlegroundsCompositionStats = sender.state == .on
        } else if sender == showBattlegroundsCompStats {
            Settings.showBattlegroundsTier7SessionCompStats = sender.state == .on
        } else if sender == alwaysShowTavernTier7 {
            Settings.alwaysShowTier7 = sender.state == .on
        } else if sender == autoShowBattlegroundsTrinketPicking {
            Settings.autoShowBattlegroundsTrinketPicking = sender.state == .on
            AppDelegate.instance().coreManager.game.windowManager.battlegroundsTrinketPicking.viewModel.statsVisibility = Settings.autoShowBattlegroundsTrinketPicking
        }
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        Settings.battlegroundsSessionScaling = scalingSlider.doubleValue / 100.0
        scalingValue.doubleValue = scalingSlider.doubleValue / 100.0
    }
    
    private func updateEnablement() {
        var enabled = showSessionRecap.state == .on
        showMinionTypes.isEnabled = enabled
        showMMR.isEnabled = enabled
        showLatestGames.isEnabled = enabled
        showMMRStartCurrent.isEnabled = enabled
        showMMRCurrentChange.isEnabled = enabled
        if enabled {
            enabled = showMMR.state == .on
            showMMRStartCurrent.isEnabled = enabled
            showMMRCurrentChange.isEnabled = enabled
            
            enabled = showMinionTypes.state == .on
            showAvailable.isEnabled = enabled
            showBanned.isEnabled = enabled
        }
        
        enabled = enableTier7Overlay.state == .on
        showTier7PreLobby.isEnabled = enabled
        showHeroPicking.isEnabled = enabled
        showBattlegroundsCompStats.isEnabled = enabled
        showQuestPicking.isEnabled = enabled
        showCompositionStats.isEnabled = enabled
        alwaysShowTavernTier7.isEnabled = showTiers.state == .on
    }
    
    @IBAction func reset(_ sender: NSButton) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = String.localizedString("Resetting current Session", comment: "")
        alert.informativeText = String.localizedString("By clicking 'Reset' you will clear your list of Latest Games and make your Start MMR the same as your current MMR.", comment: "")
        alert.addButton(withTitle: String.localizedString("Reset", comment: ""))
        alert.addButton(withTitle: String.localizedString("Cancel", comment: ""))
        
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

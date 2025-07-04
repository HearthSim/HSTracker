//
//  ImportingPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/5/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class ImportingPreferences: NSViewController, NSControlTextEditingDelegate, PreferencePane {
    let preferencePaneIdentifier = Preferences.PaneIdentifier.importing
    
    let preferencePaneTitle = String.localizedString("Importing", comment: "")
    
    let toolbarItemIcon = NSImage(named: "import")!

    @IBOutlet var dungeonIncludePassives: NSButton!
    @IBOutlet var dungeonAdventure: NSComboBox!
    @IBOutlet var dungeonTemplate: NSTextField!
    @IBOutlet var dungeonTemplatePreview: NSTextField!
    @IBOutlet var duelsTemplate: NSTextField!
    @IBOutlet var duelsTemplatePreview: NSTextField!
    @IBOutlet var arenaTemplate: NSTextField!
    @IBOutlet var arenaTemplatePreview: NSTextField!

    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard dungeonIncludePassives != nil else {
            return
        }
        
        dungeonIncludePassives.state = Settings.importDungeonIncludePassives ? .on : .off
        dungeonTemplate.stringValue = Settings.importDungeonTemplate
        duelsTemplate.stringValue = Settings.importDuelsTemplate
        arenaTemplate.stringValue = Settings.importArenaDeckNameTemplate
        dungeonAdventure.selectItem(at: 0)
        updateTemplatePreview(textField: dungeonTemplatePreview, template: dungeonTemplate.stringValue)
        updateTemplatePreview(textField: duelsTemplatePreview, template: duelsTemplate.stringValue)
        updateTemplatePreview(textField: arenaTemplatePreview, template: arenaTemplate.stringValue)
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == dungeonIncludePassives {
            Settings.importDungeonIncludePassives = dungeonIncludePassives.state == .on
        }
    }
    
    @IBAction func comboboxChange(_ sender: NSComboBox) {
        if sender == dungeonAdventure {
            let index = dungeonAdventure.indexOfSelectedItem
            
            var str = ""
            switch index {
            case 0:
                str = Settings.importDungeonTemplate
            case 1:
                str = Settings.importMonsterHuntTemplate
            case 2:
                str = Settings.importRumbleRunTemplate
            case 3:
                str = Settings.importDalaranHeistTemplate
            case 4:
                str = Settings.importTombsOfTerrorTemplate
            default:
                return
            }
            dungeonTemplate.stringValue = str
            updateTemplatePreview(textField: dungeonTemplatePreview, template: str)
        }
    }
    
    private func updateTemplatePreview(textField: NSTextField, template: String) {
        let deck = Deck()
        deck.playerClass = .neutral
        textField.stringValue = Helper.parseDeckNameTemplate(template: template, deck: deck)
    }
    
    public func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if textField == dungeonTemplate {
                let str = textField.stringValue
                switch dungeonAdventure.indexOfSelectedItem {
                case 0:
                    Settings.importDungeonTemplate = str
                case 1:
                    Settings.importMonsterHuntTemplate = str
                case 2:
                    Settings.importRumbleRunTemplate = str
                case 3:
                    Settings.importDalaranHeistTemplate = str
                case 4:
                    Settings.importTombsOfTerrorTemplate = str
                default:
                    return
                }
                
                updateTemplatePreview(textField: dungeonTemplatePreview, template: str)
            } else if textField == duelsTemplate {
                Settings.importDuelsTemplate = textField.stringValue
                updateTemplatePreview(textField: duelsTemplatePreview, template: textField.stringValue)
            } else if textField == arenaTemplate {
                Settings.importArenaDeckNameTemplate = textField.stringValue
                updateTemplatePreview(textField: arenaTemplatePreview, template: textField.stringValue)
            }
        }
    }
}

// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let importing = Self("importing")
}

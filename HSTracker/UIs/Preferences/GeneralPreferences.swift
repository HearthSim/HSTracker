//
//  GeneralPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class GeneralPreferences : NSViewController, MASPreferencesViewController {
    
    @IBOutlet weak var autoPositionTrackers: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func checkboxClicked(sender: NSButton) {
    }

    // MARK: - MASPreferencesViewController
    override var identifier: String? {
        get {
            return "general"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNameAdvanced)

    }

    var toolbarItemLabel: String! {
        return NSLocalizedString("General", comment: "")
    }
}
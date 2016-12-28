//
//  HearthstatsPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class HearthstatsPreferences: NSViewController {

    @IBOutlet weak var autoSynchronize: NSButton!
    @IBOutlet weak var synchronizeMatches: NSButton!
    @IBOutlet weak var loginButton: NSButton!
    private var hearthstatsLogin: HearthstatsLogin?
    @IBOutlet weak var loadDecks: NSButton!
    @IBOutlet weak var loader: NSProgressIndicator!

    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance

        autoSynchronize.state = settings.hearthstatsAutoSynchronize ? NSOnState : NSOffState
        synchronizeMatches.state = settings.hearthstatsSynchronizeMatches ? NSOnState : NSOffState

        reloadStates()
    }

    private func reloadStates() {
        autoSynchronize.isEnabled = HearthstatsAPI.isLogged()
        synchronizeMatches.isEnabled = HearthstatsAPI.isLogged()
        loadDecks.isEnabled = HearthstatsAPI.isLogged()

        loginButton.title = HearthstatsAPI.isLogged() ?
            NSLocalizedString("Logout", comment: "") : NSLocalizedString("Login", comment: "")
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        let settings = Settings.instance
        if sender == autoSynchronize {
            settings.hearthstatsAutoSynchronize = autoSynchronize.state == NSOnState
        } else if sender == synchronizeMatches {
            settings.hearthstatsSynchronizeMatches = synchronizeMatches.state == NSOnState
        }
    }

    @IBAction func login(_ sender: Any) {
        if HearthstatsAPI.isLogged() {
            let msg = NSLocalizedString("Are you sure you want to disconnect from Hearthstats ?",
                                        comment: "")
            if NSAlert.show(style: .informational, message: msg) {
                HearthstatsAPI.logout()
                self.reloadStates()
            }
        } else {
            hearthstatsLogin = HearthstatsLogin(windowNibName: "HearthstatsLogin")
            if let hearthstatsLogin = hearthstatsLogin {
                self.view.window?.beginSheet(hearthstatsLogin.window!) { [weak self] (response) in
                    if response == NSModalResponseOK {
                        self?.reloadStates()
                    }
                }
            }
        }
    }

    @IBAction func loadDecks(_ sender: Any) {
        do {
            loader.startAnimation(self)
            try HearthstatsAPI.loadDecks(force: true) { _, _ in
                self.loader.stopAnimation(self)
            }
        } catch HearthstatsError.notLogged {
            print("not logged")
            self.loader.stopAnimation(self)
        } catch {
            print("??? logged")
            self.loader.stopAnimation(self)
        }
    }
}

// MARK: - MASPreferencesViewController
extension HearthstatsPreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "hearthstats"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: "hearthstats_icon")
    }

    var toolbarItemLabel: String? {
        return "Hearthstats"
    }
}

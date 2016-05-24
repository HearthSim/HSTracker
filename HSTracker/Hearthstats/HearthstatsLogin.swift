//
//  HearthstatsLogin.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class HearthstatsLogin: NSWindowController {

    @IBOutlet weak var email: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var loginButton: NSButton!

    @IBAction func cancel(sender: AnyObject) {
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }

    @IBAction func connect(sender: AnyObject) {
        configureUserInterfaceForNetworkActivity(true)

        HearthstatsAPI.login(email.stringValue,
                             password: password.stringValue) { (success, message) in
            if success {
                self.loadDecks() { (success) -> (Void) in
                    let message = NSLocalizedString("You are now connected to Hearthstats",
                                                    comment: "")
                    self.displayAlert(.InformationalAlertStyle, message: message) {
                        self.endSheet()
                    }
                }
            } else {
                self.displayAlert(.CriticalAlertStyle, message: message) {
                    self.configureUserInterfaceForNetworkActivity(false)
                    self.email.becomeFirstResponder()
                }
            }
        }
    }

    private func configureUserInterfaceForNetworkActivity(isNetworkActivityInProgress: Bool) {
        if isNetworkActivityInProgress {
            self.window?.makeFirstResponder(nil)
            progressIndicator.hidden = false
            progressIndicator.startAnimation(self)
        } else {
            progressIndicator.hidden = true
            self.window?.makeFirstResponder(email)
            progressIndicator.stopAnimation(self)
        }

        [ email, password ].forEach {
            $0.selectable = !isNetworkActivityInProgress
            $0.editable = !isNetworkActivityInProgress
        }
        [ loginButton, cancelButton ].forEach { $0.enabled = !isNetworkActivityInProgress }
    }

    private func displayAlert(style: NSAlertStyle, message: String, completion: (Void) -> (Void)) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = message

        alert.beginSheetModalForWindow(self.window!) { (response) in
            completion()
        }
    }

    private func loadDecks(completion: (Bool) -> (Void)) {
        do {
            try HearthstatsAPI.loadDecks(true) { (success, newDecks) in
                completion(success)
            }
        } catch HearthstatsError.NotLogged {
            print("not logged")
            completion(false)
        } catch {
            print("??? logged")
            completion(false)
        }
    }

    private func endSheet() {
        window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }
}

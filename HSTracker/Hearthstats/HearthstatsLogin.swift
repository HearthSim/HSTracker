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

    @IBAction func cancel(_ sender: AnyObject) {
        self.endSheet()
    }

    @IBAction func connect(_ sender: AnyObject) {
        configureUserInterfaceForNetworkActivity(isNetworkActivityInProgress: true)

        HearthstatsAPI.login(email: email.stringValue,
                             password: password.stringValue) { (success, message) in
            if success {
                self.loadDecks { _ in
                    let message = NSLocalizedString("You are now connected to Hearthstats",
                                                    comment: "")
                    self.displayAlert(style: .informational, message: message) {
                        self.endSheet()
                    }
                }
            } else {
                self.displayAlert(style: .critical, message: message) {
                    self.configureUserInterfaceForNetworkActivity(
                        isNetworkActivityInProgress: false)
                    self.email.becomeFirstResponder()
                }
            }
        }
    }

    private func configureUserInterfaceForNetworkActivity(isNetworkActivityInProgress: Bool) {
        if isNetworkActivityInProgress {
            self.window?.makeFirstResponder(nil)
            progressIndicator.isHidden = false
            progressIndicator.startAnimation(self)
        } else {
            progressIndicator.isHidden = true
            self.window?.makeFirstResponder(email)
            progressIndicator.stopAnimation(self)
        }

        [ email, password ].forEach {
            $0?.isSelectable = !isNetworkActivityInProgress
            $0?.isEditable = !isNetworkActivityInProgress
        }
        [ loginButton, cancelButton ].forEach { $0.isEnabled = !isNetworkActivityInProgress }
    }

    private func displayAlert(style: NSAlertStyle, message: String,
                              completion: @escaping (Void) -> (Void)) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = message

        alert.beginSheetModal(for: self.window!) { _ in
            completion()
        }
    }

    private func loadDecks(completion: @escaping (Bool) -> (Void)) {
        do {
            try HearthstatsAPI.loadDecks(force: true) { success, _ in
                completion(success)
            }
        } catch HearthstatsError.notLogged {
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

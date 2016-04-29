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

    @IBAction func cancel(sender: AnyObject) {
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }

    @IBAction func connect(sender: AnyObject) {
        HearthstatsAPI.login(email.stringValue, password.stringValue) { (success, message) in

            let alert = NSAlert()
            if success {
                alert.alertStyle = .InformationalAlertStyle
                alert.messageText = NSLocalizedString("You are now connected to Hearthstats",
                                                      comment: "")
            } else {
                alert.alertStyle = .CriticalAlertStyle
                alert.messageText = message
            }

            alert.beginSheetModalForWindow(self.window!, completionHandler: { (response) in
                if success {
                    do {
                        try HearthstatsAPI.loadDecks(true) { (success, newDecks) in
                            self.window?.sheetParent?.endSheet(self.window!,
                                returnCode: NSModalResponseOK)
                        }
                    } catch HearthstatsError.NotLogged {
                        print("not logged")
                    } catch {
                        print("??? logged")
                    }
                }
            })
        }
    }
}

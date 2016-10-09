//
//  TrackOBotLogin.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class TrackOBotLogin: NSWindowController {
    
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var token: NSSecureTextField!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBAction func connect(sender: AnyObject) {
        configureUserInterfaceForNetworkActivity(true)
        
        TrackOBotAPI.login(username.stringValue,
                             token: token.stringValue) { (success, message) in
                                if success {
                                    let message =
                                        NSLocalizedString("You are now connected to Track-o-Bot",
                                                          comment: "")
                                    self.displayAlert(.Informational, message: message) {
                                        self.endSheet()
                                    }
                                } else {
                                    self.displayAlert(.Critical, message: message) {
                                        self.configureUserInterfaceForNetworkActivity(false)
                                        self.username.becomeFirstResponder()
                                    }
                                }
        }
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.endSheet()
    }
    
    private func configureUserInterfaceForNetworkActivity(isNetworkActivityInProgress: Bool) {
        if isNetworkActivityInProgress {
            self.window?.makeFirstResponder(nil)
            progressIndicator.hidden = false
            progressIndicator.startAnimation(self)
        } else {
            progressIndicator.hidden = true
            self.window?.makeFirstResponder(username)
            progressIndicator.stopAnimation(self)
        }
        
        [ username, token ].forEach {
            $0.selectable = !isNetworkActivityInProgress
            $0.editable = !isNetworkActivityInProgress
        }
        [ loginButton ].forEach { $0.enabled = !isNetworkActivityInProgress }
    }
    
    private func displayAlert(style: NSAlertStyle, message: String, completion: (Void) -> (Void)) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = message
        
        alert.beginSheetModalForWindow(self.window!) { (response) in
            completion()
        }
    }
    
    private func endSheet() {
        window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }
}

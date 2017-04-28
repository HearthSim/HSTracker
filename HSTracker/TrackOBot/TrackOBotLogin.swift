//
//  TrackOBotLogin.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class TrackOBotLogin: NSWindowController {
    
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var token: NSSecureTextField!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBAction func connect(_ sender: AnyObject) {
        configureUserInterfaceForNetworkActivity(isNetworkActivityInProgress: true)
        
        TrackOBotAPI.login(username: username.stringValue,
                             token: token.stringValue) { (success, message) in
                                if success {
                                    let message =
                                        NSLocalizedString("You are now connected to Track-o-Bot",
                                                          comment: "")
                                    self.displayAlert(style: .informational, message: message) {
                                        self.endSheet()
                                    }
                                } else {
                                    self.displayAlert(style: .critical, message: message) {
                                        self.configureUserInterfaceForNetworkActivity(
                                            isNetworkActivityInProgress: false)
                                        self.username.becomeFirstResponder()
                                    }
                                }
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.endSheet()
    }
    
    private func configureUserInterfaceForNetworkActivity(isNetworkActivityInProgress: Bool) {
        if isNetworkActivityInProgress {
            self.window?.makeFirstResponder(nil)
            progressIndicator.isHidden = false
            progressIndicator.startAnimation(self)
        } else {
            progressIndicator.isHidden = true
            self.window?.makeFirstResponder(username)
            progressIndicator.stopAnimation(self)
        }
        
        [ username, token ].forEach {
            $0?.isSelectable = !isNetworkActivityInProgress
            $0?.isEditable = !isNetworkActivityInProgress
        }
        [ loginButton ].forEach { $0.isEnabled = !isNetworkActivityInProgress }
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
    
    private func endSheet() {
        window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }
}

//
//  NSAlert.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 23/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

extension NSAlert {
    @discardableResult
    class func show(style: NSAlertStyle, message: String,
                    accessoryView: NSView? = nil, window: NSWindow? = nil,
                    completion: (()->())? = nil) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = message
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        if let _ = completion {
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        }
        alert.accessoryView = accessoryView

        if let window = window {
            alert.beginSheetModal(for: window) { (returnCode) in
                if returnCode == NSAlertFirstButtonReturn {
                    completion?()
                }
            }
            return true
        } else {
            return alert.runModal() == NSAlertFirstButtonReturn
        }
    }
}

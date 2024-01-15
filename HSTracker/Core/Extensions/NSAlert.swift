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
    class func show(style: NSAlert.Style, message: String,
                    accessoryView: NSView? = nil, window: NSWindow? = nil,
                    forceFront: Bool? = false, completion: (() -> Void)? = nil) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = message
        alert.addButton(withTitle: String.localizedString("OK", comment: ""))
        if completion != nil {
            alert.addButton(withTitle: String.localizedString("Cancel", comment: ""))
        }
        alert.accessoryView = accessoryView

        if let forceFront = forceFront, forceFront {
            NSRunningApplication.current.activate(options: [
                NSApplication.ActivationOptions.activateAllWindows,
                NSApplication.ActivationOptions.activateIgnoringOtherApps
                ])
            NSApp.activate(ignoringOtherApps: true)
        }

        if let window = window {
            alert.beginSheetModal(for: window) { (returnCode) in
                if returnCode == NSApplication.ModalResponse.alertFirstButtonReturn {
                    completion?()
                }
            }
            return true
        } else {
            return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
        }
    }
}

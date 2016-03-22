//
//  NSAlert+HSTracker.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 4/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//
// Code from https://github.com/incbee/NSAlert-SynchronousSheet

import Foundation

extension NSAlert {
    func runModalSheetForWindow(aWindow: NSWindow) -> Int {
        // Set ourselves as the target for button clicks
        self.buttons.forEach {
            $0.target = self
            $0.action = #selector(NSAlert._stopSynchronousSheet(_:))
        }

        // Bring up the sheet and wait until stopSynchronousSheet is triggered by a button click
        self.performSelectorOnMainThread(#selector(NSAlert._beginSheetModalForWindow(_:)), withObject: aWindow, waitUntilDone: true)
        let modalCode: Int = NSApp.runModalForWindow(self.window)

        // This is called only after stopSynchronousSheet is called (that is,
        // one of the buttons is clicked)
        NSApp.performSelectorOnMainThread(#selector(NSWindow.endSheet(_:)), withObject: self.window, waitUntilDone: true)

        // Remove the sheet from the screen
        self.window.performSelectorOnMainThread(#selector(NSWindow.orderOut(_:)), withObject: self, waitUntilDone: true)

        return modalCode
    }

    func runModalSheet() -> Int {
        return runModalSheetForWindow(NSApp.mainWindow!)
    }

    // MARK: - Private methods

    func _stopSynchronousSheet(sender: NSButton) {
        // See which of the buttons was clicked
        let clickedButtonIndex = self.buttons.indexOf(sender) ?? 0

        // Be consistent with Apple's documentation (see NSAlert's addButtonWithTitle) so that
        // the fourth button is numbered NSAlertThirdButtonReturn + 1, and so on
        //
        // TODO: handle case when alert created with alertWithMessageText:... where the buttons
        // have values NSAlertDefaultReturn, NSAlertAlternateReturn, ... instead (see also
        // the documentation for the runModal method)
        var modalCode: Int = 0
        if clickedButtonIndex == NSAlertFirstButtonReturn {
            modalCode = NSAlertFirstButtonReturn
        }
        else if clickedButtonIndex == NSAlertSecondButtonReturn {
            modalCode = NSAlertSecondButtonReturn
        }
        else if clickedButtonIndex == NSAlertThirdButtonReturn {
            modalCode = NSAlertThirdButtonReturn
        }
        else {
            modalCode = NSAlertThirdButtonReturn + (clickedButtonIndex - 2)
        }

        NSApp.stopModalWithCode(modalCode)
    }

    func _beginSheetModalForWindow(aWindow: NSWindow) {
        beginSheetModalForWindow(aWindow, completionHandler: nil)
    }
}
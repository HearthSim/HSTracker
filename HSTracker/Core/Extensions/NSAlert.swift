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

extension NSAlert {
    /// Shows the alert in a window of its own instead of running it modally.
    /// runModal() spins the main run loop in the modal panel mode, which never
    /// drains the main dispatch queue, so log processing and the overlays stall
    /// for as long as the alert waits on the user (Sentry HSTRACKER-2QE). Use
    /// this when there is no window to hang a sheet off. Any button closes the
    /// alert and hands its response to `completion`.
    func showNonModal(completion: ((NSApplication.ModalResponse) -> Void)? = nil) {
        NonModalAlert(alert: self, completion: completion).show()
    }
}

private final class NonModalAlert: NSObject {
    // keeps each alert alive until one of its buttons is clicked
    private static var visible: [NonModalAlert] = []

    private let alert: NSAlert
    private let completion: ((NSApplication.ModalResponse) -> Void)?

    init(alert: NSAlert, completion: ((NSApplication.ModalResponse) -> Void)?) {
        self.alert = alert
        self.completion = completion
    }

    func show() {
        if alert.buttons.isEmpty {
            alert.addButton(withTitle: String.localizedString("OK", comment: ""))
        }
        // the buttons would otherwise end a modal session that isn't running
        for (index, button) in alert.buttons.enumerated() {
            button.tag = NSApplication.ModalResponse.alertFirstButtonReturn.rawValue + index
            button.target = self
            button.action = #selector(buttonPressed(_:))
        }
        alert.layout()
        let window = alert.window
        window.level = .floating
        window.center()
        NonModalAlert.visible.append(self)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func buttonPressed(_ sender: NSButton) {
        alert.window.orderOut(nil)
        NonModalAlert.visible.removeAll { $0 === self }
        completion?(NSApplication.ModalResponse(rawValue: sender.tag))
    }
}

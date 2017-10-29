//
//  WindowMove.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 26/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class WindowMove: NSWindowController {

    @IBOutlet weak var windowChooser: NSComboBox!
    @IBOutlet weak var _up: NSButton!
    @IBOutlet weak var _down: NSButton!
    @IBOutlet weak var _left: NSButton!
    @IBOutlet weak var _right: NSButton!
    @IBOutlet weak var _fup: NSButton!
    @IBOutlet weak var _fdown: NSButton!
    @IBOutlet weak var _ffup: NSButton!
    @IBOutlet weak var _ffdown: NSButton!
    @IBOutlet weak var _fleft: NSButton!
    @IBOutlet weak var _fright: NSButton!
    @IBOutlet weak var _show: NSButton!
    @IBOutlet weak var _hide: NSButton!
    @IBOutlet var textbox: NSTextView!
    @IBOutlet weak var screenshot: NSImageView!
    @IBOutlet weak var screenX: NSTextField!
    @IBOutlet weak var screenY: NSTextField!
    @IBOutlet weak var screenWidth: NSTextField!
    @IBOutlet weak var screenHeight: NSTextField!
	
	private weak var windowManager: WindowManager!
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("WindowMove")
	}
	
	convenience init(windowNibName: String, windowManager: WindowManager) {
		self.init(window: nil)
		self.windowManager = windowManager
	}

    lazy var overlayWindow: NSWindow = {
        let window = NSWindow()
        window.orderFrontRegardless()
        window.backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.6)
        window.isOpaque = false
        window.hasShadow = false
        window.styleMask = .borderless
        window.level = .screenSaver

        return window
    }()
    var defaultFrame = NSRect.zero
    var x: CGFloat = 0, y: CGFloat = 0
    var currentWindow: NSWindow?

    @IBAction func opacityChange(_ sender: NSSlider) {
        if let currentWindow = currentWindow {
            let alpha = CGFloat(sender.doubleValue / 100.0)
            currentWindow.backgroundColor = NSColor(red: 0,
                    green: 0,
                    blue: 0,
                    alpha: alpha)
        }
    }

    @IBAction func windowChoose(_ sender: AnyObject) {
        var buttonEnabled = false
        if windowChooser.indexOfSelectedItem >= 0 {
            buttonEnabled = true
        }
        [_up, _down, _left, _right,
         _fup, _fdown, _fleft, _fright,
         _show, _hide, _ffdown, _ffup
        ].forEach {
            $0.isEnabled = buttonEnabled
        }

        if let window = windowChooser
                .itemObjectValue(at: windowChooser.indexOfSelectedItem) as? String {

            // reset
            y = 0
            x = 0

            currentWindow = nil
            if window == "Secret Tracker" {
                currentWindow = windowManager.secretTracker.window
                defaultFrame = NSRect(x: 200,
                        y: SizeHelper.hearthstoneWindow.frame.height - 50,
                        width: CGFloat(kMediumRowHeight), height: 300)
            } else if window == "Timer Hud" {
                currentWindow = windowManager.timerHud.window
                defaultFrame = NSRect(x: 1082.0, y: 399.0, width: 160.0, height: 115.0)
            } else if window == "Card Hud Container" {
                currentWindow = windowManager.cardHudContainer.window
                defaultFrame = NSRect(x: 529.5,
                        y: SizeHelper.hearthstoneWindow.frame.height - 80,
                        width: 400, height: 80)
            } else if window == "Full overlay" {
                currentWindow = overlayWindow
                var rect = SizeHelper.hearthstoneWindow.frame
                rect.origin = NSPoint.zero
                defaultFrame = rect
            } else if window == "Player Board Damage" {
                currentWindow = windowManager.playerBoardDamage.window
                defaultFrame = NSRect(x: 915, y: 205.0, width: 50.0, height: 50.0)
            } else if window == "Opponent Board Damage" {
                currentWindow = windowManager.opponentBoardDamage.window
                defaultFrame = NSRect(x: 910, y: 617.0, width: 50.0, height: 50.0)
            }

            update()
        }
    }

    @IBAction func up(_ sender: AnyObject) {
        y += 1
        update()
    }

    @IBAction func down(_ sender: AnyObject) {
        y -= 1
        update()
    }

    @IBAction func left(_ sender: AnyObject) {
        x -= 1
        update()
    }

    @IBAction func right(_ sender: AnyObject) {
        x += 1
        update()
    }

    @IBAction func fup(_ sender: AnyObject) {
        y += 10
        update()
    }

    @IBAction func ffup(_ sender: AnyObject) {
        y += 100
        update()
    }

    @IBAction func fdown(_ sender: AnyObject) {
        y -= 10
        update()
    }

    @IBAction func ffdown(_ sender: AnyObject) {
        y -= 100
        update()
    }

    @IBAction func fleft(_ sender: AnyObject) {
        x -= 10
        update()
    }

    @IBAction func fright(_ sender: AnyObject) {
        x += 10
        update()
    }

    fileprivate func update() {
        let _x = defaultFrame.origin.x + x
        let _y = defaultFrame.origin.y + y
        let str: String = "NSRect(x: \(_x), y: \(_y), "
                + "width: \(defaultFrame.width), height: \(defaultFrame.height))\n"
                + "NSPoint(x: \(_x), y: \(_y))"
        textbox.string = str

        if let window = currentWindow {
            let frame = SizeHelper.hearthstoneWindow.relativeFrame(
                    NSRect(x: _x, y: _y, width: defaultFrame.width, height: defaultFrame.height))
            window.setFrame(frame, display: true)
        }
    }

    @IBAction func show(_ sender: AnyObject) {
        currentWindow?.orderFrontRegardless()
    }

    @IBAction func hide(_ sender: AnyObject) {
        currentWindow?.orderOut(self)
    }

    @IBAction func screenshot(_ sender: AnyObject) {
        if let x = Float(screenX.stringValue),
           let y = Float(screenY.stringValue),
           let w = Float(screenWidth.stringValue),
           let h = Float(screenHeight.stringValue) {

            print("x: \(x), y: \(y), w: \(w), h: \(h)")
            if let image = SizeHelper.hearthstoneWindow.screenshot() {
                let rect = NSRect(x: CGFloat(x),
                        y: CGFloat(y),
                        width: CGFloat(w),
                        height: CGFloat(h))
                let cropped = ImageUtilities.cropRect(image: image, rect: rect)
                screenshot.image = cropped
            }
        }
    }
}

//
//  WindowMove.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 26/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

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

    lazy var overlayWindow: NSWindow = {
        let window = NSWindow()
        window.orderFrontRegardless()
        window.backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.6)
        window.opaque = false
        window.hasShadow = false
        window.styleMask = NSBorderlessWindowMask
        window.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))

        return window
    }()
    var defaultFrame = NSZeroRect
    var x: CGFloat = 0, y: CGFloat = 0
    var currentWindow: NSWindow?

    @IBAction func opacityChange(sender: NSSlider) {
        if let currentWindow = currentWindow {
            let alpha = CGFloat(sender.doubleValue / 100.0)
            currentWindow.backgroundColor = NSColor(red: 0,
                                                    green: 0,
                                                    blue: 0,
                                                    alpha: alpha)
        }
    }

    @IBAction func windowChoose(sender: AnyObject) {
        var buttonEnabled = false
        if windowChooser.indexOfSelectedItem >= 0 {
            buttonEnabled = true
        }
        [_up, _down, _left, _right,
            _fup, _fdown, _fleft, _fright,
            _show, _hide, _ffdown, _ffup
            ].forEach { $0.enabled = buttonEnabled }

        guard windowChooser.indexOfSelectedItem > 0 else { return }

        if let window = windowChooser
            .itemObjectValueAtIndex(windowChooser.indexOfSelectedItem) as? String {

            // reset
            y = 0
            x = 0

            currentWindow = nil
            if window == "Secret Tracker" {
                currentWindow = Game.instance.secretTracker!.window
                defaultFrame = NSRect(x: 200,
                                      y: NSHeight(SizeHelper.hearthstoneWindow.frame) - 50,
                                      width: CGFloat(kMediumRowHeight), height: 300)
            } else if window == "Timer Hud" {
                currentWindow = Game.instance.timerHud!.window
                defaultFrame = NSRect(x: 1082.0, y: 399.0, width: 160.0, height: 115.0)
            } else if window == "Card Hud Container" {
                currentWindow = Game.instance.cardHudContainer!.window
                defaultFrame = NSRect(x: 529.5,
                                      y: NSHeight(SizeHelper.hearthstoneWindow.frame) - 80,
                                      width: 400, height: 80)
            } else if window == "Full overlay" {
                currentWindow = overlayWindow
                var rect = SizeHelper.hearthstoneWindow.frame
                rect.origin = NSZeroPoint
                defaultFrame = rect
            } else if window == "Player Board Damage" {
                currentWindow = Game.instance.playerBoardDamage!.window
                defaultFrame = NSRect(x: 915, y: 205.0, width: 50.0, height: 50.0)
            } else if window == "Opponent Board Damage" {
                currentWindow = Game.instance.opponentBoardDamage!.window
                defaultFrame = NSRect(x: 910, y: 617.0, width: 50.0, height: 50.0)
            }

            update()
        }
    }

    @IBAction func up(sender: AnyObject) {
        y += 1
        update()
    }

    @IBAction func down(sender: AnyObject) {
        y -= 1
        update()
    }

    @IBAction func left(sender: AnyObject) {
        x -= 1
        update()
    }

    @IBAction func right(sender: AnyObject) {
        x += 1
        update()
    }

    @IBAction func fup(sender: AnyObject) {
        y += 10
        update()
    }

    @IBAction func ffup(sender: AnyObject) {
        y += 100
        update()
    }
    
    @IBAction func fdown(sender: AnyObject) {
        y -= 10
        update()
    }

    @IBAction func ffdown(sender: AnyObject) {
        y -= 100
        update()
    }
    
    @IBAction func fleft(sender: AnyObject) {
        x -= 10
        update()
    }

    @IBAction func fright(sender: AnyObject) {
        x += 10
        update()
    }

    private func update() {
        let _x = defaultFrame.origin.x + x
        let _y = defaultFrame.origin.y + y
        textbox.string = "NSRect(x: \(_x), y: \(_y), "
            + "width: \(NSWidth(defaultFrame)), height: \(NSHeight(defaultFrame)))\n"
            + "NSPoint(x: \(_x), y: \(_y))"

        if let window = currentWindow {
            let frame = SizeHelper.hearthstoneWindow.relativeFrame(
                NSRect(x: _x, y: _y, width: NSWidth(defaultFrame), height: NSHeight(defaultFrame)))
            window.setFrame(frame, display: true)
        }
    }

    @IBAction func show(sender: AnyObject) {
        currentWindow?.orderFrontRegardless()
    }

    @IBAction func hide(sender: AnyObject) {
        currentWindow?.orderOut(self)
    }

    @IBAction func screenshot(sender: AnyObject) {
        if let x = Float(screenX.stringValue),
            y = Float(screenY.stringValue),
            w = Float(screenWidth.stringValue),
            h = Float(screenHeight.stringValue) {
 
            print("x: \(x), y: \(y), w: \(w), h: \(h)")
            if let image = SizeHelper.hearthstoneWindow.screenshot() {
                let rect = NSRect(x: CGFloat(x),
                                  y: CGFloat(y),
                                  width: CGFloat(w),
                                  height: CGFloat(h))
                let cropped = ImageUtilities.cropRect(image, rect: rect)
                screenshot.image = cropped
            }
        }
    }
    
    @IBAction func crop(sender: AnyObject) {
            let hearthstoneWindow = SizeHelper.hearthstoneWindow
        if let x = Float(screenX.stringValue),
            y = Float(screenY.stringValue),
            w = Float(screenWidth.stringValue),
            h = Float(screenHeight.stringValue) {
            if let image = hearthstoneWindow.screenshot() {
                let scaled = ImageUtilities.resizeImage(image)
                let rect = NSRect(x: CGFloat(x),
                                  y: CGFloat(y),
                                  width: CGFloat(w),
                                  height: CGFloat(h))
                let cropped = ImageUtilities.cropRect(scaled, rect: rect)
                screenshot.image = cropped
                
                let imageCmp = ImageCompare(original: image)
                let rank = imageCmp.rank()
                Log.debug?.message("rank : \(rank)")
                
            }
        }
    }
    
    @IBAction func screenshotPlayerRank(sender: AnyObject) {
        if let image = ImageUtilities.screenshotPlayerRank() {
            screenshot.image = image
            
            let imageCmp = ImageCompare(original: image)
            let rank = imageCmp.rank()
            Log.debug?.message("rank : \(rank)")
        }
    }
}

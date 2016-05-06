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
    @IBOutlet weak var _fleft: NSButton!
    @IBOutlet weak var _fright: NSButton!
    @IBOutlet weak var _show: NSButton!
    @IBOutlet weak var _hide: NSButton!
    @IBOutlet var textbox: NSTextView!

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
            _show, _hide
            ].forEach { $0.enabled = buttonEnabled }

        guard windowChooser.indexOfSelectedItem > 0 else { return }

        if let window = windowChooser
            .itemObjectValueAtIndex(windowChooser.indexOfSelectedItem) as? String {

            // reset
            y = 0
            x = 0

            if window == "Secret Tracker" {
                currentWindow = Game.instance.secretTracker!.window
                defaultFrame = NSRect(x: 200, y: 50, width: CGFloat(kMediumRowHeight), height: 300)
            } else if window == "Timer Hud" {
                currentWindow = Game.instance.timerHud!.window
                defaultFrame = NSRect(x: 1042.0, y: 337.0, width: 160.0, height: 115.0)
            } else if window == "Card Hud 1" {
                currentWindow = Game.instance.cardHuds![0].window
                defaultFrame = NSRect(x: 529.5, y: -10, width: 36, height: 45)
            } else if window == "Card Hud 2" {
                currentWindow = Game.instance.cardHuds![1].window
                defaultFrame = NSRect(x: 560.5, y: -9, width: 36, height: 45)
            } else if window == "Card Hud 3" {
                currentWindow = Game.instance.cardHuds![2].window
                defaultFrame = NSRect(x: 590.5, y: 0, width: 36, height: 45)
            } else if window == "Card Hud 4" {
                currentWindow = Game.instance.cardHuds![3].window
                defaultFrame = NSRect(x: 618.5, y: 9, width: 36, height: 45)
            } else if window == "Card Hud 5" {
                currentWindow = Game.instance.cardHuds![4].window
                defaultFrame = NSRect(x: 646.5, y: 16, width: 36, height: 45)
            } else if window == "Card Hud 6" {
                currentWindow = Game.instance.cardHuds![5].window
                defaultFrame = NSRect(x: 675.5, y: 20, width: 36, height: 45)
            } else if window == "Card Hud 7" {
                currentWindow = Game.instance.cardHuds![6].window
                defaultFrame = NSRect(x: 704.5, y: 17, width: 36, height: 45)
            } else if window == "Card Hud 8" {
                currentWindow = Game.instance.cardHuds![7].window
                defaultFrame = NSRect(x: 732.5, y: 10, width: 36, height: 45)
            } else if window == "Card Hud 9" {
                currentWindow = Game.instance.cardHuds![8].window
                defaultFrame = NSRect(x: 762.5, y: 3, width: 36, height: 45)
            } else if window == "Card Hud 10" {
                currentWindow = Game.instance.cardHuds![9].window
                defaultFrame = NSRect(x: 797.5, y: -11, width: 36, height: 45)
            } else if window == "Full overlay" {
                currentWindow = overlayWindow
                var rect = SizeHelper.hearthstoneWindow.frame
                rect.origin = NSZeroPoint
                defaultFrame = rect
            }

            update()
        }
    }

    @IBAction func up(sender: AnyObject) {
        y -= 1
        update()
    }

    @IBAction func down(sender: AnyObject) {
        y += 1
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
        y -= 10
        update()
    }

    @IBAction func fdown(sender: AnyObject) {
        y += 10
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

        let frame = SizeHelper.frameRelativeToHearthstone(
            NSRect(x: _x, y: _y, width: NSWidth(defaultFrame), height: NSHeight(defaultFrame)),
            true)
        currentWindow?.setFrame(frame, display: true)
    }

    @IBAction func addEntity(sender: AnyObject) {
        for hud in Game.instance.cardHuds! {
            let entity = Entity()
            entity.info.hidden = false
            entity.cardId = Cards.collectible().shuffleOne()!.id
            hud.setEntity(entity)
        }
    }

    @IBAction func show(sender: AnyObject) {
        currentWindow?.orderFrontRegardless()
    }

    @IBAction func hide(sender: AnyObject) {
        currentWindow?.orderOut(self)
    }
}

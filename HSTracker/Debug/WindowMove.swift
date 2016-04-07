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
    
    var defaultFrame = NSZeroRect
    var x:CGFloat = 0, y:CGFloat = 0
    var currentWindow: NSWindowController?
    
    @IBAction func opacityChange(sender: NSSlider) {
        if currentWindow != nil {
            currentWindow!.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(sender.doubleValue / 100.0))
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
        
        if let window = windowChooser.itemObjectValueAtIndex(windowChooser.indexOfSelectedItem) as? String {
            if window == "Secret Tracker" {
                currentWindow = Game.instance.secretTracker!
                defaultFrame = NSMakeRect(200, 50, CGFloat(kMediumRowHeight), 300)
            }
            else if window == "Timer Hud" {
                currentWindow = Game.instance.timerHud!
                defaultFrame = NSMakeRect(1042.0, 337.0, 160.0, 115.0)
            }
            else if window == "Card Hud 1" {
                currentWindow = Game.instance.cardHuds![0]
                defaultFrame = NSMakeRect(529.5, -10, 36, 45)
            }
            else if window == "Card Hud 2" {
                currentWindow = Game.instance.cardHuds![1]
                defaultFrame = NSMakeRect(560.5, -9, 36, 45)
            }
            else if window == "Card Hud 3" {
                currentWindow = Game.instance.cardHuds![2]
                defaultFrame = NSMakeRect(590.5, 0, 36, 45)
            }
            else if window == "Card Hud 4" {
                currentWindow = Game.instance.cardHuds![3]
                defaultFrame = NSMakeRect(618.5, 9, 36, 45)
            }
            else if window == "Card Hud 5" {
                currentWindow = Game.instance.cardHuds![4]
                defaultFrame = NSMakeRect(646.5, 16, 36, 45)
            }
            else if window == "Card Hud 6" {
                currentWindow = Game.instance.cardHuds![5]
                defaultFrame = NSMakeRect(675.5, 20, 36, 45)
            }
            else if window == "Card Hud 7" {
                currentWindow = Game.instance.cardHuds![6]
                defaultFrame = NSMakeRect(704.5, 17, 36, 45)
            }
            else if window == "Card Hud 8" {
                currentWindow = Game.instance.cardHuds![7]
                defaultFrame = NSMakeRect(732.5, 10, 36, 45)
            }
            else if window == "Card Hud 9" {
                currentWindow = Game.instance.cardHuds![8]
                defaultFrame = NSMakeRect(762.5, 3, 36, 45)
            }
            else if window == "Card Hud 10" {
                currentWindow = Game.instance.cardHuds![9]
                defaultFrame = NSMakeRect(797.5, -11, 36, 45)
            }
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
        textbox.string = "NSMakeRect(\(_x), \(_y), \(NSWidth(defaultFrame)), \(NSHeight(defaultFrame)))\n" +
        "NSMakePoint(\(_x), \(_y))"
        
        let frame = SizeHelper.frameRelativeToHearthstone(NSMakeRect(_x, _y, NSWidth(defaultFrame), NSHeight(defaultFrame)), true)
        currentWindow?.window?.setFrame(frame, display: true)
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
        currentWindow?.showWindow(self)
    }
    
    @IBAction func hide(sender: AnyObject) {
        currentWindow?.window?.orderOut(self)
    }
}
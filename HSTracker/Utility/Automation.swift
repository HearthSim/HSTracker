//
//  Automation.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Automation {
    private var queue: dispatch_queue_t = dispatch_queue_create("export.hstracker", nil)
    
    func expertDeckToHearthstone(deck: Deck, callback: (()->())?) {
        dispatch_async(queue) {
            
            // bring HS to front
            Hearthstone.instance.bringToFront()
            
            let searchLocation = SizeHelper.searchLocation()
            let firstCardLocation = SizeHelper.firstCardLocation()
            deck.sortedCards.forEach {
                for _ in 1...$0.count {
                    self.leftClick(searchLocation)
                    NSThread.sleepForTimeInterval(0.3)
                    self.write($0.name)
                    NSThread.sleepForTimeInterval(0.3)
                    self.doubleClick(firstCardLocation)
                    NSThread.sleepForTimeInterval(0.3)
                }
            }
            
            NSThread.sleepForTimeInterval(1)
            dispatch_async(dispatch_get_main_queue()) {
                callback?()
            }
        }
    }
    
    private func leftClick(location: NSPoint) {
        let source = CGEventSourceCreate(.Private)
        let click = CGEventCreateMouseEvent(source, .LeftMouseDown, location, .Left)
        CGEventPost(.CGHIDEventTap, click)
        
        let release = CGEventCreateMouseEvent(source, .LeftMouseUp, location, .Left)
        CGEventPost(.CGHIDEventTap, release)
    }
    
    private func doubleClick(location: NSPoint) {
        let source = CGEventSourceCreate(.Private)
        
        var click = CGEventCreateMouseEvent(source, .LeftMouseDown, location, .Left)
        CGEventSetIntegerValueField(click, .MouseEventClickState, 1)
        CGEventPost(.CGHIDEventTap, click)
        
        var release = CGEventCreateMouseEvent(source, .LeftMouseUp, location, .Left)
        CGEventSetIntegerValueField(release, .MouseEventClickState, 1)
        CGEventPost(.CGHIDEventTap, release)
        
        click = CGEventCreateMouseEvent(source, .LeftMouseDown, location, .Left)
        CGEventSetIntegerValueField(click, .MouseEventClickState, 2)
        CGEventPost(.CGHIDEventTap, click)
        
        release = CGEventCreateMouseEvent(source, .LeftMouseUp, location, .Left)
        CGEventSetIntegerValueField(release, .MouseEventClickState, 2)
        CGEventPost(.CGHIDEventTap, release)
    }
    
    private func write(string: String) {
        let source = CGEventSourceCreate(.HIDSystemState)
        
        if let source = CGEventSourceCreate(.HIDSystemState) {
            for letter in string.utf16 {
                pressAndReleaseChar(letter, eventSource: source)
            }
        }
    
        // finish by ENTER
        if let event = CGEventCreateKeyboardEvent(source, 0x24, true) {
            CGEventPost(CGEventTapLocation.CGHIDEventTap, event)
        }
        if let event = CGEventCreateKeyboardEvent(source, 0x24, false) {
            CGEventPost(CGEventTapLocation.CGHIDEventTap, event)
        }
    }
    
    private func pressAndReleaseChar(char: UniChar, eventSource es: CGEventSourceRef) {
        pressChar(char, eventSource: es)
        releaseChar(char, eventSource: es)
    }
    
    private func pressChar(char: UniChar, keyDown: Bool = true, eventSource es: CGEventSourceRef) {
        let event = CGEventCreateKeyboardEvent(es, 0, keyDown)
        var char = char
        CGEventKeyboardSetUnicodeString(event, 1, &char)
        CGEventPost(CGEventTapLocation.CGHIDEventTap, event)
    }
    
    private func releaseChar(char: UniChar, eventSource es: CGEventSourceRef) {
        pressChar(char, keyDown: false, eventSource: es)
    }
}
//
//  Automation.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Automation {
    private var queue: DispatchQueue = DispatchQueue(label: "export.hstracker", attributes: [])
    
    func expertDeckToHearthstone(deck: Deck, callback: (()->())?) {
        queue.async {
            // bring HS to front
            Hearthstone.instance.bringToFront()

            let searchLocation = SizeHelper.searchLocation()
            let firstCardLocation = SizeHelper.firstCardLocation()
            deck.sortedCards.forEach {
                for _ in 1...$0.count {
                    self.leftClick(at: searchLocation)
                    Thread.sleep(forTimeInterval: 0.3)
                    self.write(string: $0.name)
                    Thread.sleep(forTimeInterval: 0.3)
                    self.doubleClick(at: firstCardLocation)
                    Thread.sleep(forTimeInterval: 0.3)
                }
            }
            
            Thread.sleep(forTimeInterval: 1)
            DispatchQueue.main.async {
                callback?()
            }
        }
    }
    
    private func leftClick(at location: NSPoint) {
        let source = CGEventSource(stateID: .privateState)
        let click = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                            mouseCursorPosition: location, mouseButton: .left)
        click?.post(tap: .cghidEventTap)
        
        let release = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                              mouseCursorPosition: location, mouseButton: .left)
        release?.post(tap: .cghidEventTap)
    }
    
    private func doubleClick(at location: NSPoint) {
        let source = CGEventSource(stateID: .privateState)
        
        var click = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                            mouseCursorPosition: location, mouseButton: .left)
        click?.setIntegerValueField(.mouseEventClickState, value: 1)
        click?.post(tap: .cghidEventTap)
        
        var release = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                              mouseCursorPosition: location, mouseButton: .left)
        release?.setIntegerValueField(.mouseEventClickState, value: 1)
        release?.post(tap: .cghidEventTap)
        
        click = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                        mouseCursorPosition: location, mouseButton: .left)
        click?.setIntegerValueField(.mouseEventClickState, value: 2)
        click?.post(tap: .cghidEventTap)
        
        release = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                          mouseCursorPosition: location, mouseButton: .left)
        release?.setIntegerValueField(.mouseEventClickState, value: 2)
        release?.post(tap: .cghidEventTap)
    }
    
    private func write(string: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        if let source = CGEventSource(stateID: .hidSystemState) {
            for letter in string.utf16 {
                pressAndReleaseChar(char: letter, eventSource: source)
            }
        }
    
        // finish by ENTER
        if let event = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true) {
            event.post(tap: CGEventTapLocation.cghidEventTap)
        }
        if let event = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false) {
            event.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }
    
    private func pressAndReleaseChar(char: UniChar, eventSource es: CGEventSource) {
        pressChar(char: char, eventSource: es)
        releaseChar(char: char, eventSource: es)
    }

    private func pressChar(char: UniChar, keyDown: Bool = true, eventSource es: CGEventSource) {
        let event = CGEvent(keyboardEventSource: es, virtualKey: 0, keyDown: keyDown)
        var char = char
        event?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
    private func releaseChar(char: UniChar, eventSource es: CGEventSource) {
        pressChar(char: char, keyDown: false, eventSource: es)
    }
}

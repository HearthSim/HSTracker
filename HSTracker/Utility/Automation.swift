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
    
    func expertDeckToHearthstone(deck: Deck, callback: (() -> Void)?) {
        queue.async {
            // bring HS to front
            Hearthstone.instance.bringToFront()

            let searchLocation = SizeHelper.searchLocation()
            let firstCardLocation = SizeHelper.firstCardLocation()
            let secondCardLocation = SizeHelper.secondCardLocation()

            let cardMissingDetection = CardMissingDetection()

            // click a first time to be sure we have the focus on hearthstone
            self.leftClick(at: searchLocation)
            Thread.sleep(forTimeInterval: 0.5)

            deck.sortedCards.forEach {
                self.leftClick(at: searchLocation)
                Thread.sleep(forTimeInterval: 0.3)
                self.write(string: self.searchText(card: $0))
                Thread.sleep(forTimeInterval: 0.3)

                for _ in 1...$0.count {
                    let silverLock = cardMissingDetection.silverLock()
                    let goldenLock = cardMissingDetection.goldenLock()
                    if silverLock || goldenLock {
                        self.doubleClick(at: secondCardLocation)
                    } else {
                        self.doubleClick(at: firstCardLocation)
                    }
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

    private func searchText(card: Card) -> String {
        var str = card.name
        guard let lang = Settings.instance.hearthstoneLanguage else {
            return str
        }

        if let text = artistDict[lang],
            let artist = card.artist.components(separatedBy: " ").last {
            str += " \(text):\(artist)"
        }
        if let text = manaDict[lang] {
            str += " \(text):\(card.cost)"
        }
        if let text = attackDict[lang], attackIds.contains(card.id) {
            str += " \(text):\(card.attack)"
        }
        return str
    }

    private let attackIds = [
        CardIds.Collectible.Neutral.Feugen,
        CardIds.Collectible.Neutral.Stalagg
    ]

    private let artistDict = [
        "enUS": "artist",
        "zhCN": "画家",
        "zhTW": "畫家",
        "enGB": "artist",
        "frFR": "artiste",
        "deDE": "künstler",
        "itIT": "artista",
        "jaJP": "アーティスト",
        "koKR": "아티스트",
        "plPL": "grafik",
        "ptBR": "artista",
        "ruRU": "художник",
        "esMX": "artista",
        "esES": "artista"
    ]

    private let manaDict = [
        "enUS": "mana",
        "zhCN": "法力值",
        "zhTW": "法力",
        "enGB": "mana",
        "frFR": "mana",
        "deDE": "mana",
        "itIT": "mana",
        "jaJP": "マナ",
        "koKR": "마나",
        "plPL": "mana",
        "ptBR": "mana",
        "ruRU": "мана",
        "esMX": "maná",
        "esES": "maná"
    ]

    private let attackDict = [
        "enUS": "attack",
        "zhCN": "攻击力",
        "zhTW": "攻擊力",
        "enGB": "attack",
        "frFR": "attaque",
        "deDE": "angriff",
        "itIT": "attacco",
        "jaJP": "攻撃",
        "koKR": "공격력",
        "plPL": "atak",
        "ptBR": "ataque",
        "ruRU": "атака",
        "esMX": "ataque",
        "esES": "ataque"
    ]
}

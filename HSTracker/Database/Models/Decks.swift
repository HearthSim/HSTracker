//
//  Decks.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 17/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import Unbox
import Wrap

final class Decks {
    static let instance = Decks()

    private var _decks = [String: Deck]()

    private var savePath: String? {
        if let path = Settings.instance.deckPath {
            return path
        }
        return nil
    }

    func loadDecks(splashscreen: Splashscreen?) {
        if let path = savePath {
            convertOldFile()
            
            let fileManager = FileManager.default
            
            // load decks
            var files: [String]? = nil
            do {
                files = try fileManager.contentsOfDirectory(atPath: path)
            } catch {
                Log.error?.message("Can not read content of \(path)")
            }
            if let files = files {
                let jsonFiles = files.filter({ $0.hasSuffix(".json") })
                DispatchQueue.main.async {
                    splashscreen?.display(String(format:
                        NSLocalizedString("Loading decks", comment: "")),
                                         total: Double(jsonFiles.count))
                }
                for file in jsonFiles {
                    DispatchQueue.main.async {
                        splashscreen?.increment()
                    }
                    load(file: file)
                }
            }
        }
    }

    private func convertOldFile() {
        guard let path = savePath else { return }
        let fileManager = FileManager.default
        
        // convert old json file
        let jsonFile = "\(path)/decks.json"
        if fileManager.fileExists(atPath: "\(path)/decks.json") {
            if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonFile)) {
                var decks: [String: [String: AnyObject]]? = nil
                do {
                    if let _decks = try JSONSerialization
                        .jsonObject(with: jsonData,
                                            options: .allowFragments)
                        as? [String: [String: AnyObject]] {
                        decks = _decks
                    }
                    try fileManager.removeItem(atPath: "\(jsonFile)")
                    if fileManager.fileExists(atPath: "\(jsonFile).bkp") {
                        try fileManager.removeItem(atPath: "\(jsonFile).bkp")
                    }
                } catch {
                    Log.error?.message("Error loading decks: \(error)")
                }
                if let decks = decks {
                    for (_, _deck) in decks {
                        let deck: Deck
                        do {
                            deck = try unbox(dictionary: _deck)
                        } catch {
                            Log.error?.message("Error unboxing deck")
                            continue
                        }
                        
                        if deck.isValid() {
                            _decks[deck.deckId] = deck
                            do {
                                let dictionary: [String : Any] = try wrap(deck)
                                let data = try JSONSerialization
                                    .data(withJSONObject: dictionary,
                                                        options: .prettyPrinted)
                                let file = "\(path)/\(deck.deckId).json"
                                try? data.write(to: URL(fileURLWithPath: file), options: [.atomic])
                            } catch {
                                Log.error?.message("Error unboxing deck")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func decks() -> [Deck] {
        return _decks.map { $0.1 }
    }

    func add(deck: Deck) {
        deck.creationDate = Date()
        _decks[deck.deckId] = deck
        save(deck: deck)
    }

    func update(deck: Deck) {
        _decks[deck.deckId] = deck
        save(deck: deck)
    }

    func remove(deck: Deck) {
        _decks[deck.deckId] = nil
        guard let path = savePath else {
            Log.warning?.message("SavePath does not exists for decks")
            return
        }
        do {
            try FileManager.default.removeItem(atPath: "\(path)/\(deck.deckId).json")
        } catch {
            Log.error?.message("Can not delete \(path)")
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_decks"),
                                        object: nil)
    }
    
    func reset(deck: Deck) {
        load(file: "\(deck.deckId).json")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_decks"),
                                        object: nil)
    }
    
    internal func load(file: String) {
        guard let path = savePath else {
            Log.warning?.message("SavePath does not exists for decks")
            return
        }
        
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: "\(path)/\(file)")) {
            do {
                let deck: Deck = try unbox(data: jsonData)
                if deck.isValid() {
                    _decks[deck.deckId] = deck
                }
            } catch {
                Log.error?.message("Error unboxing deck")
            }
        }
    }

    private func save(deck: Deck) {
        guard let path = savePath else {
            Log.warning?.message("SavePath does not exists for decks")
            return
        }
        
        do {
            try FileManager.default
                .createDirectory(atPath: path,
                                       withIntermediateDirectories: true,
                                       attributes: nil)
        } catch {
            Log.error?.message("Can not create decks dir")
            return
        }
        
        do {
            let dictionary: [String : Any] = try wrap(deck)
            let data = try JSONSerialization
                .data(withJSONObject: dictionary,
                                    options: .prettyPrinted)
            let file = "\(path)/\(deck.deckId).json"
            try? data.write(to: URL(fileURLWithPath: file), options: [.atomic])
        } catch {
            Log.error?.message("Error wrapping deck")
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_decks"),
                                        object: nil)
    }

    func byId(_ id: String) -> Deck? {
        return decks().filter({ $0.deckId == id }).first
    }
}

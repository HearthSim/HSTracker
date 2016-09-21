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
            
            let fileManager = NSFileManager.defaultManager()
            
            // load decks
            var files: [String]? = nil
            do {
                files = try fileManager.contentsOfDirectoryAtPath(path)
            } catch {
                Log.error?.message("Can not read content of \(path)")
            }
            if let files = files {
                let jsonFiles = files.filter({ $0.endsWith(".json") })
                dispatch_async(dispatch_get_main_queue()) {
                    splashscreen?.display(String(format:
                        NSLocalizedString("Loading decks", comment: "")),
                                         total: Double(jsonFiles.count))
                }
                for file in jsonFiles {
                    dispatch_async(dispatch_get_main_queue()) {
                        splashscreen?.increment()
                    }
                    load(file)
                }
            }
        }
    }

    private func convertOldFile() {
        guard let path = savePath else { return }
        let fileManager = NSFileManager.defaultManager()
        
        // convert old json file
        let jsonFile = "\(path)/decks.json"
        if fileManager.fileExistsAtPath("\(path)/decks.json") {
            if let jsonData = NSData(contentsOfFile: jsonFile) {
                var decks: [String: [String: AnyObject]]? = nil
                do {
                    if let _decks = try NSJSONSerialization
                        .JSONObjectWithData(jsonData,
                                            options: .AllowFragments)
                        as? [String: [String: AnyObject]] {
                        decks = _decks
                    }
                    try fileManager.removeItemAtPath("\(jsonFile)")
                    if fileManager.fileExistsAtPath("\(jsonFile).bkp") {
                        try fileManager.removeItemAtPath("\(jsonFile).bkp")
                    }
                } catch {
                    Log.error?.message("Error loading decks: \(error)")
                }
                if let decks = decks {
                    for (_, _deck) in decks {
                        let deck: Deck
                        do {
                            deck = try Unbox(_deck)
                        } catch {
                            Log.error?.message("Error unboxing deck")
                            continue
                        }
                        
                        if deck.isValid() {
                            _decks[deck.deckId] = deck
                            do {
                                let dictionary: [String : AnyObject] = try Wrap(deck)
                                let data = try NSJSONSerialization
                                    .dataWithJSONObject(dictionary,
                                                        options: .PrettyPrinted)
                                let file = "\(path)/\(deck.deckId).json"
                                data.writeToFile(file, atomically: true)
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
        deck.creationDate = NSDate()
        _decks[deck.deckId] = deck
        save(deck)
    }

    func update(deck: Deck) {
        _decks[deck.deckId] = deck
        save(deck)
    }

    func remove(deck: Deck) {
        _decks[deck.deckId] = nil
        guard let path = savePath else {
            Log.warning?.message("SavePath does not exists for decks")
            return
        }
        do {
            try NSFileManager.defaultManager().removeItemAtPath("\(path)/\(deck.deckId).json")
        } catch {
            Log.error?.message("Can not delete \(path)")
        }
        NSNotificationCenter.defaultCenter().postNotificationName("reload_decks", object: nil)
    }
    
    func reset(deck: Deck) {
        load("\(deck.deckId).json")
        NSNotificationCenter.defaultCenter().postNotificationName("reload_decks", object: nil)
    }
    
    internal func load(file: String) {
        guard let path = savePath else {
            Log.warning?.message("SavePath does not exists for decks")
            return
        }
        
        if let jsonData = NSData(contentsOfFile: "\(path)/\(file)") {
            do {
                let deck: Deck = try Unbox(jsonData)
                if deck.isValid() {
                    _decks[deck.deckId] = deck
                }
            } catch {
                Log.error?.message("Error unboxing deck")
            }
        }
    }

    internal func save(deck: Deck) {
        guard let path = savePath else {
            Log.warning?.message("SavePath does not exists for decks")
            return
        }
        
        do {
            try NSFileManager.defaultManager()
                .createDirectoryAtPath(path,
                                       withIntermediateDirectories: true,
                                       attributes: nil)
        } catch {
            Log.error?.message("Can not create decks dir")
            return
        }
        
        do {
            let dictionary: [String : AnyObject] = try Wrap(deck)
            let data = try NSJSONSerialization
                .dataWithJSONObject(dictionary,
                                    options: .PrettyPrinted)
            let file = "\(path)/\(deck.deckId).json"
            data.writeToFile(file, atomically: true)
        } catch {
            Log.error?.message("Error wrapping deck")
        }
        NSNotificationCenter.defaultCenter().postNotificationName("reload_decks", object: nil)
    }

    func byId(id: String) -> Deck? {
        return decks().filter({ $0.deckId == id }).first
    }
}

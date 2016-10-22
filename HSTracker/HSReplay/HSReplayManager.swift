//
//  HSReplayManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Unbox
import Wrap
import CleanroomLogger

class HSReplayManager {
    
    static let instance = HSReplayManager()
    
    var replays: [Replay] = []
    
    init() {
        loadReplays()
    }
    
    private var savePath: String? {
        if let appSupport = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true).first {
            
            return "\(appSupport)/HSTracker/replays.json"
        }
        return nil
    }
    
    private func loadReplays() {
        if let path = savePath {
            if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                do {
                    self.replays = try unbox(data: jsonData)
                } catch {
                    Log.error?.message("Error unboxing deck")
                }
            }
        }
    }
    
    func saveReplay(replayId: String, deck: String, against: String) {
        replays.append(Replay(replayId: replayId, deck: deck, against: against))
        save()
    }
    
    private func save() {
        guard let path = savePath else { return }
        do {
            let json: [Any] = try wrap(replays)
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_decks"),
                                            object: nil)
        } catch {
            Log.error?.message("Error wrapping replays")
        }
    }
    
    class func showReplay(replayId: String) {
        let url = URL(string: "\(HSReplay.baseUrl)/uploads/upload/\(replayId)")
        NSWorkspace.shared().open(url!)
    }
    
    struct Replay: Unboxable {
        var replayId: String
        var deck: String
        var against: String
        var date: Date
        
        init(replayId: String, deck: String, against: String) {
            self.replayId = replayId
            self.deck = deck
            self.against = against
            self.date = Date()
        }
        
        init(unboxer: Unboxer) throws {
            self.replayId = try unboxer.unbox(key: "replayId")
            self.deck = try unboxer.unbox(key: "deck")
            self.against = try unboxer.unbox(key: "against")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
            self.date = try unboxer.unbox(key: "date", formatter: dateFormatter)
        }
    }
    
}

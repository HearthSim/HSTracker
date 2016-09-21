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
            .ApplicationSupportDirectory, .UserDomainMask, true).first {
            
            return "\(appSupport)/HSTracker/replays.json"
        }
        return nil
    }
    
    private func loadReplays() {
        if let path = savePath {
            if let jsonData = NSData(contentsOfFile: path) {
                do {
                    self.replays = try Unbox(jsonData)
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
            let json: [AnyObject] = try Wrap(replays)
            let data = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            data.writeToFile(path, atomically: true)
            NSNotificationCenter.defaultCenter().postNotificationName("reload_decks", object: nil)
        } catch {
            Log.error?.message("Error wrapping replays")
        }
    }
    
    class func showReplay(replayId: String) {
        let url = NSURL(string: "\(HSReplay.baseUrl)/uploads/upload/\(replayId)")
        NSWorkspace.sharedWorkspace().openURL(url!)
    }
    
    struct Replay: Unboxable {
        var replayId: String
        var deck: String
        var against: String
        var date: NSDate
        
        init(replayId: String, deck: String, against: String) {
            self.replayId = replayId
            self.deck = deck
            self.against = against
            self.date = NSDate()
        }
        
        init(unboxer: Unboxer) {
            self.replayId = unboxer.unbox("replayId")
            self.deck = unboxer.unbox("deck")
            self.against = unboxer.unbox("against")
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
            self.date = unboxer.unbox("date", formatter: dateFormatter)
        }
    }
    
}

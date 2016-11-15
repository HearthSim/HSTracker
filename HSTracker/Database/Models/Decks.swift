//
//  Decks.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 17/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift

final class Decks {
    static let instance = Decks()

    func loadDecks(splashscreen: Splashscreen?) {
        let fileManager = FileManager.default

        // load decks
        let path = Paths.decks
        var files: [URL]? = nil
        do {
            files = try fileManager.contentsOfDirectory(at: path,
                                                        includingPropertiesForKeys: nil,
                                                        options: [])
        } catch {
            Log.error?.message("Can not read content of \(path)")
        }
        if let files = files {
            let jsonFiles = files.filter({ $0.pathExtension == "json" })
            DispatchQueue.main.async {
                splashscreen?.display(String(format:
                    NSLocalizedString("Loading decks", comment: "")),
                                      total: Double(jsonFiles.count))
            }

            do {
                let realm = try Realm()

                for file in jsonFiles {
                    DispatchQueue.main.async {
                        splashscreen?.increment()
                    }
                    load(file: file, realm: realm)
                }
            } catch {
                Log.error?.message("\(error)")
            }
        }
    }

    private func remove(file: URL) {
        do {
            try FileManager.default.removeItem(at: file)
        } catch {
            Log.error?.message("Can not delete \(file)")
        }
    }

    fileprivate func load(file: URL, realm: Realm) {
        guard let jsonData = try? Data(contentsOf: file) else {
            Log.error?.message("\(file) is not a valid file ???")
            remove(file: file)
            return
        }

        let json: [String: Any]?
        do {
            json = try JSONSerialization
                    .jsonObject(with: jsonData, options: []) as? [String: Any]
        } catch {
            Log.error?.message("\(file) is not a valid json file")
            remove(file: file)
            return
        }

        guard let data = json else {
            Log.error?.message("\(file) is not a valid json file")
            remove(file: file)
            return
        }

        guard let cardClass = data["playerClass"] as? String,
            let playerClass = CardClass(rawValue: cardClass.lowercased()) else {
            Log.error?.message("\(data["playerClass"]) is not a valid class")
            remove(file: file)
            return
        }

        let deck = Deck()
        deck.isArena = data["isArena"] as? Bool ?? false
        deck.name = data["name"] as? String ?? "unknown deck"
        deck.isActive = data["isActive"] as? Bool ?? true
        if let date = data["creationDate"] as? String {
            deck.creationDate = Date(fromString: date,
                                     inFormat: "YYYY-MM-dd HH:mm:ss")
        }
        deck.hearthstatsId.value = data["hearthstatsId"] as? Int
        deck.hearthstatsVersionId.value = data["hearthstatsVersionId"] as? Int
        deck.playerClass = playerClass
        deck.version = data["version"] as? String ?? "1.0"

        if let cards = data["cards"] as? [String: Int] {
            for (id, count) in cards {
                deck.cards.append(RealmCard(id: id, count: count))
            }
        }

        if let jsonStats = data["statistics"] as? [[String: Any]] {
            for stats in jsonStats {
                guard let opClass = stats["opponentClass"] as? String,
                    let opponentClass = CardClass(rawValue: opClass.lowercased()) else {
                        continue
                }
                let stat = Statistic()
                stat.opponentClass = opponentClass
                stat.hsReplayId = stats["hsReplayId"] as? String
                stat.gameResult = GameResult(rawValue: stats["gameResult"] as? Int ?? 0) ?? .unknow
                stat.duration = stats["duration"] as? Int ?? 0
                stat.opponentRank.value = stats["opponentRank"] as? Int
                stat.playerRank = stats["playerRank"] as? Int ?? 0
                stat.playerMode = GameMode(rawValue: stats["playerMode"] as? Int
                    ?? GameMode.none.rawValue) ?? .none
                stat.note = stats["note"] as? String ?? ""
                if let date = data["date"] as? String {
                    stat.date = Date(fromString: date,
                                             inFormat: "YYYY-MM-dd HH:mm:ss")
                }
                stat.season.value = stats["season"] as? Int
                stat.numTurns = stats["numTurns"] as? Int ?? 0
                stat.hasCoin = stats["hasCoin"] as? Bool ?? false
                stat.opponentName = stats["opponentName"] as? String ?? "Unknown"

                guard let cards = stats["cards"] as? [String: Int] else { continue }
                for (id, count) in cards {
                    stat.cards.append(RealmCard(id: id, count: count))
                }
                deck.statistics.append(stat)
            }
        }

        if deck.isValid() {
            do {
                try realm.write {
                    realm.add(deck)
                }
            } catch {
                Log.error?.message("Can not save deck")
            }
        }

        remove(file: file)
    }
}

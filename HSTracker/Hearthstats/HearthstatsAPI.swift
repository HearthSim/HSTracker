//
//  HearthstatsAPI.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 21/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift

extension Deck {

    func merge(deck: Deck, cards: [Card]) {
        self.name = deck.name
        self.playerClass = deck.playerClass
        self.version = deck.version
        self.creationDate = deck.creationDate
        self.hearthstatsId.value = deck.hearthstatsId.value
        self.hearthstatsVersionId.value = deck.hearthstatsVersionId.value
        self.isActive = deck.isActive
        self.isArena = deck.isArena
        self.cards.removeAll()
        for card in cards {
            self.add(card: card)
        }
    }

    static func fromHearthstatsDict(json: [String: Any]) -> (Deck, [Card])? {
        if let jsonDeck = json["deck"] as? [String: Any],
            let name = jsonDeck["name"] as? String,
            let klassId = jsonDeck["klass_id"] as? Int,
            let playerClass = HearthstatsAPI.heroes[klassId],
            let version = json["current_version"] as? String,
            let creationDate = jsonDeck["created_at"] as? String,
            let hearthstatsId = jsonDeck["id"] as? Int,
            let archived = jsonDeck["archived"] as? Bool {

            var currentVersion: [String : Any]?
            (json["versions"] as? [[String: Any]])?
                .forEach { (_version: [String : Any]) in
                    if _version["version"] as? String == version {
                        currentVersion = _version
                    }
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

            if let currentVersion = currentVersion,
                let hearthstatsVersionId = currentVersion["deck_version_id"] as? Int,
                let date = formatter.date(from: creationDate) {

                var cards = [Card]()
                (json["cards"] as? [[String: String]])?
                    .forEach({ (_card: [String: String]) in
                        if let card = Cards.by(cardId: _card["id"]),
                            let _count = _card["count"],
                            let count = Int(_count) {
                            card.count = count
                            cards.append(card)
                        }
                    })

                let deck = Deck()
                deck.playerClass = playerClass
                deck.name = name
                deck.creationDate = date
                deck.hearthstatsId.value = hearthstatsId
                deck.hearthstatsVersionId.value = hearthstatsVersionId
                deck.isActive = !archived
                deck.version = version

                if cards.isValidDeck() {
                    return (deck, cards)
                }
            }
        }

        return nil
    }
}

extension Decks {

    func addOrUpdateMatches(dict: [String: Any]) {
        var drealm: Realm?
        do {
            drealm = try Realm()
        } catch {
            Log.error?.message("Can not save match")
        }

        guard let realm = drealm else { return }
        guard let deckId = dict["deck_id"] as? Int,
            let deckVersionId = dict["deck_version_id"] as? Int else { return }

        guard let existing = realm.objects(Deck.self).filter("hearthstatsId = '\(deckId)' and "
            + "hearthstatsVersionId = \(deckVersionId)").first else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        if let dictMatch = dict["match"] as? [String: Any],
            let resultId = dictMatch["result_id"] as? Int,
            let result = HearthstatsAPI.gameResults[resultId],
            let coin = dictMatch["coin"] as? Bool,
            let classId = dictMatch["oppclass_id"] as? Int,
            let opponentClass = HearthstatsAPI.heroes[classId],
            let opponentName = dictMatch["oppname"] as? String,
            let playerRank = dict["ranklvl"] as? Int,
            let mode = dictMatch["mode_id"] as? Int,
            let playerMode = HearthstatsAPI.gameModes[mode],
            let date = dictMatch["created_at"] as? String,
            let creationDate = formatter.date(from: date) {

            let stat = Statistic()
            stat.gameResult = result
            stat.hasCoin = coin
            stat.opponentClass = opponentClass
            stat.opponentName = opponentName
            stat.playerRank = playerRank
            stat.playerMode = playerMode
            stat.date = creationDate

            do {
                try realm.write {
                    existing.statistics.append(stat)
                }
            } catch {
                Log.error?.message("Can not add statistic : \(error)")
            }
        }
    }
}

enum HearthstatsError: Error {
    case notLogged, deckNotSaved
}

struct HearthstatsAPI {
    static let gameResults: [Int: GameResult] = [
        1: .win,
        2: .loss,
        3: .draw
    ]

    static let gameModes: [Int: GameMode] = [
        1: .arena,
        2: .casual,
        3: .ranked,
        4: .none,
        5: .friendly
    ]

    static let heroes: [Int: CardClass] = [
        1: .druid,
        2: .hunter,
        3: .mage,
        4: .paladin,
        5: .priest,
        6: .rogue,
        7: .shaman,
        8: .warlock,
        9: .warrior
    ]

    private static let baseUrl = "http://api.hearthstats.net/api/v3"

    // MARK: - Authentication
    static func login(email: String, password: String,
                      callback: @escaping (_ success: Bool, _ message: String) -> ()) {
        let http = Http(url: "\(baseUrl)/users/sign_in")
        http.json(method: .post,
                  parameters: ["user_login": ["email": email, "password": password ]]) { json in
                    if let json = json as? [String: Any] {
                        if let success = json["success"] as? Bool, success {
                            let settings = Settings.instance
                            settings.hearthstatsLogin = json["email"] as? String
                            settings.hearthstatsToken = json["auth_token"] as? String
                            callback(true, "")
                        } else {
                            callback(false,
                                     json["message"] as? String ?? "Unknown error")
                        }
                    } else {
                        callback(false,
                                 NSLocalizedString("server error", comment: ""))
                    }
        }
    }

    static func logout() {
        let settings = Settings.instance
        settings.hearthstatsLogin = nil
        settings.hearthstatsToken = nil
        settings.hearthstatsLastDecksSync = 0
        settings.hearthstatsSynchronizeMatches = false
        settings.hearthstatsAutoSynchronize = false
    }

    static func isLogged() -> Bool {
        return false
        //let settings = Settings.instance
        //return settings.hearthstatsLogin != nil && settings.hearthstatsToken != nil
    }

    static func loadDecks(force: Bool = false,
                          callback: @escaping (_ success: Bool, _ added: Int) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.notLogged }
        if force {
            settings.hearthstatsLastDecksSync = Date.distantPast.timeIntervalSince1970
        }
        try getDecks(since: settings.hearthstatsLastDecksSync, callback: callback)
    }

    // MARK: - decks
    private static func getDecks(since unixTime: Double,
                                 callback: @escaping (_ success: Bool, _ added: Int) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.notLogged }

        let http = Http(url: "\(baseUrl)/decks/after_date?auth_token=\(settings.hearthstatsToken!)")
        http.json(method: .post, parameters: ["date": "\(unixTime)"]) { json in
            if let json = json as? [String: Any],
                let status = json["status"] as? Int,
                let data = json["data"] as? [[String: Any]],
                let realm = try? Realm(),
                status == 200 {

                var newDecks = 0
                for jsonDeck in data {
                    newDecks += 1
                    if let (deck, cards) = Deck.fromHearthstatsDict(json: jsonDeck),
                        let hearthstatsId = deck.hearthstatsId.value {

                        do {
                            if let existing = realm.objects(Deck.self)
                                .filter("hearthstatsId = \(hearthstatsId)").first {
                                try realm.write {
                                    existing.merge(deck: deck, cards: cards)
                                }
                            } else {
                                try realm.write {
                                    realm.add(deck)
                                    for card in cards {
                                        deck.add(card: card)
                                    }
                                }
                            }
                        } catch {
                            Log.error?.message("Can not update deck : \(error)")
                        }
                    }
                }
                Settings.instance.hearthstatsLastDecksSync = Date().timeIntervalSince1970
                callback(true, newDecks)
                return
            } else {
                callback(false, 0)
            }
        }
    }

    static func post(deck: Deck, callback: @escaping (_ success: Bool) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.notLogged }

        let deckId = deck.deckId

        let http = Http(url: "\(baseUrl)/decks?auth_token=\(settings.hearthstatsToken!)")
        http.json(method: .post,
                  parameters: [
                    "name": deck.name,
                    "tags": [],
                    "notes": "",
                    "cards": deck.sortedCards.map {["id": $0.id, "count": $0.count]},
                    "class": deck.playerClass.rawValue.capitalized,
                    "version": deck.version
        ]) { json in
            if let json = json as? [String: Any],
                let data = json["data"] as? [String: Any],
                let jsonDeck = data["deck"] as? [String: Any],
                let hearthstatsId = jsonDeck["id"] as? Int,
                let deckVersions = data["deck_versions"] as? [[String: Any]],
                let hearthstatsVersionId = deckVersions.first?["id"] as? Int {
                do {
                    let realm = try Realm()
                    guard let existing = realm.objects(Deck.self)
                        .filter("deckId = '\(deckId)'").first else { return }
                    try realm.write {
                        existing.hearthstatsId.value = hearthstatsId
                        existing.hearthstatsVersionId.value = hearthstatsVersionId
                    }
                    callback(true)
                } catch {
                    Log.error?.message("Can not update deck : \(error)")
                    callback(false)
                }
            } else {
                callback(false)
            }
        }
    }

    static func update(deck: Deck, callback: @escaping (_ success: Bool) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.notLogged }

        let http = Http(url: "\(baseUrl)/decks/edit?auth_token=\(settings.hearthstatsToken!)")
        http.json(method: .post,
                  parameters: [
                    "deck_id": deck.hearthstatsId.value!,
                    "name": deck.name,
                    "tags": [],
                    "notes": "",
                    "cards": deck.sortedCards.map {["id": $0.id, "count": $0.count]},
                    "class": deck.playerClass.rawValue.capitalized
        ]) { json in
            if let json = json {
                Log.debug?.message("update deck : \(json)")
                callback(true)
            } else {
                callback(false)
            }
        }
    }

    static func post(deckVersion deck: Deck, callback: @escaping (_ success: Bool) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.notLogged }

        let deckId = deck.deckId

        let http = Http(url:
            "\(baseUrl)/decks/create_version?auth_token=\(settings.hearthstatsToken!)")
        http.json(method: .post,
                  parameters: [
                    "deck_id": deck.hearthstatsId.value!,
                    "cards": deck.sortedCards.map {["id": $0.id, "count": $0.count]},
                    "version": deck.version
        ]) { json in
            if let json = json as? [String: Any],
                let data = json["data"] as? [String: Any],
                let hearthstatsVersionId = data["id"] as? Int {
                Log.debug?.message("post deck version : \(json)")
                do {
                    let realm = try Realm()
                    guard let existing = realm.objects(Deck.self)
                        .filter("deckId = '\(deckId)'").first else { return }
                    try realm.write {
                        existing.hearthstatsVersionId.value = hearthstatsVersionId
                    }
                    callback(true)
                } catch {
                    Log.error?.message("Can not udpdate deck : \(error)")
                    callback(false)
                }
            } else {
                callback(false)
            }
        }
    }

    static func delete(deck: Deck) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.notLogged }

        let http = Http(url: "\(baseUrl)/decks/delete?auth_token=\(settings.hearthstatsToken!)")
        http.json(method: .post,
                  parameters: ["deck_id": "[\(deck.hearthstatsId.value!)]"]) { json in
                    if let json = json {
                        Log.debug?.message("delete deck : \(json)")
                        return
                    }
        }
    }

    // MARK: - matches
    static func getGames(since unixTime: Double,
                         callback: @escaping (_ success: Bool) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.notLogged }

        let http = Http(url:
            "\(baseUrl)/matches/after_date?auth_token=\(settings.hearthstatsToken!)")
        http.json(method: .post,
                  parameters: ["date": "\(unixTime)"]) { json in
                    if let json = json as? [String: Any] {
                        Log.debug?.message("get games : \(json)")
                        (json["data"] as? [[String: Any]])?.forEach({
                            Decks.instance.addOrUpdateMatches(dict: $0)
                        })

                        let settings = Settings.instance
                        settings.hearthstatsLastMatchesSync = Date().timeIntervalSince1970
                        callback(true)
                    } else {
                        callback(false)
                    }
        }
    }
 
    static func postMatch(game: Game, deck: Deck, stat: Statistic) throws {
        let settings = Settings.instance
        guard let hearthstatsToken = settings.hearthstatsToken else {
            throw HearthstatsError.notLogged
        }
        guard let hearthstatsId = deck.hearthstatsId.value else {
            throw HearthstatsError.deckNotSaved }
        guard let hearthstatsVersionId = deck.hearthstatsVersionId.value else {
            throw HearthstatsError.deckNotSaved
        }

        let startTime: Date
        if let gameStartDate = game.gameStartDate {
            startTime = gameStartDate as Date
        } else {
            startTime = Date()
        }
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let startAt = formatter.string(from: startTime)

        var cards: [String: Int] = [:]
        stat.cards.forEach { cards[$0.id] = $0.count }

        let parameters: [String: Any] = [
            "class": deck.playerClass.rawValue.capitalized,
            "mode": "\(game.currentGameMode)".capitalized,
            "result": "\(game.gameResult)".capitalized,
            "coin": "\(stat.hasCoin)",
            "numturns": stat.numTurns,
            "duration": stat.duration,
            "deck_id": hearthstatsId,
            "deck_version_id": hearthstatsVersionId,
            "oppclass": stat.opponentClass.rawValue.capitalized,
            "oppname": stat.opponentName,
            "notes": stat.note,
            "ranklvl": stat.playerRank,
            "oppcards": cards,
            "created_at": startAt
        ]
        Log.info?.message("Posting match to Hearthstats \(parameters)")
        let http = Http(url: "\(baseUrl)/matches?auth_token=\(hearthstatsToken)")
        http.json(method: .post,
                  parameters: parameters) { json in
                if let json = json {
                    Log.debug?.message("post match : \(json)")
                }
        }
    }
    
    // MARK: - Arena
    
    static func postArenaMatch(game: Game, deck: Deck, stat: Statistic) throws {
        guard let _ = Settings.instance.hearthstatsToken else { throw HearthstatsError.notLogged }
        
        guard let _ = deck.hearthStatsArenaId.value else {
            createArenaRun(game: game, deck: deck, stat: stat)
            return
        }
        
        _postArenaMatch(game: game, deck: deck, stat: stat)
    }

    private static func _postArenaMatch(game: Game, deck: Deck, stat: Statistic) {
        let parameters: [String: Any] = [
            "class": deck.playerClass.rawValue.capitalized,
            "mode": "\(game.currentGameMode)".capitalized,
            "result": "\(game.gameResult)".capitalized,
            "coin": "\(stat.hasCoin)",
            "numturns": stat.numTurns,
            "duration": stat.duration,
            "arena_run_id": deck.hearthStatsArenaId.value!,
            "oppclass": stat.opponentClass.rawValue.capitalized,
            "oppname": stat.opponentName
            ]
        Log.info?.message("Posting arena match to Hearthstats \(parameters)")
        let http = Http(url:
            "\(baseUrl)/matches?auth_token=\(Settings.instance.hearthstatsToken!)")
        http.json(method: .post,
                  parameters: parameters) { json in
                    if let json = json {
                        Log.debug?.message("post arena match : \(json)")
                    }
        }
    }
    
    static func createArenaRun(game: Game, deck: Deck, stat: Statistic) {
        Log.info?.message("Creating new arena deck")
        let parameters: [String: Any] = [
            "class": deck.playerClass.rawValue.capitalized,
            "cards": deck.sortedCards.map {["id": $0.id, "count": $0.count]}
        ]
        let deckId = deck.deckId
        let http = Http(url:
            "\(baseUrl)/arena_runs/new?auth_token=\(Settings.instance.hearthstatsToken!)")
        http.json(method: .post,
                  parameters: parameters) { json in
                    if let json = json as? [String: Any],
                        let data = json["data"] as? [String: Any],
                        let hearthStatsArenaId = data["id"] as? Int {
                        do {
                            let realm = try Realm()
                            guard let existing = realm.objects(Deck.self)
                                .filter("deckId = '\(deckId)'").first else { return }
                            try realm.write {
                                existing.hearthStatsArenaId.value = hearthStatsArenaId
                            }
                        } catch {
                            Log.error?.message("Can not set hearthstatsArenaId on deck. "
                                + "Error: \(error)")
                        }
                        Log.debug?.message("Arena run : \(hearthStatsArenaId)")

                        _postArenaMatch(game: game, deck: deck, stat: stat)
                    }
        }
    }
}

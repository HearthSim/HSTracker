//
//  HearthstatsAPI.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 21/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Alamofire
import CleanroomLogger

extension Deck {

    func merge(deck: Deck) {
        self.name = deck.name
        self.playerClass = deck.playerClass
        self.version = deck.version
        self.creationDate = deck.creationDate
        self.hearthstatsId = deck.hearthstatsId
        self.hearthstatsVersionId = deck.hearthstatsVersionId
        self.isActive = deck.isActive
        self.isArena = deck.isArena
        self.removeAllCards()
        for card in deck.sortedCards {
            for _ in 0...card.count {
                self.addCard(card)
            }
        }
        self.statistics = deck.statistics
    }

    static func fromHearthstatsDict(json: [String: AnyObject]) -> Deck? {
        if let name = json["deck"]?["name"] as? String,
            klassId = json["deck"]?["klass_id"] as? Int,
            playerClass = HearthstatsAPI.heroes[klassId],
            version = json["current_version"] as? String,
            creationDate = json["deck"]?["created_at"] as? String,
            hearthstatsId = json["deck"]?["id"] as? Int,
            archived = json["deck"]?["archived"] as? Int,
            isArchived = archived.boolValue {

                var currentVersion: [String : AnyObject]?
                (json["versions"] as? [[String: AnyObject]])?
                    .forEach { (_version: [String : AnyObject]) in
                    if _version["version"] as? String == version {
                        currentVersion = _version
                    }
                }

                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

                if let currentVersion = currentVersion,
                    hearthstatsVersionId = currentVersion["deck_version_id"] as? Int,
                    date = formatter.dateFromString(creationDate) {

                        var cards = [Card]()
                        (json["cards"] as? [[String: String]])?
                            .forEach({ (_card: [String: String]) in
                            if let card = Cards.byId(_card["id"]),
                                _count = _card["count"],
                                count = Int(_count) {
                                card.count = count
                                cards.append(card)
                            }
                        })

                        let deck = Deck(playerClass: playerClass, name: name)
                        deck.creationDate = date
                        deck.hearthstatsId = hearthstatsId
                        deck.hearthstatsVersionId = hearthstatsVersionId
                        deck.isActive = !isArchived
                        deck.version = version
                        cards.forEach({ deck.addCard($0) })

                        if deck.isValid() {
                            return deck
                        }
                }
        }

        return nil
    }
}

extension Decks {

    func byHearthstatsId(id: Int) -> Deck? {
        return decks().filter({ $0.hearthstatsId == id }).first
    }

    func addOrUpdateMatches(dict: [String: AnyObject]) {
        if let existing = decks()
            .filter({ $0.hearthstatsId == (dict["deck_id"] as? Int)
                && $0.hearthstatsVersionId == (dict["deck_version_id"] as? Int) }).first {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            
            if let resultId = dict["match"]?["result_id"] as? Int,
                result = HearthstatsAPI.gameResults[resultId],
                coin = dict["match"]?["coin"] as? Bool,
                classId = dict["match"]?["oppclass_id"] as? Int,
                opponentClass = HearthstatsAPI.heroes[classId],
                opponentName = dict["match"]?["oppname"] as? String,
                playerRank = dict["ranklvl"] as? Int,
                mode = dict["match"]?["mode_id"] as? Int,
                playerMode = HearthstatsAPI.gameModes[mode],
                date = dict["match"]?["created_at"] as? String,
                creationDate = formatter.dateFromString(date) {
                
                let stat = Statistic()
                stat.gameResult = result
                stat.hasCoin = coin
                stat.opponentClass = opponentClass
                stat.opponentName = opponentName
                stat.playerRank = playerRank
                stat.playerMode = playerMode
                stat.date = creationDate
                
                existing.addStatistic(stat)
                update(existing)
            }
        }
    }
}

enum HearthstatsError: ErrorType {
    case NotLogged,
    DeckNotSaved
}

struct HearthstatsAPI {
    static let gameResults: [Int: GameResult] = [
        1: .Win,
        2: .Loss,
        3: .Draw
    ]

    static let gameModes: [Int: GameMode] = [
        1: .Arena,
        2: .Casual,
        3: .Ranked,
        4: .None,
        5: .Friendly
    ]

    static let heroes: [Int: String] = [
        1: "druid",
        2: "hunter",
        3: "mage",
        4: "paladin",
        5: "priest",
        6: "rogue",
        7: "shaman",
        8: "warlock",
        9: "warrior"
    ]

    private static let baseUrl = "http://api.hearthstats.net/api/v3"

    // MARK: - Authentication
    static func login(email: String, password: String,
                      callback: (success: Bool, message: String) -> ()) {
        Alamofire.request(.POST, "\(baseUrl)/users/sign_in",
            parameters: ["user_login": ["email": email, "password": password ]], encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value {
                        if let success = json["success"] as? Bool where success {
                            let settings = Settings.instance
                            settings.hearthstatsLogin = json["email"] as? String
                            settings.hearthstatsToken = json["auth_token"] as? String
                            callback(success: true, message: "")
                        } else {
                            callback(success: false,
                                message: json["message"] as? String ?? "Unknown error")
                        }
                        return
                    }
                }
                Log.error?.message("\(response.result.error)")
                callback(success: false,
                    message: NSLocalizedString("server error", comment: ""))
        }
    }

    static func logout() {
        let settings = Settings.instance
        settings.hearthstatsLogin = nil
        settings.hearthstatsToken = nil
    }

    static func isLogged() -> Bool {
        let settings = Settings.instance
        return settings.hearthstatsLogin != nil && settings.hearthstatsToken != nil
    }

    static func loadDecks(force: Bool = false,
                          callback: (success: Bool, added: Int) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.NotLogged }
        if force {
            settings.hearthstatsLastDecksSync = NSDate.distantPast().timeIntervalSince1970
        }
        try getDecks(settings.hearthstatsLastDecksSync, callback: callback)
    }

    // MARK: - decks
    private static func getDecks(unixTime: Double,
                                 callback: (success: Bool, added: Int) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.NotLogged }

        Alamofire.request(.POST,
            "\(baseUrl)/decks/after_date?auth_token=\(settings.hearthstatsToken!)",
            parameters: ["date": "\(unixTime)"], encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value,
                        status = json["status"] as? Int where status == 200 {
                        var newDecks = 0
                        (json["data"] as? [[String: AnyObject]])?.forEach({
                            newDecks += 1
                            if let deck = Deck.fromHearthstatsDict($0),
                                hearthstatsId = deck.hearthstatsId {
                                if let existing = Decks.instance.byHearthstatsId(hearthstatsId) {
                                    existing.merge(deck)
                                    Decks.instance.update(existing)
                                } else {
                                    Decks.instance.add(deck)
                                }
                            }
                        })
                        Settings.instance.hearthstatsLastDecksSync = NSDate().timeIntervalSince1970
                        callback(success: true, added: newDecks)
                        return
                    }
                }
                Log.error?.message("\(response.result.error)")
                callback(success: false, added: 0)
        }
    }

    static func postDeck(deck: Deck, callback: (success: Bool) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.NotLogged }

        Alamofire.request(.POST, "\(baseUrl)/decks?auth_token=\(settings.hearthstatsToken!)",
            parameters: [
                "name": deck.name ?? "",
                "tags": [],
                "notes": "",
                "cards": deck.sortedCards.map {["id": $0.id, "count": $0.count]},
                "class": deck.playerClass.capitalizedString,
                "version": deck.version
            ], encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value,
                        data = json["data"] as? [String:AnyObject],
                        jsonDeck = data["deck"] as? [String:AnyObject],
                        hearthstatsId = jsonDeck["id"] as? Int,
                        deckVersions = data["deck_versions"] as? [[String:AnyObject]],
                        hearthstatsVersionId = deckVersions.first?["id"] as? Int {
                        deck.hearthstatsId = hearthstatsId
                        deck.hearthstatsVersionId = hearthstatsVersionId
                        callback(success: true)
                        return
                    }
                }
                Log.error?.message("\(response.result.error)")
                callback(success: false)
        }
    }

    static func updateDeck(deck: Deck, callback: (success: Bool) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.NotLogged }

        Alamofire.request(.POST, "\(baseUrl)/decks/edit?auth_token=\(settings.hearthstatsToken!)",
            parameters: [
                "deck_id": deck.hearthstatsId!,
                "name": deck.name ?? "",
                "tags": [],
                "notes": "",
                "cards": deck.sortedCards.map {["id": $0.id, "count": $0.count]},
                "class": deck.playerClass.capitalizedString
            ], encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value {
                        Log.debug?.message("update deck : \(json)")
                        callback(success: true)
                        return
                    }
                }
                Log.error?.message("\(response.result.error)")
                callback(success: false)
        }
    }

    static func postDeckVersion(deck: Deck, callback: (success: Bool) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.NotLogged }

        Alamofire.request(.POST,
            "\(baseUrl)/decks/create_version?auth_token=\(settings.hearthstatsToken!)",
            parameters: [
                "deck_id": deck.hearthstatsId!,
                "cards": deck.sortedCards.map {["id": $0.id, "count": $0.count]},
                "version": deck.version
            ], encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value,
                        data = json["data"] as? [String:AnyObject],
                        hearthstatsVersionId = data["id"] as? Int {
                        Log.debug?.message("post deck version : \(json)")
                        deck.hearthstatsVersionId = hearthstatsVersionId
                        callback(success: true)
                        return
                    }
                }
                Log.error?.message("\(response.result.error)")
                callback(success: false)
        }
    }

    static func deleteDeck(deck: Deck) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.NotLogged }

        Alamofire.request(.POST, "\(baseUrl)/decks/delete?auth_token=\(settings.hearthstatsToken!)",
            parameters: ["deck_id": "[\(deck.hearthstatsId)]"], encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value {
                        Log.debug?.message("delete deck : \(json)")
                        return
                    }
                }
        }
    }

    // MARK: - matches
    static func getGames(unixTime: Double, callback: (success: Bool) -> ()) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.NotLogged }

        Alamofire.request(.POST,
            "\(baseUrl)/matches/after_date?auth_token=\(settings.hearthstatsToken!)",
            parameters: ["date": "\(unixTime)"], encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value {
                        Log.debug?.message("get games : \(json)")
                        (json["data"] as? [[String: AnyObject]])?.forEach({
                            Decks.instance.addOrUpdateMatches($0)
                        })

                        // swiftlint:disable line_length
                        Settings.instance.hearthstatsLastMatchesSync = NSDate().timeIntervalSince1970
                        // swiftlint:enable line_length
                        callback(success: true)
                        return
                    }
                }
                Log.error?.message("\(response.result.error)")
                callback(success: false)
        }
    }
 
    static func postMatch(game: Game, deck: Deck, stat: Statistic) throws {
        let settings = Settings.instance
        guard let _ = settings.hearthstatsToken else { throw HearthstatsError.NotLogged }
        guard let _ = deck.hearthstatsId else { throw HearthstatsError.DeckNotSaved }
        guard let _ = deck.hearthstatsVersionId else { throw HearthstatsError.DeckNotSaved }

        let startTime: NSDate
        if let gameStartDate = game.gameStartDate {
            startTime = gameStartDate
        } else {
            startTime = NSDate()
        }
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(name: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let startAt = formatter.stringFromDate(startTime)

        let parameters: [String: AnyObject] = [
            "class": deck.playerClass.capitalizedString,
            "mode": "\(game.currentGameMode)",
            "result": "\(game.gameResult)",
            "coin": "\(stat.hasCoin)",
            "numturns": stat.numTurns,
            "duration": stat.duration,
            "deck_id": deck.hearthstatsId!,
            "deck_version_id": deck.hearthstatsVersionId!,
            "oppclass": stat.opponentClass.capitalizedString,
            "oppname": stat.opponentName,
            "notes": "",
            "ranklvl": stat.playerRank,
            "oppcards": stat.cards,
            "created_at": startAt
        ]
        Log.info?.message("Posting match to Hearthstats \(parameters)")
        Alamofire.request(.POST, "\(baseUrl)/matches?auth_token=\(settings.hearthstatsToken!)",
            parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value {
                        Log.debug?.message("post match : \(json)")
                        return
                    }
                }
        }
    }
    
    // MARK: - Arena
    
    static func postArenaMatch(game: Game, deck: Deck, stat: Statistic) throws {
        guard let _ = Settings.instance.hearthstatsToken else { throw HearthstatsError.NotLogged }
        
        guard let _ = deck.hearthStatsArenaId else {
            createArenaRun(game, deck: deck, stat: stat)
            return
        }
        
        _postArenaMatch(game, deck: deck, stat: stat)
    }
    
    private static func _postArenaMatch(game: Game, deck: Deck, stat: Statistic) {
        let parameters: [String: AnyObject] = [
            "class": deck.playerClass.capitalizedString,
            "mode": "\(game.currentGameMode)",
            "result": "\(game.gameResult)",
            "coin": "\(stat.hasCoin)",
            "numturns": stat.numTurns,
            "duration": stat.duration,
            "arena_run_id": deck.hearthStatsArenaId!,
            "oppclass": stat.opponentClass.capitalizedString,
            "oppname": stat.opponentName,
        ]
        Log.info?.message("Posting arena match to Hearthstats \(parameters)")
        let url = "\(baseUrl)/matches?auth_token=\(Settings.instance.hearthstatsToken!)"
        Alamofire.request(.POST, url,
            parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value {
                        Log.debug?.message("post arena match : \(json)")
                        return
                    }
                }
        }
    }
    
    static func createArenaRun(game: Game, deck: Deck, stat: Statistic) {
        Log.info?.message("Creating new arena deck")
        let parameters: [String: AnyObject] = [
            "class": deck.playerClass.capitalizedString,
            "cards": deck.sortedCards.map {["id": $0.id, "count": $0.count]}
        ]
        let url = "\(baseUrl)/arena_runs/new?auth_token=\(Settings.instance.hearthstatsToken!)"
        Alamofire.request(.POST, url,
            parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                if response.result.isSuccess {
                    if let json = response.result.value,
                        data = json["data"] as? [String:AnyObject],
                        hearthStatsArenaId = data["id"] as? Int {
                        deck.hearthStatsArenaId = hearthStatsArenaId
                        Log.debug?.message("Arena run : \(hearthStatsArenaId)")
                        
                        _postArenaMatch(game, deck: deck, stat: stat)
                        return
                    }
                }
        }
    }
}

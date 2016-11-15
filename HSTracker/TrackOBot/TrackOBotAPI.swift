//
//  TrackOBotAPI.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

enum TrackOBotError: Error {
    case notLogged
}

struct TrackOBotAPI {
    static let baseUrl = "https://trackobot.com"
    
    // MARK: - Authentication
    static func login(username: String, token: String,
                      callback: @escaping (_ success: Bool, _ message: String) -> ()) {
        let http = Http(url: "\(baseUrl)/profile/history.json")
        http.json(method: .get,
                  parameters: ["username": username, "token": token]) { json in
                    if let json = json as? [String: Any] {
                        if let error = json["error"] as? String {
                            callback(false, error)
                        } else {
                            let settings = Settings.instance
                            settings.trackobotUsername = username
                            settings.trackobotToken = token
                            callback(true, "")
                        }
                    } else {
                        callback(false,
                                 NSLocalizedString("server error", comment: ""))
                    }
        }
    }

    static func logout() {
        let settings = Settings.instance
        settings.trackobotUsername = nil
        settings.trackobotToken = nil
    }

    static func isLogged() -> Bool {
        let settings = Settings.instance
        return settings.trackobotUsername != nil && settings.trackobotToken != nil
    }


    /**
     TODO: try to check the archetype of the deck using
     https://trackobot.com/profile/settings/decks.json
     and send it with deck_id and opponent_
     */

    // MARK: - matches
    static func postMatch(game: Game, playerClass: CardClass, stat: Statistic) throws {
        let settings = Settings.instance
        guard let username = settings.trackobotUsername else {
            throw TrackOBotError.notLogged
        }
        guard let token = settings.trackobotToken else {
            throw TrackOBotError.notLogged
        }

        let mode: String
        switch game.currentGameMode {
        case .ranked: mode = "ranked"
        case .casual: mode = "casual"
        case .arena: mode = "arena"
        case .friendly: mode = "friendly"
        case .practice: mode = "solo"
        default: mode = "unknown"
        }

        let startTime: Date
        if let gameStartDate = game.gameStartDate {
            startTime = gameStartDate as Date
        } else {
            startTime = Date()
        }

        let parameters: [String: [String: Any]] = [
            "result": [
                "hero": playerClass.rawValue.capitalized,
                "opponent": stat.opponentClass.rawValue.capitalized,
                "mode": mode,
                "coin": stat.hasCoin,
                "rank": stat.playerRank,
                "win": game.gameResult == .win,
                "duration": stat.duration,
                "added": startTime.timeIntervalSince1970,
                "note": stat.note,
                "card_history": game.playedCards.map {
                    [
                        "card_id": $0.cardId,
                        "player": $0.player == .player ? "me" : "opponent",
                        "turn": $0.turn
                    ]
                }
            ]
        ]

        let url = "\(baseUrl)/profile/results.json?username=\(username)&token=\(token)"
        Log.info?.message("Posting match to Track-o-Bot \(parameters)")
        let http = Http(url: url)
        http.json(method: .post,
                  parameters: parameters) { json in
                    if let json = json {
                        Log.debug?.message("post match : \(json)")
                    }
        }
    }
}

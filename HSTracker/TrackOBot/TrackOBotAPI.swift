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
                      callback: @escaping (_ success: Bool, _ message: String) -> Void) {
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
    static func postMatch(stat: InternalGameStats, cards: [PlayedCard]) throws {
        let settings = Settings.instance
        guard let username = settings.trackobotUsername else {
            throw TrackOBotError.notLogged
        }
        guard let token = settings.trackobotToken else {
            throw TrackOBotError.notLogged
        }

        let mode: String
        switch stat.gameMode {
        case .ranked: mode = "ranked"
        case .casual: mode = "casual"
        case .arena: mode = "arena"
        case .friendly: mode = "friendly"
        case .practice: mode = "solo"
        default: mode = "unknown"
        }

        let duration = stat.endTime.timeIntervalSince1970 - stat.startTime.timeIntervalSince1970

        let parameters: [String: [String: Any]] = [
            "result": [
                "hero": stat.playerHero.rawValue.capitalized,
                "opponent": stat.opponentHero.rawValue.capitalized,
                "mode": mode,
                "coin": stat.coin,
                "rank": stat.rank,
                "win": stat.result == .win,
                "duration": duration,
                "added": stat.startTime.timeIntervalSince1970,
                "note": stat.note,
                "card_history": cards.map {
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

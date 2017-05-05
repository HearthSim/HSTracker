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
                            Settings.trackobotUsername = username
                            Settings.trackobotToken = token
                            callback(true, "")
                        }
                    } else {
                        callback(false,
                                 NSLocalizedString("server error", comment: ""))
                    }
        }
    }

    static func logout() {
        Settings.trackobotUsername = nil
        Settings.trackobotToken = nil
    }

    static func isLogged() -> Bool {
        return Settings.trackobotUsername != nil && Settings.trackobotToken != nil
    }

    /**
     TODO: try to check the archetype of the deck using
     https://trackobot.com/profile/settings/decks.json
     and send it with deck_id and opponent_
     */

    // MARK: - matches
    static func postMatch(stat: InternalGameStats, cards: [PlayedCard]) throws {
        guard let username = Settings.trackobotUsername else {
            throw TrackOBotError.notLogged
        }
        guard let token = Settings.trackobotToken else {
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
                        Log.debug?.message("Track-o-Bot post match : \(json)")
                    }
        }
    }

    static func openProfile() throws {
        guard let username = Settings.trackobotUsername else {
            throw TrackOBotError.notLogged
        }
        guard let token = Settings.trackobotToken else {
            throw TrackOBotError.notLogged
        }

        let url = "\(baseUrl)/one_time_auth.json?username=\(username)&token=\(token)"
        Log.info?.message("Getting Track-o-Bot auth")
        let http = Http(url: url)
        http.json(method: .post) { json in
            if let json = json as? [String: String] {
                Log.debug?.message("Track-o-Bot auth : \(json)")
                if let url = json["url"],
                    let nsurl = URL(string: url) {
                    NSWorkspace.shared().open(nsurl)
                }
            }
        }
    }
}

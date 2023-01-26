//
//  UploadMetaData.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

class UploadMetaData {
    private var statistic: InternalGameStats?
    private var game: Game?
    private var log: [String] = []
    var dateStart: Date?
    
    var gameHandle: String?
    var clientHandle: String?
    var reconnected: String?
    var resumable: Bool?
    var serverVersion: String?
    var matchStart: String?
    var hearthstoneBuild: Int?
    var gameType: Int?
    var spectatorMode: Bool?
    var friendlyPlayerId: Int?
    var ladderSeason: Int?
    var brawlSeason: Int?
    var scenarioId: Int?
    var format: Int?
    var players: [Player] = []
    var league_id: Int?
    var battlegrounds_races: [Int]?
    var mercenaries_bounty_run_id: String?
    var mercenaries_bounty_run_turns_taken: Int?
    var mercenaries_bounty_run_completed_nodes: Int?
    var mercenaries_rewards: [MercenaryReward]?
    
    public static let iso8601StringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    static func generate(stats: InternalGameStats, buildNumber: Int, deck: PlayingDeck?) -> (UploadMetaData, String) {
        let metaData = UploadMetaData()

        metaData.league_id = stats.playerMedalInfo?.leagueId
        
        metaData.players.append(getFriendlyPlayer(stats: stats, deck: deck))
        metaData.players.append(getOpposingPlayer(stats: stats))
        metaData.friendlyPlayerId = stats.friendlyPlayerId

        if let serverInfo = stats.serverInfo {
            if serverInfo.gameHandle > 0 {
				metaData.gameHandle = "\(serverInfo.gameHandle)"
            }
            if serverInfo.clientHandle > 0 {
				metaData.clientHandle = "\(serverInfo.clientHandle)"
            }

            if !serverInfo.version.isBlank {
				metaData.serverVersion = serverInfo.version
            }
        }
        
        if stats.startTime > Date.distantPast {
            metaData.matchStart = UploadMetaData.iso8601StringFormatter.string(from: stats.startTime)
        }
        
        metaData.gameType = stats.gameType != .gt_unknown
            ? BnetGameType.getBnetGameType(gameType: stats.gameType,
                                           format: stats.format).rawValue
            : BnetGameType.getGameType(mode: stats.gameMode,
                                       format: stats.format).rawValue
        
        if let format = stats.format {
            metaData.format = format.toFormatType().rawValue
        }
        
        if stats.brawlSeasonId > 0 {
            metaData.brawlSeason = stats.brawlSeasonId
        }
        if stats.rankedSeasonId > 0 {
            metaData.ladderSeason = stats.rankedSeasonId
        }

        metaData.spectatorMode = stats.gameMode == .spectator
        //metaData.reconnected = gameMetaData?.reconnected ?? false
        metaData.resumable = stats.serverInfo?.resumable ?? false

        let scenarioId = stats.serverInfo?.mission ?? 0
        if scenarioId > 0 {
            metaData.scenarioId = scenarioId
        }

        metaData.hearthstoneBuild = buildNumber
        
        if stats.gameMode == .battlegrounds {
            metaData.battlegrounds_races = stats.battlegroundsRaces
        }
        
        if stats.mercenariesBountyRunId.count > 0 {
            metaData.mercenaries_bounty_run_id = stats.mercenariesBountyRunId
            if stats.mercenariesBountyRunTurnsTaken > 0 {
                metaData.mercenaries_bounty_run_turns_taken = stats.mercenariesBountyRunTurnsTaken
            }
            if stats.mercenariesBountyRunCompletedNodes > 0 {
                metaData.mercenaries_bounty_run_completed_nodes = stats.mercenariesBountyRunCompletedNodes
            }
        }
        
        if let mercenariesRewards = stats.mercenariesBountyRunRewards {
            metaData.mercenaries_rewards = mercenariesRewards.compactMap { x in MercenaryReward(mercenary_id: x.id, coins: x.coins) }
        }

        return (metaData, stats.statId)
    }
    
    static func retryWhileNull<T>(f: @escaping (() -> T?), tries: Int = 5, delay: Int = 150) -> T? {
        for _ in 0 ..< tries {
            let value = f()
            if value != nil {
                return value
            }
            usleep(useconds_t(1000 * delay))
        }
        return nil
    }

    static func getFriendlyPlayer(stats: InternalGameStats, deck: PlayingDeck?) -> Player {

        let friendly = Player()
		
        friendly.player_id = stats.friendlyPlayerId
        if let deck = deck {
			friendly.add(deck: deck)
		}

        if stats.playerCardbackId > 0 {
            friendly.cardBack = stats.playerCardbackId
        }
        if let hsDeckId = stats.hsDeckId, hsDeckId > 0 {
            friendly.deckId = hsDeckId
        }

        if stats.gameMode == .arena {
            if stats.arenaWins > 0 {
                friendly.wins = stats.arenaWins
            }
            if stats.arenaLosses > 0 {
                friendly.losses = stats.arenaLosses
            }
        } else if stats.gameMode == .brawl {
            if stats.brawlWins > 0 {
                friendly.wins = stats.brawlWins
            }
            if stats.brawlLosses > 0 {
                friendly.losses = stats.brawlLosses
            }
        } else if stats.gameMode == .battlegrounds {
            friendly.battlegrounds_rating = stats.battlegroundsRating

            if let ratingsChange = retryWhileNull(f: MirrorHelper.getBattlegroundsRatingChange) {
                friendly.battlegrounds_rating_after = ratingsChange.ratingNew as? Int
            }
            friendly.deckId = nil
            friendly.deck = nil
        } else if stats.gameMode == .mercenaries {
            if stats.mercenariesRating > 0 {
                friendly.mercenaries_rating = stats.mercenariesRating
            }
            if let ratingsChange = retryWhileNull(f: MirrorHelper.getMercenariesRatingChange) {
                friendly.mercenaries_rating_after = ratingsChange.ratingNew as? Int
            }
        } else {
            friendly.star_level = stats.playerMedalInfo?.starLevel
            friendly.stars = stats.playerMedalInfo?.stars
            friendly.star_multiplier = nil //stats.playerMedalInfo?.starMultiplier

            if let medalData = retryWhileNull(f: MirrorHelper.getMedalData) {
                let medalInfo: MirrorMedalInfo
                if stats.format == .wild {
                    medalInfo = medalData.wild
                } else {
                    medalInfo = medalData.standard
                }
                
                friendly.star_level_after = medalInfo.starLevel as? Int ?? 0
                friendly.stars_after = medalInfo.stars as? Int ?? 0
                friendly.star_multiplier_after = nil //stats.playerMedalInfo?.starMultiplier
            }
        }

        return friendly
    }

    static func getOpposingPlayer(stats: InternalGameStats) -> Player {
        let opposing = Player()
        
        opposing.player_id = stats.opposingPlayerId
        opposing.star_level = stats.opponentMedalInfo?.starLevel
        opposing.stars = nil //stats.opponentMedalInfo?.stars
        opposing.star_multiplier = nil //stats.opponentMedalInfo?.starMultiplier

        logger.info("LADDER opponentStarLevel=\(opposing.star_level ?? -1)")
        
        if stats.opponentCardbackId > 0 {
            opposing.cardBack = stats.opponentCardbackId
        }

        return opposing
    }

    class Player {
        var player_id: Int?
        
        var star_level: Int?
        var star_level_after: Int?

        var stars: Int?
        var stars_after: Int?

        var star_multiplier: Int?
        var star_multiplier_after: Int?
        
        var legend_rank: Int?
        var legend_rank_after: Int?
        
        var battlegrounds_rating: Int?
        var battlegrounds_rating_after: Int?
        
        var mercenaries_rating: Int?
        var mercenaries_rating_after: Int?

        var wins: Int?
        var losses: Int?
        var deck: [String]?
        var deckId: Int64?
        var cardBack: Int?
		
		func add(deck: PlayingDeck) {
			var cards = [String]()
			for card in deck.cards {
				for _ in 0 ..< card.count {
					cards.append(card.id)
				}
			}
			self.deck = cards
		}
    }

    struct PlayerInfo {
        let player1: Player
        let player2: Player
        let friendlyPlayerId: Int

        init(player1: Player, player2: Player, friendlyPlayerId: Int = -1) {
            self.player1 = player1
            self.player2 = player2
            self.friendlyPlayerId = friendlyPlayerId
        }
    }
    
    struct MercenaryReward {
        let mercenary_id: Int
        let coins: Int
        
        init(mercenary_id: Int, coins: Int) {
            self.mercenary_id = mercenary_id
            self.coins = coins
        }
    }
}
extension UploadMetaData.Player: WrapCustomizable {
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        switch propertyName {
        case "legendRank": return "legend_rank"
        case "deckId": return "deck_id"
        case "cardBack": return "cardback"
        default: break
        }
        
        return propertyName
    }
}
extension UploadMetaData: WrapCustomizable {
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        switch propertyName {
        case "gameHandle": return "game_handle"
        case "clientHandle": return "client_handle"
        case "reconnected": return "reconnecting"
        case "serverVersion": return "server_version"
        case "matchStart": return "match_start"
        case "hearthstoneBuild": return "build"
        case "gameType": return "game_type"
        case "spectatorMode": return "spectator_mode"
        case "friendlyPlayerId": return "friendly_player"
        case "scenarioId": return "scenario_id"
        case "ladderSeason": return "ladder_season"
        case "brawlSeason": return "brawl_season"
        case "statistic", "game",
             "log", "gameStart":
            return nil
        default: break
        }
        
        return propertyName
    }
}


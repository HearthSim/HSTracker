//
//  UploadMetaData.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class UploadMetaData: Encodable {
    private enum CodingKeys: String, CodingKey {
        case game_handle,
             client_handle,
             reconnecting,
             resumable,
             server_version,
             match_start,
             build,
             game_type,
             spectator_mode,
             friendly_player,
             scenario_id,
             brawl_season,
             ladder_season,
             league_id,
             format,
             player1,
             player2,
             players,
             battlegrounds_races,
             mercenaries_bounty_run_id,
             mercenaries_bounty_run_turns_taken,
             mercenaries_bounty_run_completed_nodes,
             mercenaries_rewards
    }
    
    private var statistic: InternalGameStats?
    private var game: Game?
    private var log: [String] = []
    var dateStart: Date?
    
    var game_handle: String?
    var client_handle: String?
    var reconnecting: Bool?
    var resumable: Bool?
    var server_version: String?
    var match_start: String?
    var build: Int?
    var game_type: Int?
    var spectator_mode: Bool?
    var friendly_player: Int?
    var scenario_id: Int?
    var brawl_season: Int?
    var ladder_season: Int?
    var league_id: Int?
    var format: Int?
    var player1: Player?
    var player2: Player?
    var players: [Player]?
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

    static func generate(stats: InternalGameStats, buildNumber: Int, game: Game) -> (UploadMetaData, String) {
        let metaData = UploadMetaData()
        
        let players = getPlayerInfo(stats: stats)

        if players.count > 0 {
            if stats.gameMode == .battlegrounds || stats.gameMode == .mercenaries {
                metaData.players = players
            } else {
                metaData.player1 = players.first { x in x.player_id == 1 }
                metaData.player2 = players.first { x in x.player_id == 2 }
            }
        }
        if let serverInfo = stats.serverInfo {
            if serverInfo.gameHandle > 0 {
                metaData.game_handle = "\(serverInfo.gameHandle)"
            }
            if serverInfo.clientHandle > 0 {
                metaData.client_handle = "\(serverInfo.clientHandle)"
            }

            if !serverInfo.version.isBlank {
                metaData.server_version = serverInfo.version
            }
        }
        if stats.startTime > Date.distantPast {
            metaData.match_start = UploadMetaData.iso8601StringFormatter.string(from: stats.startTime)
        }
        metaData.game_type = stats.gameType != .gt_unknown
            ? BnetGameType.getBnetGameType(gameType: stats.gameType,
                                           format: stats.format).rawValue
            : BnetGameType.getGameType(mode: stats.gameMode,
                                       format: stats.format).rawValue
        if let format = stats.format {
            metaData.format = format.toFormatType().rawValue
        }
        metaData.spectator_mode = stats.gameMode == .spectator
        metaData.reconnecting = false //gameMetaData?.reconnected ?? false
        metaData.resumable = stats.serverInfo?.resumable ?? false
        metaData.friendly_player = stats.friendlyPlayerId
        let scenarioId = stats.serverInfo?.mission ?? 0
        if scenarioId > 0 {
            metaData.scenario_id = scenarioId
        }
        metaData.build = buildNumber
        if stats.brawlSeasonId > 0 {
            metaData.brawl_season = stats.brawlSeasonId
        }
        if stats.rankedSeasonId > 0 {
            metaData.ladder_season = stats.rankedSeasonId
        }
        if stats.leagueId > 0 {
            metaData.league_id = stats.leagueId
        }
        if stats.gameMode == .battlegrounds {
            metaData.battlegrounds_races = stats.battlegroundsRaces
        }
        if stats.gameMode == .mercenaries {
            if let mercenariesRewards = stats.mercenariesBountyRunRewards {
                metaData.mercenaries_rewards = mercenariesRewards.compactMap { x in MercenaryReward(mercenary_id: x.id, coins: x.coins) }
            }
            if stats.mercenariesBountyRunId.count > 0 {
                metaData.mercenaries_bounty_run_id = stats.mercenariesBountyRunId
                metaData.mercenaries_bounty_run_turns_taken = stats.mercenariesBountyRunTurnsTaken
                metaData.mercenaries_bounty_run_completed_nodes = stats.mercenariesBountyRunCompletedNodes
            }
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

    private static func getPlayerInfo(stats: InternalGameStats) -> [Player] {
        if stats.friendlyPlayerId == 0 {
            return [Player]()
        }
        
        let friendly = Player()
        let opposing = Player()
        
        friendly.player_id = stats.friendlyPlayerId
        opposing.player_id = stats.opposingPlayerId
        
        if stats.playerCardbackId > 0 {
            friendly.cardback = stats.playerCardbackId
        }
        
        if stats.gameMode == .ranked {
            if stats.rank > 0 {
                friendly.rank = stats.rank
            }
            if stats.legendRank > 0 {
                friendly.legend_rank = stats.legendRank
            }
            if stats.stars > 0 {
                friendly.stars = stats.stars
            }
            if stats.starLevel > 0 {
                friendly.star_level = stats.starLevel
            }
            if stats.starMultiplier > 0 {
                friendly.star_multiplier = stats.starMultiplier
            }
            
            if stats.starsAfter > 0 {
                friendly.stars_after = stats.starsAfter
            }
            if stats.starLevelAfter > 0 {
                friendly.star_level_after = stats.starLevelAfter
            }
            if stats.legendRankAfter > 0 {
                friendly.legend_rank_after = stats.legendRankAfter
            }
            
            if stats.opponentRank > 0 {
                opposing.rank = stats.opponentRank
            }
            if stats.opponentLegendRank > 0 {
                opposing.legend_rank = stats.opponentLegendRank
            }
            if stats.opponentStarLevel > 0 {
                opposing.star_level = stats.opponentStarLevel
            }
        }
        let playerDeckSize = stats.playerCards.reduce(0, { $0 + $1.count })
        if stats.gameMode == .battlegrounds {
            if stats.battlegroundsRating > 0 {
                friendly.battlegrounds_rating = stats.battlegroundsRating
            }
            if stats.battlegroundsRatingAfter > 0 {
                friendly.battlegrounds_rating_after = stats.battlegroundsRatingAfter
            }
        } else if stats.gameMode == .mercenaries {
            if stats.mercenariesRating > 0 {
                friendly.mercenaries_rating = stats.mercenariesRating
            }
            if stats.mercenariesRatingAfter > 0 {
                friendly.mercenaries_rating_after = stats.mercenariesRatingAfter
            }
        } else if playerDeckSize == 30 || playerDeckSize == 40 || stats.isPVPDungeonMatch || stats.isDungeonMatch && stats.deckId.count > 0 {
            friendly.deck = stats.playerCards.filter { x in x.id?.count ?? 0 > 0 }.flatMap { x in repeatElement(x.id ?? "", count: x.count) }
            // TODO: sideboard
            if stats.hsDeckId ?? 0 > 0 {
                friendly.deck_id = stats.hsDeckId
            }
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
        }
        if stats.opponentCardbackId > 0 {
            opposing.cardback = stats.opponentCardbackId
        }
        return [ friendly, opposing ]
    }

    class Player: Encodable {
        var player_id: Int?
        var rank: Int?
        
        var star_level: Int?
        var star_level_after: Int?

        var legend_rank: Int?
        var legend_rank_after: Int?
        
        var stars: Int?
        var stars_after: Int?

        var star_multiplier: Int?
        
        var rating: Int?
        var rating_after: Int?
        
        var wins: Int?
        var losses: Int?
        var deck: [String]?
        //var sideboards: [Sideboard]?
        var deck_id: Int64?
        var cardback: Int?

        var battlegrounds_rating: Int?
        var battlegrounds_rating_after: Int?
        
        var mercenaries_rating: Int?
        var mercenaries_rating_after: Int?
    }

    struct MercenaryReward: Encodable {
        let mercenary_id: Int
        let coins: Int
    }
}

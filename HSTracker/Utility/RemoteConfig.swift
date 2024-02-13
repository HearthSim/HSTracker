//
//  RemoteConfig.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/14/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct NewsData: Codable {
    var id: Int?
    var items: [String]?
}

struct CollectionBannerData: Codable {
    var visible: Bool?
    var removable_pre_sync: Bool?
    var removable_post_sync: Bool?
    var removal_id: Int?
}

struct ArenaData: Codable {
    var current_sets: [String]?
    var exclusive_secrets: [String]?
    var banned_secrets: [String]?
}

struct RemoteConfigCard: Codable {
    var dbf_id: Int?
    var count: Int?
}

struct TagOverride: Codable {
    var dbf_id: Int
    var tag: Int // not using GameTag as it is not 100% up to date
    var value: Int
}

struct BobsBuddyData: Codable {
    var disabled: Bool?
    var min_required_version: String?
    var sentry_reporting: Bool?
    var metric_sampling: Double?
    var can_remove_lich_king: Bool?
    var log_lines_kept: Int?
}

struct MercenaryAbilityTier: Codable {
    let tier: Int
    let dbf_id: Int
}

struct MercenaryAbility: Codable {
    var id: Int
    var tiers: [MercenaryAbilityTier]
}

struct MercenarySpecialization: Codable {
    var id: Int
    var abilities: [MercenaryAbility]
}

struct Mercenary: Codable {
    var id: Int
    var name: String
    var collectible: Bool
    var skinDbfIds: [Int]
    var specializations: [MercenarySpecialization]
}

struct CardShortName: Codable {
    var dbf_id: Int
    var short_name: String
}

struct Tier7Data: Codable {
    var disabled: Bool
}

struct ConfigData: Codable {
    var news: NewsData?
    var collection_banner: CollectionBannerData?
    var arena: ArenaData?
    var battlegrounds_short_names: [CardShortName]?
    var battlegrounds_tag_overrides: [TagOverride]?
    var bobs_buddy: BobsBuddyData?
    var tier7: Tier7Data?
}

struct BattlegroundsAnomalyBans: Codable {
    var anomaly_dbf_id: Int
    var banned_minion_ids: [String]
}

struct BattlegroundsBans: Codable {
    var by_anomaly: [BattlegroundsAnomalyBans]
}

struct LiveSecrets: Codable {
    var by_game_type_and_format_type: [String: Set<String>]
}

class RemoteConfig {
    static var data: ConfigData?
    static var mercenaries: [Mercenary]?
    static var battlegroundsBans: BattlegroundsBans?
    static var liveSecrets: LiveSecrets?
    
    private static var url = "https://hsdecktracker.net/config.json"
    private static var mercsUrl = "https://api.hearthstonejson.com/v1/latest/enUS/mercenaries.json"
    private static var bgBansUrl = "https://hsreplay.net/api/v1/battlegrounds/banned_minions/"
    private static var secretsUrl = "https://hsreplay.net/api/v1/live/secrets/"

    static func checkRemoteConfig(splashscreen: Splashscreen) {
        DispatchQueue.main.async {
            splashscreen.display(String.localizedString("Loading remote configuration", comment: ""),
                                 indeterminate: true)
        }

        let http = Http(url: RemoteConfig.url)
        let semaphore = DispatchSemaphore(value: 0)
        _ = http.getPromise(method: .get).map { data in
            try JSONDecoder().decode(ConfigData.self, from: data!)
        }.done { data in
            self.data = data
            logger.info("Retrieved remote configuration")
            let http2 = Http(url: RemoteConfig.mercsUrl)
            _ = http2.getPromise(method: .get).map { data in
                try JSONDecoder().decode([Mercenary].self, from: data!)
            }.done { mercs in
                self.mercenaries = mercs
                logger.info("Retrieved remote mercenaries configuration")
                let http3 = Http(url: RemoteConfig.bgBansUrl)
                _ = http3.getPromise(method: .get).map { data in
                    try JSONDecoder().decode(BattlegroundsBans.self, from: data!)
                }.done { bans in
                    self.battlegroundsBans = bans
                    logger.info("Retrieved battlegrounds bans configuration")
                    let http4 = Http(url: RemoteConfig.secretsUrl)
                    _ = http4.getPromise(method: .get).map { data in
                        try JSONDecoder().decode(LiveSecrets.self, from: data!)
                    }.done { secrets in
                        self.liveSecrets = secrets
                        logger.info("Retrieved live secrets configuration")
                        semaphore.signal()
                    }.catch { error in
                        logger.error("Error parsing live secrets configuration: \(error)")
                        semaphore.signal()
                    }
                }.catch { error in
                    logger.error("Error parsing battlegrounds bans configuration: \(error)")
                    semaphore.signal()
                }
            }.catch { error in
                logger.error("Error parsing remote mercenaries config: \(error)")
                semaphore.signal()
            }
        }.catch { error in
            logger.error("Error parsing remote config: \(error)")
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
}


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

struct ArenasmithData: Codable {
    var disabled: Bool?
}

struct CardInfo: Codable {
    var dbf_id: Int
}

struct SaleData: Codable {
    var enabled: Bool
    var id: Int
    var discount: Int
}

struct SalesData: Codable {
    var battlegrounds: SaleData?
    var traditional: SaleData?
}

struct ConfigData: Codable {
    struct MulliganGuideData: Codable {
        var disabled: Bool
    }
    var news: NewsData?
    var collection_banner: CollectionBannerData?
    var battlegrounds_short_names: [CardShortName]?
    var bobs_buddy: BobsBuddyData?
    var tier7: Tier7Data?
    var arenasmith: ArenasmithData?
    var mulligan_guide: MulliganGuideData?
    var sales: SalesData?
    //swiftlint:disable inclusive_language
    var draw_card_blacklist: [CardInfo]?
    //swiftlint:enable inclusive_language
}

struct LiveSecrets: Codable {
    var by_game_type_and_format_type: [String: Set<String>]
    var created_by_game_type_and_format_type: [String: [String: Set<String>]]?
}

struct MetaPeriod: Codable {
    var period_start: Int64
    var mechanics: [String]
    var tag_overrides: [TagOverride]?
    var minion_types: [Int]?

    // The API sends the tribes as HearthDb's numeric Race values. HSTracker's
    // Race is a String enum whose numeric lookup is built at startup, so the
    // mapping happens here rather than in the decoder.
    var minionTypes: [Race]? {
        minion_types?.compactMap { Race(rawValue: $0) }
    }
}

class RemoteConfig {
    static var data: ConfigData?
    static var mercenaries: [Mercenary]?
    static var liveSecrets: LiveSecrets?
    // The season currently being played. Replaces both the tag overrides, which
    // had a feed of their own, and the full list of meta periods that had to be
    // sorted by start date to find this one.
    static var battlegroundsLiveMetaPeriod: MetaPeriod?
    // Mirrors HDT's DataLoader.Loaded event for that one loader: the only
    // subscriber is BattlegroundsDb, which has to rebuild itself whenever the
    // overrides change under it.
    static var battlegroundsLiveMetaPeriodLoaded: ((MetaPeriod?) -> Void)?

    private static var url = "https://hsdecktracker.net/config.json"
    private static var mercsUrl = "https://api.hearthstonejson.com/v1/latest/enUS/mercenaries.json"
    private static var secretsUrl = "https://hsreplay.net/api/v1/live/secrets/"
    // The live meta period is region specific, so the region the player is on is
    // attached whenever it is known - HDT builds the same query string lazily, since the
    // region is not settled yet when the loader is created.
    private static var battlegroundsLiveMetaPeriodUrl: String {
        let url = "https://hsreplay.net/api/v1/battlegrounds/meta_periods/live/"
        let region = AppDelegate.instance().coreManager?.game.currentRegion ?? .unknown
        guard region != .unknown else {
            return url
        }
        return "\(url)?region=\(Region.toBnetRegion(region: region))"
    }

    static func checkRemoteConfig(splashscreen: Splashscreen) {
        DispatchQueue.main.async {
            splashscreen.display(String.localizedString("Loading remote configuration", comment: ""),
                                 indeterminate: true)
        }

        let dispatchGroup = DispatchGroup()

        func fetchData<T: Decodable>(
            url: String,
            decodeType: T.Type,
            assignment: @escaping (T) -> Void,
            errorMessage: String
        ) {
            dispatchGroup.enter()
            RemoteConfig.fetchData(url: url, decodeType: decodeType, assignment: assignment,
                                   errorMessage: errorMessage) {
                dispatchGroup.leave()
            }
        }

        // 1. Fetch main config
        fetchData(url: RemoteConfig.url,
                  decodeType: ConfigData.self,
                  assignment: { self.data = $0 },
                  errorMessage: "main configuration")

        // 2. Fetch mercenaries
        fetchData(url: RemoteConfig.mercsUrl,
                  decodeType: [Mercenary].self,
                  assignment: { self.mercenaries = $0 },
                  errorMessage: "mercenaries configuration")

        // 3. Fetch live secrets
        fetchData(url: RemoteConfig.secretsUrl,
                  decodeType: LiveSecrets.self,
                  assignment: { self.liveSecrets = $0 },
                  errorMessage: "live secrets configuration")

        // 4. Fetch the live meta period
        fetchData(url: RemoteConfig.battlegroundsLiveMetaPeriodUrl,
                  decodeType: MetaPeriod.self,
                  assignment: { self.setBattlegroundsLiveMetaPeriod($0) },
                  errorMessage: "battlegrounds live meta period")

        dispatchGroup.notify(queue: .main) {
            logger.info("All remote configurations loaded.")
            splashscreen.progressBar.stopAnimation(nil)
            // Optionally, you can close the splash screen here or transition to the main app view
        }
    }

    // HDT's Remote.BattlegroundsLiveMetaPeriod.Load(), called again whenever the
    // Battlegrounds lobby is entered: a season can roll over while the app is
    // running, and with it the tag overrides everything below reads.
    static func loadBattlegroundsLiveMetaPeriod() {
        fetchData(url: RemoteConfig.battlegroundsLiveMetaPeriodUrl,
                  decodeType: MetaPeriod.self,
                  assignment: { self.setBattlegroundsLiveMetaPeriod($0) },
                  errorMessage: "battlegrounds live meta period")
    }

    private static func setBattlegroundsLiveMetaPeriod(_ metaPeriod: MetaPeriod?) {
        battlegroundsLiveMetaPeriod = metaPeriod
        battlegroundsLiveMetaPeriodLoaded?(metaPeriod)
    }

    // Safely decode and assign data. `completion` runs whether the fetch
    // succeeded or not, so a caller waiting on a group can leave it.
    private static func fetchData<T: Decodable>(
        url: String,
        decodeType: T.Type,
        assignment: @escaping (T) -> Void,
        errorMessage: String,
        completion: (() -> Void)? = nil
    ) {
        let http = Http(url: url)
        http.getPromise(method: .get)
            .map { data in
                guard let validData = data else {
                    throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
                return try JSONDecoder().decode(decodeType, from: validData)
            }
            .done { decodedData in
                assignment(decodedData)
                logger.info("Successfully retrieved: \(errorMessage)")
            }
            .catch { error in
                logger.error("Error retrieving \(errorMessage): \(error)")
            }
            .finally {
                completion?()
            }
    }
}


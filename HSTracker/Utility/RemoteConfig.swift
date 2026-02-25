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

struct CardInfo: Codable {
    var dbf_id: Int
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
    var mulligan_guide: MulliganGuideData?
    //swiftlint:disable inclusive_language
    var draw_card_blacklist: [CardInfo]?
    //swiftlint:enable inclusive_language
}

struct LiveSecrets: Codable {
    var by_game_type_and_format_type: [String: Set<String>]
    var created_by_game_type_and_format_type: [String: [String: Set<String>]]?
}

class RemoteConfig {
    static var data: ConfigData?
    static var mercenaries: [Mercenary]?
    static var liveSecrets: LiveSecrets?
    static var battlegroundsTagOverrides: [TagOverride]?
    
    private static var url = "https://hsdecktracker.net/config.json"
    private static var mercsUrl = "https://api.hearthstonejson.com/v1/latest/enUS/mercenaries.json"
    private static var secretsUrl = "https://hsreplay.net/api/v1/live/secrets/"
    private static var overridesUrl = "https://hsreplay.net/api/v1/battlegrounds/tag_overrides/"

    static func checkRemoteConfig(splashscreen: Splashscreen) {
        DispatchQueue.main.async {
            splashscreen.display(String.localizedString("Loading remote configuration", comment: ""),
                                 indeterminate: true)
        }

        let dispatchGroup = DispatchGroup()

        // Helper function to safely decode and assign data
        func fetchData<T: Decodable>(
            url: String,
            decodeType: T.Type,
            assignment: @escaping (T) -> Void,
            errorMessage: String
        ) {
            dispatchGroup.enter()
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
                    dispatchGroup.leave()
                }
        }

        // 1. Fetch main config
        fetchData(url: RemoteConfig.url,
                  decodeType: ConfigData.self,
                  assignment: { self.data = $0 },
                  errorMessage: "main configuration")

        // 2. Fetch battlegrounds tag overrides
        fetchData(url: RemoteConfig.overridesUrl,
                  decodeType: [TagOverride].self,
                  assignment: { self.battlegroundsTagOverrides = $0 },
                  errorMessage: "battlegrounds tag overrides")

        // 3. Fetch mercenaries
        fetchData(url: RemoteConfig.mercsUrl,
                  decodeType: [Mercenary].self,
                  assignment: { self.mercenaries = $0 },
                  errorMessage: "mercenaries configuration")

        // 4. Fetch live secrets
        fetchData(url: RemoteConfig.secretsUrl,
                  decodeType: LiveSecrets.self,
                  assignment: { self.liveSecrets = $0 },
                  errorMessage: "live secrets configuration")

        dispatchGroup.notify(queue: .main) {
            logger.info("All remote configurations loaded.")
            splashscreen.progressBar.stopAnimation(nil)
            // Optionally, you can close the splash screen here or transition to the main app view
        }
    }
}


//
//  RemoteConfig.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/14/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct NewsData: Codable {
    var id: Int
    var items: [String]
}

struct CollectionBannerData: Codable {
    var visible: Bool
    var removable_pre_sync: Bool
    var removable_post_sync: Bool
    var removal_id: Int
}

struct ArenaData: Codable {
    var current_sets: [String] //FIXME
    var exclusive_secrets: [String]
    var banned_secrets: [String]
}

struct PVPDRData: Codable {
    var current_sets: [String]
    var banned_secrets: [String]
}

struct RemoteConfigCard: Codable {
    var dbf_id: Int
    var count: Int
}

struct WhizbangDeck: Codable {
    var title: String
    var card_class: Int
    var deck_id: Int
    var cards: [RemoteConfigCard]
    
    enum CodingKeys: String, CodingKey {
        case title
        case card_class = "class"
        case deck_id
        case cards
    }
}

struct TagOverride: Codable {
    var dbf_id: Int
    var tag: Int // not using GameTag as it is not 100% up to date
    var value: Int
}

struct BobsBuddyData: Codable {
    var disabled: Bool
    var min_required_version: String
    var sentry_reporting: Bool
    var metric_sampling: Double
    var can_remove_lich_king: Bool?
    var log_lines_kept: Int
}

struct ConfigData: Codable {
    var news: NewsData
    var collection_banner: CollectionBannerData
    var arena: ArenaData
    var pvpdr: PVPDRData
    var whizbang_decks: [WhizbangDeck]
    var battlegrounds_tag_overrides: [TagOverride]
    var bobs_buddy: BobsBuddyData
}

class RemoteConfig {
    static var data: ConfigData?
    
    private static var url = "https://hsdecktracker.net/config.json"

    static func checkRemoteConfig(splashscreen: Splashscreen) {
        DispatchQueue.main.async {
            splashscreen.display(NSLocalizedString("Loading remote configuration", comment: ""),
                                 indeterminate: true)
        }

        let http = Http(url: RemoteConfig.url)
        let semaphore = DispatchSemaphore(value: 0)
        _ = http.getPromise(method: .get).done { data in
            let d = try JSONDecoder().decode(ConfigData.self, from: data!)
            self.data = d
            logger.info("Retrieved remote configuration")
            semaphore.signal()
        }.catch { error in
            logger.error("Error parsing remote config: \(error.localizedDescription)")
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
}


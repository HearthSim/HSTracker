//
//  GetAccountResult.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/8/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BlizzardAccount: Decodable {
    var battletag: String
    var account_hi: Int64
    var account_lo: Int
    var region: Int
    
    enum CodingKeys: String, CodingKey {
        case battletag
        case account_hi
        case account_lo
        case region
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        battletag = try container.decode(String.self, forKey: .battletag)
        account_hi = try Int64(container.decode(String.self, forKey: .account_hi))!
        account_lo = try container.decode(Int.self, forKey: .account_lo)
        region = try container.decode(Int.self, forKey: .region)
    }
}

struct AccountData: Decodable {
    var id: Int
    var username: String
    var battletag: String
    var is_premium: Bool
    var is_tier7: Bool
    var blizzard_accounts: [BlizzardAccount]
    var tokens: [String]
}

enum GetAccountResult {
    case failed
    case success(account: AccountData)
}

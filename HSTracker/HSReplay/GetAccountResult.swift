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
    var account_hi: Int
    var account_lo: Int
    var region: Int
}

struct AccountData: Decodable {
    var id: Int
    var username: String
    var battletag: String
    var is_premium: Bool
    var blizzard_accounts: [BlizzardAccount]
    var tokens: [String]
}

enum GetAccountResult {
    case failed
    case success(account: AccountData)
}

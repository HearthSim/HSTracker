//
//  HSReplay.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct HSReplay {
    static let hsreplayUrl = "https://hsreplay.net"
    static let baseUrl = "https://api.hsreplay.net"
    static let baseUploadUrl = "https://upload.hsreplay.net"
    private static let baseOAuth = "/oauth2"
    private static let baseApi = "/api/v1"
    private static let uploadRequestApi = "/replay/upload/request"
    private static let tokensApi = "/tokens"
    private static let claimAccountApi = "/claim_account"
    private static let claimBattleTagApi = "/blizzard_accounts"
    private static let authorizeApi = "/authorize/"
    private static let tokenApi = "/token/"
    private static let collectionTokenApi = "/collection/upload_request/"
    private static let accountApi = "/account/"
    
    static let baseApiUrl = "\(baseUrl)\(baseApi)"
    static let baseOAuthUrl = "\(hsreplayUrl)\(baseOAuth)"
    static let baseUploadApiUrl = "\(baseUploadUrl)\(baseApi)"
    static let uploadRequestUrl = "\(baseUploadApiUrl)\(uploadRequestApi)"
    static let tokensUrl = "\(baseApiUrl)\(tokensApi)"
    static let collectionTokensUrl = "\(baseApiUrl)\(collectionTokenApi)"
    static let claimAccountUrl = "\(baseApiUrl)\(claimAccountApi)/"
    static let claimBattleTagUrl = "\(baseApiUrl)\(claimBattleTagApi)"
    static let oAuthAuthorizeUrl = "\(baseOAuthUrl)\(authorizeApi)"
    static let oAuthTokenUrl = "\(baseOAuthUrl)\(tokenApi)"
    static let accountUrl = "\(baseApiUrl)\(accountApi)"
}

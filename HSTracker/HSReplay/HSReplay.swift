//
//  HSReplay.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct HSReplay {
    static let baseUrl = "https://hsreplay.net"
    static let baseUploadUrl = "https://upload.hsreplay.net"
    private static let baseOAuth = "/oauth2"
    private static let baseApi = "/api/v1"
    private static let uploadRequestApi = "/replay/upload/request"
    private static let tokensApi = "/tokens"
    private static let claimAccountApi = "/claim_account"
    private static let authorizeApi = "/authorize/"
    private static let tokenApi = "/token/"
    
    static let baseApiUrl = "\(baseUrl)\(baseApi)"
    static let baseOAuthUrl = "\(baseUrl)\(baseOAuth)"
    static let baseUploadApiUrl = "\(baseUploadUrl)\(baseApi)"
    static let uploadRequestUrl = "\(baseUploadApiUrl)\(uploadRequestApi)"
    static let tokensUrl = "\(baseApiUrl)\(tokensApi)"
    static let claimAccountUrl = "\(baseApiUrl)\(claimAccountApi)/"
    static let oAuthAuthorizeUrl = "\(baseOAuthUrl)\(authorizeApi)"
    static let oAuthTokenUrl = "\(baseOAuthUrl)\(tokenApi)"
}

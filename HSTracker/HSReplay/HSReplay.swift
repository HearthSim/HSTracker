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
    private static let claimAccountApi = "/account/claim_token"
    private static let claimBattleTagApi = "/blizzard_accounts"
    private static let authorizeApi = "/authorize/"
    private static let tokenApi = "/token/"
    private static let collectionTokenApi = "/collection/upload_request/"
    private static let accountApi = "/account/"
    
    static let baseApiUrl = "\(baseUrl)\(baseApi)"
    static let baseOAuthUrl = "\(baseUrl)\(baseOAuth)"
    static let baseUploadApiUrl = "\(baseUploadUrl)\(baseApi)"
    static let uploadRequestUrl = "\(baseUploadApiUrl)\(uploadRequestApi)"
    static let tokensUrl = "\(baseApiUrl)\(tokensApi)"
    static let collectionTokensUrl = "\(baseApiUrl)\(collectionTokenApi)"
    static let claimAccountUrl = "\(baseApiUrl)\(claimAccountApi)/"
    static let claimBattleTagUrl = "\(baseApiUrl)\(claimBattleTagApi)"
    static let oAuthAuthorizeUrl = "\(baseOAuthUrl)\(authorizeApi)"
    static let oAuthTokenUrl = "\(baseOAuthUrl)\(tokenApi)"
    static let accountUrl = "\(baseApiUrl)\(accountApi)"

    static let tier7HeroPickStatsUrl = "\(baseApiUrl)/battlegrounds/hero_pick/"
    static let tier7DuosHeroPickStatsUrl = "\(baseApiUrl)/battlegrounds/duos/hero_pick/"
    static let tier7QuestStatsUrl = "\(baseApiUrl)/battlegrounds/quest_pick/"
    static let tier7AllTimeMMR = "\(baseApiUrl)/battlegrounds/alltime/"
    static let tier7CompStatsUrl = "\(baseApiUrl)/battlegrounds/first_place_comps/"
    static let battlegroundsInspirationUrl = "\(baseApiUrl)/battlegrounds/inspiration/"
    static let playerTrial = "\(baseApiUrl)/playertrials/"
    static let constructedMulliganGuide = "\(baseApiUrl)/mulligan/overlay/"
    static let constructedMulliganGuideStatus = "\(baseApiUrl)/mulligan/status/"
    // Endpoint path inferred from HDT's Mulligan G-V2 commit; verify against a live response before shipping.
    static let constructedMulliganGuideV2 = "\(baseApiUrl)/mulligan_v2/overlay/"
    static let constructedMulliganGuideV2Status = "\(baseApiUrl)/mulligan_v2/status/"
    static let tier7TrinketPickStats = "\(baseApiUrl)/battlegrounds/trinket_pick/"

    static let mixpanelIdentifyUrl = "\(baseApiUrl)/client_analytics/identify/"

    static let compGuidesUrl = "\(baseUrl)\(baseApi)/battlegrounds/comp_guides/"
    static let tier7CompGuidesUrl = "\(baseUrl)\(baseApi)/battlegrounds/comp_guides/tier7/"
    static let heroGuidesUrl = "\(baseUrl)\(baseApi)/battlegrounds/hero_guides/"
    static let trinketGuidesUrl = "\(baseUrl)\(baseApi)/battlegrounds/trinket_guides/"
    static let anomalyGuidesUrl = "\(baseUrl)\(baseApi)/battlegrounds/anomaly_guides/"
    static let questGuidesUrl = "\(baseUrl)\(baseApi)/battlegrounds/quest_guides/"
}

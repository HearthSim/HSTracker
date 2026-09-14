//
//  HSReplayAPI.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import OAuthSwift
import PromiseKit
import Mixpanel

enum HSReplayError: Error {
    case missingAccount
    case authorizationTokenNotSet
    case collectionUploadMissingURL
    case genericError(message: String)
}

enum ClaimBlizzardAccountResponse {
    case success
    case error
    case tokenAlreadyClaimed
}

class HSReplayAPI {
    static let apiKey = "f1c6965c-f5ee-43cb-ab42-768f23dd35e8"
    static let oAuthClientKey = "pk_live_IB0TiMMT8qrwIJ4G6eVHYaAi"//"pk_test_AUThiV1Ex9nKCbHSFchv7ybX"
    private static let defaultHeaders = ["Accept": "application/json", "Content-Type": "application/json"]
    static var accountData: AccountData?
    
    static let tokenRenewalHandler: OAuthSwift.TokenRenewedHandler = { result in
        switch result {
        case .success(let credential):
            logger.debug("HSReplay: Refreshed OAuthToken")
            Settings.hsReplayOAuthToken = credential.oauthToken
            Settings.hsReplayOAuthRefreshToken = credential.oauthRefreshToken
            Settings.hsReplayOAuthTokenExpiration = credential.oauthTokenExpiresAt
        case .failure(let error):
            logger.error("Failed to renew token: \(error)")
        }
    }
    
    static let oauthswift = {
        return OAuth2Swift(
            consumerKey: oAuthClientKey,
            consumerSecret: "",
            authorizeUrl: HSReplay.oAuthAuthorizeUrl,
            accessTokenUrl: HSReplay.oAuthTokenUrl,
            responseType: "code"
        )
    }()
    
    private static let _requiredScopes = [ "fullaccess" ]
    
    static var isFullyAuthenticated: Bool {
        return isAuthenticatedFor(_requiredScopes)
    }
    
    static func isAuthenticatedFor(_ scopes: [String]) -> Bool {
        guard let currentScopes = Settings.hsReplayOAuthScope?.components(separatedBy: " ") else {
            return false
        }
        if currentScopes.contains("fullaccess") {
            return true
        }
        return scopes.all({ x in currentScopes.contains(x) })
    }
    
    static func oAuthAuthorize(handle: @escaping () -> Void) {
        _ = oauthswift.authorize(
            withCallbackURL: URL(string: "hstracker://oauth-callback/hsreplay")!,
            scope: "fullaccess",
            state: "HSREPLAY",
            completionHandler: { result in
                switch result {
                case .success(let (credential, _, _)):
                    logger.info("HSReplay: OAuth succeeded")
                    Settings.hsReplayOAuthToken = credential.oauthToken
                    Settings.hsReplayOAuthRefreshToken = credential.oauthRefreshToken
                    Settings.hsReplayOAuthTokenExpiration = credential.oauthTokenExpiresAt
                    
                    HSReplayAPI.getUploadToken { _ in
                        HSReplayAPI.claimAccount()
                    }

                    handle()
                case .failure(let error):
                    // TODO: Better error handling
                    logger.info("HSReplay: OAuth failed \(error)")
                }
            }
        )
    }
    
    static func updateOAuthCredential() {
        let credential = HSReplayAPI.oauthswift.client.credential
        if let refreshToken = Settings.hsReplayOAuthRefreshToken {
            credential.oauthRefreshToken = refreshToken
        }
        if let oauthToken = Settings.hsReplayOAuthToken {
            credential.oauthToken = oauthToken
        }
        if let expiration = Settings.hsReplayOAuthTokenExpiration {
            credential.oauthTokenExpiresAt = expiration
        }
    }
    
    static func startAuthorizedRequest(_ url: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, onTokenRenewal: OAuthSwift.TokenRenewedHandler? = nil, completionHandler completion: @escaping OAuthSwiftHTTPRequest.CompletionHandler) {
        
        if let expiration = Settings.hsReplayOAuthTokenExpiration {
            if expiration.timeIntervalSince(Date()) <= 0 {
                logger.debug("OAuth token is expired, renewing")
                
                HSReplayAPI.oauthswift.renewAccessToken(withRefreshToken: HSReplayAPI.oauthswift.client.credential
                    .oauthRefreshToken, completionHandler: { result in
                        switch result {
                        case .success(let (credential, _, parameters)):
                            logger.debug("HSReplay: Refreshed OAuthToken")
                            Settings.hsReplayOAuthToken =  credential.oauthToken
                            Settings.hsReplayOAuthRefreshToken = credential.oauthRefreshToken
                            Settings.hsReplayOAuthTokenExpiration = credential.oauthTokenExpiresAt
                            Settings.hsReplayOAuthScope = parameters["scope"] as? String
                            updateOAuthCredential()
                            oauthswift.client.requestWithAutomaticAccessTokenRenewal(url: URL(string: url)!, method: method, parameters: parameters, headers: headers, accessTokenUrl: HSReplay.oAuthTokenUrl, onTokenRenewal: onTokenRenewal, completionHandler: completion)
                        case .failure(let error):
                            logger.error(error)
                            // try again, just in case
                            oauthswift.client.requestWithAutomaticAccessTokenRenewal(url: URL(string: url)!, method: method, parameters: parameters, headers: headers, accessTokenUrl: HSReplay.oAuthTokenUrl, onTokenRenewal: onTokenRenewal, completionHandler: completion)
                        }
                    })
                return
            }
        }
        oauthswift.client.request(url, method: method, parameters: parameters, headers: headers, body: body) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                switch error {
                case .tokenExpired:
                    if let onTokenRenewal {
                        oauthswift.renewAccessToken(withRefreshToken: HSReplayAPI.oauthswift.client.credential
                            .oauthRefreshToken, completionHandler: { result in
                                switch result {
                                case .success(let (credential, _, _)):
                                    onTokenRenewal(.success(credential))
                                    startAuthorizedRequest(url, method: method, parameters: parameters, headers: headers, body: body, onTokenRenewal: nil, completionHandler: completion)
                                case .failure(let error):
                                    completion(.failure(.tokenExpired(error: error)))
                                }
                            })
                    }
                case .requestError:
                    completion(.failure(error))
                default:
                    completion(.failure(.tokenExpired(error: nil)))
                }
            }
        }
    }
    
    static func getUploadToken(handle: @escaping (String) -> Void) {
        if let token = Settings.hsReplayUploadToken {
            handle(token)
            return
        }
        let http = Http(url: "\(HSReplay.tokensUrl)/")
        http.json(method: .post,
                  parameters: ["api_token": apiKey],
                  headers: ["X-Api-Key": apiKey]) { json in
            if let json = json as? [String: Any],
               let key = json["key"] as? String {
                logger.info("HSReplay : Obtained new upload-token")
                Settings.hsReplayUploadToken = key
                handle(key)
            } else {
                logger.error("Failed to obtain upload token")
                handle("failed-token")
            }
        }
    }
    
    //    static func claimBlizzardAccount(account_hi: Int64, account_lo: Int64, battleTag: String) async -> ClaimBlizzardAccountResponse {
    //        await withCheckedContinuation { continuation in
    //            oauthswift.startAuthorizedRequest("\(HSReplay.claimBattleTagUrl)/\(account_hi)/\(account_lo)/", method: .POST,
    //                                              parameters: ["battletag": battleTag], headers: defaultHeaders,
    //                                              onTokenRenewal: tokenRenewalHandler,
    //                                              completionHandler: { result in
    //                                                  switch result {
    //                                                  case .success:
    //                                                      continuation.resume(returning: .success)
    //                                                      return
    //                                                  case .failure(let error):
    //                                                      logger.error(error)
    //                                                      if error.description.contains("account_already_claimed") {
    //                                                          continuation.resume(returning: .tokenAlreadyClaimed)
    //                                                          return
    //                                                      } else {
    //                                                          continuation.resume(returning: .error)
    //                                                          return
    //                                                      }
    //                                                  }
    //                                              }
    //                                          )
    //        }
    //    }
    
    static func claimBattleTag(account_hi: Int64, account_lo: Int64, battleTag: String) -> Promise<ClaimBlizzardAccountResponse> {
        return Promise<ClaimBlizzardAccountResponse> { seal in
            startAuthorizedRequest("\(HSReplay.claimBattleTagUrl)/\(account_hi)/\(account_lo)/", method: .POST,
                                   parameters: ["battletag": battleTag], headers: defaultHeaders,
                                   onTokenRenewal: tokenRenewalHandler,
                                   completionHandler: { result in
                switch result {
                case .success:
                    seal.fulfill(.success)
                case .failure(let error):
                    logger.error(error)
                    if error.description.contains("account_already_claimed") {
                        seal.fulfill(.tokenAlreadyClaimed)
                    } else {
                        seal.fulfill(.error)
                    }
                }
            }
            )
        }
    }
    
    static func claimAccount() {
        guard let token = Settings.hsReplayUploadToken else {
            logger.error("Authorization token not set yet")
            return
        }
        
        logger.info("Claiming account...")
        
        startAuthorizedRequest(
            HSReplay.claimAccountUrl,
            method: .POST,
            parameters: ["token": token],
            headers: defaultHeaders,
            onTokenRenewal: tokenRenewalHandler,
            completionHandler: { result in
                switch result {
                case .success:
                    logger.info("Account Successfully Claimed")
                case .failure(let error):
                    switch error {
                    case .requestError(let error, _):
                        logger.error("\(error.localizedDescription)")
                    default:
                        logger.error("Failed to claim account: \(error)")
                    }
                }
            })
    }
    
    static func linkMixpanelAccount() {
        let token_payload = [
            "i": "hst",
            "m": Mixpanel.mainInstance().distinctId
        ]

        logger.info(token_payload)

        do {
            let json_string = String(data: try JSONSerialization.data(withJSONObject: token_payload), encoding: String.Encoding.utf8)

            let encoded_payload = json_string?.data(using: .utf8)?.base64EncodedString()

            var body: Data?

            let encoder = JSONEncoder()

            do {
                body = try encoder.encode(["client_analytics_token": encoded_payload])
            } catch {
                logger.error(error)
            }

            startAuthorizedRequest(
                HSReplay.mixpanelIdentifyUrl,
                method: .POST,
                parameters: [:],
                headers: defaultHeaders,
                body: body,
                onTokenRenewal: tokenRenewalHandler,
                completionHandler: { result in
                    switch result {
                    case .success:
                        MixpanelEvents.linkedMixpanelToken = true
                        logger.info("Succesfully identified mixpanel token")
                    case .failure(let error):
                        switch error {
                        case .requestError(let error, _):
                            logger.error("\(error.localizedDescription)")
                        default:
                            logger.error("Failed to identified token: \(error)")
                        }
                    }
                })
        } catch let error {
            logger.error("Failed to create payload : \(error)")
        }
    }

    static func updateAccountStatus(handle: @escaping (Bool) -> Void) {
        guard let token = Settings.hsReplayUploadToken else {
            logger.error("Authorization token not set yet")
            handle(false)
            return
        }
        logger.info("Checking account status...")
        
        let http = Http(url: "\(HSReplay.tokensUrl)/\(token)/")
        http.json(method: .get,
                  headers: [
                    "X-Api-Key": apiKey,
                    "Authorization": "Token \(token)"
                  ]) { json in
                      if let json = json as? [String: Any],
                         let user = json["user"] as? [String: Any] {
                          if let username = user["username"] as? String {
                              Settings.hsReplayUsername = username
                          }
                          Settings.hsReplayId = user["id"] as? Int ?? 0
                          logger.info("id=\(String(describing: Settings.hsReplayId)), Username=\(String(describing: Settings.hsReplayUsername))")
                          handle(true)
                      } else {
                          handle(false)
                      }
                  }
    }
    
    //    private static func getUploadCollectionToken(type: CollectionType) async throws -> String {
    //        guard let accountId = MirrorHelper.getAccountId() else {
    //            throw HSReplayError.missingAccount
    //        }
    //        return try await withCheckedThrowingContinuation { continuation in
    //            oauthswift.startAuthorizedRequest("\(HSReplay.collectionTokensUrl)", method: .GET, parameters: ["account_hi": accountId.hi, "account_lo": accountId.lo, "type": type == .constructed ? "CONSTRUCTED" : "MERCENARIES"], headers: defaultHeaders, onTokenRenewal: tokenRenewalHandler,
    //                                              completionHandler: { result in
    //                switch result {
    //                case .success(let response):
    //                    do {
    //                        guard let json = try response.jsonObject() as? [String: Any], let token = json["url"] as? String else {
    //                            logger.error("HSReplay: Unexpected JSON \(response.string ?? "")")
    //                            continuation.resume(throwing: HSReplayError.collectionUploadMissingURL)
    //                            return
    //                        }
    //                        logger.info("HSReplay: obtained new collection upload json: \(json)")
    //                        continuation.resume(returning: token)
    //                        return
    //                    } catch {
    //                        logger.error("HSReplay: unknown error get upload token: \(error)")
    //                        continuation.resume(throwing: HSReplayError.missingAccount)
    //                        return
    //                    }
    //                case .failure(let error):
    //                    logger.error(error)
    //                    continuation.resume(throwing: HSReplayError.authorizationTokenNotSet)
    //                    return
    //                }
    //            })
    //        }
    //    }
    
    private static func getUploadCollectionToken(collectionType: CollectionType) -> Promise<String> {
        return Promise<String> { seal in
            guard let accountId = MirrorHelper.getAccountId() else {
                seal.reject(HSReplayError.missingAccount)
                return
            }
            startAuthorizedRequest("\(HSReplay.collectionTokensUrl)", method: .POST, parameters: ["account_hi": accountId.hi, "account_lo": accountId.lo, "type": collectionType == .constructed ? "CONSTRUCTED" : "MERCENARIES"], headers: defaultHeaders, onTokenRenewal: tokenRenewalHandler,
                                   completionHandler: { result in
                switch result {
                case .success(let response):
                    do {
                        guard let json = try response.jsonObject() as? [String: Any], let token = json["url"] as? String else {
                            logger.error("HSReplay: Unexpected JSON \(String(describing: response.string))")
                            seal.reject(HSReplayError.collectionUploadMissingURL)
                            return
                        }
                        logger.info("HSReplay: obtained new collection upload json: \(json)")
                        seal.fulfill(token)
                    } catch {
                        seal.reject(HSReplayError.missingAccount)
                    }
                case .failure(let error):
                    logger.error(error)
                    seal.reject(HSReplayError.authorizationTokenNotSet)
                }
            })
        }
    }
    
    //    static func updateCollection(collection: Collection) async -> Bool {
    //        do {
    //            let token = try await getUploadCollectionToken(type: .constructed)
    //            let upload = Http(url: token)
    //            if let data = try? JSONEncoder().encode(collection) {
    //                if let result = await upload.uploadAsync(method: .put, data: data, headers: [ "Content-Type": "application/json" ]) {
    //                    logger.debug("Upload result: \(result)")
    //                }
    //                return true
    //            } else {
    //                logger.error("JSON conversion failed")
    //                return false
    //            }
    //        } catch {
    //            return false
    //        }
    //    }
    //
    //    static func updateMercenariesCollection(collection: MercenariesCollection) async -> Bool {
    //        do {
    //            let token = try await getUploadCollectionToken(type: .mercenaries)
    //            let upload = Http(url: token)
    //            if let data = try? JSONEncoder().encode(collection) {
    //                if let result = await upload.uploadAsync(method: .put, data: data, headers: [ "Content-Type": "application/json" ]) {
    //                    logger.debug("Upload result: \(result)")
    //                }
    //                return true
    //            } else {
    //                logger.error("JSON conversion failed")
    //                return false
    //            }
    //        } catch {
    //            return false
    //        }
    //    }
    
    private static func uploadCollectionInternal(collection: CollectionBase, url: String, seal: Resolver<Bool>) {
        let upload = Http(url: url)
        let enc = JSONEncoder()
        enc.outputFormatting = .sortedKeys
        if let data = try? enc.encode(collection) {
            upload.uploadPromise(method: .put, headers: [ "Content-Type": "application/json" ], data: data).done { data in
                if data != nil {
                    seal.fulfill(true)
                }
            }.catch { error in
                logger.error(error)
                seal.fulfill(false)
            }
        } else {
            seal.fulfill(false)
        }
    }
    
    static func uploadCollection(collection: CollectionBase, collectionType: CollectionType) -> Promise<Bool> {
        return Promise<Bool> { seal in
            getUploadCollectionToken(collectionType: collectionType).done { url in
                uploadCollectionInternal(collection: collection, url: url, seal: seal)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    static func parseResponse<T: Decodable>(data: Data, defaultValue: T) -> T {
        let decoder = JSONDecoder()
        do {
            let bqs = try decoder.decode(T.self, from: data)
            return bqs
        } catch let error {
            logger.error("Failed to parse response: \(error)")
            return defaultValue
        }
    }
    
    private static func parseAccountData(data: Data) -> AccountData? {
        let decoder = JSONDecoder()
        do {
            let ad = try decoder.decode(AccountData.self, from: data)
            return ad
        } catch let error {
            logger.error("Failed to parse account response: \(error)")
            return nil
        }
    }
    
    static func getAccount() -> Promise<GetAccountResult> {
        return Promise<GetAccountResult> { seal in
            startAuthorizedRequest("\(HSReplay.accountUrl)", method: .GET, parameters: [:], headers: defaultHeaders, onTokenRenewal: tokenRenewalHandler, completionHandler: { result in
                switch result {
                case .success(let response):
                    if let ad = parseAccountData(data: response.data) {
                        accountData = ad
                        seal.fulfill(.success(account: ad))
                    } else {
                        accountData = nil
                        seal.fulfill(.failed)
                    }
                case .failure(let error):
                    accountData = nil
                    logger.error(error)
                    seal.fulfill(.failed)
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getAccountAsync() async -> GetAccountResult {
        await withCheckedContinuation { continuation in
            _ = getAccount().map { result in
                continuation.resume(returning: result)
                return
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getTier7HeroPickStats(parameters: BattlegroundsHeroPickStatsParams) async -> BattlegroundsHeroPickStats? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending hero picks request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            startAuthorizedRequest("\(HSReplay.tier7HeroPickStatsUrl)", method: .POST, headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    logger.debug("Response: \(String(data: response.data, encoding: .utf8) ?? "FAILED")")
                    let bqs: BattlegroundsHeroPickStats? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: bqs)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getTier7HeroPickStats(token: String?, parameters: BattlegroundsHeroPickStatsParams) async -> BattlegroundsHeroPickStats? {
        guard let token = token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending hero picks request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            guard let body = body else {
                continuation.resume(returning: nil)
                return
            }
            let http = Http(url: "\(HSReplay.tier7HeroPickStatsUrl)")
            _ = http.uploadPromise(method: .post, headers: ["Content-Type": "application/json", "X-Trial-Token": token], data: body).done { response in
                guard let data = response as? Data else {
                    continuation.resume(returning: nil)
                    return
                }
                logger.debug("Response: \(String(data: data, encoding: .utf8) ?? "FAILED")")
                let bqs: BattlegroundsHeroPickStats? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: bqs)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getTier7DuosHeroPickStats(parameters: BattlegroundsHeroPickStatsParams) async -> BattlegroundsHeroPickStats? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending hero picks request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            startAuthorizedRequest("\(HSReplay.tier7DuosHeroPickStatsUrl)", method: .POST, headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    logger.debug("Response: \(String(data: response.data, encoding: .utf8) ?? "FAILED")")
                    let bqs: BattlegroundsHeroPickStats? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: bqs)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getTier7DuosHeroPickStats(token: String?, parameters: BattlegroundsHeroPickStatsParams) async -> BattlegroundsHeroPickStats? {
        guard let token = token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending hero picks request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            guard let body = body else {
                continuation.resume(returning: nil)
                return
            }
            let http = Http(url: "\(HSReplay.tier7DuosHeroPickStatsUrl)")
            _ = http.uploadPromise(method: .post, headers: ["Content-Type": "application/json", "X-Trial-Token": token], data: body).done { response in
                guard let data = response as? Data else {
                    continuation.resume(returning: nil)
                    return
                }
                logger.debug("Response: \(String(data: data, encoding: .utf8) ?? "FAILED")")
                let bqs: BattlegroundsHeroPickStats? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: bqs)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getTier7QuestStats(parameters: BattlegroundsQuestPickParams) async -> [BattlegroundsQuestStats]? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending quest rewards request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            startAuthorizedRequest("\(HSReplay.tier7QuestStatsUrl)", method: .POST, headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    let bqs: [BattlegroundsQuestStats]? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: bqs)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getTier7QuestStats(token: String?, parameters: BattlegroundsQuestPickParams) async -> [BattlegroundsQuestStats]? {
        guard let token = token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending quest rewards request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            guard let body = body else {
                continuation.resume(returning: nil)
                return
            }
            let http = Http(url: "\(HSReplay.tier7QuestStatsUrl)")
            _ = http.uploadPromise(method: .post, headers: ["Content-Type": "application/json", "X-Trial-Token": token], data: body).done { response in
                guard let data = response as? Data else {
                    continuation.resume(returning: nil)
                    return
                }
                logger.debug("Response: \(String(data: data, encoding: .utf8) ?? "FAILED")")
                let bqs: [BattlegroundsQuestStats]? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: bqs)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getAllTimeBGsMMR(hi: Int64, lo: Int) async -> Tier7AllTime? {
        return await withCheckedContinuation { continuation in
            startAuthorizedRequest("\(HSReplay.tier7AllTimeMMR)", method: .GET, parameters: ["account_hi": hi, "account_lo": lo], completionHandler: { result in
                switch result {
                case .success(let response):
                    let res: Tier7AllTime? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: res)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getPlayerTrialStatus(name: String, hi: Int64, lo: Int64) async -> PlayerTrialStatus? {
        return await withCheckedContinuation { continuation in
            startAuthorizedRequest("\(HSReplay.playerTrial)\(name)/?account_hi=\(hi)&account_lo=\(lo)", method: .GET, parameters: [:], completionHandler: { result in
                switch result {
                case .success(let response):
                    let res: PlayerTrialStatus? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: res)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func activatePlayerTrial(name: String, hi: Int64, lo: Int64) async -> PlayerTrialActivation? {
        return await withCheckedContinuation { continuation in
            startAuthorizedRequest("\(HSReplay.playerTrial)\(name)/?account_hi=\(hi)&account_lo=\(lo)", method: .POST, parameters: [:], completionHandler: { result in
                switch result {
                case .success(let response):
                    if let str = String(data: response.data, encoding: .utf8) {
                        logger.debug("Response data: \(str)")
                    }
                    let res: PlayerTrialActivation? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: res)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getMulliganGuideData(parameters: MulliganGuideParams) async -> MulliganGuideData? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending mulligan guide data request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            
            startAuthorizedRequest("\(HSReplay.constructedMulliganGuide)", method: .POST, parameters: [:], headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    if let str = String(data: response.data, encoding: .utf8) {
                        logger.debug("Response data: \(str)")
                        let bqs: MulliganGuideData? = parseResponse(data: response.data, defaultValue: nil)
                        continuation.resume(returning: bqs)
                    } else {
                        continuation.resume(returning: nil)
                    }
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getConstructedMulliganV2(parameters: MulliganV2Params) async -> MulliganV2Data? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending mulligan guide v2 data request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }

            startAuthorizedRequest("\(HSReplay.constructedMulliganGuideV2)", method: .POST, parameters: [:], headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    if let str = String(data: response.data, encoding: .utf8) {
                        logger.debug("Response data: \(str)")
                        let bqs: MulliganV2Data? = parseResponse(data: response.data, defaultValue: nil)
                        continuation.resume(returning: bqs)
                    } else {
                        continuation.resume(returning: nil)
                    }
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }

    // Trial-token variant, matching getTier7HeroPickStats(token:parameters:) -
    // an unauthenticated request carrying the trial token in a header
    // instead of the user's own OAuth session.
    @available(macOS 10.15.0, *)
    static func getConstructedMulliganV2(token: String?, parameters: MulliganV2Params) async -> MulliganV2Data? {
        guard let token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending mulligan guide v2 data request (trial): \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            guard let body = body else {
                continuation.resume(returning: nil)
                return
            }
            let http = Http(url: "\(HSReplay.constructedMulliganGuideV2)")
            _ = http.uploadPromise(method: .post, headers: ["Content-Type": "application/json", "X-Trial-Token": token], data: body).done { response in
                guard let data = response as? Data else {
                    continuation.resume(returning: nil)
                    return
                }
                logger.debug("Response data (trial): \(String(data: data, encoding: .utf8) ?? "FAILED")")
                let bqs: MulliganV2Data? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: bqs)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    static func getMulliganGuideStatus(parameters: MulliganGuideStatusParams) async -> MulliganGuideStatusData? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending mulligan guide status request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            
            startAuthorizedRequest("\(HSReplay.constructedMulliganGuideStatus)", method: .POST, parameters: [:], headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    if let str = String(data: response.data, encoding: .utf8) {
                        logger.debug("Response data: \(str)")
                        let bqs: MulliganGuideStatusData? = parseResponse(data: response.data, defaultValue: nil)
                        continuation.resume(returning: bqs)
                    } else {
                        continuation.resume(returning: nil)
                    }
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }

    @available(macOS 10.15.0, *)
    static func getMulliganV2Status(parameters: MulliganV2StatusParams) async -> MulliganV2StatusData? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending mulligan guide v2 status request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }

            startAuthorizedRequest("\(HSReplay.constructedMulliganGuideV2Status)", method: .POST, parameters: [:], headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    if let str = String(data: response.data, encoding: .utf8) {
                        logger.debug("Response data: \(str)")
                        let bqs: MulliganV2StatusData? = parseResponse(data: response.data, defaultValue: nil)
                        continuation.resume(returning: bqs)
                    } else {
                        continuation.resume(returning: nil)
                    }
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }

    @available(macOS 10.15.0, *)
    static func getTier7CompStats(parameters: BattlegroundsCompStatsParams) async -> BattlegroundsCompStats? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending quest rewards request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            startAuthorizedRequest("\(HSReplay.tier7CompStatsUrl)", method: .POST, headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    logger.debug("Response: \(String(data: response.data, encoding: .utf8) ?? "FAILED")")
                    let bqs: BattlegroundsCompStats? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: bqs)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }
    
    @available(macOS 10.15.0, *)
    static func getTier7CompStats(token: String?, parameters: BattlegroundsCompStatsParams) async -> BattlegroundsCompStats? {
        guard let token = token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending quest rewards request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            guard let body = body else {
                continuation.resume(returning: nil)
                return
            }
            let http = Http(url: "\(HSReplay.tier7CompStatsUrl)")
            _ = http.uploadPromise(method: .post, headers: ["Content-Type": "application/json", "X-Trial-Token": token], data: body).done { response in
                guard let data = response as? Data else {
                    continuation.resume(returning: nil)
                    return
                }
                logger.debug("Response: \(String(data: data, encoding: .utf8) ?? "FAILED")")
                let bqs: BattlegroundsCompStats? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: bqs)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }
    
    // Mirrors BattlegroundsInspirationViewModel.MakeRequest. Two variants, as
    // with the comp stats above: OAuth for accounts that own Tier7, an
    // X-Trial-Token header for accounts riding a trial.
    @available(macOS 10.15.0, *)
    static func getBattlegroundsInspiration(parameters: BattlegroundsInspirationParams) async -> BattlegroundsInspiration? {
        return await withCheckedContinuation { continuation in
            var body: Data?
            do {
                body = try JSONEncoder().encode(parameters)
                if let body {
                    logger.debug("Sending inspiration request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            startAuthorizedRequest("\(HSReplay.battlegroundsInspirationUrl)", method: .POST, headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    let inspiration: BattlegroundsInspiration? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: inspiration)
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                }
            })
        }
    }

    @available(macOS 10.15.0, *)
    static func getBattlegroundsInspiration(token: String?, parameters: BattlegroundsInspirationParams) async -> BattlegroundsInspiration? {
        guard let token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            var body: Data?
            do {
                body = try JSONEncoder().encode(parameters)
                if let body {
                    logger.debug("Sending inspiration request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            guard let body else {
                continuation.resume(returning: nil)
                return
            }
            let http = Http(url: "\(HSReplay.battlegroundsInspirationUrl)")
            _ = http.uploadPromise(method: .post, headers: ["Content-Type": "application/json", "X-Trial-Token": token], data: body).done { response in
                guard let data = response as? Data else {
                    continuation.resume(returning: nil)
                    return
                }
                let inspiration: BattlegroundsInspiration? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: inspiration)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    // Builds the query string by hand (rather than passing a parameters dict
    // to startAuthorizedRequest/Http) so `minion_types` can be repeated once
    // per value - matching the HSReplayNET client exactly (it appends
    // "&minion_types={type}" in a loop) - instead of relying on either
    // library's own array-parameter serialization, which isn't guaranteed to
    // produce the same wire format.
    private static func compGuidesQuery(gameLanguage: String, minionTypes: [Int]) -> String {
        var query = "?game_language=\(gameLanguage)"
        for type in minionTypes {
            query += "&minion_types=\(type)"
        }
        return query
    }

    @available(macOS 10.15.0, *)
    static func getCompGuides(gameLanguage: String) async -> BattlegroundsCompGuidesData? {
        return await withCheckedContinuation { continuation in
            let http = Http(url: "\(HSReplay.compGuidesUrl)?game_language=\(gameLanguage)")
            _ = http.getPromise(method: .get).done { data in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                let guides: BattlegroundsCompGuidesData? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: guides)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    static func getTier7CompGuides(gameLanguage: String, minionTypes: [Int]) async -> BattlegroundsTier7CompGuidesData? {
        return await withCheckedContinuation { continuation in
            let url = "\(HSReplay.tier7CompGuidesUrl)\(compGuidesQuery(gameLanguage: gameLanguage, minionTypes: minionTypes))"
            startAuthorizedRequest(url, method: .GET, parameters: [:], completionHandler: { result in
                switch result {
                case .success(let response):
                    let guides: BattlegroundsTier7CompGuidesData? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: guides)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }

    @available(macOS 10.15.0, *)
    static func getTier7CompGuides(token: String?, gameLanguage: String, minionTypes: [Int]) async -> BattlegroundsTier7CompGuidesData? {
        guard let token = token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let url = "\(HSReplay.tier7CompGuidesUrl)\(compGuidesQuery(gameLanguage: gameLanguage, minionTypes: minionTypes))"
            let http = Http(url: url)
            _ = http.getPromise(method: .get, headers: ["X-Trial-Token": token]).done { data in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                let guides: BattlegroundsTier7CompGuidesData? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: guides)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Arenasmith
    //
    // The three pick endpoints go out over OAuth when the user is signed in and
    // plain otherwise - there is no X-Trial-Token here, unlike the Tier7 routes.
    // Arena trials are resolved server-side from account_lo plus deck_id, so an
    // anonymous request from a player with trials left is still served.

    @available(macOS 10.15.0, *)
    /// `logResponse` dumps the raw body before decoding, for when the decoded
    /// model loses something the JSON text still has - key order, say, which is
    /// gone the moment an object becomes a Swift Dictionary. Off by default;
    /// pass it at a call site while investigating.
    private static func postArena<P: Encodable, R: Decodable>(url: String, parameters: P, as: R.Type,
                                                              logResponse: Bool = false) async -> R? {
        let encoder = JSONEncoder()
        var body: Data?
        do {
            body = try encoder.encode(parameters)
            if let body {
                logger.debug("Arena request to \(url): \(String(data: body, encoding: .utf8) ?? "ERROR")")
            }
        } catch {
            logger.error(error)
            return nil
        }
        guard let body else { return nil }

        if accountData != nil && isFullyAuthenticated {
            return await withCheckedContinuation { continuation in
                startAuthorizedRequest(url, method: .POST, headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                    switch result {
                    case .success(let response):
                        if logResponse {
                            logger.debug("Arena response from \(url): \(String(data: response.data, encoding: .utf8) ?? "ERROR")")
                        }
                        let parsed: R? = parseResponse(data: response.data, defaultValue: nil)
                        continuation.resume(returning: parsed)
                    case .failure(let error):
                        logger.error(error)
                        continuation.resume(returning: nil)
                    }
                })
            }
        }

        return await withCheckedContinuation { continuation in
            let http = Http(url: url)
            _ = http.uploadPromise(method: .post, headers: ["Content-Type": "application/json"], data: body).done { response in
                guard let data = response as? Data else {
                    continuation.resume(returning: nil)
                    return
                }
                if logResponse {
                    logger.debug("Arena response from \(url): \(String(data: data, encoding: .utf8) ?? "ERROR")")
                }
                let parsed: R? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: parsed)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    private static func getArenaJson<R: Decodable>(url: String, as: R.Type) async -> R? {
        return await withCheckedContinuation { continuation in
            let http = Http(url: url)
            _ = http.getPromise(method: .get).done { data in
                guard let data else {
                    continuation.resume(returning: nil)
                    return
                }
                let parsed: R? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: parsed)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    static func getArenaHeroPickStats(parameters: ArenaHeroPickParams) async -> ArenaHeroPickApiResponse? {
        return await postArena(url: HSReplay.arenaHeroPickUrl, parameters: parameters,
                               as: ArenaHeroPickApiResponse.self)
    }

    @available(macOS 10.15.0, *)
    static func getArenaCardPickStats(parameters: ArenaCardPickParams) async -> ArenaCardPickApiResponse? {
        return await postArena(url: HSReplay.arenaCardPickUrl, parameters: parameters, as: ArenaCardPickApiResponse.self)
    }

    @available(macOS 10.15.0, *)
    static func scoreArenaDeck(parameters: ArenaScoreDeckParams) async -> ArenaCardStats? {
        return await postArena(url: HSReplay.arenaScoreDeckUrl, parameters: parameters, as: ArenaCardStats.self)
    }

    @available(macOS 10.15.0, *)
    static func getArenaTrialStatus(hi: Int64, lo: Int64) async -> ArenaTrialStatus? {
        return await getArenaJson(url: "\(HSReplay.arenaTrialsUrl)?account_hi=\(hi)&account_lo=\(lo)", as: ArenaTrialStatus.self)
    }

    @available(macOS 10.15.0, *)
    static func getArenasmithStatus() async -> ArenasmithStatus? {
        return await getArenaJson(url: HSReplay.arenasmithStatusUrl, as: ArenasmithStatus.self)
    }

    /// The signed-in route, HSReplay-API-Client's `OAuthClient.GetArenaPackages()`.
    ///
    /// The account is the whole request here - the packages are the ones the server
    /// has for that player's current run - so this overload takes no parameters.
    @available(macOS 10.15.0, *)
    static func getArenaPackages() async -> ArenaPackages? {
        return await withCheckedContinuation { continuation in
            startAuthorizedRequest(HSReplay.arenaCardPackagesUrl, method: .GET, parameters: [:], completionHandler: { result in
                switch result {
                case .success(let response):
                    let parsed: ArenaPackages? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: parsed)
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                }
            })
        }
    }

    /// The free-trial route, HSReplay-API-Client's `HsReplayClient.GetArenaPackages(params)`:
    /// unauthenticated, and identified by the drafted deck instead. The caller is
    /// responsible for checking the deck is registered for a trial - see
    /// `ArenaPackagesManager.fetchPackages()`.
    @available(macOS 10.15.0, *)
    static func getArenaPackages(deckId: Int64, accountLo: Int64, playerRegion: Int) async -> ArenaPackages? {
        let url = "\(HSReplay.arenaCardPackagesFreeUrl)?deck_id=\(deckId)&account_lo=\(accountLo)&player_region=\(playerRegion)"
        return await getArenaJson(url: url, as: ArenaPackages.self)
    }

    // Ports HSReplay-API-Client's two GetDiscoverPoolKeywords overloads: the premium path goes
    // through OAuth (OAuthClient.DataQueries), the trial path sends an X-Trial-Token header
    // (HsReplayClient). Both return the same keyword -> card-ids map.
    @available(macOS 10.15.0, *)
    static func getDiscoverPoolKeywords() async -> [String: [String]]? {
        return await withCheckedContinuation { continuation in
            startAuthorizedRequest(HSReplay.discoverPoolKeywordsUrl, method: .GET, parameters: [:], completionHandler: { result in
                switch result {
                case .success(let response):
                    let keywords: [String: [String]]? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: keywords)
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                }
            })
        }
    }

    @available(macOS 10.15.0, *)
    static func getDiscoverPoolKeywords(token: String?) async -> [String: [String]]? {
        guard let token = token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let http = Http(url: HSReplay.discoverPoolKeywordsUrl)
            _ = http.getPromise(method: .get, headers: ["X-Trial-Token": token]).done { data in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                let keywords: [String: [String]]? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: keywords)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    static func getHeroGuides(gameLanguage: String) async -> BattlegroundsHeroGuidesData? {
        return await withCheckedContinuation { continuation in
            let http = Http(url: "\(HSReplay.heroGuidesUrl)?game_language=\(gameLanguage)")
            _ = http.getPromise(method: .get).done { data in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                let guides: BattlegroundsHeroGuidesData? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: guides)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    static func getTrinketGuides(gameLanguage: String) async -> BattlegroundsTrinketGuidesData? {
        return await withCheckedContinuation { continuation in
            let http = Http(url: "\(HSReplay.trinketGuidesUrl)?game_language=\(gameLanguage)")
            _ = http.getPromise(method: .get).done { data in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                let guides: BattlegroundsTrinketGuidesData? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: guides)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    static func getAnomalyGuides(gameLanguage: String) async -> BattlegroundsAnomalyGuidesData? {
        return await withCheckedContinuation { continuation in
            let http = Http(url: "\(HSReplay.anomalyGuidesUrl)?game_language=\(gameLanguage)")
            _ = http.getPromise(method: .get).done { data in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                let guides: BattlegroundsAnomalyGuidesData? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: guides)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    static func getQuestGuides(gameLanguage: String) async -> BattlegroundsQuestGuidesData? {
        return await withCheckedContinuation { continuation in
            let http = Http(url: "\(HSReplay.questGuidesUrl)?game_language=\(gameLanguage)")
            _ = http.getPromise(method: .get).done { data in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                let guides: BattlegroundsQuestGuidesData? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: guides)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }

    @available(macOS 10.15.0, *)
    static func getTier7TrinketPickStats(parameters: BattlegroundsTrinketPickParams) async -> BattlegroundsTrinketPickStats? {
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending trinket pick request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            startAuthorizedRequest("\(HSReplay.tier7TrinketPickStats)", method: .POST, headers: ["Content-Type": "application/json"], body: body, completionHandler: { result in
                switch result {
                case .success(let response):
                    logger.debug("Response: \(String(data: response.data, encoding: .utf8) ?? "FAILED")")
                    let bqs: BattlegroundsTrinketPickStats? = parseResponse(data: response.data, defaultValue: nil)
                    continuation.resume(returning: bqs)
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: nil)
                    return
                }
            })
        }
    }

    @available(macOS 10.15.0, *)
    static func getTier7TrinketPickStats(token: String?, parameters: BattlegroundsTrinketPickParams) async -> BattlegroundsTrinketPickStats? {
        guard let token = token else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let encoder = JSONEncoder()
            var body: Data?
            do {
                body = try encoder.encode(parameters)
                if let body = body {
                    logger.debug("Sending trinket pick request: \(String(data: body, encoding: .utf8) ?? "ERROR")")
                }
            } catch {
                logger.error(error)
            }
            guard let body = body else {
                continuation.resume(returning: nil)
                return
            }
            let http = Http(url: "\(HSReplay.tier7TrinketPickStats)")
            _ = http.uploadPromise(method: .post, headers: ["Content-Type": "application/json", "X-Trial-Token": token], data: body).done { response in
                guard let data = response as? Data else {
                    continuation.resume(returning: nil)
                    return
                }
                logger.debug("Response: \(String(data: data, encoding: .utf8) ?? "FAILED")")
                let bqs: BattlegroundsTrinketPickStats? = parseResponse(data: data, defaultValue: nil)
                continuation.resume(returning: bqs)
            }.catch { error in
                logger.error(error)
                continuation.resume(returning: nil)
            }
        }
    }}

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
    }
    
    @available(macOS 10.15.0, *)
    static func getCompsGuides(gameLanguage: String) async -> [BattlegroundsCompGuide] {
        return await withCheckedContinuation { continuation in
            startAuthorizedRequest("\(HSReplay.battlegroundsCompGuides)?game_language=\(gameLanguage)", method: .GET, completionHandler: { result in
                switch result {
                case .success(let response):
                    logger.debug("Response: \(String(data: response.data, encoding: .utf8) ?? "FAILED")")
                    if let bqs: [BattlegroundsCompGuide] = parseResponse(data: response.data, defaultValue: nil) {
                        continuation.resume(returning: bqs)
                    } else {
                        continuation.resume(returning: [BattlegroundsCompGuide]())
                    }
                    return
                case .failure(let error):
                    logger.error(error)
                    continuation.resume(returning: [BattlegroundsCompGuide]())
                    return
                }
            })
        }
    }

}

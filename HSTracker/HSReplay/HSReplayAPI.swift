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
}

class HSReplayAPI {
    static let apiKey = "f1c6965c-f5ee-43cb-ab42-768f23dd35e8"
    static let oAuthClientKey = "pk_live_IB0TiMMT8qrwIJ4G6eVHYaAi"//"pk_test_AUThiV1Ex9nKCbHSFchv7ybX"
    static let oAuthClientSecret = "sk_live_20180308078UceCXo8qmoG72ExZxeqOW"//"sk_test_20180308Z5qWO7yiYpqi8qAmQY0PDzcJ"
    private static let defaultHeaders = ["Accept": "application/json", "Content-Type": "application/json"]

    static let tokenRenewalHandler: OAuthSwift.TokenRenewedHandler = { result in
        switch result {
        case .success(let credential):
            Settings.hsReplayOAuthToken = credential.oauthToken
            Settings.hsReplayOAuthRefreshToken = credential.oauthRefreshToken
        case .failure(let error):
            logger.error("Failed to renew token: \(error)")
        }
    }
    
    static let oauthswift = {
        return OAuth2Swift(
            consumerKey: oAuthClientKey,
            consumerSecret: oAuthClientSecret,
            authorizeUrl: HSReplay.oAuthAuthorizeUrl,
            accessTokenUrl: HSReplay.oAuthTokenUrl,
            responseType: "code"
        )
    }()

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

                    handle()
                case .failure(let error):
                    // TODO: Better error handling
                    logger.info("HSReplay: OAuth failed \(error)")
                }
            }
        )
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

    static func claimBattleTag(complete: @escaping () -> Void, failed: @escaping () -> Void ) {
        guard let accountId = MirrorHelper.getAccountId(), let battleTag = MirrorHelper.getBattleTag() else {
            failed()
            return
        }
        oauthswift.startAuthorizedRequest("\(HSReplay.claimBattleTagUrl)/\(accountId.hi)/\(accountId.lo)/", method: .POST,
            parameters: ["battletag": battleTag], headers: defaultHeaders,
            onTokenRenewal: tokenRenewalHandler,
            completionHandler: { result in
                switch result {
                case .success:
                    complete()
                case .failure(let error):
                    logger.error(error)
                    failed()
                }
            }
        )
    }

    static func claimAccount() {
        guard let token = Settings.hsReplayUploadToken else {
            logger.error("Authorization token not set yet")
            return
        }
        
        logger.info("Getting claim url...")

        let http = Http(url: HSReplay.claimAccountUrl)
        http.json(method: .post,
                  headers: [
                    "X-Api-Key": apiKey,
                    "Authorization": "Token \(token)"]) { json in
            if let json = json as? [String: Any],
                let url = json["url"] as? String {
                logger.info("Opening browser to claim account...")

                let url = URL(string: "\(HSReplay.baseUrl)\(url)")
                NSWorkspace.shared.open(url!)
            } else {

            }
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
    
    private static func getUploadCollectionToken() -> Promise<String> {
        return Promise<String> { seal in
            guard let accountId = MirrorHelper.getAccountId() else {
                seal.reject(HSReplayError.missingAccount)
                return
            }
            oauthswift.startAuthorizedRequest("\(HSReplay.collectionTokensUrl)", method: .GET, parameters: ["account_hi": accountId.hi, "account_lo": accountId.lo], headers: defaultHeaders, onTokenRenewal: tokenRenewalHandler,
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
    
    static func uploadCollection(collectionData: UploadCollectionData) -> Promise<CollectionUploadResult> {
        return Promise<CollectionUploadResult> { seal in
            
            getUploadCollectionToken().done { url in
                let upload = Http(url: url)
                let enc = JSONEncoder()
                if let data = try? enc.encode(collectionData) {
                    upload.uploadPromise(method: .put, headers: [ "Content-Type": "application/json" ], data: data).done { data in
                        if data != nil {
                            seal.fulfill(.successful)
                        }
                    }.catch { error in
                        seal.fulfill(.failed(error: error.localizedDescription))
                    }
                } else {
                    seal.fulfill(.failed(error: "JSON convertion failed"))
                }
            }.catch { error in
                logger.error("HSReplay: Collection upload error \(error)")
                seal.fulfill(.failed(error: error.localizedDescription))
            }
        }
    }
}

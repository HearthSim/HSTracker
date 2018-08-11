//
//  HSReplayAPI.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import OAuthSwift

class HSReplayAPI {
    static let apiKey = "f1c6965c-f5ee-43cb-ab42-768f23dd35e8"
    private static let oAuthClientKey = "pk_test_AUThiV1Ex9nKCbHSFchv7ybX"
    private static let oAuthClientSecret = "sk_test_20180308Z5qWO7yiYpqi8qAmQY0PDzcJ"
    
    static let oauthswift = {
        return OAuth2Swift(
            consumerKey: oAuthClientKey,
            consumerSecret: oAuthClientSecret,
            authorizeUrl: HSReplay.oAuthAuthorizeUrl,
            accessTokenUrl: HSReplay.oAuthTokenUrl,
            responseType: "code"
        )
    }()
    
    static func oAuthAuthorize() {
        _ = oauthswift.authorize(
            withCallbackURL: URL(string: "hstracker://oauth-callback/hsreplay")!,
            scope: "fullaccess",
            state: "HSREPLAY",
            success: { credential, _, _ in
                Settings.hsReplayOAuthToken = credential.oauthToken
                Settings.hsReplayOAuthRefreshToken = credential.oauthRefreshToken
                getUploadCollectionToken { token in
                    print(token)
                }
            },
            failure: { error in
                // TODO: Error handling
                print(error.localizedDescription)
            })
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
                        // TODO error handling
                    }
        }
    }

    static func getUploadCollectionToken(handle: @escaping (String) -> Void) {
        guard let accountId = MirrorHelper.getAccountId() else {
            return
        }
        if let token = Settings.hsReplayUploadCollectionToken {
            handle(token)
            return
        }
        oauthswift.client.get(HSReplay.collectionTokensUrl, parameters: ["account_hi": accountId.hi, "account_lo": accountId.lo], headers: ["Accept": "application/json"], success: { response in
            if let json = response.string {
                print(json)
            }
        }, failure: { error in
            print(error)
        })
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
}

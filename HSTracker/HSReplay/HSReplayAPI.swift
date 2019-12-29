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
    private static let oAuthClientKey = "pk_live_IB0TiMMT8qrwIJ4G6eVHYaAi"//"pk_test_AUThiV1Ex9nKCbHSFchv7ybX"
    private static let oAuthClientSecret = "sk_live_20180308078UceCXo8qmoG72ExZxeqOW"//"sk_test_20180308Z5qWO7yiYpqi8qAmQY0PDzcJ"
    private static let defaultHeaders = ["Accept": "application/json", "Content-Type": "application/json"]

    static let tokenRenewalHandler: OAuthSwift.TokenRenewedHandler = { credential in
        Settings.hsReplayOAuthToken = credential.oauthToken
        Settings.hsReplayOAuthRefreshToken = credential.oauthRefreshToken
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
            success: { credential, _, _ in
                logger.info("HSReplay: OAuth succeeded")
                Settings.hsReplayOAuthToken = credential.oauthToken
                Settings.hsReplayOAuthRefreshToken = credential.oauthRefreshToken
                AppDelegate.instance().coreManager.exposedHsReplay.setTokens(
                    accessToken: credential.oauthToken,
                    refreshToken: credential.oauthRefreshToken
                )
                handle()
            },
            failure: { error in
                // TODO: Better error handling
                logger.info("HSReplay: OAuth failed \(error)")
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

    static func claimBattleTag(complete: @escaping () -> Void, failed: @escaping () -> Void ) {
        guard let accountId = MirrorHelper.getAccountId(), let battleTag = MirrorHelper.getBattleTag() else {
            failed()
            return
        }
        oauthswift.startAuthorizedRequest("\(HSReplay.claimBattleTagUrl)/\(accountId.hi)/\(accountId.lo)/", method: .POST,
            parameters: ["battletag": battleTag], headers: defaultHeaders,
            onTokenRenewal: tokenRenewalHandler, success: { response in

            complete()
        }, failure: { error in
            logger.error(error)
            failed()
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

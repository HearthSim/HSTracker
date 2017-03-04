//
//  HSReplayAPI.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class HSReplayAPI {
    static let apiKey = "f1c6965c-f5ee-43cb-ab42-768f23dd35e8"

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
                        Log.info?.message("HSReplay : Obtained new upload-token")
                        Settings.hsReplayUploadToken = key
                        handle(key)
                    } else {
                        // TODO error handling
                    }
        }
    }

    static func claimAccount() {
        guard let token = Settings.hsReplayUploadToken else {
            Log.error?.message("Authorization token not set yet")
            return
        }
        
        Log.info?.message("Getting claim url...")

        let http = Http(url: HSReplay.claimAccountUrl)
        http.json(method: .post,
                  headers: [
                    "X-Api-Key": apiKey,
                    "Authorization": "Token \(token)"]) { json in
            if let json = json as? [String: Any],
                let url = json["url"] as? String {
                Log.info?.message("Opening browser to claim account...")

                let url = URL(string: "\(HSReplay.baseUrl)\(url)")
                NSWorkspace.shared().open(url!)
            } else {

            }
        }
    }

    static func updateAccountStatus(handle: @escaping (Bool) -> Void) {
        guard let token = Settings.hsReplayUploadToken else {
            Log.error?.message("Authorization token not set yet")
            handle(false)
            return
        }
        Log.info?.message("Checking account status...")

        let http = Http(url: "\(HSReplay.tokensUrl)/\(token)/")
        http.json(method: .get,
                  headers: [
                    "X-Api-Key": apiKey,
                    "Authorization": "Token \(token)"
        ]) { json in
            print("\(json)")
            if let json = json as? [String: Any],
                let user = json["user"] as? [String: Any] {
                if let username = user["username"] as? String {
                    Settings.hsReplayUsername = username
                }
                Settings.hsReplayId = user["id"] as? Int ?? 0
                Log.info?.message("id=\(Settings.hsReplayId), "
                    + "Username=\(Settings.hsReplayUsername)")
                handle(true)
            } else {
                handle(false)
            }
        }
    }
}

//
//  ArenaHelperSync.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 10/04/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class ArenaHelperSync {
    private static var latestVersion: String?
    private static var url = "https://raw.githubusercontent.com/rembound/Arena-Helper/master/data"

    static func checkTierList(splashscreen: Splashscreen) {
        DispatchQueue.main.async {
            splashscreen.display(NSLocalizedString("Loading Arena card tiers", comment: ""),
                                 indeterminate: true)
        }

        let url = "\(self.url)/version.json"
        let semaphore = DispatchSemaphore(value: 0)
        let http = Http(url: url)
        http.json(method: .get) { json in
            if let json: [String: String] = json as? [String: String] {
                self.latestVersion = json["tierlist"]
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    static func isOutdated() -> Bool {
        guard let latest = self.latestVersion else { return true }

        guard let actual = UserDefaults.standard.string(forKey: "arena_helper_version") else {
            return true
        }

        Log.info?.message("Latest card tiers version: \(latest), HSTracker build: \(actual)")

        return latest.compare(actual, options: .numeric) == .orderedDescending
    }

    static func jsonFilesAreValid() -> Bool {
        let jsonFile = Paths.arenaJson.appendingPathComponent("cardtier.json")
        guard let jsonData = try? Data(contentsOf: jsonFile) else {
            Log.error?.message("\(jsonFile) is not a valid file")
            return false
        }
        guard let _ = try? JSONSerialization
            .jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                Log.error?.message("\(jsonFile) is not a valid file")
                return false
        }
        return true
    }

    static func downloadTierList(splashscreen: Splashscreen) {
        guard let latest = self.latestVersion else { return }

        DispatchQueue.main.async {
            splashscreen.increment(String(format:
                NSLocalizedString("Downloading %@", comment: ""),
                                          "cardtier.json"))
        }

        let semaphore = DispatchSemaphore(value: 0)
        let cardTierUrl = "\(self.url)/cardtier.json"

        var hasError = false

        if let url = URL(string: cardTierUrl) {
            URLSession.shared
                .dataTask(with: url) { data, response, error in
                    if let response = response as? HTTPURLResponse,
                        response.statusCode != 200 {
                        hasError = true
                        Log.error?.message("Can not download \(cardTierUrl) "
                            + "-> statusCode : \(response.statusCode)")
                    } else if let error = error {
                        hasError = true
                        Log.error?.message("\(error)")
                    } else if let data = data {
                        let dir = Paths.arenaJson
                        let dest = dir.appendingPathComponent("cardtier.json")
                        Log.info?.message("Saving \(cardTierUrl) to \(dest)")
                        try? data.write(to: dest, options: [.atomic])
                    }

                    semaphore.signal()
                }.resume()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        if !hasError {
            UserDefaults.standard.set(latest, forKey: "arena_helper_version")
        }
    }
}

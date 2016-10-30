//
//  BuildDate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct BuildDates {

    private static var knownBuildDates: [BuildDate] = []
    
    struct BuildDate {
        let date: Date
        let build: Int
    }

    static func loadBuilds(splashscreen: Splashscreen) {
        DispatchQueue.main.async {
            splashscreen.display(NSLocalizedString("Loading Hearthstone builds", comment: ""),
                                 indeterminate: true)
        }

        let url = "https://raw.githubusercontent.com/HearthSim/HSTracker/master/hs-build-dates.json"
        let semaphore = DispatchSemaphore(value: 0)
        let http = Http(url: url)
        http.json(method: .get) { json in
            if let json: [String: String] = json as? [String: String] {
                for (build, date) in json {
                    if let nsdate = Date.NSDateFromString(date,
                                                            inFormat: "yyyy-MM-dd"),
                        let intBuild = Int(build) {
                        let buildDate = BuildDate(date: nsdate, build: intBuild)
                        knownBuildDates.append(buildDate)
                    }
                }
            }
            semaphore.signal()
        }
        let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    static func isOutdated() -> Bool {
        guard let latestBuild = self.latestBuild else { return true }

        let actual = UserDefaults.standard.integer(forKey: "hs_latest_build")
        Log.info?.message("Latest build : \(latestBuild.build), actual is \(actual)")

        return actual != latestBuild.build
    }

    static func downloadCards(splashscreen: Splashscreen) {
        DispatchQueue.main.async {
            splashscreen.display(NSLocalizedString("Download Hearthstone cards", comment: ""),
                                 total: Double(Language.hsLanguages.count))
        }


        guard let latestBuild = self.latestBuild else { return }
        let build = latestBuild.build
        for locale in Language.hsLanguages {
            DispatchQueue.main.async {
                splashscreen.increment(String(format:
                    NSLocalizedString("Downloading %@", comment: ""),
                                              "cardsDB.\(locale).json"))
            }

            let semaphore = DispatchSemaphore(value: 0)
            let cardUrl = "https://api.hearthstonejson.com/v1/\(build)/\(locale)/cards.json"

            if let url = URL(string: cardUrl) {
                URLSession.shared
                    .dataTask(with: url, completionHandler: {
                        (data, response, error) in
                        if let data = data {
                            let dir = Paths.cardJson
                            let dest = dir.appendingPathComponent("cardsDB.\(locale).json")
                            Log.info?.message("Saving \(cardUrl) to \(dest)")
                            try? data.write(to: dest, options: [.atomic])
                        } else if let error = error {
                            Log.error?.message("\(error)")
                        }

                        semaphore.signal()
                    }) .resume()
            }
            let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }

        UserDefaults.standard.set(build, forKey: "hs_latest_build")
    }

    static func get(byDate date: Date) -> BuildDate? {
        for buildDate in knownBuildDates.sorted(by: {
            $0.date > $1.date
        }) {
            if date >= buildDate.date {
                Log.info?.message("Getting build from date : \(buildDate)")
                return buildDate
            }
        }
        return nil
    }

    static func getByProductDb() -> BuildDate? {
        let path = Settings.instance.hearthstoneLogPath
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: "\(path)/.product.db")) else {
            return nil
        }
        let bytes = UnsafeBufferPointer(start: (data as NSData)
            .bytes.bindMemory(to: UInt8.self,
                              capacity: data.count),
                                        count: data.count)
        guard let content = String(bytes: bytes, encoding: String.Encoding.ascii) else {
            return nil
        }
        let matches = content.matches("(\\d+.\\d.\\d.(\\d+))")
        guard let match = matches.last?.value, matches.count > 0 else {
            return nil
        }
        guard let build = Int(match) else { return nil }

        let buildDate = BuildDate(date: Date(), build: build)
        Log.info?.message("Getting build from product DB : \(buildDate)")
        return buildDate
    }

    private static var latestBuild: BuildDate? {
        return knownBuildDates.sorted {
            $0.date < $1.date
        }.reversed().first
    }
}

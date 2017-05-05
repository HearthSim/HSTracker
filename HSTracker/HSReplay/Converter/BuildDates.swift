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
    
    public static let dateStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

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
                    if let dateTime = BuildDates.dateStringFormatter.date(from: date),
                        let intBuild = Int(build) {
                        let buildDate = BuildDate(date: dateTime, build: intBuild)
                        knownBuildDates.append(buildDate)
                    }
                }
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    static func isOutdated() -> Bool {
        guard let latestBuild = self.latestBuild else { return true }

        let actual = UserDefaults.standard.integer(forKey: "hs_latest_build")
        var message = "Latest build: \(latestBuild.build), HSTracker build: \(actual)"
        let productId = getByProductDb()
        if let productId = productId {
            message += ", Hearthstone productId: \(productId.build)"
        }
        Log.info?.message(message)

        return actual < max(latestBuild.build, productId?.build ?? 0)
    }

    static func downloadCards(splashscreen: Splashscreen) {
        DispatchQueue.main.async {
            splashscreen.display(NSLocalizedString("Download Hearthstone cards", comment: ""),
                                 total: Double(Array(Language.Hearthstone.cases()).count))
        }

        guard let latestBuild = self.latestBuild else { return }
        let build = latestBuild.build

        var hasError = false
        for locale in Language.Hearthstone.cases() {
            DispatchQueue.main.async {
                splashscreen.increment(String(format:
                    NSLocalizedString("Downloading %@", comment: ""),
                                              "cardsDB.\(locale.rawValue).json"))
            }

            let semaphore = DispatchSemaphore(value: 0)
            let cardUrl = "https://api.hearthstonejson.com/v1/\(build)/\(locale.rawValue)/cards.json"

            if let url = URL(string: cardUrl) {
                URLSession.shared
                    .dataTask(with: url) { data, response, error in
                        if let response = response as? HTTPURLResponse,
                            response.statusCode != 200 {
                            hasError = true
                            Log.error?.message("Can not download \(cardUrl) "
                                + "-> statusCode : \(response.statusCode)")
                        } else if let error = error {
                            hasError = true
                            Log.error?.message("\(error)")
                        } else if let data = data {
                            let dir = Paths.cardJson
                            let dest = dir.appendingPathComponent("cardsDB.\(locale).json")
                            Log.info?.message("Saving \(cardUrl) to \(dest)")
                            try? data.write(to: dest, options: [.atomic])
                        }

                        semaphore.signal()
                    }.resume()
            }
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }

        if !hasError {
            UserDefaults.standard.set(build, forKey: "hs_latest_build")
        }
    }

    static func get(byDate date: Date) -> BuildDate? {
        for buildDate in knownBuildDates.sorted(by: {
            $0.date > $1.date
        }) where date >= buildDate.date {
            Log.info?.message("Getting build from date : \(buildDate)")
            return buildDate
        }
        return nil
    }

    static func getByProductDb() -> BuildDate? {
        let path = Settings.hearthstonePath
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
        let matches = content.matches("(\\d+\\.\\d\\.\\d\\.(\\d+))")
        guard let match = matches.last?.value, matches.count > 0 else {
            return nil
        }
        guard let build = Int(match) else { return nil }

        let buildDate = BuildDate(date: Date(), build: build)
        Log.info?.message("Getting build from product DB : \(buildDate)")
        knownBuildDates.append(buildDate)
        return buildDate
    }

    static var latestBuild: BuildDate? {
        return knownBuildDates.sorted {
            $0.date < $1.date
        }.reversed().first
    }
}

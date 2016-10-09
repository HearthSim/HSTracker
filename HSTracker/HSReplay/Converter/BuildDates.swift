//
//  BuildDate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Alamofire
import Unbox
import CleanroomLogger

struct BuildDates {

    private static var knownBuildDates: [BuildDate] = []
    
    struct BuildDate {
        let date: NSDate
        let build: Int
    }

    static func loadBuilds(splashscreen: Splashscreen) {
        dispatch_async(dispatch_get_main_queue()) {
            splashscreen.display(NSLocalizedString("Loading Hearthstone builds", comment: ""),
                                 indeterminate: true)
        }

        let f = "https://raw.githubusercontent.com/HearthSim/HSTracker/master/hs-build-dates.json"
        if let url = NSURL(string: f) {

            let semaphore = dispatch_semaphore_create(0)
            NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
                if let data = data {
                    do {
                        if let json: [String: String] = try NSJSONSerialization
                            .JSONObjectWithData(data,
                                                options: .AllowFragments) as? [String: String] {
                            for (build, date) in json {
                                if let nsdate = NSDate.NSDateFromString(date,
                                                                        inFormat: "yyyy-MM-dd"),
                                    intBuild = Int(build) {
                                    let buildDate = BuildDate(date: nsdate, build: intBuild)
                                    knownBuildDates.append(buildDate)
                                }
                            }
                        }
                    } catch let error {
                        Log.error?.message("\(error)")
                    }
                } else if let error = error {
                    Log.error?.message("\(error)")
                }
                dispatch_semaphore_signal(semaphore)
            }.resume()

            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }

    static func isOutdated() -> Bool {
        guard let latestBuild = self.latestBuild else { return true }

        let actual = NSUserDefaults.standardUserDefaults().integerForKey("hs_latest_build")
        Log.info?.message("Latest build : \(latestBuild.build), actual is \(actual)")

        return actual != latestBuild.build
    }

    static func downloadCards(splashscreen: Splashscreen) {
        dispatch_async(dispatch_get_main_queue()) {
            splashscreen.display(NSLocalizedString("Download Hearthstone cards", comment: ""),
                                 total: Double(Language.hsLanguages.count))
        }

        if let latestBuild = self.latestBuild,
            destination = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory,
                                                                 .UserDomainMask, true).first {

            let path = "\(destination)/HSTracker/json"
            do {
                try NSFileManager.defaultManager()
                    .createDirectoryAtPath(path,
                                           withIntermediateDirectories: true,
                                           attributes: nil)
            } catch { }

            let build = latestBuild.build
            for locale in Language.hsLanguages {
                dispatch_async(dispatch_get_main_queue()) {
                    splashscreen.increment(String(format:
                        NSLocalizedString("Downloading %@", comment: ""),
                        "cardsDB.\(locale).json"))
                }

                let semaphore = dispatch_semaphore_create(0)
                let cardUrl = "https://api.hearthstonejson.com/v1/\(build)/\(locale)/cards.json"

                if let url = NSURL(string: cardUrl) {
                    NSURLSession.sharedSession()
                        .dataTaskWithURL(url) { (data, response, error) in
                            if let data = data {
                                Log.info?.message("Saving \(cardUrl) to "
                                    + "\(path)/cardsDB.\(locale).json")
                                data.writeToFile("\(path)/cardsDB.\(locale).json",
                                                 atomically: true)
                            } else if let error = error {
                                Log.error?.message("\(error)")
                            }

                            dispatch_semaphore_signal(semaphore)
                        }.resume()
                }
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }

            NSUserDefaults.standardUserDefaults().setInteger(build, forKey: "hs_latest_build")
        }
    }

    static func getByDate(date: NSDate) -> BuildDate? {
        for buildDate in knownBuildDates {
            if date >= buildDate.date {
                Log.info?.message("Getting build from date : \(buildDate)")
                return buildDate
            }
        }
        return nil
    }

    static func getByProductDb() -> BuildDate? {
        let path = Settings.instance.hearthstoneLogPath
        guard let data = NSData(contentsOfFile: "\(path)/.product.db") else {
            return nil
        }
        let bytes = UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes),
                                        count: data.length)
        guard let content = String(bytes: bytes, encoding: NSASCIIStringEncoding) else {
            return nil
        }
        let matches = content.matches("(\\d+.\\d.\\d.(\\d+))")
        guard let match = matches.last?.value where matches.count > 0 else {
            return nil
        }
        guard let build = Int(match) else { return nil }

        let buildDate = BuildDate(date: NSDate(), build: build)
        Log.info?.message("Getting build from product DB : \(buildDate)")
        return buildDate
    }

    private static var latestBuild: BuildDate? {
        return knownBuildDates.sort {
            $0.date < $1.date
        }.reverse().first
    }
}
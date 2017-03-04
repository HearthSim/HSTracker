//
//  Version.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Version {
    static let buildName: String = {
        if let info = Bundle.main.infoDictionary {
            let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
            let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
            let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
            let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

            let osNameVersion: String = {
                let version = ProcessInfo.processInfo.operatingSystemVersion
                let versionString = "\(version.majorVersion)"
                    + ".\(version.minorVersion)"
                    + ".\(version.patchVersion)"

                return "macOS \(versionString)"
            }()

            let hsLocale: String = Settings.hearthstoneLanguage ?? ""
            let htLocale = Settings.hsTrackerLanguage ?? ""

            return "\(executable)/\(appVersion).\(appBuild); "
                + "(\(hsLocale);\(htLocale);\(osNameVersion))"
        }
        return "HSTracker"
    }()
}

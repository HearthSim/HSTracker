//
//  Language.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 4/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Language {
    enum Hearthstone: String, CaseIterable {
        case deDE, enUS, esES, esMX, frFR, itIT, koKR, plPL, ptBR, ruRU, zhCN, zhTW, jaJP, thTH

        var localeValue: Locale? {
            return Locale(identifier: self.rawValue.replace("(.)(\\p{Upper})", with: "$1_$2"))
        }

        var localizedString: String {
            guard let locale = self.localeValue,
                let localized = locale.localizedString(forIdentifier: locale.identifier) else {
                    return self.rawValue
            }
            return localized.capitalized(with: locale)
        }
    }

    enum HSTracker: String, CaseIterable {
        case de, en, fr, it, pt_br = "pt-br", zh_cn = "zh-cn", es, ko, ru, zh_tw = "zh-tw"

        var localeValue: Locale? {
            return Locale(identifier: self.rawValue)
        }

        var localizedString: String {
            guard let locale = self.localeValue,
                let localized = locale.localizedString(forIdentifier: locale.identifier) else {
                    return self.rawValue
            }
            return localized.capitalized(with: locale)
        }
    }
}

extension Language {
    /// The locale to format numbers and dates with.
    ///
    /// `Locale.current` mixes the language HSTracker was told to display in with the region
    /// configured in macOS, so a French UI on a US system would still format numbers the US way.
    /// Formatting against the selected language instead keeps the overlay consistent with the
    /// text around it.
    static var culture: Locale {
        return Settings.hsTrackerLanguage?.localeValue ?? Locale.current
    }
}

//
//  Language.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 4/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RegexUtil

struct Language {
    enum Hearthstone: String {
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

        static func allValues() -> [Hearthstone] {
            return [.deDE, .enUS, .esES, .esMX, .frFR,
                    .itIT, .koKR, .plPL, .ptBR, .ruRU,
                    .zhCN, .zhTW, .jaJP, .thTH]
        }
    }

    enum HSTracker: String {
        case de, en, fr, it, pt_br = "pt-br", zh_cn = "zh-cn", es, ko

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

        static func allValues() -> [HSTracker] {
            return [.de, .en, .fr, .it, .pt_br, .zh_cn, .es, .ko]
        }
    }
}

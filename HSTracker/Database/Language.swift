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
        case de, en, fr, it, pt_br = "pt-br", zh_cn = "zh-cn", es, ko, zh_tw = "zh-tw"

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

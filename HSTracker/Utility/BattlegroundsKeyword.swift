//
//  BattlegroundsKeyword.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/19/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's BattlegroundsKeyword.cs. There, the type is an abstract record
// with two concrete cases:
//
//   MentionedKeyword - a keyword the client never exposes as a tag, recognized
//                      purely by its mention in the card text.
//   TagKeyword       - a keyword that *does* have a GameTag, matched by that tag
//                      OR by the same text mention.
//
// Swift collapses those into one value type with an optional `mechanic`: a nil
// mechanic is a MentionedKeyword, a non-nil one is a TagKeyword. Being a struct
// also gives the record's value equality for free, which the view model relies
// on to compare `activeKeyword == keyword`.
struct BattlegroundsKeyword: Hashable, Identifiable {
    /// Localization key for the displayed name, matching HDT's LocKey.
    let locKey: String

    /// The English name. HDT reads this back out of its own loc table with
    /// LocUtil.GetEnglish so the filter never depends on the language the app
    /// runs in; HSTracker has no English-invariant lookup over
    /// Localizable.strings, so the invariant string is carried here directly.
    let englishName: String

    /// Database.mechanics name for this keyword's GameTag, or nil when the
    /// client doesn't tag it (HDT's MentionedKeyword).
    let mechanic: String?

    var id: String { locKey }

    /// Displayed name, localized. Falls back to the English name rather than
    /// the raw key, since String.localizedString returns the key on a miss and
    /// these keys ("GameTag_BGAvenge") are not presentable.
    var name: String {
        let localized = String.localizedString(locKey, comment: "")
        return localized == locKey ? englishName : localized
    }

    /// Mirrors TagKeyword.Matches: the tag if there is one, else/or the English
    /// text mention. The empty-mention guard matters - without it a missing
    /// string would become a `contains("")` that matches every card.
    ///
    /// The text comparison is case-insensitive, where HDT's string.Contains is
    /// ordinal. Two of its own display strings capitalise differently from the
    /// card text they are matched against - "End Of Turn" and "Start Of Combat"
    /// versus "...Start of Combat:" on the cards - so an exact comparison
    /// silently matches nothing for those, leaving only their tag to carry them.
    func matches(_ card: Card) -> Bool {
        if let mechanic, card.mechanics.contains(mechanic) {
            return true
        }
        guard !englishName.isEmpty else { return false }
        return card.enText.range(of: englishName, options: .caseInsensitive) != nil
    }
}

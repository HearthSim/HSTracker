//
//  BattlegroundsMinionsViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// What the "Card Types" filter can be set to. HDT overloads its Race enum for
// this, casting the sentinels (Race)(-1) and (Race)(-2) alongside real races;
// Swift's Race is a String enum with no such room, so the three cases are
// explicit here instead.
enum BattlegroundsMinionType: Hashable {
    case race(Race)
    case spells    // HDT's (Race)(-1)
    case buddies   // HDT's (Race)(-2)

    // HDT's BattlegroundsMinionType.TribeImages, mapped onto HSTracker's
    // `tribe_<name>` image sets. Race.invalid is "Other".
    var iconName: String {
        switch self {
        case .spells: return "tribe_spell"
        case .buddies: return "tribe_buddy"
        case .race(let race):
            let name = race == .invalid ? "tribe_other" : "tribe_\(race.rawValue)"
            // Mirrors HDT's Tribe getter, which falls back to the Beast icon for
            // any race missing from TribeImages. Only the ten BG types plus
            // Other/Spells/Buddies ship an image, and Db.races is built from
            // whatever the card data happens to say, so an unrecognized race
            // would otherwise render as an empty circle.
            return NSImage(named: name) != nil ? name : "tribe_beast"
        }
    }

    // English display names, taken from HDT-Localization's Strings.resx (the
    // Race_* keys). Used as the fallback because String.localizedString hands
    // back the key itself on a miss, and HSTracker's Localizable.strings has no
    // entry for most race names - so without these the UI renders raw keys
    // ("mechanical") instead of names ("Mech").
    //
    // Note Race_Mechanical is "Mech", not "Mechanical", and Race_INVALID is
    // "No Type" - HSTracker used to call that one "neutral", which is a
    // different concept (see EditDeck's class chooser, which keeps that key).
    private static let englishRaceNames: [Race: String] = [
        .beast: "Beast", .demon: "Demon", .dragon: "Dragon", .elemental: "Elemental",
        .mechanical: "Mech", .murloc: "Murloc", .naga: "Naga", .pirate: "Pirate",
        .quilboar: "Quilboar", .undead: "Undead", .totem: "Totem", .all: "All"
    ]

    private static func localized(_ key: String, fallback: String) -> String {
        let value = String.localizedString(key, comment: "")
        return value == key ? fallback : value
    }

    // Mirrors HearthDbConverter.GetLocalizedRace, including its handling of the
    // sentinels - which are singular there: "Spell" and "Buddy", not the plurals
    // the tier view's spell group is titled with (see spellsGroupTitle).
    static func raceName(_ race: Race) -> String {
        if race == .invalid { return localized("no_type", fallback: "No Type") }
        return localized("\(race)", fallback: englishRaceNames[race] ?? "\(race)".capitalized)
    }

    // HDT titles the tier view's spell group from Battlegrounds_Spells ("Spells")
    // rather than from GetLocalizedRace, which is why this is plural while
    // displayName is not.
    static var spellsGroupTitle: String { localized("spells", fallback: "Spells") }

    var displayName: String {
        switch self {
        case .spells: return Self.localized("spell", fallback: "Spell")
        case .buddies: return Self.localized("buddy", fallback: "Buddy")
        case .race(let race): return Self.raceName(race)
        }
    }

    // Label for the Card Types buttons - HDT's GetUppercaseLocalizedRace. It
    // keeps separate _Uppercase loc keys because not every language uppercases
    // mechanically; HSTracker folds that into .uppercased() on the display name,
    // which is right for English and harmless where casing is a no-op.
    var buttonLabel: String { displayName.uppercased() }

    // The tier-mode group headers are clickable only for real, filterable races -
    // not Spells, and not the "Other" (INVALID) bucket. Mirrors
    // BattlegroundsCardsGroup.HeaderCursor plus HDT's own INVALID exclusion.
    var isFilterableFromGroupHeader: Bool {
        if case .race(let race) = self {
            return race != .invalid
        }
        return false
    }
}

// Mirrors HDT's BattlegroundsMinionsViewModel: drives the Minions tab that
// replaced the AppKit BattlegroundsTierDetailsView + BattlegroundsTierDetailWindowController.
// Filter state is three-way exclusive - activeTier (a tier's cards grouped by
// tribe) XOR activeMinionType (a type's cards grouped by tier) XOR
// activeKeyword (a mechanic's cards grouped by tier) - matching the three
// branches of HDT's Groups.
@available(macOS 10.15, *)
final class BattlegroundsMinionsViewModel: ObservableObject {
    struct MinionGroup: Identifiable {
        var id: String {
            "\(tier)-\(minionType.map { "\($0)" } ?? "none")-\(keyword?.id ?? "none")"
        }
        let tier: Int
        // nil for a keyword group covering a whole tier, which has no single type.
        let minionType: BattlegroundsMinionType?
        let keyword: BattlegroundsKeyword?
        let groupedByMinionType: Bool  // true in type mode (groups by tier)
        let groupedByKeyword: Bool     // true in keyword mode (groups by tier)
        let cards: [Card]
        // Carried per group exactly as HDT's CardGroup.IsInspirationEnabled is,
        // so the value a group renders with is the one that was live when the
        // group was built.
        let isInspirationEnabled: Bool
    }

    @Published var activeTier: Int?
    @Published var activeMinionType: BattlegroundsMinionType?
    @Published var activeKeyword: BattlegroundsKeyword?
    // Purely which tiers the lobby actually offers, straight from the anomaly -
    // HDT's AvailableTiers. Deliberately does *not* include a tier 7 that only
    // the always-show setting or a tier-7 hero power/trinket/quest turned on:
    // that one is displayed but marked unavailable, which is the whole point of
    // the Available flag on the tier buttons below.
    @Published var availableTiers: [Int] = BattlegroundsUtils.getAvailableTiers(anomalyCardId: nil)

    // Snapshot of HDT's ShowTavernTier7, taken whenever
    // updateTavernTier7Visibility runs. Stored rather than read live off the
    // tier overlay so it is a real @Published dependency - a computed property
    // reaching into AppKit would leave SwiftUI with nothing to invalidate on.
    @Published private(set) var isTier7Forced = false

    // HDT's BattlegroundsMinionsViewModel.IsInspirationEnabled, set from
    // OverlayWindow as `_game.IsBattlegroundsMatch && userHasTier7`. Gates the
    // per-card inspiration indicator (see MinionCardRow) - it is a Tier7
    // entitlement flag, nothing to do with Duos.
    @Published private(set) var isInspirationEnabled = false

    // Extra-filters panel state. isFilterRegionHovered is driven by
    // RootOverlayWindow from HDT's BgsTopBarMask - a hover-only rectangle over
    // the canvas's top-right corner - not by any hover tracking on these views,
    // since the button slides out into click-through space that SwiftUI's own
    // .onHover never sees.
    @Published var isFiltersOpen = false
    @Published var isFilterRegionHovered = false

    // nil until onMatchStart reads the lobby. For testing outside a match,
    // seed it with the line below and flip the `if true` gate in
    // GuidesTabsView.body; five of the ten types leaves the rest unavailable,
    // so the "unavailable" footer and the faded tier badges show up too.
    // private var availableRaces: [Race]? = [.murloc, .beast, .dragon, .undead, .quilboar]
    private var availableRaces: [Race]?
    private var isDuos = false
    private var anomaly: String?
    private var settingsCancellable: AnyCancellable?
    private var trialCancellable: AnyCancellable?

    // The three mid-match sources of a tier 7, owned here rather than read off
    // the AppKit tier overlay. Mirrors HDT's HasTier7HeroPower / HasTier7Trinket
    // / HasTier7QuestReward, fed by the onHeroPowers / onTrinkets / onQuests
    // hooks below.
    //
    // Previously this reached through AppDelegate into the tier overlay's own
    // showTavernTier7. That coupled the Minions tab to an @IBOutlet that stays
    // nil until the tier overlay's nib is first loaded, so the tab silently fell
    // back to "no tier 7" whenever that window had never been shown.
    private var hasTier7HeroPower = false
    private var hasTier7Trinket = false
    private var hasTier7QuestReward = false

    // HDT's ShowTavernTier7.
    private var showTier7: Bool {
        Settings.alwaysShowTier7 || hasTier7HeroPower || hasTier7Trinket || hasTier7QuestReward
    }

    init() {
        settingsCancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateTavernTier7Visibility() }

        // HDT hooks Tier7Trial.OnTrialActivated in OverlayWindow's constructor to
        // re-run the same assignment; a trial can be activated mid-lobby (hero
        // pick, composition stats) long after onMatchStart has run.
        trialCancellable = NotificationCenter.default
            .publisher(for: Notification.Name(rawValue: Events.tier7_trial_activated))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateInspirationEnabled() }
    }

    // Mirrors OverlayWindow's `IsInspirationEnabled = _game.IsBattlegroundsMatch
    // && userHasTier7`, with Tier7Trial.token standing in for HDT's
    // IsTrialForCurrentGameActive(gameId). HSTracker's Tier7Trial keeps no
    // per-game handle and nothing calls its clear(), so a token activated once
    // lasts the rest of the app session - slightly more permissive than HDT's
    // per-game check, but this is exactly how the Comp guides and the quest
    // picker already read the entitlement.
    private func updateInspirationEnabled() {
        let game = AppDelegate.instance().coreManager.game
        let userHasTier7 = (HSReplayAPI.accountData?.is_tier7 ?? false) || Tier7Trial.token != nil
        isInspirationEnabled = game.isBattlegroundsMatch() && userHasTier7
    }

    // Mirrors HDT's UpdateTavernTier7Visibility(): recomputes the tier list when
    // anything feeding it changes - the anomaly at match start, the tier-7
    // setting, or a mid-match tier-7 hero power / trinket / quest reward.
    //
    // Must stay the single source of truth for which tiers exist. Callers used
    // to compensate for it going stale by re-appending 7 themselves, which
    // double-counted the tier whenever it was *not* stale (see groupsByTier).
    func updateTavernTier7Visibility() {
        availableTiers = BattlegroundsUtils.getAvailableTiers(anomalyCardId: anomaly)
        isTier7Forced = showTier7
    }

    // MARK: - Tier 7 sources (mirrors HDT's OnHeroPowers / OnTrinkets / OnQuests)
    //
    // Each recomputes the tier list, as HDT's property setters do by way of
    // UpdateTavernTier7Visibility - that is what republishes availableTiers and
    // isTier7Forced so the strip and the groups pick a new tier 7 up mid-match.

    func onHeroPowers(_ heroPowers: [String]) {
        hasTier7HeroPower = heroPowers.contains(CardIds.NonCollectible.Neutral.ThorimStormlord_ChooseYourChampion)
        updateTavernTier7Visibility()
    }

    func onTrinkets(_ trinkets: [String]) {
        hasTier7Trinket = trinkets.contains { trinket in
            trinket == CardIds.NonCollectible.Neutral.PaglesFishingRod
                || trinket == CardIds.NonCollectible.Neutral.Kaleidoscope
                || trinket == CardIds.NonCollectible.Neutral.Kaleidoscope_KaleidoscopeToken
                || trinket == CardIds.NonCollectible.Neutral.WaxLance
        }
        updateTavernTier7Visibility()
    }

    func onQuests(_ quests: [String]) {
        hasTier7QuestReward = quests.contains(CardIds.NonCollectible.Neutral.NorgannonsReward)
        updateTavernTier7Visibility()
    }

    // Whether the strip shows a seventh badge at all - HDT's shouldShowTier7.
    // A forced tier 7 gets a badge even though it is not `available`.
    var shouldShowTier7: Bool {
        availableTiers.contains(7) || isTier7Forced
    }

    // Tiers that get their own group in type/keyword mode: the available ones,
    // plus a forced tier 7. HDT appends that 7 unconditionally, duplicating it
    // whenever AvailableTiers already had one; the contains check is the fix.
    var groupTiers: [Int] {
        var tiers = availableTiers
        if isTier7Forced && !tiers.contains(7) {
            tiers.append(7)
        }
        return tiers
    }

    var unavailableRaces: [Race] {
        guard let available = availableRaces else { return [] }
        return BattlegroundsDbSingleton.instance.races.filter {
            !available.contains($0) && $0 != .invalid && $0 != .all
        }
    }

    // MARK: - Extra filter state (mirrors HDT's like-named properties)

    var isExtraFilterSelected: Bool {
        activeMinionType != nil || activeKeyword != nil
    }

    var isFilterButtonVisible: Bool {
        isExtraFilterSelected || isFilterRegionHovered || isFiltersOpen
    }

    var keywords: [BattlegroundsKeyword] {
        BattlegroundsUtils.getAvailableKeywords()
    }

    // Mirrors HDT's TierButton: every tier 1-6 (plus 7 when shown) always gets a
    // button, with availability and fading carried as flags rather than by
    // omitting the tier from the list.
    struct TierButton: Identifiable {
        let tier: Int
        let isActive: Bool
        let isAvailable: Bool
        let isFaded: Bool
        var id: Int { tier }
    }

    var tierButtons: [TierButton] {
        var tiers = Array(1...6)
        if shouldShowTier7 {
            tiers.append(7)
        }
        return tiers.map { tier in
            TierButton(
                tier: tier,
                isActive: activeTier == tier,
                isAvailable: availableTiers.contains(tier),
                // Everything dims once the list is showing something other than
                // this tier - either a different tier, or a type/keyword filter.
                isFaded: (activeTier != nil && activeTier != tier) || isExtraFilterSelected
            )
        }
    }

    struct MinionTypeButton: Identifiable {
        let minionType: BattlegroundsMinionType
        let isActive: Bool
        let isFaded: Bool
        var id: BattlegroundsMinionType { minionType }
    }

    struct KeywordButton: Identifiable {
        let keyword: BattlegroundsKeyword
        let isActive: Bool
        let isFaded: Bool
        var id: String { keyword.id }
    }

    // Mirrors HDT's MinionTypeButtons: the lobby's races (or every known race
    // out of match), with ALL dropped, "Other" (INVALID) forced to the end, and
    // the Spells / Buddies sentinels appended after it.
    var minionTypeButtons: [MinionTypeButton] {
        var races: [Race]
        if let available = availableRaces {
            // Mirror order comes straight from the game, so keep it as-is.
            races = available
        } else {
            // Db.races is a Set, and HDT leans on HashSet iteration order here.
            // Sort so the out-of-match grid doesn't reshuffle between launches.
            races = BattlegroundsDbSingleton.instance.races.sorted { "\($0)" < "\($1)" }
        }
        races.removeAll { $0 == .invalid || $0 == .all }
        races.append(.invalid)

        var types = races.map { BattlegroundsMinionType.race($0) }
        types.append(.spells)
        types.append(.buddies)

        return types.map { type in
            MinionTypeButton(
                minionType: type,
                isActive: activeMinionType == type,
                isFaded: activeMinionType != nil && activeMinionType != type
            )
        }
    }

    var keywordButtons: [KeywordButton] {
        keywords.map { keyword in
            KeywordButton(
                keyword: keyword,
                isActive: activeKeyword == keyword,
                isFaded: activeKeyword != nil && activeKeyword != keyword
            )
        }
    }

    var groups: [MinionGroup] {
        if let tier = activeTier {
            return groupsByTribe(tier: tier)
        }
        if let minionType = activeMinionType {
            return groupsByTier(minionType: minionType)
        }
        if let keyword = activeKeyword {
            return groupsByKeyword(keyword)
        }
        return []
    }

    // MARK: - Lifecycle

    // Mirrors HDT's ShowBgsTopBar, which re-reads the lobby on *every* overlay
    // update rather than once at match start.
    //
    // That matters because availableRaces comes from Hearthstone's memory via
    // the mirror, and is not there yet when gameStart fires. Reading it once at
    // match start latched nil for the whole match, and nil falls back to
    // "every race in the card DB" - which is why the Card Types grid showed all
    // ten tribes instead of the lobby's own. Game.availableRaces retries the
    // mirror on each call while it is still nil, so simply asking again works.
    //
    // Early-out when nothing changed: this runs on the gui update tick, and
    // publishing every time would re-render the whole panel continuously.
    func updateLobby() {
        guard let game = AppDelegate.instance().coreManager?.game else { return }
        let races = game.availableRaces
        let duos = game.isBattlegroundsDuosMatch()
        let anomalyDbfId = BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: game.gameEntity)
        let anomalyCardId = Cards.by(dbfId: anomalyDbfId, collectible: false)?.id

        guard races != availableRaces || duos != isDuos || anomalyCardId != anomaly else { return }

        objectWillChange.send()
        availableRaces = races
        isDuos = duos
        anomaly = anomalyCardId
        // The anomaly decides which tiers exist.
        updateTavernTier7Visibility()
    }

    func onMatchStart() {
        updateLobby()
        clearFilters()
        updateInspirationEnabled()
        // The tier-7 sources are deliberately *not* cleared here, only in
        // onMatchEnd - HDT calls Reset() solely from HideBgsTopBar. Clearing on
        // the way in would race the hooks: onMatchStart and the forwards from
        // Game both hop to main, so a hero power or trinket pushed during
        // mulligan can already be queued ahead of this and would be wiped.
        updateTavernTier7Visibility()
    }

    func onMatchEnd() {
        clearFilters()
        availableRaces = nil
        resetTier7Sources()
        // HDT lets its next Update() tick drop the flag once IsBattlegroundsMatch
        // goes false; there is no such tick here, so clear it explicitly.
        isInspirationEnabled = false
    }

    // HDT's Reset() clears all three alongside the filters, at match end only;
    // without this a tier 7 unlocked in one match would carry into the next.
    private func resetTier7Sources() {
        hasTier7HeroPower = false
        hasTier7Trinket = false
        hasTier7QuestReward = false
    }

    private func clearFilters() {
        activeTier = nil
        activeMinionType = nil
        activeKeyword = nil
        isFiltersOpen = false
        isFilterRegionHovered = false
    }

    // MARK: - Filter actions
    //
    // Each setter clears the other two dimensions, mirroring HDT's property
    // setters (ActiveTier clears ActiveMinionType + ActiveMinionKeyword, etc.).
    // Re-selecting what's already active clears it.

    func selectTier(_ tier: Int) {
        let wasActive = activeTier == tier
        activeMinionType = nil
        activeKeyword = nil
        activeTier = wasActive ? nil : tier
    }

    func selectMinionType(_ minionType: BattlegroundsMinionType) {
        let wasActive = activeMinionType == minionType
        activeTier = nil
        activeKeyword = nil
        activeMinionType = wasActive ? nil : minionType
    }

    func selectKeyword(_ keyword: BattlegroundsKeyword) {
        let wasActive = activeKeyword == keyword
        activeTier = nil
        activeMinionType = nil
        activeKeyword = wasActive ? nil : keyword
    }

    // Convenience for the tier-mode group headers, which can only ever select a
    // real race.
    func selectTribe(_ race: Race) {
        selectMinionType(.race(race))
    }

    func toggleFilters() {
        isFiltersOpen.toggle()
    }

    // MARK: - Group computation (mirrors HDT's BattlegroundsMinionsViewModel.Groups)

    private func groupsByTribe(tier: Int) -> [MinionGroup] {
        var result = [MinionGroup]()
        for race in BattlegroundsDbSingleton.instance.races {
            if let ar = availableRaces, !ar.contains(race) && race != .invalid && race != .all {
                continue
            }
            let cards = BattlegroundsDbSingleton.instance.getCards(tier, race, isDuos)
            guard !cards.isEmpty else { continue }
            result.append(MinionGroup(
                tier: tier,
                minionType: .race(race),
                keyword: nil,
                groupedByMinionType: false,
                groupedByKeyword: false,
                cards: cards.sorted { $0.name < $1.name },
                isInspirationEnabled: isInspirationEnabled
            ))
        }
        if Settings.showTavernSpells {
            let spells = BattlegroundsDbSingleton.instance.getSpells(tier, isDuos)
                .sorted { a, b in a.cost == b.cost ? a.name < b.name : a.cost < b.cost }
            if !spells.isEmpty {
                result.append(MinionGroup(tier: tier, minionType: .spells, keyword: nil,
                                          groupedByMinionType: false, groupedByKeyword: false,
                                          cards: spells,
                                          isInspirationEnabled: isInspirationEnabled))
            }
        }
        return result.sorted { a, b in
            let sa = sortKey(a.minionType)
            let sb = sortKey(b.minionType)
            return sa == sb ? groupSortName(a) < groupSortName(b) : sa < sb
        }
    }

    private func groupsByTier(minionType: BattlegroundsMinionType) -> [MinionGroup] {
        var result = [MinionGroup]()
        for tier in groupTiers {
            let cards: [Card]
            switch minionType {
            case .spells:
                cards = BattlegroundsDbSingleton.instance.getSpells(tier, isDuos)
                    .sorted { a, b in a.cost == b.cost ? a.name < b.name : a.cost < b.cost }
            case .buddies:
                cards = BattlegroundsDbSingleton.instance.getBuddies(tier, isDuos)
                    .sorted { $0.name < $1.name }
            case .race(let race):
                let main = BattlegroundsDbSingleton.instance.getCards(tier, race, isDuos)
                // Neutrals (Race.ALL) play with every type, so they're folded in
                // alongside - except when the selected type *is* ALL or Other.
                let extra = (race != .all && race != .invalid)
                    ? BattlegroundsDbSingleton.instance.getCards(tier, .all, isDuos)
                    : []
                cards = (main + extra).sorted { $0.name < $1.name }
            }
            guard !cards.isEmpty else { continue }
            result.append(MinionGroup(tier: tier, minionType: minionType, keyword: nil,
                                      groupedByMinionType: true, groupedByKeyword: false,
                                      cards: cards,
                                      isInspirationEnabled: isInspirationEnabled))
        }
        return result
    }

    // Mirrors HDT's ActiveMinionKeyword branch: one group per tier of matching
    // minions, then a single trailing group of matching spells across all tiers
    // (tier 0, so its header shows the keyword rather than a tavern tier).
    private func groupsByKeyword(_ keyword: BattlegroundsKeyword) -> [MinionGroup] {
        let races = availableRaces ?? Array(BattlegroundsDbSingleton.instance.races)
        var result = [MinionGroup]()
        for tier in groupTiers {
            let cards = BattlegroundsDbSingleton.instance
                .getCards(tier, keyword: keyword, races: races, isDuos)
                .sorted { $0.name < $1.name }
            guard !cards.isEmpty else { continue }
            result.append(MinionGroup(tier: tier, minionType: nil, keyword: keyword,
                                      groupedByMinionType: false, groupedByKeyword: true,
                                      cards: cards,
                                      isInspirationEnabled: isInspirationEnabled))
        }
        // Gated on showTavernSpells for the same reason the tier view is: a user
        // who turned tavern spells off shouldn't get them back via a keyword.
        // HDT has no such setting and always appends this group.
        if Settings.showTavernSpells {
            let spells = BattlegroundsDbSingleton.instance
                .getSpells(keyword: keyword, isDuos)
                .sorted { a, b in a.cost == b.cost ? a.name < b.name : a.cost < b.cost }
            if !spells.isEmpty {
                result.append(MinionGroup(tier: 0, minionType: .spells, keyword: keyword,
                                          groupedByMinionType: false, groupedByKeyword: true,
                                          cards: spells,
                                          isInspirationEnabled: isInspirationEnabled))
            }
        }
        return result
    }

    // ALL first, then real types, then Other, then Spells - HDT's OrderBy switch.
    private func sortKey(_ minionType: BattlegroundsMinionType?) -> Int {
        switch minionType {
        case .race(.all): return -1
        case .race(.invalid): return 1
        case .spells: return 2
        default: return 0
        }
    }

    private func groupSortName(_ group: MinionGroup) -> String {
        group.minionType?.displayName ?? ""
    }
}

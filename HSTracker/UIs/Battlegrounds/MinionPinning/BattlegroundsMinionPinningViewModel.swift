//
//  BattlegroundsMinionPinningViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Mirrors HDT's BattlegroundsMinionPinningViewModel
// (Controls/Overlay/Battlegrounds/MinionPinning/). "Tavern Pinning" marks
// minions in Bob's shop so they stand out while rolling, from three
// independent sources:
//
//   manual pin  - a card the user pinned by id, from the minion browser, a
//                 comp guide, or the panel itself. Drawn as a plain pin.
//   tribe pin   - every minion of a selected minion type. Drawn as a pin with
//                 the tribe icon inside it.
//   key piece   - a card named in the "when to commit" copy of a comp guide
//                 available in this lobby. Drawn as a key.
//
// The three are deliberately separate flags on a shop slot, not one "pinned"
// state, because a card can qualify under all three at once and each gets its
// own marker (see BattlegroundsMinionPinningCardView).
//
// HDT raises a PinsChanged event so its WPF controls can re-read IsCardPinned;
// the SwiftUI ports observe this object directly instead, so there is no
// equivalent event here.
//
// Every `Core.Game.Metrics.TavernMarkers*` assignment in the HDT source is
// dropped: HSTracker has no ValueMoments/GameMetrics telemetry to write to.
@available(macOS 10.15, *)
final class BattlegroundsMinionPinningViewModel: ObservableObject {

    // MARK: - Pinned slots (the panel's grid)

    // One cell of the panel's 5-wide grid. HDT keeps a live
    // ObservableCollection<PinnedSlotViewModel> and mutates it in place
    // (EnsureCapacity / SyncPinnedSlotsFromIds) because a WPF ItemsControl wants
    // stable item instances; SwiftUI rebuilds its rows from a value array, so
    // the slots are derived from pinnedCardIds on demand instead. The resulting
    // layout - including where the Clear button lands - is identical, see
    // `pinnedSlots`.
    struct PinnedSlot: Identifiable {
        let index: Int
        let cardId: String?
        let isClearButton: Bool
        // PinnedSlotViewModel.Tier: Math.Max(1, card?.TechLevel ?? 1).
        let tier: Int

        var id: Int { index }
        var hasCard: Bool { cardId != nil }
    }

    // MARK: - Shop slots (the markers drawn over Bob's shop)

    // HDT's BattlegroundsMinionPinningCardViewModel. Seven of them, one per
    // shop position, held in a fixed-length array that is cleared and refilled
    // on every shop change rather than resized.
    struct ShopCard: Identifiable {
        let index: Int
        var cardId: String?
        var isSlotOccupied = false
        var isHovered = false
        var isMinionPinned = false
        var isTribePinned = false
        var tribeIconRace: Race = .invalid
        var isRecommendedPinned = false
        var recommendedComps: [BattlegroundsCompGuideViewModel] = []
        // RecommendedSectionCanvasLeft: where the "Comps - Enabler / Commit
        // Piece" tooltip hangs relative to this slot, so the middle slots open
        // it to the left and the outer ones to the right.
        var recommendedSectionOffsetX: CGFloat = 0

        var id: Int { index }

        // ShouldShowRecommendedSection.
        var shouldShowRecommendedSection: Bool { !recommendedComps.isEmpty && isHovered }
    }

    // HDT's ShopCards, seven fixed entries.
    private static let shopSlotCount = 7

    // Number of cells per row in the panel's grid, and the growth quantum for
    // the slot list. HDT's SlotGroupSize.
    private static let slotGroupSize = 5

    // MARK: - State

    // Whether the whole feature is showing - HDT's BgsMinionPinningVisibility,
    // recomputed from ShouldShowBgsMinionPinning() on the overlay update tick
    // (see updateVisibility). Hiding it clears the pins, as HDT's setter does.
    @Published private(set) var isShown = false

    // BgsMinionPinningShop.Visibility: the shop markers show from the start of
    // a shopping phase until combat begins, independently of the panel.
    @Published private(set) var isShopShown = false

    @Published private(set) var pinnedCardIds: [String] = []
    @Published private(set) var selectedRaces: Set<Race> = []
    @Published private(set) var shopCards: [ShopCard] =
        (0 ..< shopSlotCount).map { ShopCard(index: $0) }
    @Published private(set) var mousedOverSlot = -1
    @Published private(set) var enableRecommended = false

    // Panel chrome, ported from BattlegroundsMinionPinning.xaml.cs (which keeps
    // these on the control rather than the view model).
    @Published var isCogVisible = false
    @Published var isQuickCompGuideVisible = false
    @Published var isAutoEnableMessageVisible = false
    @Published private(set) var quickGuideDismissed = Settings.dismissedTavernMarkerQuickGuide
    @Published private(set) var compGuidesMarkerQuickGuideDismissed = Settings.dismissedCompGuidesMarkerQuickGuide

    // IsCompGuidesMarkerPanelVisible.
    var isCompGuidesMarkerPanelVisible: Bool {
        isQuickCompGuideVisible || isAutoEnableMessageVisible
    }

    // HDT's IsOnTrial: true for anyone who does not own Tier7 outright, which
    // is what puts the "Tier7 Feature" tag in the panel header. Note this is
    // *not* the gate on the feature itself - see updateVisibility.
    @Published private(set) var isOnTrial = true

    // IsExpanded, persisted through ConfigWrapper.TavernMarkersPanelExpanded.
    @Published var isExpanded = Settings.tavernMarkersPanelExpanded {
        didSet {
            if Settings.tavernMarkersPanelExpanded != isExpanded {
                Settings.tavernMarkersPanelExpanded = isExpanded
            }
        }
    }

    // The lobby's minion types, mirrored from the same source the minion
    // browser reads (see updateLobby). Setting it prunes any selected race the
    // new lobby doesn't offer, exactly as HDT's AvailableRaces setter does.
    @Published private(set) var availableRaces: [Race]?

    // The comp guides the "key pieces" recommendation is derived from. Set once
    // from RootOverlayViewModel; HDT assigns the same reference in
    // OverlayWindow's constructor.
    weak var compsGuides: BattlegroundsCompsGuidesViewModel?

    private var recommendedCardIds: Set<String> = []
    private var recommendedCardGuides: [String: [BattlegroundsCompGuideViewModel]] = [:]

    // HDT also keeps a _racePinnedCardIds set, filled by RecomputeRacePinnedIds
    // from the selected races. Nothing ever reads it - UpdatePinnedFlags tests
    // _selectedRaces against the card's own races directly - so it is dead
    // state there and is not ported.

    private var isDuos = false

    init() {
        updateTrialState()
    }

    // MARK: - Pinning

    var pinnedCount: Int { pinnedCardIds.count }
    var hasPins: Bool { !pinnedCardIds.isEmpty }

    func isCardPinned(_ cardId: String?) -> Bool {
        guard let cardId, !cardId.isEmpty else { return false }
        return pinnedCardIds.contains(cardId)
    }

    func pinCard(_ cardId: String) {
        guard !cardId.isEmpty, !pinnedCardIds.contains(cardId) else { return }
        pinnedCardIds.append(cardId)
        // PinCard opens the panel so the new pin is actually visible.
        isExpanded = true
        updatePinnedFlags()
    }

    func togglePinCard(_ cardId: String) {
        if pinnedCardIds.contains(cardId) {
            unpinCard(cardId)
        } else {
            pinCard(cardId)
        }
    }

    func unpinCard(_ cardId: String) {
        guard let index = pinnedCardIds.firstIndex(of: cardId) else { return }
        pinnedCardIds.remove(at: index)
        isExpanded = true
        updatePinnedFlags()
    }

    // ClearPins - note it deliberately does *not* expand the panel, unlike
    // pin/unpin.
    func clearPins() {
        guard !pinnedCardIds.isEmpty else { return }
        pinnedCardIds.removeAll()
        updatePinnedFlags()
    }

    // Mirrors SyncPinnedSlotsFromIds + EnsureCapacity. The grid always shows at
    // least one full row of five, grows in whole rows, and reserves the last
    // cell of the final row for the Clear button once anything is pinned -
    // which is why five pins take two rows (five cards, then Clear alone).
    var pinnedSlots: [PinnedSlot] {
        let count = pinnedCardIds.count
        let group = Self.slotGroupSize
        // HDT: totalItems = count + 1 (the Clear button), rowForClearButton =
        // (totalItems - 1) / group, clearButtonIndex = (row + 1) * group - 1,
        // and EnsureCapacity then rounds the slot count up to clearIndex + 1 -
        // which is already a multiple of group. That reduces to this.
        let slotCount = count == 0 ? group : ((count + 1 + group - 1) / group) * group
        let clearButtonIndex = count == 0 ? -1 : slotCount - 1

        return (0 ..< slotCount).map { index in
            if index == clearButtonIndex {
                return PinnedSlot(index: index, cardId: nil, isClearButton: true, tier: 1)
            }
            guard index < count else {
                return PinnedSlot(index: index, cardId: nil, isClearButton: false, tier: 1)
            }
            let cardId = pinnedCardIds[index]
            let tier = max(1, Cards.by(cardId: cardId)?.techLevel ?? 1)
            return PinnedSlot(index: index, cardId: cardId, isClearButton: false, tier: tier)
        }
    }

    // PinnedSlotViewModel.UnpinCommand: the Clear cell clears everything, a
    // card cell unpins just that card, an empty cell does nothing.
    func activatePinnedSlot(_ slot: PinnedSlot) {
        if slot.isClearButton {
            clearPins()
        } else if let cardId = slot.cardId {
            unpinCard(cardId)
        }
    }

    // MARK: - Minion type (tribe) pins

    // MinionTypeButtons. Reuses the browser's own button model so the panel and
    // the Card Types grid render through the same BattlegroundsMinionTypeButton
    // view - HDT does the same, instantiating minions:BattlegroundsMinionTypeButton
    // in both places.
    //
    // Unlike the browser's grid this one carries real races only: HDT removes
    // INVALID and ALL and appends neither the Spells nor the Buddies sentinel,
    // because a tribe pin matches on a card's race.
    var minionTypeButtons: [BattlegroundsMinionsViewModel.MinionTypeButton] {
        var races = availableRaces ?? BattlegroundsDbSingleton.instance.races.sorted { "\($0)" < "\($1)" }
        races.removeAll { $0 == .invalid || $0 == .all }

        let hasActiveSelection = !selectedRaces.isEmpty
        return races.map { race in
            BattlegroundsMinionsViewModel.MinionTypeButton(
                minionType: .race(race),
                isActive: selectedRaces.contains(race),
                isFaded: hasActiveSelection && !selectedRaces.contains(race)
            )
        }
    }

    // SetActiveMinionTypeCommand: toggles the race in or out of the selection.
    // Several can be active at once, unlike the browser's exclusive filter.
    func toggleMinionType(_ minionType: BattlegroundsMinionType) {
        guard case .race(let race) = minionType else { return }
        if selectedRaces.contains(race) {
            selectedRaces.remove(race)
        } else {
            selectedRaces.insert(race)
        }
        updatePinnedFlags()
    }

    // MARK: - Key piece recommendations

    // ToggleRecommendedCommand. Turning the feature *off* is what offers to make
    // that choice permanent, via the auto-enable popup.
    func toggleRecommended() {
        let wasEnabled = enableRecommended
        setEnableRecommended(!enableRecommended)

        if wasEnabled && !enableRecommended {
            showAutoEnablePopup()
        }
    }

    private func setEnableRecommended(_ value: Bool) {
        guard enableRecommended != value else { return }
        enableRecommended = value

        if value {
            recomputeRecommendedFromGuides()
        } else {
            recommendedCardIds.removeAll()
            recommendedCardGuides.removeAll()
        }
        updatePinnedFlags()
    }

    // RecomputeRecommendedFromGuides. Two things worth noting, both matching
    // HDT:
    //
    //  - only the "when to commit" copy is mined, despite the quick guide's own
    //    text promising enablers too. CommonEnablerTags is never read here.
    //  - the tier7 (per-lobby) guides are preferred, falling back to the free
    //    list; with neither loaded there is simply nothing to recommend, which
    //    is how the feature stays a Tier7 one without an explicit entitlement
    //    check.
    private func recomputeRecommendedFromGuides() {
        recommendedCardIds.removeAll()
        recommendedCardGuides.removeAll()

        guard let compsGuides else { return }

        // The lobby's pool, plus the two catch-all races a card can carry.
        var races: Set<Race> = availableRaces.map { Set($0) } ?? BattlegroundsDbSingleton.instance.races
        races.insert(.all)
        races.insert(.invalid)
        let availableDbfIds = Set(
            BattlegroundsDbSingleton.instance.getCardsByRaces(Array(races), isDuos).map { $0.dbfId }
        )

        let allGuides: [BattlegroundsCompGuideViewModel]
        if let byTier = compsGuides.compsByTier {
            allGuides = byTier.values.flatMap { $0 }
        } else {
            allGuides = compsGuides.comps ?? []
        }

        for guide in allGuides {
            for line in guide.whenToCommitLines {
                for segment in line {
                    guard case .card(_, let dbfId) = segment, let dbfId else { continue }
                    guard availableDbfIds.contains(dbfId) else { continue }
                    guard let card = Cards.by(dbfId: dbfId, collectible: false), !card.id.isEmpty else { continue }

                    recommendedCardIds.insert(card.id)
                    var guides = recommendedCardGuides[card.id] ?? []
                    if !guides.contains(where: { $0.id == guide.id }) {
                        guides.append(guide)
                        recommendedCardGuides[card.id] = guides
                    }
                }
            }
        }
    }

    // MARK: - Shop state

    // OnShopChange. `boardCards` is the opposing play zone, which in
    // Battlegrounds is Bob's shop; `mousedOverSlot` is the 1-based position the
    // cursor is hovering, or -1.
    //
    // The hovered slot is skipped over rather than filled: Hearthstone lifts the
    // hovered minion out of the row, so every card at or past that position
    // renders one slot to the right of where the board list has it.
    func onShopChange(boardCards: [MirrorBoardCard], mousedOverSlot: Int) {
        self.mousedOverSlot = mousedOverSlot

        var cards = (0 ..< Self.shopSlotCount).map { ShopCard(index: $0) }

        if mousedOverSlot > 0 && mousedOverSlot <= cards.count {
            cards[mousedOverSlot - 1].isMinionPinned = false
            cards[mousedOverSlot - 1].isSlotOccupied = true
        }

        for (i, boardCard) in boardCards.enumerated() {
            let oneBasedIndex = i + 1
            let targetPos = (mousedOverSlot > 0 && oneBasedIndex >= mousedOverSlot)
                ? oneBasedIndex + 1
                : oneBasedIndex
            let targetIdx = targetPos - 1
            guard targetIdx >= 0 && targetIdx < cards.count else { continue }

            cards[targetIdx].isSlotOccupied = true
            cards[targetIdx].cardId = boardCard.cardId
            cards[targetIdx].isHovered = boardCard.hovered
            cards[targetIdx].recommendedSectionOffsetX =
                Self.tooltipOffset(cardCount: boardCards.count, cardIndex: i)
        }

        shopCards = cards
        updatePinnedFlags()
    }

    // SetTooltipPosition. The 249pt tooltip opens to the left of the middle
    // slot(s) so it stays on screen, and just right of the marker otherwise.
    private static func tooltipOffset(cardCount: Int, cardIndex: Int) -> CGFloat {
        let halfCount = cardCount / 2
        let isOdd = cardCount % 2 == 1
        if isOdd {
            if cardIndex == halfCount { return -620 }
            return cardIndex < halfCount ? -80 : -50
        }
        if cardIndex == halfCount - 1 || cardIndex == halfCount { return -620 }
        return cardIndex < halfCount - 1 ? -80 : -50
    }

    // ClearShopCards.
    func clearShopCards() {
        shopCards = (0 ..< Self.shopSlotCount).map { ShopCard(index: $0) }
    }

    // UpdatePinnedFlags: recomputes all three marker flags for every occupied
    // shop slot.
    private func updatePinnedFlags() {
        for index in shopCards.indices {
            guard shopCards[index].isSlotOccupied, let cardId = shopCards[index].cardId, !cardId.isEmpty else {
                shopCards[index].isMinionPinned = false
                shopCards[index].isTribePinned = false
                shopCards[index].tribeIconRace = .invalid
                shopCards[index].isRecommendedPinned = false
                shopCards[index].recommendedComps = []
                continue
            }

            shopCards[index].isMinionPinned = pinnedCardIds.contains(cardId)

            // HDT checks RaceEnum then SecondaryRaceEnum; HSTracker's Card
            // carries the same information as `race` plus a `races` list for
            // dual-tribe cards, so the first selected race among them wins.
            let card = Cards.by(cardId: cardId)
            let cardRaces = (card?.races.isEmpty ?? true) ? [card?.race ?? .invalid] : (card?.races ?? [])
            let pinnedRace = cardRaces.first { selectedRaces.contains($0) && $0 != .invalid && $0 != .all }

            shopCards[index].isTribePinned = pinnedRace != nil
            shopCards[index].tribeIconRace = pinnedRace ?? .invalid

            if enableRecommended && recommendedCardIds.contains(cardId) {
                shopCards[index].isRecommendedPinned = true
                shopCards[index].recommendedComps = recommendedCardGuides[cardId] ?? []
            } else {
                shopCards[index].isRecommendedPinned = false
                shopCards[index].recommendedComps = []
            }
        }
    }

    // MARK: - Lifecycle

    // Mirrors HDT's ShouldShowBgsMinionPinning(), evaluated from the overlay
    // update tick as OverlayWindow.Update does. Unlike the minion browser this
    // *is* a hard Tier7 gate - free users get no panel at all.
    func updateVisibility() {
        guard let game = AppDelegate.instance().coreManager?.game else { return }

        let userHasTier7 = (HSReplayAPI.accountData?.is_tier7 ?? false) || Tier7Trial.token != nil
        let shouldShow = Settings.showBattlegroundsTavernMarkers
            && game.isBattlegroundsHeroPickingDone
            && game.setupDone
            && userHasTier7

        updateTrialState()

        guard shouldShow != isShown else { return }
        isShown = shouldShow
        // "Clear all pins when the feature is hidden to prevent persistence."
        if !shouldShow {
            clearPins()
        }
    }

    private func updateTrialState() {
        let onTrial = !(HSReplayAPI.accountData?.is_tier7 ?? false)
        if onTrial != isOnTrial {
            isOnTrial = onTrial
        }
    }

    // OnBattlegroundsShoppingStart sets BgsMinionPinningShop visible; both
    // combat-setup transitions collapse it again.
    func setShopVisible(_ visible: Bool) {
        guard isShopShown != visible else { return }
        isShopShown = visible
    }

    // The lobby's races and duos flag, refreshed on the overlay tick for the
    // same reason the minion browser does it there - they are not readable from
    // the game-memory mirror yet at match start. HDT pushes AvailableRaces from
    // OverlayWindow.ShowBgsTopBar.
    func updateLobby() {
        guard let game = AppDelegate.instance().coreManager?.game else { return }
        let races = game.availableRaces
        let duos = game.isBattlegroundsDuosMatch()
        guard races != availableRaces || duos != isDuos else { return }

        availableRaces = races
        isDuos = duos

        // AvailableRaces setter: drop selections the new lobby doesn't offer,
        // then re-derive everything that depends on the pool.
        if let races {
            let allowed = Set(races)
            selectedRaces = selectedRaces.filter { allowed.contains($0) }
        }
        if enableRecommended {
            recomputeRecommendedFromGuides()
        }
        updatePinnedFlags()
    }

    // Reset().
    func reset() {
        mousedOverSlot = -1
        clearShopCards()
        clearPins()
        selectedRaces.removeAll()
        setEnableRecommended(Settings.autoEnableTavernMarkersRecommended)
        if !enableRecommended {
            recommendedCardIds.removeAll()
            recommendedCardGuides.removeAll()
        }
        isExpanded = Settings.tavernMarkersPanelExpanded
        isQuickCompGuideVisible = false
        isAutoEnableMessageVisible = false
        refreshQuickGuideState()
    }

    func onMatchEnd() {
        reset()
        setShopVisible(false)
        isShown = false
        availableRaces = nil
    }

    // MARK: - Quick guides
    //
    // BattlegroundsMinionPinning.xaml.cs keeps these on the control; there is no
    // separate control here, so they live with the rest of the panel state.

    func refreshQuickGuideState() {
        quickGuideDismissed = Settings.dismissedTavernMarkerQuickGuide
        compGuidesMarkerQuickGuideDismissed = Settings.dismissedCompGuidesMarkerQuickGuide
    }

    // ShowGuide(): re-arms all three pieces of onboarding. Reached from the
    // Battlegrounds settings pane, as HDT's ShowQuickGuide is.
    func showGuide() {
        Settings.dismissedTavernMarkerQuickGuide = false
        Settings.dismissedCompGuidesMarkerQuickGuide = false
        Settings.dismissedAutoEnablePopup = false
        refreshQuickGuideState()
    }

    // DismissGuide().
    func dismissGuide() {
        Settings.dismissedTavernMarkerQuickGuide = true
        refreshQuickGuideState()
    }

    // DismissCompGuidesMarkerQuickGuide().
    func dismissCompGuidesMarkerQuickGuide() {
        Settings.dismissedCompGuidesMarkerQuickGuide = true
        isQuickCompGuideVisible = false
        refreshQuickGuideState()
    }

    // BtnHelp_Click: the header's "?" toggles the quick guide back on if either
    // half has been dismissed, and dismisses it otherwise.
    func toggleQuickGuide() {
        if Settings.dismissedTavernMarkerQuickGuide || Settings.dismissedCompGuidesMarkerQuickGuide {
            showGuide()
        } else {
            dismissGuide()
        }
    }

    // RecommendComp_MouseEnter / _MouseLeave.
    func setRecommendCompHovered(_ hovering: Bool) {
        if hovering {
            if !Settings.dismissedCompGuidesMarkerQuickGuide {
                isQuickCompGuideVisible = true
            }
        } else {
            isQuickCompGuideVisible = false
        }
    }

    // ShowAutoEnablePopup().
    private func showAutoEnablePopup() {
        guard !Settings.dismissedAutoEnablePopup else { return }
        isAutoEnableMessageVisible = true
    }

    // BtnAutoEnableYes_Click / BtnAutoEnableNo_Click.
    func answerAutoEnable(_ enable: Bool) {
        Settings.autoEnableTavernMarkersRecommended = enable
        Settings.dismissedAutoEnablePopup = true
        isAutoEnableMessageVisible = false
    }
}

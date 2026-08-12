//
//  ConstructedMulliganGuidePreLobbyViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

enum SingleDeckState {
    case invalid,
         loading, // indicates that a task is currently fetching some
         no_data,
         v1_ready,
         v2_ready,
         v2_partial
}

class SingleDeckStatus {
    private(set) var visibility: Bool
    private(set) var state: SingleDeckState
    private(set) var hasRunes: Bool
    private(set) var isFocused: Bool
    var padding: Int {
        return hasRunes ? 29 : 15
    }
    
    init() {
        visibility = false
        state = .invalid
        hasRunes = false
        isFocused = false
    }
    
    init(state: SingleDeckState, hasRunes: Bool, isFocused: Bool) {
        self.visibility = true
        self.state = state
        self.hasRunes = hasRunes
        self.isFocused = isFocused
    }
    
    var iconVisibility: Bool {
        return switch state {
        case .v1_ready, .v2_ready, .v2_partial, .no_data, .loading:
            true
        default:
            false
        }
    }

    var iconSource: NSImage? {
        return switch state {
        case .no_data:
            NSImage(named: "mulligan-guide-no-data")
        default:
            NSImage(named: "mulligan-guide-data")
        }
    }

    var borderBrush: String {
        return switch state {
        case .no_data:
            "#CCE3D000"
        case .v2_partial:
            "#CCE0A200"
        default:
            "#CC00AA00"
        }
    }

    var background: String {
        return switch state {
        case .no_data:
            "#CC1A1100"
        case .v2_partial:
            "#CC221900"
        default:
            "#CC002200"
        }
    }

    var label: String {
        return switch state {
        case .loading:
            String.localizedString("ConstructedMulliganGuidePreLobby_Status_Loading", comment: "")
        case .no_data:
            String.localizedString("ConstructedMulliganGuidePreLobby_Status_NoData", comment: "")
        case .v1_ready:
            String.localizedString("ConstructedMulliganGuidePreLobby_Status_V1Ready", comment: "")
        case .v2_ready:
            String.localizedString("ConstructedMulliganGuidePreLobby_Status_V2Ready", comment: "")
        case .v2_partial:
            String.localizedString("ConstructedMulliganGuidePreLobby_Status_Partial", comment: "")
        default:
            "\(state)"
        }
    }
    
    var labelVisibility: Bool {
        return isFocused
    }
}

class ConstructedMulliganGuidePreLobbyViewModel: ViewModel {
    private var _deckStatusByDeckstring = [BnetGameType: [String: SingleDeckState]]()
    
    override init() {
        // TODO: HSReplayNetOAuth.AccountDataUpdated += () => Core.Overlay.UpdateMulliganGuidePreLobby();
        // TODO: HSReplayNetOAuth.LoggedOut += () => Core.Overlay.UpdateMulliganGuidePreLobby();
    }
    
    // MARK: - Pagination
    var decksOnPage: [CollectionDeckBoxVisual?]? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            onPropertyChanged("pageStatus")
            onPropertyChanged("pageStatusRows")
            onPropertyChanged("validDecksOnPage")
        }
    }
 
    var validDecksOnPage: [CollectionDeckBoxVisual?]? {
        return decksOnPage?.map { x in
            guard let x else {
                return nil
            }
            if x.isShowingInvalidCardCount || x.invalidSideboardCardCount > 0 || x.missingSideboardCardCount > 0 {
                return nil
            }
            return x
        }
    }
    
    // MARK: - Deckstrings
    
    struct DeckData {
        var deckstring: String
        var hasRunes: Bool
        var dbfIds: [Int]
    }
    
    private var _decksByFormatAndDeckId = [FormatType: [Int64: DeckData]]()
    
    private static func isElligibleForFormat(deck: MirrorDeck, formatType: FormatType) -> Bool {
        let deckFormat = FormatType(rawValue: deck.formatType.intValue) ?? FormatType.ft_unknown
        return switch formatType {
        case .ft_standard:
            deckFormat == .ft_standard
        case .ft_wild:
            deckFormat == .ft_standard || deckFormat == .ft_wild
        case .ft_classic:
            deckFormat == .ft_classic
        case .ft_twist:
            deckFormat == .ft_twist
        default:
            false
        }
    }
    
    private static func getDeckDataByDeckId(formatType: FormatType) -> [Int64: DeckData] {
        var cache = [Int64: DeckData]()
        
        guard let decks = MirrorHelper.getDecks() else {
            return cache
        }
        for deck in decks {
            if !isElligibleForFormat(deck: deck, formatType: formatType) {
                continue
            }
            
            guard let hearthDbDeck = HearthDbConverter.toHearthDbDeck(deck: deck, format: formatType) else {
                continue
            }
            let dbfIds = hearthDbDeck.cards.flatMap { card in Array(repeating: card.dbfId, count: max(card.count, 1)) }
            let deckData = DeckData(deckstring: DeckSerializer.serialize(deck: hearthDbDeck) ?? "", hasRunes: hearthDbDeck.getHero()?.playerClass == .deathknight || hearthDbDeck.cards.any { x in x.tourist == CardClass.allCases.firstIndex(of: .deathknight) }, dbfIds: dbfIds)
            cache[deck.id.int64Value] = deckData
        }
        return cache
    }
    
    private func cacheDecks(formatType: FormatType) -> [Int64: DeckData] {
        let cache = ConstructedMulliganGuidePreLobbyViewModel.getDeckDataByDeckId(formatType: formatType)
        _decksByFormatAndDeckId[formatType] = cache
        return cache
    }
    
    // MARK: - VisualsFormatType
    
    var visualsFormatType: VisualsFormatType {
        get {
            return getProp(.vft_unknown)
        }
        set {
            setProp(newValue)
            onPropertyChanged("gameType")
            onPropertyChanged("formatType")
            onPropertyChanged("pageStatus")
            onPropertyChanged("pageStatusRows")
            if #available(macOS 10.15.0, *) {
                Task.detached {
                    await self.ensureLoaded()
                }
            }
        }
    }
    
    private var gameType: BnetGameType {
        return switch visualsFormatType {
        case .vft_standard:
            BnetGameType.bgt_ranked_standard
        case .vft_wild:
            BnetGameType.bgt_ranked_wild
        case .vft_twist:
            BnetGameType.bgt_ranked_twist
        case .vft_casual:
            BnetGameType.bgt_casual_wild
        default:
            BnetGameType.bgt_unknown
        }
    }
    
    var formatType: FormatType {
        return switch visualsFormatType {
        case .vft_standard:
            FormatType.ft_standard
        case .vft_wild:
            FormatType.ft_wild
        case .vft_twist:
            FormatType.ft_twist
        case .vft_casual:
            FormatType.ft_wild
        default:
            FormatType.ft_unknown
        }
    }
    
    // MARK: - Visibility
    var isModalOpen: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
            onPropertyChanged("visibility")
        }
    }
    
    var isInQueue: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
            onPropertyChanged("visibility")
        }
    }
    
    var visibility: Bool {
        return isModalOpen || isInQueue ? false : true
    }
    
    // MARK: -
    
    @available(macOS 10.15.0, *)
    private static func loadMulliganGuideStatus(gameType: BnetGameType, starLevel: Int?, decks: [DeckData]) async -> [String: SingleDeckState] {
        if decks.count == 0 {
            return [String: SingleDeckState]()
        }

        let deckstrings = decks.map { $0.deckstring }
        let parameters = MulliganGuideStatusParams(decks: deckstrings, game_type: gameType.rawValue, star_level: starLevel)
        let result = await HSReplayAPI.getMulliganGuideStatus(parameters: parameters)
        return Dictionary(uniqueKeysWithValues: deckstrings.map { x in
            let status = result?.decks[x].map { MulliganGuideStatusData.Status(rawValue: $0.status) ?? .NO_DATA } ?? .NO_DATA
            return (x, status == .READY ? SingleDeckState.v1_ready : SingleDeckState.no_data)
        })
    }

    // Standard Ranked/Friendly decks are checked against the Mulligan G-V2
    // status endpoint instead, which needs each deck's dbfIds (not just its
    // deckstring) to evaluate partial coverage card-by-card.
    @available(macOS 10.15.0, *)
    private static func loadMulliganV2Status(gameType: BnetGameType, starLevel: Int?, decks: [DeckData]) async -> [String: SingleDeckState] {
        if decks.count == 0 {
            return [String: SingleDeckState]()
        }

        // AppDelegate.instance().coreManager.game.currentRegion is a plain
        // cached property read (populated once, non-blocking, at tracking
        // startup - see CoreManager.swift) rather than calling
        // Helper.getCurrentRegion() directly here, which does its own
        // blocking retry loop (up to 10 * 2s sleeps) and would stall this
        // status refresh.
        let parameters = MulliganV2StatusParams(
            deck_boxes: decks.map { MulliganV2StatusParams.Deck(deckstring: $0.deckstring, dbf_ids: $0.dbfIds) },
            game_type: gameType.rawValue,
            star_level: starLevel,
            player_region: Region.toBnetRegion(region: AppDelegate.instance().coreManager.game.currentRegion)
        )
        let result = await HSReplayAPI.getMulliganV2Status(parameters: parameters)
        let statusByDeckstring = Dictionary(uniqueKeysWithValues: (result?.data ?? []).map { ($0.deckstring, $0.status) })
        return Dictionary(uniqueKeysWithValues: decks.map { deck in
            let status = statusByDeckstring[deck.deckstring].map { MulliganV2StatusData.Status(rawValue: $0) ?? .NONE } ?? .NONE
            let state: SingleDeckState = switch status {
            case .SUPPORTED: .v2_ready
            case .PARTIAL: .v2_partial
            case .NONE: .no_data
            }
            return (deck.deckstring, state)
        })
    }
    
    @available(macOS 10.15.0, *)
    func ensureLoaded() async {
        await update(true)
        await update()
    }
    
    @available(macOS 10.15.0, *)
    private func update(_ onlyVisibilePage: Bool = false) async {
        if gameType == .bgt_unknown || formatType == .ft_unknown {
            return
        }
        
        // Generate the deckstrings for the current format
        
        let deckboxes = _decksByFormatAndDeckId[formatType].map { x in x } ?? cacheDecks(formatType: formatType)
        
        // Assemble the deck strings that are not known yet
        if _deckStatusByDeckstring[gameType] == nil {
            _deckStatusByDeckstring[gameType] = [String: SingleDeckState]()
        }
        var toLoad = [DeckData]()
        if onlyVisibilePage {
            guard let validDecksOnPage else {
                return
            }
            for box in validDecksOnPage {
                guard let box, let deckId = box.deckid else {
                    continue
                }
                if let deckData = deckboxes[deckId], _deckStatusByDeckstring[gameType]?[deckData.deckstring] == nil {
                    toLoad.append(deckData)
                    _deckStatusByDeckstring[gameType]?[deckData.deckstring] = .loading
                }
            }
        } else {
            for deckbox in deckboxes.values where _deckStatusByDeckstring[gameType]?[deckbox.deckstring] == nil {
                toLoad.append(deckbox)
                _deckStatusByDeckstring[gameType]?[deckbox.deckstring] = .loading
            }
        }
        
        onPropertyChanged("pageStatus")
        onPropertyChanged("pageStatusRows")
        
        // Assemble the request
        if toLoad.count > 0 {
            let medalInfo = MirrorHelper.getMedalData()
            var starLevel: Int?
            if let medalInfo {
                let medalInfoData: MirrorMedalInfo? = switch visualsFormatType {
                case .vft_standard:
                    medalInfo.standard
                case .vft_wild:
                    medalInfo.wild
                case .vft_classic:
                    medalInfo.classic
                case .vft_twist:
                    medalInfo.twist
                default:
                    nil
                }
                starLevel = medalInfoData?.starLevel.intValue
            }
            // It's important to copy this out, because it can change while awaiting the mulligan guide status
            // => this would lead to a "miscache"
            let theGameType = gameType
            let results = theGameType == .bgt_ranked_standard
                ? await ConstructedMulliganGuidePreLobbyViewModel.loadMulliganV2Status(gameType: theGameType, starLevel: starLevel, decks: toLoad)
                : await ConstructedMulliganGuidePreLobbyViewModel.loadMulliganGuideStatus(gameType: theGameType, starLevel: starLevel, decks: toLoad)

            for result in results {
                _deckStatusByDeckstring[theGameType]?[result.key] = result.value
            }
            
            onPropertyChanged("pageStatus")
            onPropertyChanged("pageStatusRows")
        }
    }
    
    var pageStatus: [SingleDeckStatus] {
        guard let validDecksOnPage, formatType != .ft_unknown, let deckMap = _decksByFormatAndDeckId[formatType], let allDecks = _deckStatusByDeckstring[gameType] else {
            return [SingleDeckStatus]()
        }
        return validDecksOnPage.compactMap { x in
            if let box = x, let deckId = box.deckid, let deckData = deckMap[deckId] {
                // At this point we know the deck is valid for this format, so either fetch the API status or show NO_DATA
                if let state = allDecks[deckData.deckstring] {
                    return SingleDeckStatus(state: state, hasRunes: deckData.hasRunes, isFocused: box.isFocused || box.isSelected)
                }
                return SingleDeckStatus(state: .no_data, hasRunes: deckData.hasRunes, isFocused: box.isSelected)
            }
            return SingleDeckStatus()
        }
    }
    
    // PageStatus, but grouped into 3 rows of 3 cols
    var pageStatusRows: [[SingleDeckStatus]] {

        return pageStatus.chunks(3)
    }
    
    func invalidateDeck(deckId: Int64) {
        // Clear from deckId -> deckstring mapping
        for formatType in _decksByFormatAndDeckId.keys {
            _decksByFormatAndDeckId[formatType]?.removeValue(forKey: deckId)
        }
    }
    
    func invlidateAllDecks() {
        _decksByFormatAndDeckId.removeAll()
    }

    // Matches HDT's GameEventHandler.IsDeckAvailableForMulliganGuide(): reuses
    // this same badge-grid status cache to decide whether a non-premium
    // player's trial should even be spent on this deck - only decks the
    // status check already confirmed have real (or partial) coverage are
    // worth burning a trial on.
    func isDeckAvailableForMulliganGuide(gameType: BnetGameType, deckstring: String) -> Bool {
        guard let state = _deckStatusByDeckstring[gameType]?[deckstring] else {
            return false
        }
        switch state {
        case .v1_ready, .v2_ready, .v2_partial:
            return true
        default:
            return false
        }
    }

    func reset() {
        _decksByFormatAndDeckId.removeAll()
        _deckStatusByDeckstring.removeAll()
    }
}

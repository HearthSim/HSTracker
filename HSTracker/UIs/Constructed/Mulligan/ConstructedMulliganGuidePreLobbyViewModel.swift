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
         ready
}

class SingleDeckStatus {
    private(set) var visibility: Bool
    private(set) var state: SingleDeckState
    private(set) var cardClass: CardClass
    private(set) var isFocused: Bool
    var padding: Int {
        return cardClass == .deathknight ? 29 : 15
    }
    
    init() {
        visibility = false
        state = .invalid
        cardClass = .invalid
        isFocused = false
    }
    
    init(state: SingleDeckState, cardClass: CardClass, isFocused: Bool) {
        self.visibility = true
        self.state = state
        self.cardClass = cardClass
        self.isFocused = isFocused
    }
    
    var iconVisibility: Bool {
        return switch state {
        case .ready, .no_data, .loading:
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
        default:
            "#CC00AA00"
        }
    }
        
    var background: String {
        return switch state {
        case .no_data:
            "#CC1A1100"
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
        case .ready:
            String.localizedString("ConstructedMulliganGuidePreLobby_Status_Ready", comment: "")
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
        var cardClass: CardClass
        var deckstring: String
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
            let deckData = DeckData(cardClass: hearthDbDeck.getHero()?.playerClass ?? .invalid, deckstring: DeckSerializer.serialize(deck: hearthDbDeck) ?? "")
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
    private static func loadMulliganGuideStatus(gameType: BnetGameType, starLevel: Int?, deckstrings: [String]) async -> [String: MulliganGuideStatusData.Status] {
        if deckstrings.count == 0 {
            return [String: MulliganGuideStatusData.Status]()
        }
        
        let parameters = MulliganGuideStatusParams(decks: deckstrings, game_type: gameType.rawValue, star_level: starLevel)
        let result = await HSReplayAPI.getMulliganGuideStatus(parameters: parameters)
        return Dictionary(uniqueKeysWithValues: deckstrings.compactMap { x in
            if let res = result?.decks[x] {
                return (x, MulliganGuideStatusData.Status(rawValue: res.status) ?? .NO_DATA)
            } else {
                return (x, MulliganGuideStatusData.Status.NO_DATA)
            }
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
        var toLoad = [String]()
        if onlyVisibilePage {
            guard let validDecksOnPage else {
                return
            }
            for box in validDecksOnPage {
                guard let box, let deckId = box.deckid else {
                    continue
                }
                if let deckData = deckboxes[deckId], _deckStatusByDeckstring[gameType]?[deckData.deckstring] == nil {
                    toLoad.append(deckData.deckstring)
                    _deckStatusByDeckstring[gameType]?[deckData.deckstring] = .loading
                }
            }
        } else {
            for deckbox in deckboxes.values where _deckStatusByDeckstring[gameType]?[deckbox.deckstring] == nil {
                toLoad.append(deckbox.deckstring)
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
            let results = await ConstructedMulliganGuidePreLobbyViewModel.loadMulliganGuideStatus(gameType: theGameType, starLevel: starLevel, deckstrings: toLoad)
            
            for result in results {
                _deckStatusByDeckstring[theGameType]?[result.key] = switch result.value {
                case .READY:
                    SingleDeckState.ready
                default:
                    SingleDeckState.no_data
                }
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
                    return SingleDeckStatus(state: state, cardClass: deckData.cardClass, isFocused: box.isFocused || box.isSelected)
                }
                return SingleDeckStatus(state: .no_data, cardClass: deckData.cardClass, isFocused: box.isSelected)
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
    
    func reset() {
        _decksByFormatAndDeckId.removeAll()
        _deckStatusByDeckstring.removeAll()
    }
}

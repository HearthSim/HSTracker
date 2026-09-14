//
//  ArenaLastDrafts.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/13/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

//swiftlint:disable nesting
final class ArenaLastDrafts: Initializable {
    static let instance = ArenaLastDrafts.load()
    
    var drafts = [DraftItem]()
    
    private static var dataPath = Paths.HSTracker.appendingPathComponent("ArenaLastDrafts.json")
    
    internal init() {
        
    }
    
    private static func load() -> ArenaLastDrafts {
        let res: ArenaLastDrafts = JsonManager.load(dataPath)
        return res
    }
    
    private func getPlayerId() -> String? {
        if let accountId = UploadMetaData.retryWhileNull(f: MirrorHelper.getAccountId, tries: 2, delay: 3000) {
            return "\(accountId.hi)_\(accountId.lo)"
        }
        return nil
    }
    
    public func playerDrafts() -> [DraftItem] {
        if let playerId = getPlayerId() {
            return drafts.filter { draft in draft.player == nil || draft.player == playerId }
        }
        return [DraftItem]()
    }
    
    //swiftlint:disable function_parameter_count
    public func addPick(_ startTime: Date, _ pickedTime: Date, _ picked: String, _ choices: [String], _ slot: Int, _ overlayVisible: Bool, _ pickedCards: [String], _ deckId: Int64, _ isUnderground: Bool, _ pickedPackage: [String]?, _ packages: [String: [String]]?, isOverlayEnabled: Bool = false, isArenasmithAvailable: Bool = false, isTrialsActivated: Bool = false, arenasmithScores: [String: Float]? = nil, _ save: Bool = true) {
        guard let playerId = getPlayerId() else {
            logger.info("Unable to save the game. user account can not be found...")
            return
        }

        // DraftItem is a struct, so this has to write back through the index rather
        // than mutating a returned copy - otherwise the pick is appended to a
        // temporary and silently lost.
        let draftIndex = indexOfDraft(startTime, playerId, deckId, isUnderground)

        // HDT stores (int)timeSpent.TotalMilliseconds, and the API documents
        // time_on_choice in milliseconds; timeIntervalSince is in seconds.
        let timeSpent = pickedTime.timeIntervalSince(startTime) * 1000

        drafts[draftIndex].picks.append(PickItem(picked, choices, slot, Int(timeSpent), overlayVisible, pickedCards, pickedPackage, packages,
                                                 isOverlayEnabled, isArenasmithAvailable, isTrialsActivated, arenasmithScores))

        if save {
            ArenaLastDrafts.save()
        }
    }
    //swiftlint:enable function_parameter_count

    //swiftlint:disable function_parameter_count
    public func addRedraftPick(_ startTime: Date, _ pickedTime: Date, _ picked: String, _ choices: [String], _ slot: Int, _ overlayVisible: Bool, _ originalDeck: [String], _ redraftPickedCards: [String], _ originalDeckId: Int64, _ redraftDeckId: Int64, _ losses: Int, _ isUnderground: Bool, isOverlayEnabled: Bool = false, isArenasmithAvailable: Bool = false, isTrialsActivated: Bool = false, arenasmithScores: [String: Float]? = nil, _ save: Bool = true) {
        guard let playerId = getPlayerId() else {
            logger.info("Unable to save the game. User account can not found...")
            return
        }

        let draftIndex = indexOfDraft(startTime, playerId, originalDeckId, isUnderground)
        let redraftIndex = indexOfRedraft(draftIndex, startTime, playerId, originalDeckId, redraftDeckId, losses, originalDeck, isUnderground)

        let timeSpent = pickedTime.timeIntervalSince(startTime) * 1000

        drafts[draftIndex].redrafts[redraftIndex].picks.append(
            RedraftPickItem(picked, choices, slot, Int(timeSpent), overlayVisible, redraftPickedCards,
                            isOverlayEnabled, isArenasmithAvailable, isTrialsActivated, arenasmithScores))

        if save {
            ArenaLastDrafts.save()
        }
    }
    //swiftlint:enable function_parameter_count

    public func removeDraft(_ player: String, _ isUnderground: Bool, _ save: Bool = true) {
        // the same player can't have 2 drafts of same type open at same time
        if let existingEntry = drafts.firstIndex(where: { x in x.player != nil && x.player == player && x.isUnderground == isUnderground }) {
            drafts.remove(at: existingEntry)
        }
        if save {
            ArenaLastDrafts.save()
        }
    }

    static public func save() {
        JsonManager.save(dataPath, instance)
    }
    
    func reset() {
        drafts.removeAll()
        ArenaLastDrafts.save()
    }
    
    private func indexOfDraft(_ startTime: Date, _ player: String, _ deckId: Int64, _ isUnderground: Bool) -> Int {
        if let index = drafts.firstIndex(where: { $0.deckId == deckId && $0.isUnderground == isUnderground }) {
            return index
        }

        removeDraft(player, isUnderground, false)
        drafts.append(DraftItem(startTime, player, deckId, isUnderground))
        return drafts.count - 1
    }

    //swiftlint:disable:next function_parameter_count
    private func indexOfRedraft(_ draftIndex: Int, _ startTime: Date, _ player: String, _ originalDeckId: Int64, _ redraftDeckId: Int64, _ losses: Int, _ originalDeck: [String], _ isUnderground: Bool) -> Int {
        if let index = drafts[draftIndex].redrafts.firstIndex(where: { $0.redraftedDeckId == redraftDeckId && $0.losses == losses }) {
            return index
        }

        drafts[draftIndex].redrafts.append(
            RedraftItem(startTime, player, originalDeckId, redraftDeckId, losses, originalDeck, isUnderground))
        return drafts[draftIndex].redrafts.count - 1
    }

    struct DraftItem: Codable {
        var player: String?
        var startTime: Date?
        var deckId: Int64
        var isUnderground: Bool
        var picks = [PickItem]()
        var redrafts = [RedraftItem]()
        
        enum CodingKeys: String, CodingKey {
            case player = "Player"
            case startTime = "StartTime"
            case deckId = "DeckId"
            case isUnderground = "IsUnderground"
            case picks = "Pick"
            case redrafts = "Redraft"
        }
        
        init(_ startTime: Date, _ player: String, _ deckId: Int64, _ isUnderground: Bool) {
            self.player = player
            self.startTime = startTime
            self.deckId = deckId
            self.isUnderground = isUnderground
        }
    }
    
    struct PickItem: Codable {
        var slot: Int
        var picked: String?
        var choices = [String]()
        var timeOnChoice: Int
        var overlayVisible: Bool
        var overlayEnabled: Bool
        var arenasmithAvailable: Bool
        var trialsActivated: Bool
        var arenasmithScores: [ArenasmithScore]?
        var pickedCards = [String]()
        var pickedPackage: [String]?
        var packages: [CardPackage]?
        
        enum CodingKeys: String, CodingKey {
            case slot = "Slot"
            case picked = "Picked"
            case choices = "Choices"
            case timeOnChoice = "TimeOnChoice"
            case overlayVisible = "OverlayVisitible"
            case overlayEnabled = "OverlayEnabled"
            case arenasmithAvailable = "ArenasmithAvailable"
            case trialsActivated = "TrialsActivated"
            case arenasmithScores = "ArenasmithScores"
            case pickedCards = "PickedCards"
            case pickedPackage = "PickedPackage"
            case packages = "Packages"
        }
        
        //swiftlint:disable:next function_parameter_count
        init(_ picked: String, _ choices: [String], _ slot: Int, _ timeOnChoice: Int, _ overlayVisible: Bool, _ pickedCards: [String], _ pickedPackage: [String]?, _ packages: [String: [String]]?, _ overlayEnabled: Bool, _ arenasmithAvailable: Bool, _ trialsActivated: Bool, _ arenasmithScores: [String: Float]?) {
            self.picked = picked
            self.choices = choices
            self.slot = slot
            self.timeOnChoice = timeOnChoice
            self.overlayVisible = overlayVisible
            self.overlayEnabled = overlayEnabled
            self.arenasmithAvailable = arenasmithAvailable
            self.trialsActivated = trialsActivated
            self.arenasmithScores = arenasmithScores?.map { ArenasmithScore(cardId: $0.key, score: $0.value) }
            self.pickedCards = pickedCards
            self.pickedPackage = pickedPackage
            self.packages = packages?.compactMap({ p in CardPackage(keyCard: p.key, cards: p.value)})
        }
    }
    
    struct ArenasmithScore: Codable {
        var cardId: String
        var score: Float
        
        enum CodingKeys: String, CodingKey {
            case cardId = "CardId"
            case score = "Score"
        }
    }
    
    struct CardPackage: Codable {
        var keyCard: String?
        var cards = [String]()
        
        enum CodingKeys: String, CodingKey {
            case keyCard = "KeyCard"
            case cards = "Card"
        }
    }
    
    struct RedraftItem: Codable {
        var player: String?
        var startTime: Date?
        var originalDeckId: Int64
        var redraftedDeckId: Int64
        var losses: Int
        var isUnderground: Bool
        var originalDeck = [String]()
        var picks = [RedraftPickItem]()
        
        enum CodingKeys: String, CodingKey {
            case player = "Player"
            case startTime = "StartTime"
            case originalDeckId = "OriginalDeckId"
            case redraftedDeckId = "RedraftedDeckId"
            case losses = "Losses"
            case isUnderground = "IsUnderground"
            case originalDeck = "OriginalDeck"
            case picks = "Pick"
        }
        
        init(_ startTime: Date, _ player: String, _ originalDeckId: Int64, _ redraftDeckId: Int64, _ losses: Int, _ originalDeck: [String], _ isUnderground: Bool) {
            self.startTime = startTime
            self.player = player
            self.originalDeckId = originalDeckId
            self.redraftedDeckId = redraftDeckId
            self.losses = losses
            self.originalDeck = originalDeck
            self.isUnderground = isUnderground
        }
    }
    
    struct RedraftPickItem: Codable {
        var slot: Int
        var picked: String?
        var choices = [String]()
        var timeOnChoice: Int
        var overlayVisible: Bool
        var overlayEnabled: Bool
        var arenasmithAvailable: Bool
        var trialsActivated: Bool
        var arenasmithScores: [ArenasmithScore]?
        var redraftPickedCards = [String]()
        
        enum CodingKeys: String, CodingKey {
            case slot = "Slot"
            case picked = "Picked"
            case choices = "Choice"
            case timeOnChoice = "TimeOnChoice"
            case overlayVisible = "OverlayVisitible"
            case overlayEnabled = "OverlayEnabled"
            case arenasmithAvailable = "ArenasmithAvailable"
            case trialsActivated = "TrialsActivated"
            case arenasmithScores = "ArenasmithScores"
            case redraftPickedCards = "RedraftPickedCards"
        }
        
        //swiftlint:disable:next function_parameter_count
        init(_ picked: String, _ choices: [String], _ slot: Int, _ timeOnChoice: Int, _ overlayVisible: Bool, _ redraftedPickedCards: [String], _ overlayEnabled: Bool, _ arenasmithAvailable: Bool, _ trialsActivated: Bool, _ arenasmithScores: [String: Float]?) {
            self.picked = picked
            self.choices = choices
            self.slot = slot
            self.timeOnChoice = timeOnChoice
            self.overlayVisible = overlayVisible
            self.overlayEnabled = overlayEnabled
            self.arenasmithAvailable = arenasmithAvailable
            self.trialsActivated = trialsActivated
            self.arenasmithScores = arenasmithScores?.map { ArenasmithScore(cardId: $0.key, score: $0.value) }
            self.redraftPickedCards = redraftedPickedCards
        }
    }
}
//swiftlint:enable nesting

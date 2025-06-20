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
    private static var instance = {
        return ArenaLastDrafts.load()
    }()
    
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
    
    public func addPick(_ startTime: Date, _ pickedTime: Date, _ picked: String, _ choices: [String], _ slot: Int, _ overlayVisible: Bool, _ pickedCards: [String], _ deckId: Int64, _ isUnderground: Bool, _ pickedPackage: [String]?, _ packages: [String: [String]]?, _ save: Bool = true) {
        guard let playerId = getPlayerId() else {
            logger.info("Unable to save the game. user account can not be found...")
            return
        }
        
        var currentDraft = getOrCreateDraft(startTime, playerId, deckId, isUnderground)
        
        let start = startTime
        let end = pickedTime
        let timeSpent = end.timeIntervalSince(start)
        
        currentDraft.picks.append(PickItem(picked, choices, slot, Int(timeSpent), overlayVisible, pickedCards, pickedPackage, packages))
        
        if save {
            ArenaLastDrafts.save()
        }
    }
    
    public func addRedraftPick(_ startTime: Date, _ pickedTime: Date, _ picked: String, _ choices: [String], _ slot: Int, _ overlayVisible: Bool, _ originalDeck: [String], _ redraftPickedCards: [String], _ originalDeckId: Int64, _ redraftDeckId: Int64, _ losses: Int, _ isUnderground: Bool, _ save: Bool = true) {
        guard let playerId = getPlayerId() else {
            logger.info("Unable to save the game. User account can not found...")
            return
        }

        var currentDraft = getOrCreateDraft(startTime, playerId, originalDeckId, isUnderground)
        var currentRedraft = getOrCreateRedraft(&currentDraft, startTime, playerId, originalDeckId, redraftDeckId, losses, originalDeck, isUnderground)

        let start = startTime
        let end = pickedTime
        let timeSpent = end.timeIntervalSince(start)

        currentRedraft.picks.append(RedraftPickItem(picked, choices, slot, Int(timeSpent), overlayVisible, redraftPickedCards))

        if save {
            ArenaLastDrafts.save()
        }
    }
    
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
    
    private func getOrCreateDraft(_ startTime: Date, _ player: String, _ deckId: Int64, _ isUnderground: Bool) -> DraftItem {
        if let draft = drafts.first(where: { d in d.deckId == deckId && d.isUnderground == isUnderground }) {
            return draft
        }

        let draft = DraftItem(startTime, player, deckId, isUnderground)
        removeDraft(player, isUnderground, false)
        drafts.append(draft)
        return draft
    }

    private func getOrCreateRedraft(_ currentDraft: inout DraftItem, _ startTime: Date, _ player: String, _ originalDeckId: Int64, _ redraftDeckId: Int64, _ losses: Int, _ originalDeck: [String], _ isUnderground: Bool) -> RedraftItem {
        if let redraft = currentDraft.redrafts.first(where: { r in r.redraftedDeckId == redraftDeckId && r.losses == losses }) {
            return redraft
        }

        let redraft = RedraftItem(startTime, player, originalDeckId, redraftDeckId, losses, originalDeck, isUnderground)
        currentDraft.redrafts.append(redraft)
        return redraft
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
        var pickedCards = [String]()
        var pickedPackage: [String]?
        var packages: [CardPackage]?
        
        enum CodingKeys: String, CodingKey {
            case slot = "Slot"
            case picked = "Picked"
            case choices = "Choices"
            case timeOnChoice = "TimeOnChoice"
            case overlayVisible = "OverlayVisitible"
            case pickedCards = "PickedCards"
            case pickedPackage = "PickedPackage"
            case packages = "Packages"
        }
        
        init(_ picked: String, _ choices: [String], _ slot: Int, _ timeOnChoice: Int, _ overlayVisible: Bool, _ pickedCards: [String], _ pickedPackage: [String]?, _ packages: [String: [String]]?) {
            self.picked = picked
            self.choices = choices
            self.slot = slot
            self.timeOnChoice = timeOnChoice
            self.overlayVisible = overlayVisible
            self.pickedCards = pickedCards
            self.pickedPackage = pickedPackage
            self.packages = packages?.compactMap({ p in CardPackage(keyCard: p.key, cards: p.value)})
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
        var redraftPickedCards = [String]()
        
        enum CodingKeys: String, CodingKey {
            case slot = "Slot"
            case picked = "Picked"
            case choices = "Choice"
            case timeOnChoice = "TimeOnChoice"
            case overlayVisible = "OverlayVisitible"
            case redraftPickedCards = "RedraftPickedCards"
        }
        
        init(_ picked: String, _ choices: [String], _ slot: Int, _ timeOnChoice: Int, _ overlayVisible: Bool, _ redraftedPickedCards: [String]) {
            self.picked = picked
            self.choices = choices
            self.slot = slot
            self.timeOnChoice = timeOnChoice
            self.overlayVisible = overlayVisible
            self.redraftPickedCards = redraftedPickedCards
        }
    }
}
//swiftlint:enable nesting

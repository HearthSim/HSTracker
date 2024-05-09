//
//  BattlegroundsLastGames.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/15/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsLastGames: Codable {
    struct GameItem: Codable {
        var player: String?
        var startTime: Date
        var endTime: Date
        var hero: String
        var rating: Int
        var ratingAfter: Int
        var placement: Int
        var finalBoard: FinalBoardItem?
        var friendlyGame: Bool?
        var duos: Bool?
        
        init(startTime: Date, endTime: Date, hero: String, rating: Int, ratingAfter: Int, placement: Int, finalBoard: [Entity], friendlyGame: Bool, player: String, duos: Bool) {
            self.startTime = startTime
            self.endTime = endTime
            self.hero = hero
            self.rating = rating
            self.ratingAfter = ratingAfter
            self.placement = placement
            self.finalBoard = FinalBoardItem(finalBoard: finalBoard)
            self.friendlyGame = friendlyGame
            self.player = player
            self.duos = duos
        }
    }
    
    struct FinalBoardItem: Codable {
        var minions: [MinionItem]
        
        init(finalBoard: [Entity]) {
            self.minions = finalBoard.compactMap({ x in MinionItem(entity: x)})
        }
    }
    
    struct MinionItem: Codable {
        var cardId: String
        var tags: [TagItem]
        
        init(entity: Entity) {
            cardId = entity.cardId
            tags = entity.tags.compactMap({ (k, v) in TagItem(key: k.rawValue, value: v)})
        }
    }
    
    struct TagItem: Codable {
        var tag: Int
        var value: Int
        
        init(key: Int, value: Int) {
            tag = key
            self.value = value
        }
    }
                                        
    private static var _instance: BattlegroundsLastGames?
    
    static var instance: BattlegroundsLastGames {
        if let inst = _instance {
            return inst
        }
        let inst = BattlegroundsLastGames.load()
        _instance = inst
        return inst
    }
    
    var games = [GameItem]()
    
    private static let cacheFilePath = Paths.HSTracker.appendingPathComponent("BgsLastGames.json")
    
    init() {
        
    }
    
    private static func load() -> BattlegroundsLastGames {
        if !FileManager.default.fileExists(atPath: BattlegroundsLastGames.cacheFilePath.path) {
            return BattlegroundsLastGames()
        }
        do {
            let data = try Data(contentsOf: BattlegroundsLastGames.cacheFilePath)
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            let account = try dec.decode(BattlegroundsLastGames.self, from: data)
            return account
        } catch {
            logger.error("Error loading BattlegroundsLastGames cache: \(error)")
        }
        return BattlegroundsLastGames()
    }
    
    private func getPlayerId() -> String? {
        if let accountId = MirrorHelper.getAccountId() {
            return "\(accountId.hi.int64Value)_\(accountId.lo.intValue)"
        }
        return nil
    }
    
    func getPlayerGames(duos: Bool) -> [GameItem] {
        guard let playerId = getPlayerId() else {
            return [GameItem]()
        }
        return games.filter { g in (g.player == nil || g.player == playerId) && (g.duos == duos || (g.duos == nil && !duos)) }
    }
    
    func addGame(startTime: Date, endTime: Date, hero: String, rating: Int, ratingAfter: Int, placement: Int, finalBoard: [Entity], friendlyGame: Bool, duos: Bool, save: Bool = true) {
        guard let playerId = getPlayerId() else {
            logger.info("Unable to save the game. User account can not found...")
            return
        }
        removeGame(startTime: startTime, save: false)
        games.append(GameItem(startTime: startTime, endTime: endTime, hero: hero, rating: rating, ratingAfter: ratingAfter, placement: placement, finalBoard: finalBoard, friendlyGame: friendlyGame, player: playerId, duos: duos))
        if save {
            self.save()
        }
    }
    
    func removeGame(startTime: Date, save: Bool = false) {
        games.removeAll { x in x.startTime == startTime }
        if save {
            self.save()
        }
    }
    
    func save() {
        do {
            let enc = JSONEncoder()
            enc.dateEncodingStrategy = .iso8601
            let json = try enc.encode(BattlegroundsLastGames.instance)
            try json.write(to: BattlegroundsLastGames.cacheFilePath)
        } catch {
            logger.error("Error while saving BattlegroundsLastGames data: \(error)")
        }
    }
    
    func reset() {
        games.removeAll()
        save()
    }

}

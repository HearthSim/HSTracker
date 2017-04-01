//
//  ReplayMaker.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import Wrap
import ZipArchive

final class ReplayMaker {
    private static var points = [ReplayKeyPoint]()

    static func reset() { points.removeAll() }

    static func generate(type: KeyPointType, id: Int, player: PlayerType, eventHandler: PowerEventHandler) {
        let replay = ReplayKeyPoint(data: eventHandler.entities.map { $0.1 },
                                    type: type,
                                    id: id,
                                    player: player)
        points.append(replay)
    }
    
    public static let dateStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
        return formatter
    }()

    static func saveToDisk(powerLog: [LogLine]) {
        guard points.count > 0 else {
            Log.warning?.message("replay is empty, skipping")
            return
        }

        let log = powerLog.sorted { $0.time < $1.time }.map { $0.line }

        resolveZonePos()
        resolveCardIds()
        removeObsoletePlays()
		
		/* TODO: better way of handling this, game might be already "old"
        guard let player = points.last?.data.firstWhere({$0.isPlayer}) else {
            Log.warning?.message("Replay : cannot get player, skipping")
            return
        }
        guard let opponent = points.last?.data
            .firstWhere({$0.has(tag: .player_id) && !$0.isPlayer}) else {
                Log.warning?.message("Replay : cannot get opponent, skipping")
                return
        }
        
        guard let playerHero = points.last?.data
            .firstWhere({$0[.cardtype] == CardType.hero.rawValue
                && $0.isControlled(by: player[.controller])
            }) else {
                Log.warning?.message("Replay : playerHero is nil, skipping")
                return
        }
        
        var opponentHero = points.last?.data
            .firstWhere({$0[.cardtype] == CardType.hero.rawValue &&
                $0.isControlled(by: opponent[.controller])
            })
        
        if opponentHero == nil {
            // adventure bosses
            opponentHero = points.last?.data
                .firstWhere({
                    !$0.cardId.isBlank
                        && (($0.cardId.hasPrefix("NAX") && $0.cardId.contains("_01"))
                            || $0.cardId.hasPrefix("BRMA"))
                        && Cards.hero(byId: $0.cardId) != nil
                })
            if opponentHero == nil {
                Log.warning?.message("Replay : opponentHero is nil")
                return
            }
            resolve(opponentName: Cards.hero(byId: opponentHero!.cardId)?.name)
        }
        
        if let playerName = player.name,
            let playerHeroName = Cards.hero(byId: playerHero.cardId)?.name,
            let opponentName = opponent.name,
            let opponentHeroName = Cards.hero(byId: opponentHero!.cardId)?.name {

            let path = Paths.replays
            let tmp = Paths.tmpReplays
                
            let output = tmp.appendingPathComponent("output_log.txt")
            do {
                try log.joined(separator: "\n").write(to: output,
                                                      atomically: true,
                                                      encoding: .utf8)
            } catch {
                Log.error?.message("Can not save powerLog")
                return
            }

            let dateStr = ReplayMaker.dateStringFormatter.string(from: Date())
            
            let name = "\(dateStr) - \(playerName)(\(playerHeroName)) vs "
                + "\(opponentName)(\(opponentHeroName)).hdtreplay"
            let filename = path.appendingPathComponent(name)

            SSZipArchive.createZipFile(atPath: filename.path, withFilesAtPaths: [output.path])
            Log.info?.message("Replay saved to \(filename)")
            
            do {
                try FileManager.default.removeItem(at: output)
            } catch {
                Log.error?.message("Can not remove tmp files")
            }

            reset()
        }*/
    }

	private static func resolve(opponentName: String?, eventHandler: PowerEventHandler) {
        if opponentName == nil {
            return
        }
        for kp in points {
			if let opponent = kp.data.firstWhere({ $0.has(tag: .player_id) && !$0.isPlayer(eventHandler: eventHandler) }) {
                opponent.name = opponentName
            }
        }
    }

    private static func resolveCardIds() {
        if let lastKeyPoint = points.last {
            for kp in points {
                for entity in lastKeyPoint.data {
                    if !entity.cardId.isBlank {
                        if let e2 = kp.data.firstWhere({ $0.id == entity.id }) {
                            e2.cardId = entity.cardId
                            e2.name = entity.name
                        }
                    }
                }
            }
        }
    }

    private static func resolveZonePos() {
        // ZONE_POSITION changes happen after draws, meaning drawn card will not appear.
        var handPos = [Int: Int]()
        var boardPos = [Int: Int]()
        points = points.reversed()
        for kp in points {
            if kp.type == .handPos {
                handPos[kp.id] = kp.data.firstWhere { $0.id == kp.id }?[.zone_position]
            } else if kp.type == .boardPos {
                boardPos[kp.id] = kp.data.firstWhere { $0.id == kp.id }?[.zone_position]
            } else if kp.type == .draw || kp.type == .obtain {
                if let zp = handPos[kp.id] {
                    kp.data.firstWhere { $0.id == kp.id }?[.zone_position] = zp
                    handPos[zp] = nil
                }
            } else if kp.type == .summon || kp.type == .play {
                if let zp = boardPos[kp.id] {
                    kp.data.firstWhere { $0.id == kp.id }?[.zone_position] = zp
                    boardPos[zp] = nil
                }
            }
        }
        let toRemove = points.filter { $0.type == .boardPos || $0.type == .handPos }
        for kp in toRemove {
            points.remove(kp)
        }

        // this one is still needed for hand zonepos I think...
        var occupiedZonePos = [Int]()
        var noUniqueZonePos = [Entity]()
        for kp in points {
            let currentEntity = kp.data.firstWhere { $0.id == kp.id }
            if currentEntity == nil || !currentEntity!.has(tag: .zone_position) {
                continue
            }

            occupiedZonePos.removeAll()
            noUniqueZonePos.removeAll()
            noUniqueZonePos.append(currentEntity!)
            for entity in kp.data.filter({ $0.id != kp.id && $0.has(tag: .zone_position) }) {
                let zonePos = entity[.zone_position]
                if entity[.zone] == currentEntity![.zone]
                && entity[.controller] == currentEntity![.controller] {
                    if !occupiedZonePos.contains(zonePos) {
                        occupiedZonePos.append(zonePos)
                    } else {
                        noUniqueZonePos.append(entity)
                    }
                }
            }
            for entity in noUniqueZonePos {
                if occupiedZonePos.contains(entity[.zone_position]) {
                    if let max = occupiedZonePos.max() {
                        let targetPos = max + 1
                        currentEntity![.zone_position] = targetPos
                        occupiedZonePos.append(targetPos)
                    }
                } else {
                    occupiedZonePos.append(entity[.zone_position])
                }
            }
        }

        var onBoard = [Entity]()
        for kp in points {
            let currentBoard = kp.data
                .filter { $0.isInZone(zone: .play) && $0.has(tag: .health)
                    && !$0.cardId.isBlank && !$0.cardId.contains("HERO")
            }
            if onBoard.all({ (e) in
                currentBoard.any({ (e2) in e2.id == e.id }) })
                && currentBoard.all({ (e) in onBoard.any({ (e2) in e2.id == e.id }) }) {
                for entity in currentBoard {
                    if let pos = onBoard
                        .firstWhere({ (e) in e.id == entity.id })?[.zone_position] {
                        entity[.zone_position] = pos
                    }
                }
            } else {
                onBoard = currentBoard
            }
        }

        // re-reverse
        points = points.reversed()
    }

    private static func removeObsoletePlays() {
        let spellsWithTarget = points.filter { $0.type == .playSpell }.map { $0.id }
        let obsoletePlays = points
            .filter { (kp) in
                kp.type == .play && spellsWithTarget.any { (id) in id == kp.id }
        }
        for play in obsoletePlays {
            points.remove(play)
        }
    }
}

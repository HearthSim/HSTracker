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
    
    static func replayDir() -> String? {
        guard let appSupport = NSSearchPathForDirectoriesInDomains(
            .ApplicationSupportDirectory, .UserDomainMask, true).first else { return nil }
        
        let path = "\(appSupport)/HSTracker/replays"
        do {
            try NSFileManager.defaultManager()
                .createDirectoryAtPath(path,
                                       withIntermediateDirectories: true,
                                       attributes: nil)
        } catch {
            Log.error?.message("Can not create replays dir")
            return nil
        }
        return path
    }
    
    static func tmpReplayDir() -> String? {
        guard let path = replayDir() else { return nil }
        
        let tmp = "\(path)/tmp"
        do {
            try NSFileManager.defaultManager()
                .createDirectoryAtPath(tmp,
                                       withIntermediateDirectories: true,
                                       attributes: nil)
        } catch {
            Log.error?.message("Can not create replays tmp dir")
            return nil
        }
        return tmp
    }

    static func reset() { points.removeAll() }

    static func generate(type: KeyPointType, id: Int, player: PlayerType, game: Game) {
        let replay = ReplayKeyPoint(data: game.entities.map { $0.1 },
                                    type: type,
                                    id: id,
                                    player: player)
        points.append(replay)
    }

    static func saveToDisk(powerLog: [LogLine]) {
        guard points.count > 0 else {
            Log.warning?.message("replay is empty, skipping")
            return
        }

        let log = powerLog.sort { $0.time < $1.time }.map { $0.line }

        resolveZonePos()
        resolveCardIds()
        removeObsoletePlays()
        
        guard let player = points.last?.data.firstWhere({$0.isPlayer}) else {
            Log.warning?.message("Replay : cannot get player, skipping")
            return
        }
        guard let opponent = points.last?.data
            .firstWhere({$0.hasTag(.player_id) && !$0.isPlayer}) else {
                Log.warning?.message("Replay : cannot get opponent, skipping")
                return
        }
        
        guard let playerHero = points.last?.data
            .firstWhere({$0.getTag(.cardtype) == CardType.hero.rawValue
                && $0.isControlledBy(player.getTag(.controller))
            }) else {
                Log.warning?.message("Replay : playerHero is nil, skipping")
                return
        }
        
        var opponentHero = points.last?.data
            .firstWhere({$0.getTag(.cardtype) == CardType.hero.rawValue &&
                $0.isControlledBy(opponent.getTag(.controller))
            })
        
        if opponentHero == nil {
            // adventure bosses
            opponentHero = points.last?.data
                .firstWhere({
                    !String.isNullOrEmpty($0.cardId)
                        && (($0.cardId.hasPrefix("NAX") && $0.cardId.contains("_01"))
                            || $0.cardId.hasPrefix("BRMA"))
                        && Cards.hero(byId: $0.cardId) != nil
                })
            if opponentHero == nil {
                Log.warning?.message("Replay : opponentHero is nil")
                return
            }
            resolveOpponentName(Cards.hero(byId: opponentHero!.cardId)?.name)
        }
        
        if let playerName = player.name,
            playerHeroName = Cards.hero(byId: playerHero.cardId)?.name,
            opponentName = opponent.name,
            opponentHeroName = Cards.hero(byId: opponentHero!.cardId)?.name,
            path = replayDir(),
            tmp = tmpReplayDir() {
                
            let output = "\(tmp)/output_log.txt"
            do {
                try log.joinWithSeparator("\n").writeToFile(output,
                                                            atomically: true,
                                                            encoding: NSUTF8StringEncoding)
            } catch {
                Log.error?.message("Can not save powerLog")
                return
            }
            
            let filename = "\(path)/\(NSDate().utcFormatted) - \(playerName)(\(playerHeroName)) vs "
                + "\(opponentName)(\(opponentHeroName)).hdtreplay"
            
            SSZipArchive.createZipFileAtPath(filename, withFilesAtPaths: [output])
            Log.info?.message("Replay saved to \(filename)")
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(output)
            } catch {
                Log.error?.message("Can not remove tmp files")
            }
        }
    }

    private static func resolveOpponentName(opponentName: String?) {
        if opponentName == nil {
            return
        }
        for kp in points {
            if let opponent = kp.data.firstWhere({ $0.hasTag(.player_id) && !$0.isPlayer }) {
                opponent.name = opponentName
            }
        }
    }

    private static func resolveCardIds() {
        if let lastKeyPoint = points.last {
            for kp in points {
                for entity in lastKeyPoint.data {
                    if !String.isNullOrEmpty(entity.cardId) {
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
        points = points.reverse()
        for kp in points {
            if kp.type == .handPos {
                handPos[kp.id] = kp.data.firstWhere { $0.id == kp.id }?.getTag(.zone_position)
            } else if kp.type == .boardPos {
                boardPos[kp.id] = kp.data.firstWhere { $0.id == kp.id }?.getTag(.zone_position)
            } else if kp.type == .draw || kp.type == .obtain {
                if let zp = handPos[kp.id] {
                    kp.data.firstWhere { $0.id == kp.id }?.setTag(.zone_position, value: zp)
                    handPos[zp] = nil
                }
            } else if kp.type == .summon || kp.type == .play {
                if let zp = boardPos[kp.id] {
                    kp.data.firstWhere { $0.id == kp.id }?.setTag(.zone_position, value: zp)
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
            if currentEntity == nil || !currentEntity!.hasTag(.zone_position) {
                continue
            }

            occupiedZonePos.removeAll()
            noUniqueZonePos.removeAll()
            noUniqueZonePos.append(currentEntity!)
            for entity in kp.data.filter({ $0.id != kp.id && $0.hasTag(.zone_position) }) {
                let zonePos = entity.getTag(.zone_position)
                if entity.getTag(.zone) == currentEntity!.getTag(.zone)
                && entity.getTag(.controller) == currentEntity!.getTag(.controller) {
                    if !occupiedZonePos.contains(zonePos) {
                        occupiedZonePos.append(zonePos)
                    } else {
                        noUniqueZonePos.append(entity)
                    }
                }
            }
            for entity in noUniqueZonePos {
                if occupiedZonePos.contains(entity.getTag(.zone_position)) {
                    if let max = occupiedZonePos.maxElement() {
                        let targetPos = max + 1
                        currentEntity!.setTag(.zone_position, value: targetPos)
                        occupiedZonePos.append(targetPos)
                    }
                } else {
                    occupiedZonePos.append(entity.getTag(.zone_position))
                }
            }
        }

        var onBoard = [Entity]()
        for kp in points {
            let currentBoard = kp.data
                .filter { $0.isInZone(.play) && $0.hasTag(.health)
                    && !String.isNullOrEmpty($0.cardId) && !$0.cardId.contains("HERO")
            }
            if onBoard.all({ (e) in
                currentBoard.any({ (e2) in e2.id == e.id }) })
                && currentBoard.all({ (e) in onBoard.any({ (e2) in e2.id == e.id }) }) {
                for entity in currentBoard {
                    if let pos = onBoard
                        .firstWhere({ (e) in e.id == entity.id })?.getTag(.zone_position) {
                        entity.setTag(.zone_position, value: pos)
                    }
                }
            } else {
                onBoard = currentBoard
            }
        }

        // re-reverse
        points = points.reverse()
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

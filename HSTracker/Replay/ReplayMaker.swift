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

    static func saveToDisk(powerLog: [String]) {
        guard points.count > 0 else {
            Log.warning?.message("replay is empty, skipping")
            return
        }
        
        resolveZonePos()
        resolveCardIds()
        removeObsoletePlays()
        
        guard let player = points.last?.data.firstWhere({$0.isPlayer}) else {
            Log.warning?.message("Replay : cannot get player, skipping")
            return
        }
        guard let opponent = points.last?.data
            .firstWhere({$0.hasTag(.PLAYER_ID) && !$0.isPlayer}) else {
                Log.warning?.message("Replay : cannot get opponent, skipping")
                return
        }
        
        guard let playerHero = points.last?.data
            .firstWhere({$0.getTag(.CARDTYPE) == CardType.HERO.rawValue
                && $0.isControlledBy(player.getTag(.CONTROLLER))
            }) else {
                Log.warning?.message("Replay : playerHero is nil, skipping")
                return
        }
        
        var opponentHero = points.last?.data
            .firstWhere({$0.getTag(.CARDTYPE) == CardType.HERO.rawValue &&
                $0.isControlledBy(opponent.getTag(.CONTROLLER))
            })
        
        if opponentHero == nil {
            // adventure bosses
            opponentHero = points.last?.data
                .firstWhere({
                    !String.isNullOrEmpty($0.cardId)
                        && (($0.cardId.startsWith("NAX") && $0.cardId.contains("_01"))
                            || $0.cardId.startsWith("BRMA"))
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

            /*let data: NSData
            do {
                data = try Wrap(points)
            } catch {
                Log.error?.message("Can not convert points to json")
                return
            }
            
            let replay = "\(tmp)/replay.json"
            data.writeToFile(replay, atomically: true)
            */
                
            let output = "\(tmp)/output_log.txt"
            do {
                try powerLog.joinWithSeparator("\n").writeToFile(output,
                                                                 atomically: true,
                                                                 encoding: NSUTF8StringEncoding)
            } catch {
                Log.error?.message("Can not save powerLog")
                return
            }
            
            let filename = "\(path)/\(NSDate().utcFormatted) - \(playerName)(\(playerHeroName)) vs "
                + "\(opponentName)(\(opponentHeroName)).hdtreplay"
            
            SSZipArchive.createZipFileAtPath(filename, withFilesAtPaths: [/*replay, */output])
            Log.info?.message("Replay saved to \(filename)")
            
            do {
                //try NSFileManager.defaultManager().removeItemAtPath(replay)
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
            if let opponent = kp.data.firstWhere({ $0.hasTag(.PLAYER_ID) && !$0.isPlayer }) {
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
            if kp.type == .HandPos {
                handPos[kp.id] = kp.data.firstWhere { $0.id == kp.id }?.getTag(.ZONE_POSITION)
            } else if kp.type == .BoardPos {
                boardPos[kp.id] = kp.data.firstWhere { $0.id == kp.id }?.getTag(.ZONE_POSITION)
            } else if kp.type == .Draw || kp.type == .Obtain {
                if let zp = handPos[kp.id] {
                    kp.data.firstWhere { $0.id == kp.id }?.setTag(.ZONE_POSITION, value: zp)
                    handPos[zp] = nil
                }
            } else if kp.type == .Summon || kp.type == .Play {
                if let zp = boardPos[kp.id] {
                    kp.data.firstWhere { $0.id == kp.id }?.setTag(.ZONE_POSITION, value: zp)
                    boardPos[zp] = nil
                }
            }
        }
        let toRemove = points.filter { $0.type == .BoardPos || $0.type == .HandPos }
        for kp in toRemove {
            points.remove(kp)
        }

        // this one is still needed for hand zonepos I think...
        var occupiedZonePos = [Int]()
        var noUniqueZonePos = [Entity]()
        for kp in points {
            let currentEntity = kp.data.firstWhere { $0.id == kp.id }
            if currentEntity == nil || !currentEntity!.hasTag(.ZONE_POSITION) {
                continue
            }

            occupiedZonePos.removeAll()
            noUniqueZonePos.removeAll()
            noUniqueZonePos.append(currentEntity!)
            for entity in kp.data.filter({ $0.id != kp.id && $0.hasTag(.ZONE_POSITION) }) {
                let zonePos = entity.getTag(.ZONE_POSITION)
                if entity.getTag(.ZONE) == currentEntity!.getTag(.ZONE)
                && entity.getTag(.CONTROLLER) == currentEntity!.getTag(.CONTROLLER) {
                    if !occupiedZonePos.contains(zonePos) {
                        occupiedZonePos.append(zonePos)
                    } else {
                        noUniqueZonePos.append(entity)
                    }
                }
            }
            for entity in noUniqueZonePos {
                if occupiedZonePos.contains(entity.getTag(.ZONE_POSITION)) {
                    if let max = occupiedZonePos.maxElement() {
                        let targetPos = max + 1
                        currentEntity!.setTag(.ZONE_POSITION, value: targetPos)
                        occupiedZonePos.append(targetPos)
                    }
                } else {
                    occupiedZonePos.append(entity.getTag(.ZONE_POSITION))
                }
            }
        }

        var onBoard = [Entity]()
        for kp in points {
            let currentBoard = kp.data
                .filter { $0.isInZone(.PLAY) && $0.hasTag(.HEALTH)
                    && !String.isNullOrEmpty($0.cardId) && !$0.cardId.contains("HERO")
            }
            if onBoard.all({ (e) in
                currentBoard.any({ (e2) in e2.id == e.id }) })
                && currentBoard.all({ (e) in onBoard.any({ (e2) in e2.id == e.id }) }) {
                for entity in currentBoard {
                    if let pos = onBoard
                        .firstWhere({ (e) in e.id == entity.id })?.getTag(.ZONE_POSITION) {
                        entity.setTag(.ZONE_POSITION, value: pos)
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
        let spellsWithTarget = points.filter { $0.type == .PlaySpell }.map { $0.id }
        let obsoletePlays = points
            .filter { (kp) in
                kp.type == .Play && spellsWithTarget.any { (id) in id == kp.id }
        }
        for play in obsoletePlays {
            points.remove(play)
        }
    }
}

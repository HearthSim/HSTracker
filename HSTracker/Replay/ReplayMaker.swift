//
//  ReplayMaker.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

final class ReplayMaker {
    private static var points = [ReplayKeyPoint]()

    static func reset() { points.removeAll() }

    static func generate(type: KeyPointType, _ id: Int, _ player: PlayerType, _ game: Game) {
        let replay = ReplayKeyPoint(data: game.entities.map { $0.1 },
                                    type: type,
                                    id: id,
                                    player: player)
        points.append(replay)
    }

    static func saveToDisk() {
        if points.count == 0 {
            return
        }
        resolveZonePos()
        resolveCardIds()
        removeObsoletePlays()

        if let player = points.last?.data.firstWhere({$0.isPlayer}),
            opponent = points.last?.data
                .firstWhere({$0.hasTag(.PLAYER_ID) && !$0.isPlayer}) {
                let playerHero = points.last?.data
                    .firstWhere({$0.getTag(.CARDTYPE) == CardType.HERO.rawValue
                        && $0.isControlledBy(player.getTag(.CONTROLLER))
                    })
                if playerHero == nil {
                    Log.warning?.message("Replay : playerHero is nil")
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
                                && Cards.heroById($0.cardId) != nil
                        })
                    if opponentHero == nil {
                        Log.warning?.message("Replay : opponentHero is nil")
                        return
                    }
                    resolveOpponentName(Cards.heroById(opponentHero!.cardId)?.name)
                }

                if let playerName = player.name,
                    playerHeroName = Cards.heroById(playerHero!.cardId)?.name,
                    opponentName = opponent.name,
                    opponentHeroName = Cards.heroById(opponentHero!.cardId)?.name {
                    // swiftlint:disable line_length
                        let filename = "\(playerName)(\(playerHeroName)) vs \(opponentName)(\(opponentHeroName)) \(NSDate().getUTCFormateDate())"
                        Log.info?.message("will save to \(filename)")
                    // swiftlint:enable line_length
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
                    kp.data.firstWhere { $0.id == kp.id }?.setTag(.ZONE_POSITION, zp)
                    handPos[zp] = nil
                }
            } else if kp.type == .Summon || kp.type == .Play {
                if let zp = boardPos[kp.id] {
                    kp.data.firstWhere { $0.id == kp.id }?.setTag(.ZONE_POSITION, zp)
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
                        currentEntity!.setTag(.ZONE_POSITION, targetPos)
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
                        entity.setTag(.ZONE_POSITION, pos)
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

/*
* This file is part of the HSTracker package.
* (c) Benjamin Michotte <bmichotte@gmail.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*
* Created on 13/02/16.
*/

import Foundation
import CleanroomLogger

final class LogReaderManager {
    let powerGameStateHandler = PowerGameStateHandler()
    let netHandler = NetHandler()
    let assetHandler = AssetHandler()
    let bobHandler = BobHandler()
    let rachelleHandler = RachelleHandler()
    let arenaHandler = ArenaHandler()
    let loadingScreenHandler = LoadingScreenHandler()
    var fullScreenFxHandler = FullScreenFxHandler()

    private let powerLog = LogReader(info: LogReaderInfo(name: .Power,
        startsWithFilters: ["PowerTaskList.DebugPrintPower", "GameState.DebugPrintEntityChoices()"],
        containsFilters: ["Begin Spectating",
            "Start Spectator", "End Spectator"]))
    private let gameStatePowerLogReader = LogReader(info: LogReaderInfo(name: .Power,
        startsWithFilters: ["GameState."],
        include: false))
    private let bob = LogReader(info: LogReaderInfo(name: .Bob))
    private let rachelle = LogReader(info: LogReaderInfo(name: .Rachelle))
    private let asset = LogReader(info: LogReaderInfo(name: .Asset))
    private let arena = LogReader(info: LogReaderInfo(name: .Arena))
    private let loadingScreen = LogReader(info: LogReaderInfo(name: .LoadingScreen,
        startsWithFilters: ["LoadingScreen.OnSceneLoaded",
            "Gameplay"]))
    private let net = LogReader(info: LogReaderInfo(name: .Net))
    private let fullScreenFx = LogReader(info: LogReaderInfo(name: .FullScreenFX))

    private var readers: [LogReader] {
        return [powerLog, bob, rachelle, asset, arena, net, loadingScreen, fullScreenFx]
    }

    var running = false
    var stopped = false

    func start() {
        guard !running else { return }

        running = true
        let entryPoint = self.entryPoint()
        for reader in readers {
            reader.start(self, entryPoint: entryPoint)
        }
        gameStatePowerLogReader.start(self, entryPoint: entryPoint)
    }

    func stop() {
        Log.info?.message("Stopping all trackers")
        stopped = true
        running = false
        for reader in readers {
            reader.stop()
        }
        gameStatePowerLogReader.stop()  
    }

    func restart() {
        stop()
        start()
    }

    private func entryPoint() -> NSDate {
        let powerEntry = powerLog.findEntryPoint(["tag=GOLD_REWARD_STATE", "End Spectator"])
        let loadingScreenEntry = loadingScreen.findEntryPoint("Gameplay.Start")

        Log.verbose?.message("powerEntry : \(powerEntry.millisecondsFormatted) / "
            + "loadingScreenEntry : \(loadingScreenEntry.millisecondsFormatted)")
        
        return powerEntry > loadingScreenEntry ? powerEntry : loadingScreenEntry
    }

    func processLine(line: LogLine) {
        let game = Game.instance
        
        if line.include {
            switch line.namespace {
            case .Power: powerGameStateHandler.handle(game, logLine: line)
            case .Net: netHandler.handle(game, logLine: line)
            case .Asset: assetHandler.handle(game, logLine: line)
            case .Bob: bobHandler.handle(game, logLine: line)
            case .Rachelle: rachelleHandler.handle(game, logLine: line)
            case .Arena: arenaHandler.handle(game, logLine: line)
            case .LoadingScreen: loadingScreenHandler.handle(game, logLine: line)
            case .FullScreenFX: fullScreenFxHandler.handle(game, logLine: line)
            default: break
            }
        } else {
            if line.namespace == .Power {
               game.powerLog.append(line)
            }
        }
    }
}

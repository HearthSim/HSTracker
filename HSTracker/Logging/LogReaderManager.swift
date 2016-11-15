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

    private let powerLog = LogReader(info: LogReaderInfo(name: .power,
        startsWithFilters: ["PowerTaskList.DebugPrintPower",
            "GameState.DebugPrintEntityChoices\\(\\)\\s-\\sid=(\\d) Player=(.+) TaskList=(\\d)"],
        containsFilters: ["Begin Spectating", "Start Spectator", "End Spectator"]))
    private let gameStatePowerLogReader = LogReader(info: LogReaderInfo(name: .power,
        startsWithFilters: ["GameState."], include: false))
    private let bob = LogReader(info: LogReaderInfo(name: .bob))
    private let rachelle = LogReader(info: LogReaderInfo(name: .rachelle))
    private let asset = LogReader(info: LogReaderInfo(name: .asset))
    private let arena = LogReader(info: LogReaderInfo(name: .arena))
    private let loadingScreen = LogReader(info: LogReaderInfo(name: .loadingScreen,
        startsWithFilters: ["LoadingScreen.OnSceneLoaded", "Gameplay"]))
    private let net = LogReader(info: LogReaderInfo(name: .net))
    private let fullScreenFx = LogReader(info: LogReaderInfo(name: .fullScreenFX))

    private var readers: [LogReader] {
        return [powerLog, bob, rachelle, asset, arena, net, loadingScreen, fullScreenFx]
    }

    var running = false
    var stopped = false

    func start() {
        guard !running else {
            Log.error?.message("LogReaderManager is already running")
            return
        }

        stopped = false
        running = true
        let entryPoint = self.entryPoint()
        for reader in readers {
            reader.start(manager: self, entryPoint: entryPoint)
        }
        gameStatePowerLogReader.start(manager: self, entryPoint: entryPoint)
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
        Log.info?.message("LogReaderManager is restarting")
        stop()
        start()
    }

    private func entryPoint() -> Date {
        let powerEntry = powerLog.findEntryPoint(choices:
            ["tag=GOLD_REWARD_STATE", "End Spectator"])
        let loadingScreenEntry = loadingScreen.findEntryPoint(choice: "Gameplay.Start")

        Log.verbose?.message("powerEntry : \(powerEntry.millisecondsFormatted) / "
            + "loadingScreenEntry : \(loadingScreenEntry.millisecondsFormatted)")
        
        return powerEntry > loadingScreenEntry ? powerEntry : loadingScreenEntry
    }

    func processLine(line: LogLine) {
        let game = Game.instance
        
        if line.include {
            switch line.namespace {
            case .power: powerGameStateHandler.handle(game: game, logLine: line)
            case .net: netHandler.handle(game: game, logLine: line)
            case .asset: assetHandler.handle(game: game, logLine: line)
            case .bob: bobHandler.handle(game: game, logLine: line)
            case .rachelle: rachelleHandler.handle(game: game, logLine: line)
            case .arena: arenaHandler.handle(game: game, logLine: line)
            case .loadingScreen: loadingScreenHandler.handle(game: game, logLine: line)
            case .fullScreenFX: fullScreenFxHandler.handle(game: game, logLine: line)
            default: break
            }
        } else {
            if line.namespace == .power {
               game.powerLog.append(line)
            }
        }
    }
}

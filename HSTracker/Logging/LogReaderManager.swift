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

    private let powerLogReader = LogReader(info: LogReaderInfo(name: .Power,
                                        startsWithFilters: ["PowerTaskList.DebugPrintPower"],
                                        containsFilters: ["Begin Spectating",
                                            "Start Spectator", "End Spectator"]))
    private let gameStatePowerLogReader = LogReader(info: LogReaderInfo(name: .Power,
                                                         startsWithFilters: ["GameState."]))
    private let bob = LogReader(info: LogReaderInfo(name: .Bob))
    private let rachelle = LogReader(info: LogReaderInfo(name: .Rachelle))
    private let asset = LogReader(info: LogReaderInfo(name: .Asset))
    private let arena = LogReader(info: LogReaderInfo(name: .Arena))
    private let loadScreen = LogReader(info: LogReaderInfo(name: .LoadingScreen,
                                            startsWithFilters: ["LoadingScreen.OnSceneLoaded"]))
    private let net = LogReader(info: LogReaderInfo(name: .Net))

    private var readers: [LogReader] {
        return [powerLogReader, bob, rachelle, asset, arena, net, loadScreen]
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
    }

    func stop() {
        Log.info?.message("Stopping all trackers")
        stopped = true
        running = false
        for reader in readers {
            reader.stop()
        }
    }

    func restart() {
        stop()
        start()
    }

    private func entryPoint() -> Double {
        // DEBUG return 0
        let powerEntry = powerLogReader.findEntryPoint(["tag=GOLD_REWARD_STATE", "End Spectator"])
        let netEntry = net.findEntryPoint("ConnectAPI.GotoGameServer")

        return powerEntry > netEntry ? powerEntry : netEntry
    }

    func processLine(line: LogLine) {
        let game = Game.instance
        switch line.namespace {
        case .Power: powerGameStateHandler.handle(game, line: line.line)
        case .Net: netHandler.handle(game, line: line.line)
        case .Asset: assetHandler.handle(game, line: line.line)
        case .Bob: bobHandler.handle(game, line: line.line)
        case .Rachelle: rachelleHandler.handle(game, line: line.line)
        case .Arena: arenaHandler.handle(game, line: line.line)
        case .LoadingScreen: loadingScreenHandler.handle(game, line: line.line)
        }
    }
}

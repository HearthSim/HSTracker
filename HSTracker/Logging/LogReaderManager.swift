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

class LogReaderManager {
    var readers: [LogReader];

    var powerLogReader: LogReader?
    var gameStatePowerLogReader: LogReader?
    var bob: LogReader?
    var rachelle: LogReader?
    var asset: LogReader?
    var arena: LogReader?
    var loadScreen: LogReader?
    var net: LogReader?

    var toProcess = [Int: [LogLine]]()
    var running = false
    var stopped = false

    init() {
        self.powerLogReader = LogReader(name: "Power",
            startFilters: ["PowerTaskList.DebugPrintPower"],
            containsFilters: ["Begin Spectating", "Start Spectator", "End Spectator"])

        self.gameStatePowerLogReader = LogReader(name: "Power", startFilters: ["GameState."])

        self.bob = LogReader(name: "Bob")
        self.rachelle = LogReader(name: "Rachelle")
        self.asset = LogReader(name: "Asset")
        self.arena = LogReader(name: "Arena")
        self.net = LogReader(name: "Net")

        self.loadScreen = LogReader(name: "LoadingScreen", startFilters: ["LoadingScreen.OnSceneLoaded"])

        readers = [self.powerLogReader!, self.bob!, self.rachelle!, self.asset!, self.arena!, self.net!, self.loadScreen!]
    }

    func start() {
        if self.running {
            return
        }

        self.running = true
        let entryPoint = self.entryPoint()
        for reader in self.readers {
            reader.start(entryPoint)
        }
        self.gameStatePowerLogReader?.start(entryPoint)

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            var powerLines = [LogLine]()

            while !self.stopped {
                for reader in self.readers {
                    let lines = reader.collect()
                    for line in lines {
                        if self.toProcess[line.time] == nil {
                            self.toProcess[line.time] = [LogLine]()
                        }
                        self.toProcess[line.time]!.append(line)
                    }
                }
                if let gameStatePowerLogReader = self.gameStatePowerLogReader {
                    powerLines = gameStatePowerLogReader.collect()
                }

                self.processLines()
                if powerLines.count > 0 {
                    // Core.Game.PowerLog.AddRange(powerLines.Select(x => x.Line));
                    powerLines.removeAll()
                }
                NSThread.sleepForTimeInterval(0.1)
            }
        }
    }

    func stop() {
        DDLogVerbose("Stopping all trackers")
        self.stopped = true
        for reader in readers {
            reader.stop()
        }
    }

    func restart() {
        stop()
        start()
    }

    func entryPoint() -> Double {
        // return 0
        let powerEntry = self.powerLogReader!.findEntryPoint(["tag=GOLD_REWARD_STATE", "End Spectator"])
        let netEntry = self.net!.findEntryPoint("ConnectAPI.GotoGameServer")

        return powerEntry > netEntry ? powerEntry : netEntry
    }

    func processLines() {
        for (_, item) in toProcess.filter({ $0.1 != nil }) {
            for line in item.filter({ $0 != nil }) {
                // DDLogVerbose("processing line \(line)", line)
                dispatch_async(dispatch_get_main_queue()) {
                    let game = Game.instance
                    switch (line.namespace) {
                    case "Power":
                        PowerGameStateHandler.handle(game, line.line)
                    case "Net":
                        NetHandler.handle(game, line.line)
                    case "Asset":
                        AssetHandler.handle(game, line.line)
                    case "Bob":
                        BobHandler.handle(game, line.line)
                    case "Rachelle":
                        RachelleHandler.handle(game, line.line)
                    case "Arena":
                        ArenaHandler.handle(game, line.line)
                    case "LoadingScreen":
                        LoadingScreenHandler.handle(game, line.line)
                    default:
                        break
                    }
                }
            }
        }
        toProcess.removeAll()
    }
}
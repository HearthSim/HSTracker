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

class LogReaderManager: LogLineReader {
    var readers: [LogReader];

    var power: LogReader?
    var fullPower: LogReader?
    var bob: LogReader?
    var rachelle: LogReader?
    var asset: LogReader?
    var arena: LogReader?
    var loadScreen: LogReader?
    var net: LogReader?

    init() {
        self.power = LogReader(name: "Power",
            startFilters: ["PowerTaskList.DebugPrintPower"],
            containsFilters: ["Begin Spectating", "Start Spectator", "End Spectator"])

        self.fullPower = LogReader(name: "Power", startFilters: ["GameState."])

        self.bob = LogReader(name: "Bob")
        self.rachelle = LogReader(name: "Rachelle")
        self.asset = LogReader(name: "Asset")
        self.arena = LogReader(name: "Arena")
        self.net = LogReader(name: "Net")

        self.loadScreen = LogReader(name: "LoadingScreen", startFilters: ["LoadingScreen.OnSceneLoaded"])

        readers = [self.fullPower!, self.bob!, self.rachelle!, self.asset!, self.arena!, self.net!, self.loadScreen!]
    }

    func start() {
        let entryPoint = self.entryPoint()
        for reader in readers {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                reader.setDelegate(self)
                reader.start(entryPoint)
            }
        }
    }

    func stop() {
        for reader in readers {
            reader.stop()
        }
    }

    func restart() {
        stop()
        start()
    }

    func entryPoint() -> Double {
        let powerEntry = self.power!.findEntryPoint(["tag=GOLD_REWARD_STATE", "End Spectator"])
        let netEntry = self.net!.findEntryPoint("ConnectAPI.GotoGameServer")

        return powerEntry > netEntry ? powerEntry : netEntry
    }

    func processNewLine(line: LogLine) {
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
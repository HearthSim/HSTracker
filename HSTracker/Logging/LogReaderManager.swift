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
                startFilters: ["PowerTaskList."],
                containsFilters: ["Begin Spectating", "Start Spectator", "End Spectator"])

        self.fullPower = LogReader(name: "Power")

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
        let netEntry = self.net!.findEntryPoint(["ConnectAPI.GotoGameServer"])

        return powerEntry > netEntry ? powerEntry : netEntry
    }

    func processNewLine(line: LogLine) {
        //DDLogVerbose("processing line \(line)", line)
        dispatch_async(dispatch_get_main_queue()) {
            switch (line.namespace) {
            case "Power":
                PowerGameStateHandler.handle(line.line)
            case "Net":
                NetHandler.handle(line.line)
            case "Asset":
                AssetHandler.handle(line.line)
            case "Bob":
                BobHandler.handle(line.line)
            case "Rachelle":
                RachelleHandler.handle(line.line)
            case "Arena":
                ArenaHandler.handle(line.line)
            case "LoadingScreen":
                LoadingScreenHandler.handle(line.line)
            default:
                break
            }
        }
    }

}
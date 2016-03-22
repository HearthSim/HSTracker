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
    var readers: [LogReader]
    
    let powerGameStateHandler = PowerGameStateHandler()
    let netHandler = NetHandler()
    let assetHandler = AssetHandler()
    let bobHandler = BobHandler()
    let rachelleHandler = RachelleHandler()
    let arenaHandler = ArenaHandler()
    let loadingScreenHandler = LoadingScreenHandler()
    
    var powerLogReader: LogReader
    var gameStatePowerLogReader: LogReader
    var bob: LogReader
    var rachelle: LogReader
    var asset: LogReader
    var arena: LogReader
    var loadScreen: LogReader
    var net: LogReader

    var running = false
    var stopped = false
    
    init() {
        powerLogReader = LogReader(name: .Power,
            startFilters: ["PowerTaskList.DebugPrintPower"],
            containsFilters: ["Begin Spectating", "Start Spectator", "End Spectator"])
        
        gameStatePowerLogReader = LogReader(name: .Power, startFilters: ["GameState."])
        
        bob = LogReader(name: .Bob)
        rachelle = LogReader(name: .Rachelle)
        asset = LogReader(name: .Asset)
        arena = LogReader(name: .Arena)
        net = LogReader(name: .Net)
        
        loadScreen = LogReader(name: .LoadingScreen, startFilters: ["LoadingScreen.OnSceneLoaded"])
        
        readers = [powerLogReader, bob, rachelle, asset, arena, net, loadScreen]
    }
    
    func start() {
        guard !running else { return }
        
        running = true
        let entryPoint = self.entryPoint()
        for reader in readers {
            reader.start(entryPoint)
        }
        
        var toProcess = [LogLine]()
        while !stopped {
            toProcess.removeAll()
            
            for reader in self.readers {
                let lines = reader.collect()
                toProcess.appendContentsOf(lines)
            }
            
            processLines(toProcess)
            NSThread.sleepForTimeInterval(0.2)
        }
    }
    
    func stop() {
        DDLogVerbose("Stopping all trackers")
        stopped = true
        for reader in readers {
            reader.stop()
        }
    }
    
    func restart() {
        stop()
        start()
    }
    
    private func entryPoint() -> Double {
        let powerEntry = powerLogReader.findEntryPoint(["tag=GOLD_REWARD_STATE", "End Spectator"])
        let netEntry = net.findEntryPoint("ConnectAPI.GotoGameServer")
        
        return powerEntry > netEntry ? powerEntry : netEntry
    }
    
    private func processLines(process: [LogLine]) {
        for line in process.filter({ $0 != nil }) {
            //print("\(line.namespace) \(line.line)")
            
            let game = Game.instance
            switch (line.namespace) {
            case .Power: powerGameStateHandler.handle(game, line.line)
            case .Net: netHandler.handle(game, line.line)
            case .Asset: assetHandler.handle(game, line.line)
            case .Bob: bobHandler.handle(game, line.line)
            case .Rachelle: rachelleHandler.handle(game, line.line)
            case .Arena: arenaHandler.handle(game, line.line)
            case .LoadingScreen: loadingScreenHandler.handle(game, line.line)
            }
        }
    }
}
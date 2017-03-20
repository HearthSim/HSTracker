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
import BTree

final class LogReaderManager {
    let powerGameStateHandler = PowerGameStateHandler()
    let rachelleHandler = RachelleHandler()
    let arenaHandler = ArenaHandler()
    let loadingScreenHandler = LoadingScreenHandler()
    var fullScreenFxHandler = FullScreenFxHandler()

    private let powerLog: LogReader
    private let gameStatePowerLogReader: LogReader
    private let rachelle: LogReader
    private let arena: LogReader
    private let loadingScreen: LogReader
    private let fullScreenFx: LogReader

    private var readers: [LogReader] {
        return [powerLog, rachelle, arena, loadingScreen, fullScreenFx]
    }
    
    public static let dateStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    public static let iso8601StringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
    
    public static let fullDateStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
        return formatter
    }()
    
    public static let timeZone = TimeZone.current
    public static let calendar = Calendar.current

    var running = false
    var stopped = false
    private var queue: DispatchQueue?
    private var processMap = Map<Date, [LogLine]>()
    
    init(logPath: String) {
        let rx = "GameState.DebugPrintEntityChoices\\(\\)\\s-\\sid=(\\d) Player=(.+) TaskList=(\\d)"
        let plReader = LogReaderInfo(name: .power,
                                     startsWithFilters: ["PowerTaskList.DebugPrintPower", rx],
                                     containsFilters: ["Begin Spectating", "Start Spectator",
                                                       "End Spectator"])
        powerLog = LogReader(info: plReader, logPath: logPath)
        
        gameStatePowerLogReader = LogReader(info: LogReaderInfo(name: .power,
                                                                startsWithFilters: ["GameState."],
                                                                include: false),
                                            logPath: logPath)

        rachelle = LogReader(info: LogReaderInfo(name: .rachelle), logPath: logPath)
        arena = LogReader(info: LogReaderInfo(name: .arena), logPath: logPath)
        loadingScreen = LogReader(info: LogReaderInfo(name: .loadingScreen,
                                                      startsWithFilters: [
                                                        "LoadingScreen.OnSceneLoaded", "Gameplay"]),
                                  logPath: logPath)
        fullScreenFx = LogReader(info: LogReaderInfo(name: .fullScreenFX), logPath: logPath)
    }

    func start() {
        guard !running else {
            Log.error?.message("LogReaderManager is already running")
            return
        }
        
        queue = DispatchQueue(label: "be.michotte.hstracker.logReaderManager", attributes: [])
        
        if let queue = queue {
            queue.async {
                self.startLogReaders()
            }
        }
    }
    
    private func startLogReaders() {
        stopped = false
        running = true
        let entryPoint = self.entryPoint()
        for reader in readers {
            reader.start(manager: self, entryPoint: entryPoint)
        }
        gameStatePowerLogReader.start(manager: self, entryPoint: entryPoint)
        
        while !stopped {
            for reader in readers {
                let loglines = reader.collect()
                for line in loglines {
                    var lineList: [LogLine]?
                    if let loglist = processMap[line.time] {
                        lineList = loglist
                    } else {
                        lineList = [LogLine]()
                    }
                    lineList?.append(line)
                    processMap[line.time] = lineList
                }
                
            }
            
            for lineList in processMap.values {
                if stopped {
                    break
                }
                for line in lineList {
                    if stopped {
                        break
                    }
                    processLine(line: line)
                }
            }
            processMap.removeAll()
            
            let powerLines = gameStatePowerLogReader.collect()
            for line in powerLines {
                processLine(line: line)
            }
            
            Thread.sleep(forTimeInterval: 0.1)
        }
        running = false
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

        let pe = LogReaderManager.iso8601StringFormatter.string(from: powerEntry)
        let lse = LogReaderManager.iso8601StringFormatter.string(from: loadingScreenEntry)
        Log.verbose?.message("powerEntry : \(pe) / loadingScreenEntry : \(lse)")
        
        return powerEntry > loadingScreenEntry ? powerEntry : loadingScreenEntry
    }

    private func processLine(line: LogLine) {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else { return }
        
        if line.include {
            switch line.namespace {
            case .power: self.powerGameStateHandler.handle(game: game, logLine: line)
            case .rachelle: self.rachelleHandler.handle(game: game, logLine: line)
            case .arena: self.arenaHandler.handle(game: game, logLine: line)
            case .loadingScreen: self.loadingScreenHandler.handle(game: game, logLine: line)
            case .fullScreenFX: self.fullScreenFxHandler.handle(game: game, logLine: line)
            default: break
            }
        } else {
            if line.namespace == .power {
                game.powerLog.append(line)
            }
        }
    }
}

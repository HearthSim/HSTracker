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

final class LogReaderManager {
	
    // lower update times result in faster operation but higher CPU usage
	static let updateDelay: TimeInterval = 0.05

    // how long stop() waits for the reader thread to leave its loop
    static let stopTimeout: TimeInterval = 5.0
	
    let powerGameStateParser: PowerGameStateParser
    let rachelleHandler = RachelleHandler()
	let arenaHandler: LogEventParser
	let loadingScreenHandler: LogEventParser
    let choicesHandler: ChoicesHandler
    let gameInfoHandler: GameInfoHandler

    private let powerLog: LogReader
    private let rachelle: LogReader
    private let arena: LogReader
    private let loadingScreen: LogReader

    private var readers: [LogReader] {
        return [powerLog, rachelle, arena, loadingScreen]
    }
    
    public static let dateStringFormatter: LogDateFormatter = {
        let formatter = LogDateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    public static let iso8601StringFormatter: LogDateFormatter = {
        let formatter = LogDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
    
    public static let fullDateStringFormatter: LogDateFormatter = {
        let formatter = LogDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
        return formatter
    }()
	
    public static let timeZone = TimeZone.current
    public static let calendar = Calendar.current

    private(set) var running = false
    private var stopped = false
    private var queue: DispatchQueue?
    /// Signalled by the worker once `startLogReaders()` has returned, so
    /// `stop()` can wait for it instead of leaving a second reader racing the
    /// first one.
    private let finished = DispatchSemaphore(value: 0)
    private let coreManager: CoreManager
    
	init(logPath: String, coreManager: CoreManager) {
        self.coreManager = coreManager
		loadingScreenHandler = LoadingScreenHandler(with: coreManager)
		powerGameStateParser = PowerGameStateParser(with: coreManager.game)
		arenaHandler = ArenaHandler(with: coreManager)
        choicesHandler = ChoicesHandler(with: coreManager.game)
		
        let plReader = LogReaderInfo(name: .power,
                                     startsWithFilters: ["PowerTaskList.DebugPrintPower", "GameState.", "PowerProcessor.EndCurrentTaskList"],
                                     containsFilters: ["Begin Spectating", "Start Spectator",
                                                       "End Spectator"])
        powerLog = LogReader(info: plReader, logPath: logPath)

        rachelle = LogReader(info: LogReaderInfo(name: .rachelle), logPath: logPath)
        arena = LogReader(info: LogReaderInfo(name: .arena), logPath: logPath)
        loadingScreen = LogReader(info: LogReaderInfo(name: .loadingScreen,
                                                      startsWithFilters: ["LoadingScreen.OnSceneLoaded", "Gameplay", "LoadingScreen.OnScenePreUnload", "MulliganManager.HandleGameStart"]),
                                  logPath: logPath)
        gameInfoHandler = GameInfoHandler()
    }

    func start() {
        guard !running else {
            logger.error("LogReaderManager is already running")
            return
        }
        logger.info("LogReaderManager is starting")
        
        queue = DispatchQueue(label: "net.hearthsim.hstracker.logReaderManager", attributes: [])
        
        guard let queue = queue else {
            logger.error("LogReaderManager can not create queue")
            return
        }
        self.stopped = false
        self.running = true
        queue.async {
            self.startLogReaders()
            self.finished.signal()
        }
    }
    
    private func startLogReaders() {
        // Do not clear `stopped` here: a stop() that arrives before this block
        // starts running has to take effect, otherwise the loop would outlive
        // its manager and keep driving the watchers alongside a newer reader.
        let entryPoint = self.entryPoint()
        for reader in readers {
            reader.start(manager: self, entryPoint: entryPoint)
        }
        
        while !stopped {
            autoreleasepool {
                var processMap = [LogDate: [LogLine]]()

                for reader in readers {
                    let loglines = reader.collect()
                    for line in loglines {
                        var lineList = processMap[line.time] ?? [LogLine]()
                        lineList.append(line)
                        processMap[line.time] = lineList
                    }
                    
                }
                
                let keys = processMap.keys.sorted()
                for time in keys {
                    if let lineList = processMap[time] {
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
                }
                processMap.removeAll()
            }
            Thread.sleep(forTimeInterval: LogReaderManager.updateDelay)
        }
    }

	func stop(eraseLogFile: Bool) {
        guard running else {
            return
        }
        logger.info("Stopping all trackers")
        stopped = true
        for reader in readers {
			reader.stop(eraseLogFile: eraseLogFile)
        }
        // Wait for the worker to actually leave its loop. Returning early would
        // let a freshly started manager process the same log lines in parallel
        // with this one, which races every watcher they share.
        if finished.wait(timeout: .now() + LogReaderManager.stopTimeout) == .timedOut {
            logger.error("LogReaderManager did not stop within \(LogReaderManager.stopTimeout)s")
        }
        running = false
    }

	func restart(eraseLogFile: Bool = false) {
        logger.info("LogReaderManager is restarting")
		stop(eraseLogFile: eraseLogFile)
        start()
    }

    private func entryPoint() -> LogDate {
        let powerEntry = powerLog.findEntryPoint(choices:
            ["tag=STATE value=COMPLETE", "End Spectator"])
        let loadingScreenEntry = loadingScreen.findEntryPoint(choice: "Gameplay.Start")

        let pe = LogReaderManager.iso8601StringFormatter.string(from: powerEntry)
        let lse = LogReaderManager.iso8601StringFormatter.string(from: loadingScreenEntry)
        logger.verbose("powerEntry : \(pe) / loadingScreenEntry : \(lse)")
        
        return powerEntry > loadingScreenEntry ? powerEntry : loadingScreenEntry
	}
	
	private func processLine(line: LogLine) {
        switch line.namespace {
        case .power:
            if line.content.hasPrefix("GameState.") {
                coreManager.game.add(powerLog: line)
                if line.content.hasPrefix("GameState.DebugPrintEntityChoices") ||
                    line.content.hasPrefix("GameState.DebugPrintEntitiesChosen") {
                    self.choicesHandler.handle(logLine: line)
                } else {
                    self.choicesHandler.flush()
                }
                if line.content.hasPrefix("GameState.DebugPrintGame") {
                    gameInfoHandler.handle(logLine: line)
                }
            } else if line.content.hasPrefix("PowerProcessor.EndCurrentTaskList") {
                choicesHandler.handle(logLine: line)
            } else {
                self.powerGameStateParser.handle(logLine: line)
                choicesHandler.flush()
            }
        case .rachelle: self.rachelleHandler.handle(logLine: line)
        case .arena: self.arenaHandler.handle(logLine: line)
        case .loadingScreen: self.loadingScreenHandler.handle(logLine: line)
        default: break
        }
	}
}

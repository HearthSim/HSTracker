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

final class LogReader {
    var stopped = true
    var offset: UInt64 = 0
	var startingPoint: LogDate = LogDate(date: Date.distantPast)
    var fileHandle: FileHandle?
    var eraseFile = false

    var path: String
    let fileManager = FileManager()
    private var info: LogReaderInfo
    private var logReaderManager: LogReaderManager?

    private var queue: DispatchQueue?
    private var _lines = ConcurrentQueue<LogLine>()

	init(info: LogReaderInfo, logPath: String, removeLogfile: Bool = true) {
        self.info = info
		
        self.path = "\(logPath)/\(info.name.rawValue).log"
        logger.info("Init reader for \(info.name) at path \(self.path)")
        if fileManager.fileExists(atPath: self.path)
                   && !FileUtils.isFileOpen(byHearthstone: self.path)
					&& removeLogfile {
            do {
				logger.info("Removing log file at \(self.path)")
                try fileManager.removeItem(atPath: self.path)
            } catch {
                logger.error("\(error)")
            }
        }
    }

    func findEntryPoint(choice: String) -> LogDate {
        return findEntryPoint(choices: [choice])
    }

    func findEntryPoint(choices: [String]) -> LogDate {
        guard fileManager.fileExists(atPath: path) else {
			return LogDate(date: Date.distantPast)
        }
        var fileContent: String
        do {
            fileContent = try String(contentsOfFile: path)
        } catch {
            return LogDate(date: Date.distantPast)
        }

        let lines: [String] = fileContent
                .components(separatedBy: "\n")
                .filter({ !$0.isBlank }).reversed()
        for line in lines {
            if choices.any({ line.range(of: $0) != nil }) {
                logger.verbose("Found \(line)")
				return LogLine(namespace: .power, line: line).time
            }
        }

        return LogDate(date: Date.distantPast)
    }

    func start(manager logReaderManager: LogReaderManager, entryPoint: LogDate) {
        stopped = false
        self.logReaderManager = logReaderManager
        startingPoint = entryPoint

        var queueName = "net.hearthsim.hstracker.readers.\(info.name)"
        if info.startsWithFiltersGroup.count > 0, let filter = info.startsWithFiltersGroup[0].first {
            queueName += ".\(filter.lowercased())"
        }
        queue = DispatchQueue(label: queueName, attributes: [])
        if let queue = queue {
            logger.info("Starting to track \(info.name)")
            let sp = LogReaderManager.fullDateStringFormatter.string(from: startingPoint)
            logger.verbose("\(info.name) has queue \(queueName) starting at \(sp)")
            queue.async {
                self.readFile()
            }
        }
    }

    func readFile() {
        self.offset = findInitialOffset()
        logger.verbose("reading \(path) starting at offset \(offset)")

        while !stopped {
            if fileHandle == nil && fileManager.fileExists(atPath: path) {
                fileHandle = FileHandle(forReadingAtPath: path)
                
                let sp = LogReaderManager.fullDateStringFormatter.string(from: startingPoint)
                logger.verbose("file exists \(path), offset for \(sp) is \(offset),"
                    + " queue: net.hearthsim.hstracker.readers.\(info.name)")
            }
            
            fileHandle?.seek(toFileOffset: offset)
            
            if let data = fileHandle?.readDataToEndOfFile() {
                autoreleasepool {
                    
                    let linesStr = String(decoding: data, as: UTF8.self)
                    if !linesStr.isBlank {
                        let lines = linesStr
                            .components(separatedBy: CharacterSet.newlines)
                            .filter {
                                !$0.isEmpty && $0.hasPrefix(info.prefix) && $0.count > 20
                        }

                        if !lines.isEmpty {
                            for line in lines {
                                offset += UInt64((line + "\n")
                                    .lengthOfBytes(using: .utf8))
                                let logLine = LogLine(namespace: info.name,
                                                      line: line)

                                if (!info.hasFilters || info.startsWithFiltersGroup.any({ logLine.content.hasPrefix($0)}) || info.containsFiltersGroup.any({ logLine.content.contains($0)})) && logLine.time >= startingPoint {
                                        _lines.enqueue(value: logLine)
                                }
                            }
                        }
                    }

                    if !fileManager.fileExists(atPath: path) {
                        logger.verbose("setting \(path) handle to nil \(offset))")
                        fileHandle = nil
                    }
                    if fileHandle == nil {
                        offset = 0
                    }
                }
            } else {
                fileHandle = nil
            }

            Thread.sleep(forTimeInterval: LogReaderManager.updateDelay)
        }
        
        fileHandle?.closeFile()
        fileHandle = nil
        
        _lines.clear()
        
        // try to truncate log file when stopping
        if fileManager.fileExists(atPath: path) && eraseFile {
            let file = FileHandle(forWritingAtPath: path)
            file?.truncateFile(atOffset: UInt64(0))
            file?.closeFile()
            offset = 0
        }
    }

    func findInitialOffset() -> UInt64 {
        guard fileManager.fileExists(atPath: path) else {
            return 0
        }
        
        return autoreleasepool {
            
            var offset: UInt64 = 0
            guard let fileHandle = FileHandle(forReadingAtPath: path) else {
                return 0
            }
            fileHandle.seekToEndOfFile()
            let fileLength = fileHandle.offsetInFile
            fileHandle.seek(toFileOffset: 0)
            
            while offset < fileLength {
                let sizeDiff = 4096 - min(fileLength - offset, UInt64(4096))
                offset += 4096
                let fileOffset: UInt64 = UInt64(max(Int64(fileLength) - Int64(offset), Int64(0)))
                fileHandle.seek(toFileOffset: fileOffset)
                let data = fileHandle.readData(ofLength: 4096)
                if let string = String(data: data, encoding: .ascii) {
                    
                    var skip: UInt64 = 0
                    for i in 0 ... 4096 {
                        skip += 1
                        if i >= string.count || string.char(at: i) == "\n" {
                            break
                        }
                    }
                    offset -= skip
                    let lines = String(string.dropFirst(Int(skip)))
                        .components(separatedBy: "\n")
                    for i in 0 ... (lines.count - 1) {
                        if lines[i].isBlank {
                            continue
                        }
                        let logLine = LogLine(namespace: info.name, line: lines[i])
                        if logLine.time < startingPoint {
                            let negativeOffsetTmp = lines.take(i + 1)
                                .map({ UInt64(($0 + "\n").count) })
                            let negativeOffset = negativeOffsetTmp
                                .reduce(0, +)
                            let current = Int64(fileLength) - Int64(offset)
                                + Int64(negativeOffset) + Int64(sizeDiff)
                            
                            return UInt64(max(current, Int64(0)))
                        }
                    }
                    
                }
            }
            return 0
        }
    }

	func stop(eraseLogFile: Bool) {
        logger.info("Stopping tracker \(info.name)")
        eraseFile = eraseLogFile
        stopped = true
    }
    
    func collect() -> [LogLine] {
        var items = [LogLine]()
        let size = _lines.count
        
        if size == 0 {
            return items
        }
        
        for _ in 0..<size {
            if let elem = _lines.dequeue() {
                items.append(elem)
            } else {
                break
            }
        }

        return items
    }
}

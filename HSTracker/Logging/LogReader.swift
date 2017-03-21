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

final class LogReader {
    var stopped = true
    var offset: UInt64 = 0
    var startingPoint: Date = Date.distantPast
    var fileHandle: FileHandle?

    var path: String
    let fileManager = FileManager()
    private var info: LogReaderInfo
    private var logReaderManager: LogReaderManager?

    private var queue: DispatchQueue?
    private var _lines = ConcurrentQueue<LogLine>()

    init(info: LogReaderInfo, logPath: String) {
        self.info = info

        self.path = "\(logPath)/Logs/\(info.name).log"
        Log.info?.message("Init reader for \(info.name) at path \(self.path)")
        if fileManager.fileExists(atPath: self.path)
                   && !FileUtils.isFileOpen(byHearthstone: self.path) {
            do {
                try fileManager.removeItem(atPath: self.path)
            } catch {
                Log.error?.message("\(error)")
            }
        }
    }

    func findEntryPoint(choice: String) -> Date {
        return findEntryPoint(choices: [choice])
    }

    func findEntryPoint(choices: [String]) -> Date {
        guard fileManager.fileExists(atPath: path) else {
            return Date.distantPast
        }
        var fileContent: String
        do {
            fileContent = try String(contentsOfFile: path)
        } catch {
            return Date.distantPast
        }

        let lines: [String] = fileContent
                .components(separatedBy: "\n")
                .filter({ !String.isNullOrEmpty($0) }).reversed()
        for line in lines {
            if choices.any({ line.range(of: $0) != nil }) {
                Log.verbose?.message("Found \(line)")
				return LogLine(namespace: .power, line: line).time
            }
        }

        return Date.distantPast
    }

    func start(manager logReaderManager: LogReaderManager, entryPoint: Date) {
        stopped = false
        self.logReaderManager = logReaderManager
        startingPoint = entryPoint

        var queueName = "be.michotte.hstracker.readers.\(info.name)"
        if let filter = info.startsWithFilters.first {
            queueName += ".\(filter.lowercased())"
        }
        queue = DispatchQueue(label: queueName, attributes: [])
        if let queue = queue {
            Log.info?.message("Starting to track \(info.name)")
            let sp = LogReaderManager.fullDateStringFormatter.string(from: startingPoint)
            Log.verbose?.message("\(info.name) has queue \(queueName) starting at \(sp)")
            queue.async {
                self.readFile()
            }
        }
    }

    func readFile() {
        Log.verbose?.message("reading \(path)")

        while !stopped {
            if fileHandle == nil && fileManager.fileExists(atPath: path) {
                fileHandle = FileHandle(forReadingAtPath: path)
                findInitialOffset()
                fileHandle?.seek(toFileOffset: offset)

                let sp = LogReaderManager.fullDateStringFormatter.string(from: startingPoint)
                Log.verbose?.message("file exists \(path), offset for \(sp) is \(offset)")
            }

            if let data = fileHandle?.readDataToEndOfFile() {
                if let linesStr = String(data: data, encoding: .utf8) {

                    let lines = linesStr
                            .components(separatedBy: CharacterSet.newlines)
                            .filter {
                                !$0.isEmpty && $0.hasPrefix("D ") && $0.characters.count > 20
                            }

                    if !lines.isEmpty {
                        for line in lines {
                            offset += UInt64((line + "\n")
                                    .lengthOfBytes(using: .utf8))
                            let cutted = line.substring(from:
                            line.characters.index(line.startIndex, offsetBy: 19))

                            if !info.hasFilters
                                       || info.startsWithFilters.any({
                                cutted.hasPrefix($0) || cutted.match($0)
                            })
                                       || info.containsFilters.any({ cutted.contains($0) }) {

                                let logLine = LogLine(namespace: info.name,
                                        line: line,
                                        include: info.include)
                                if logLine.time >= startingPoint {
                                    _lines.enqueue(value: logLine)
                                }
                            }
                        }
                    }
                } else {
                    Log.warning?.message("Can not read \(path) as utf8, resetting")
                    fileHandle = nil
                }

                if !fileManager.fileExists(atPath: path) {
                    Log.verbose?.message("setting \(path) handle to nil \(offset))")
                    fileHandle = nil
                }
                if fileHandle == nil {
                    offset = 0
                }
            } else {
                fileHandle = nil
            }

            Thread.sleep(forTimeInterval: LogReaderManager.updateDelay)
        }
    }

    func findInitialOffset() {
        guard fileManager.fileExists(atPath: path) else {
            return
        }

        var offset: UInt64 = 0
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            return
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
                    if i >= string.characters.count || string.char(at: i) == "\n" {
                        break
                    }
                }
                offset -= skip
                let lines = String(string.characters.dropFirst(Int(skip)))
                        .components(separatedBy: "\n")
                for i in 0 ... (lines.count - 1) {
                    if String.isNullOrEmpty(lines[i].trim()) {
                        continue
                    }
                    let logLine = LogLine(namespace: info.name, line: lines[i])
                    if logLine.time < startingPoint {
                        let negativeOffset = lines.take(i + 1)
                                .map({ UInt64(($0 + "\n").characters.count) })
                                .reduce(0, +)
                        let current = Int64(fileLength) - Int64(offset)
                                + Int64(negativeOffset) + Int64(sizeDiff)
                        self.offset = UInt64(max(current, Int64(0)))
                        return
                    }
                }

            }
        }
    }

    func stop() {
        Log.info?.message("Stopping tracker \(info.name)")
        fileHandle?.closeFile()
        fileHandle = nil
        
        _lines.clear()
        
        // try to truncate log file when stopping
        if let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
           fileManager.fileExists(atPath: path), !hearthstone.isHearthstoneRunning {
            let file = FileHandle(forWritingAtPath: path)
            file?.truncateFile(atOffset: UInt64(0))
            file?.closeFile()
            offset = 0
        }
        stopped = true
    }
    
    func collect() -> [LogLine] {
        var items = [LogLine]()
        let size = _lines.count
        
        for _ in 0..<size {
            if let elem = _lines.dequeue() {
                items.append(elem)
            }
        }

        return items
    }
}

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
    var startingPoint: NSDate = NSDate.distantPast()
    var fileHandle: NSFileHandle?

    var path: String
    let fileManager = NSFileManager()
    private var info: LogReaderInfo
    private var logReaderManager: LogReaderManager?

    private var queue: dispatch_queue_t?

    init(info: LogReaderInfo) {
        self.info = info

        self.path = Hearthstone.instance.logPath + "/Logs/\(info.name).log"
        Log.info?.message("Init reader for \(info.name) at path \(self.path)")
        if fileManager.fileExistsAtPath(self.path)
            && !Hearthstone.instance.isHearthstoneRunning {
            do {
                try fileManager.removeItemAtPath(self.path)
            } catch let error as NSError {
                Log.error?.message("\(error.description)")
            }
        }
    }

    func findEntryPoint(choice: String) -> NSDate {
        return findEntryPoint([choice])
    }

    func findEntryPoint(choices: [String]) -> NSDate {
        guard fileManager.fileExistsAtPath(path) else {
            return NSDate.distantPast()
        }
        var fileContent: String
        do {
            fileContent = try String(contentsOfFile: path)
        } catch {
            return NSDate.distantPast()
        }

        let lines: [String] = fileContent
            .componentsSeparatedByString("\n")
            .filter({ !String.isNullOrEmpty($0) }).reverse()
        for line in lines {
            if choices.any({ line.rangeOfString($0) != nil }) {
                Log.verbose?.message("Found \(line)")
                return LogLine.parseTimeAsDate(line)
            }
        }

        return NSDate.distantPast()
    }

    func start(logReaderManager: LogReaderManager, entryPoint: NSDate) {
        stopped = false
        self.logReaderManager = logReaderManager
        startingPoint = entryPoint

        var queueName = "be.michotte.hstracker.readers.\(info.name)"
        if let filter = info.startsWithFilters.first {
            queueName += ".\(filter.lowercaseString)"
        }
        queue = dispatch_queue_create(queueName, nil)
        if let queue = queue {
            Log.info?.message("Starting to track \(info.name)")
            Log.verbose?.message("\(info.name) has queue \(queueName) " +
                "starting at \(startingPoint.millisecondsFormatted)")
            dispatch_async(queue) {
                self.readFile()
            }
        }
    }

    func readFile() {
        Log.verbose?.message("reading \(path)")

        if fileManager.fileExistsAtPath(path) {
            fileHandle = NSFileHandle(forReadingAtPath: path)
            findInitialOffset()
            Log.verbose?.message("file exists \(path), " +
                "offset for \(startingPoint.millisecondsFormatted) " +
                "is \(offset)")
        }

        while !stopped {
            if fileHandle == .None && fileManager.fileExistsAtPath(path) {
                fileHandle = NSFileHandle(forReadingAtPath: path)
                findInitialOffset()
            }

            if let data = fileHandle?.readDataToEndOfFile() {
                if let linesStr = String(data: data, encoding: NSUTF8StringEncoding) {

                    let lines = linesStr
                        .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                        .filter { !$0.isEmpty && $0.startsWith("D ") && $0.length > 20 }

                    if !lines.isEmpty {
                        for line in lines {
                            offset += UInt64((line + "\n")
                                .lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                            let cutted = line.substringFromIndex(line.startIndex.advancedBy(19))

                            if !info.hasFilters
                                || info.startsWithFilters.any({ cutted.startsWith($0) })
                                || info.containsFilters.any({ cutted.containsString($0) }) {

                                let logLine = LogLine(namespace: info.name,
                                                      line: line,
                                                      include: info.include)
                                if logLine.time >= startingPoint {
                                    logReaderManager?.processLine(logLine)
                                }
                            }
                        }
                    }
                }

                if !fileManager.fileExistsAtPath(path) {
                    Log.verbose?.message("setting \(path) handle to nil \(offset))")
                    fileHandle = nil
                }
            }

            NSThread.sleepForTimeInterval(0.1)
        }
    }

    func findInitialOffset() {
        guard fileManager.fileExistsAtPath(path) else { return }

        var offset: UInt64 = 0
        guard let fileHandle = NSFileHandle(forReadingAtPath: path) else { return }
        fileHandle.seekToEndOfFile()
        let fileLength = fileHandle.offsetInFile
        fileHandle.seekToFileOffset(0)

        while offset < fileLength {
            let sizeDiff = 4096 - min(fileLength - offset, UInt64(4096))
            offset += 4096
            let fileOffset: UInt64 = UInt64(max(Int64(fileLength) - Int64(offset), Int64(0)))
            fileHandle.seekToFileOffset(fileOffset)
            let data = fileHandle.readDataOfLength(4096)
            if let string = String(data: data, encoding: NSASCIIStringEncoding) {
                
                var skip: UInt64 = 0
                for i in 0...4096 {
                    skip += 1
                    if i >= string.characters.count || string.charAt(i) == "\n" {
                        break
                    }
                }
                offset -= skip
                let lines = String(string.characters.dropFirst(Int(skip)))
                    .componentsSeparatedByString("\n")
                    for i in 0...(lines.count - 1) {
                        if String.isNullOrEmpty(lines[i].trim()) {
                            continue
                        }
                        let logLine = LogLine(namespace: info.name, line: lines[i])
                        if logLine.time < startingPoint {
                            let negativeOffset = lines.take(i + 1)
                                .map({ UInt64(($0 + "\n").characters.count) })
                                .reduce(0, combine: +)
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

        // try to truncate log file when stopping
        if fileManager.fileExistsAtPath(path)
            && !Hearthstone.instance.isHearthstoneRunning {
            let file = NSFileHandle(forWritingAtPath: path)
            file?.truncateFileAtOffset(UInt64(0))
            file?.closeFile()
            offset = 0
        }
        stopped = true
    }
}

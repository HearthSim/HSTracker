//
//  DecksReaderManager.swift
//  HSTracker
//
//  Created by Martin Bonnin on 16/05/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class DecksReader {
    let queue = DispatchQueue(label: "decks.log", attributes: [])
    var stopped = false
    
    private var path = "/Applications/Hearthstone//Logs/Decks.log"
    private let fileManager = FileManager()

    init() {
        
    }
    
    func start() {
        logger.verbose("Start reading Decks.log")

        queue.async {
            self.readFile()
        }
    }
    
    func stop() {
        stopped = true
    }
    
    func readFile() {
        var fileHandle: FileHandle?
        var offset = UInt64(0)
        
        while !stopped {
            if fileHandle == nil && fileManager.fileExists(atPath: path) {
                fileHandle = FileHandle(forReadingAtPath: path)
            }
            
            fileHandle?.seek(toFileOffset: offset)

            if let data = fileHandle?.readDataToEndOfFile(), data.count > 0 {
                offset += UInt64(data.count)
                let linesStr = String(decoding: data, as: UTF8.self)
                DispatchQueue.main.async {
                    let lines = linesStr.components(separatedBy: CharacterSet.newlines)
                        
                    for line in lines {
                        logger.debug("Deck: \(line)")
                        //TODO: should we do something with this?
                    }
                }
            }

            if !fileManager.fileExists(atPath: path) {
                fileHandle = nil
                offset = 0
            }

            Thread.sleep(forTimeInterval: LogReaderManager.updateDelay)
        }
    }
}

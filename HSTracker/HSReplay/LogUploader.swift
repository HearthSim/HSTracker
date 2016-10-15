//
//  LogUploader.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import Wrap
import ZipArchive

class LogUploader {
    private static var inProgress: [UploaderItem] = []
    
    static func upload(filename: String, completion: UploadResult -> ()) {
        guard let tmp = ReplayMaker.tmpReplayDir() else {
            completion(.failed(error: "Can not get tmp dir"))
            return
        }
    
        if !SSZipArchive.unzipFileAtPath(filename, toDestination: tmp) {
            completion(.failed(error: "Can not unzip \(filename)"))
            return
        }
        
        let output = "\(tmp)/output_log.txt"
        if !NSFileManager.defaultManager().fileExistsAtPath(output) {
            completion(.failed(error: "Can not find \(output)"))
            return
        }
        do {
            let content = try String(contentsOfURL: NSURL(fileURLWithPath: output))
            let lines = content.componentsSeparatedByString("\n")
            if lines.isEmpty {
                completion(.failed(error: "Log is empty"))
                return
            }
            
            if lines.first?.hasPrefix("[") ?? true {
                completion(.failed(error: "Output log not supported"))
                return
            }
            if lines.first?.contains("PowerTaskList.") ?? true {
                completion(.failed(error: "PowerTaskList is not supported"))
                return
            }
            if !lines.any({ $0.contains("CREATE_GAME") }) {
                completion(.failed(error: "'CREATE_GAME' not found"))
                return
            }
            
            var date: NSDate? = nil
            do {
                let attr: NSDictionary? = try NSFileManager.defaultManager()
                    .attributesOfItemAtPath(output)
                
                if let _attr = attr {
                    date = _attr.fileCreationDate()
                }
            } catch {
                print("\(error)")
            }

            guard let _ = date else {
                completion(.failed(error: "Cannot find game start date"))
                return
            }
            if let line = lines.first({ $0.contains("CREATE_GAME") }) {
                let gameStart = LogLine.parseTimeAsDate(line)
                date = NSDate.NSDateFromYear(year: date!.year,
                                             month: date!.month,
                                             day: date!.day,
                                             hour: gameStart.hour,
                                             minute: gameStart.minute,
                                             second: gameStart.second)
            }
            
            self.upload(lines, game: nil, statistic: nil,
                        gameStart: date, fromFile: true) { (result) in
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(output)
                } catch {
                    Log.error?.message("Can not remove tmp files")
                }
                completion(result)
            }
        } catch {
            return completion(.failed(error: "Can not read \(output)"))
        }
    }

    static func upload(logLines: [LogLine], game: Game?, statistic: Statistic?,
                       gameStart: NSDate? = nil, fromFile: Bool = false,
                       completion: UploadResult -> ()) {
        let log = logLines.sort { $0.time < $1.time }.map { $0.line }
        upload(log, game: game, statistic: statistic, gameStart: gameStart,
               fromFile: fromFile, completion: completion)
    }

    static func upload(logLines: [String], game: Game?, statistic: Statistic?,
                       gameStart: NSDate? = nil, fromFile: Bool = false,
                       completion: UploadResult -> ()) {
        guard let token = Settings.instance.hsReplayUploadToken else {
            Log.error?.message("Authorization token not set yet")
            completion(.failed(error: "Authorization token not set yet"))
            return
        }

        if logLines.filter({ $0.contains("CREATE_GAME") }).count != 1 {
            completion(.failed(error: "Log contains none or multiple games"))
            return
        }
        
        let log = logLines.joinWithSeparator("\n")
        if logLines.isEmpty || log.trim().isEmpty {
            Log.warning?.message("Log file is empty, skipping")
            completion(.failed(error: "Log file is empty"))
            return
        }
        let item = UploaderItem(hash: log.hash)
        if inProgress.contains(item) {
            inProgress.append(item)
            Log.info?.message("\(item.hash) already in progress. Waiting for it to complete...")
            completion(.failed(error:
                "\(item.hash) already in progress. Waiting for it to complete..."))
            return
        }
        
        inProgress.append(item)
        
        do {
            let uploadMetaData = UploadMetaData(log: logLines,
                                                game: game,
                                                statistic: statistic,
                                                gameStart: gameStart)
            if let date = uploadMetaData.dateStart where fromFile {
                uploadMetaData.hearthstoneBuild = BuildDates.getByDate(date)?.build
            } else if let build = BuildDates.getByProductDb() {
                uploadMetaData.hearthstoneBuild = build.build
            } else {
                uploadMetaData.hearthstoneBuild = BuildDates.getByDate(NSDate())?.build
            }
            let metaData: [String : AnyObject] = try Wrap(uploadMetaData)
            Log.info?.message("Uploading \(item.hash) -> \(metaData)")

            let headers = [
                "X-Api-Key": HSReplayAPI.apiKey,
                "Authorization": "Token \(token)"
            ]

            let http = Http(url: HSReplay.uploadRequestUrl)
            http.json(.post,
                      parameters: metaData,
                      headers: headers) { json in
                        if let json = json as? [String: AnyObject],
                            putUrl = json["put_url"] as? String,
                            uploadShortId = json["shortid"] as? String {

                            if let data = log.dataUsingEncoding(NSUTF8StringEncoding) {
                                do {
                                    let gzip = try data.gzippedData()

                                    let http = Http(url: putUrl)
                                    http.upload(.put,
                                                headers: [
                                                    "Content-Type": "text/plain",
                                                    "Content-Encoding": "gzip"
                                        ],
                                                data: gzip)
                                } catch {
                                    Log.error?.message("can not gzip")
                                }
                            }

                            if let statistic = statistic {
                                statistic.hsReplayId = uploadShortId
                                if let deck = statistic.deck {
                                    Decks.instance.update(deck)
                                }
                            }

                            let result = UploadResult.successful(replayId: uploadShortId)

                            Log.info?.message("\(item.hash) upload done: Success")
                            inProgress = inProgress.filter({ $0.hash == item.hash })

                            completion(result)
                            return
                        }
            }
        } catch {
            Log.error?.message("\(error)")
            completion(.failed(error: "\(error)"))
        }
    }
    
    struct UploaderItem: Equatable {
        let hash: Int
    }
}
func == (lhs: LogUploader.UploaderItem, rhs: LogUploader.UploaderItem) -> Bool {
    return lhs.hash == rhs.hash
}

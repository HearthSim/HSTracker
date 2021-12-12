//
//  LogUploader.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap
import Gzip
import RealmSwift
import RegexUtil

class LogUploader {
    private static var inProgress: [UploaderItem] = []
    
    static func upload(logLines: [LogLine], buildNumber: Int, metaData: (metaData: UploadMetaData, statId: String )? = nil,
                       gameStart: Date? = nil, fromFile: Bool = false,
                       completion: @escaping (UploadResult) -> Void) {
        let log = logLines.sorted {
            return $0.time < $1.time
            }.map { $0.line }
        upload(logLines: log, buildNumber: buildNumber, metaData: metaData, gameStart: gameStart,
               fromFile: fromFile, completion: completion)
    }

    static func upload(logLines: [String], buildNumber: Int, metaData: (metaData: UploadMetaData, statId: String )? = nil,
                       gameStart: Date? = nil, fromFile: Bool = false,
                       completion: @escaping (UploadResult) -> Void) {
        guard let token = Settings.hsReplayUploadToken else {
            logger.error("HSReplay upload failed: Authorization token not set yet")
            completion(.failed(error: "Authorization token not set yet"))
            return
        }

        var lines = logLines
        let numCreates = logLines.filter({ $0.contains("CREATE_GAME") }).count
        if numCreates != 1 {
            logger.error("HSReplay upload: Log contains none or multiple games (\(numCreates))")
            // remove every line before _last_ create game
            if let index = logLines.reversed().firstIndex(where: { $0.contains("CREATE_GAME") }) {
                lines = logLines.reversed()[...index].reversed() as [String]
            } else {
                completion(.failed(error: "Log contains none or multiple games"))
                return
            }
        }
        
        let log = lines.joined(separator: "\n")
        if lines.isEmpty || log.trim().isEmpty {
            logger.warning("Log file is empty, skipping")
            completion(.failed(error: "Log file is empty"))
            return
        }
        let item = UploaderItem(hash: log.hash)
        if inProgress.contains(item) {
            inProgress.append(item)
            logger.info("\(item.hash) already in progress. Waiting for it to complete...")
            completion(.failed(error:
                "\(item.hash) already in progress. Waiting for it to complete..."))
            return
        }
        
        inProgress.append(item)

        metaData?.metaData.hearthstoneBuild = buildNumber

        guard let wrappedMetaData: [String: Any] = try? wrap(metaData?.metaData) else {
            logger.warning("Can not encode to json game metadata")
            completion(.failed(error: "Can not encode to json game metadata"))
            return
        }
//        logger.debug("Upload metadata: \(wrappedMetaData)")
        logger.info("Uploading \(item.hash)")

        let headers = [
            "X-Api-Key": HSReplayAPI.apiKey,
            "Authorization": "Token \(token)"
        ]

        let statId: String? = metaData?.statId

        let http = Http(url: HSReplay.uploadRequestUrl)
        http.json(method: .post,
                  parameters: wrappedMetaData,
                  headers: headers) { jsonData in

                    guard let json = jsonData as? [String: Any],
                        let putUrl = json["put_url"] as? String,
                        let uploadShortId = json["shortid"] as? String,
                        let replayUrl = json["url"] as? String
                    else {
                            logger.error("JSON Error : \(String(describing: jsonData))")
                            let message = "Can not gzip : \(String(describing: jsonData))"
                            completion(.failed(error: message))
                            return
                    }

                    guard let data = log.data(using: .utf8) else {
                        logger.error("Can not convert log to data")
                        completion(.failed(error: "Can not convert log to data"))
                        return
                    }
                    guard let gzip = try? data.gzipped() else {
                        logger.error("Can not gzip log")
                        completion(.failed(error: "Can not gzip log"))
                        return
                    }
                    
                    logger.info("putURL: \(putUrl), replayUrl: \(replayUrl), shortid: \(uploadShortId)")

                    let http = Http(url: putUrl)
                    http.upload(method: .put,
                                headers: [
                                    "Content-Type": "text/plain",
                                    "Content-Encoding": "gzip"
                        ],
                                data: gzip)

                    logger.info("\(item.hash) upload done: Success")
                    inProgress = inProgress.filter({ $0.hash == item.hash })

                    let gt = metaData?.metaData.gameType
                    if gt != BnetGameType.bgt_battlegrounds.rawValue && gt != BnetGameType.bgt_battlegrounds_friendly.rawValue && gt != BnetGameType.bgt_mercenaries_pve.rawValue && gt != BnetGameType.bgt_mercenaries_pvp.rawValue && gt != BnetGameType.bgt_mercenaries_friendly.rawValue && gt != BnetGameType.bgt_mercenaries_pve_coop.rawValue {
                            guard let statId = statId,
                                let existing = RealmHelper.getGameStat(with: statId)  else {
                                        logger.error("Can not update statistic")
                                        completion(.failed(error: "Can not update statistic"))
                                        return
                            }
                            RealmHelper.update(stat: existing, hsReplayId: uploadShortId)
                    }
            
                    completion(.successful(replayId: uploadShortId))
        }
    }
}

private struct UploaderItem {
    let hash: Int
}

extension UploaderItem: Equatable {
    static func == (lhs: UploaderItem, rhs: UploaderItem) -> Bool {
        return lhs.hash == rhs.hash
    }
}

//
//  CollectionUploader.swift
//  HSTracker
//
//  Created by Richard Lee on 2018/8/5.
//  Copyright © 2018 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

class CollectionUploader {
    static func upload(collectionData: UploadCollectionData, completion: @escaping(CollectionUploadResult) -> Void) {

        logger.debug("Start Wrapping \(NSDate().timeIntervalSince1970)")
        guard let data: Data = try? wrap(collectionData) else {
            logger.error("Can not convert collection to data")
            completion(.failed(error: "101"))
            return
        }
        logger.debug("Stop Wrapping \(NSDate().timeIntervalSince1970)")

        HSReplayAPI.claimBattleTag(complete: {
            HSReplayAPI.getUploadCollectionToken(handle: { token in
                logger.verbose("Got upload collection token \(token)")
                guard !token.isBlank else {
                    logger.error("Collection token is empty")
                    completion(.failed(error: "102"))
                    return
                }

                let http = Http(url: token)
                http.upload(method: .put,
                    headers: [
                        "Content-Type": "application/json"
                    ],
                    data: data)

                logger.info("Collection upload done: Success")
                completion(.successful)
            }, failed: {
                logger.error("Failed to obtain collection upload token")
                completion(.failed(error: "103"))
            })
        }, failed: {
            logger.error("Failed to claim battle Tag")
            completion(.failed(error: "104"))
        })
    }
}

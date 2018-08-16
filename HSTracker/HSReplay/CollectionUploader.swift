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
    static func upload(collectionData: UploadCollectionData, completion: @escaping(UploadResult) -> Void) {
        guard let wrappedMetaData: [String: Any] = try? wrap(collectionData) else {
            logger.warning("Can not encode to json game metadata")
            completion(.failed(error: "Can not encode to json game metadata"))
            return
        }

        print(wrappedMetaData)
    }
}
